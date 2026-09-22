#!/usr/bin/env bash
# Gemini bridge. Backend: Gemini CLI (preferred, if installed) or REST API (GEMINI_API_KEY).
# Usage: gemini.sh [-m model] [-f prompt.md] [--] [context files...]   (prompt also from stdin)
# Env: GEMINI_MODEL, GEMINI_BACKEND=auto|cli|api, GEMINI_API_KEY, GEMINI_TIMEOUT (s, default 300)
set -euo pipefail
MODEL="${GEMINI_MODEL:-gemini-2.5-pro}"; PF=""; BACKEND="${GEMINI_BACKEND:-auto}"
while getopts "m:f:h" o; do
  case $o in m) MODEL=$OPTARG;; f) PF=$OPTARG;; *) sed -n 2,5p "$0"; exit 2;; esac
done
shift $((OPTIND-1)); [ "${1:-}" = "--" ] && shift
TMP=$(mktemp); trap 'rm -f "$TMP" "$TMP.json"' EXIT
if [ -n "$PF" ]; then cat "$PF" > "$TMP"; elif [ ! -t 0 ]; then cat > "$TMP"; else echo "gemini.sh: no prompt (-f or stdin)" >&2; exit 2; fi
for f in "$@"; do printf '\n\n=== FILE: %s ===\n' "$f" >> "$TMP"; cat "$f" >> "$TMP"; done

use_cli() { command -v gemini >/dev/null 2>&1; }
if [ "$BACKEND" = "cli" ] || { [ "$BACKEND" = "auto" ] && use_cli; }; then
  timeout "${GEMINI_TIMEOUT:-300}" gemini -m "$MODEL" -p "Execute the task described in the input (stdin). Answer concisely and specifically." < "$TMP"
  exit $?
fi
[ -n "${GEMINI_API_KEY:-}" ] || { echo "gemini.sh: no Gemini CLI or GEMINI_API_KEY" >&2; exit 3; }
python3 - "$TMP" > "$TMP.json" <<'PY'
import json,sys
print(json.dumps({"contents":[{"role":"user","parts":[{"text":open(sys.argv[1],encoding="utf-8").read()}]}]}))
PY
curl -sS --fail-with-body -m "${GEMINI_TIMEOUT:-300}" \
  -H "Content-Type: application/json" -H "x-goog-api-key: ${GEMINI_API_KEY}" \
  --data-binary @"$TMP.json" \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
| python3 -c '
import json,sys
r=json.load(sys.stdin)
try: print("".join(p.get("text","") for p in r["candidates"][0]["content"]["parts"]))
except Exception: print(json.dumps(r,indent=2)); sys.exit(4)
u=r.get("usageMetadata",{}); print(f"\n<!-- gemini tokens in={u.get(\"promptTokenCount\")} out={u.get(\"candidatesTokenCount\")} -->")'

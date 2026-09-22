#!/usr/bin/env bash
# Usage: new-session.sh "<topic>" [tier]  -> prints session dir
set -euo pipefail
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
TOPIC="${1:?topic required}"; TIER="${2:-?}"
SLUG=$(python3 -c '
import re,sys,unicodedata
t=sys.argv[1].replace("ł","l").replace("Ł","L")
t=unicodedata.normalize("NFKD",t).encode("ascii","ignore").decode().lower()
print(re.sub(r"[^a-z0-9]+","-",t).strip("-")[:40])' "$TOPIC")
DIR="$PROJ/.council/sessions/$(date +%Y%m%d-%H%M%S)-${SLUG:-session}"
mkdir -p "$DIR"
printf '{"topic":%s,"tier":"%s","created":"%s","rounds":[]}\n' \
  "$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1],ensure_ascii=False))' "$TOPIC")" "$TIER" "$(date -u +%FT%TZ)" > "$DIR/meta.json"
printf '%s\n' "${DIR#$PROJ/}"

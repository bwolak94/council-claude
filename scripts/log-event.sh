#!/usr/bin/env bash
# Hook sink: appends hook payload (stdin JSON) to .council/logs/events.jsonl
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"; D="$PROJ/.council/logs"
[ -d "$D" ] || exit 0
payload=$(cat); [ -n "$payload" ] || payload=null
printf '{"ts":"%s","event":"%s","data":%s}\n' "$(date -u +%FT%TZ)" "${1:-event}" "$payload" >> "$D/events.jsonl"
exit 0

#!/usr/bin/env bash
# Sync plugin assets into <project>/.council. Without --init runs only if .council already exists.
set -euo pipefail
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
C="$PROJ/.council"
[ "${1:-}" = "--init" ] || [ -d "$C" ] || exit 0
mkdir -p "$C"/{bin,sessions,plans,decisions,logs,templates}
cp -f "$ROOT"/scripts/{gemini.sh,new-session.sh,log-event.sh} "$C/bin/"
chmod +x "$C"/bin/*.sh
cp -f "$ROOT/templates/PROTOCOL.md" "$C/PROTOCOL.md"
cp -f "$ROOT"/templates/*.md "$C/templates/"
[ -f "$C/config.json" ] || cp "$ROOT/config/council.config.json" "$C/config.json"
[ -f "$C/decisions/INDEX.md" ] || printf '# Decisions index\n\n| ADR | Date | Tier | Topic | Decision | Session |\n|---|---|---|---|---|---|\n' > "$C/decisions/INDEX.md"
[ -f "$C/decisions/rejected-ideas.md" ] || printf '# Rejected ideas (global)\n\nRejected options from all sessions — check before proposing something again.\n\n' > "$C/decisions/rejected-ideas.md"
[ "${1:-}" = "--init" ] && echo "council: initialized $C"
exit 0

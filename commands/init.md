---
description: Initializes .council/ in the project (config, scripts, templates)
allowed-tools: Bash, Read
---
Run: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh" --init`
If the variable is empty / file does not exist: find the script `find ~/.claude/plugins -path '*council*' -name bootstrap.sh | head -1` and run it with `--init`.
Then:
- check `command -v gemini` and whether `GEMINI_API_KEY` is set (do not print the value) — report the available Gemini backend,
- suggest adding `.council/logs/` to `.gitignore` (sessions and decisions stay in the repo — they are documentation).
Return a brief status.

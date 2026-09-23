---
description: Review of decisions, rejected ideas, and council sessions
argument-hint: [ADR-NNN | search phrase | --rejected | --stats]
allowed-tools: Read, Grep, Glob, Bash
---
Argument: $ARGUMENTS
- none: last 10 rows of `.council/decisions/INDEX.md` + session count.
- `ADR-NNN`: show decision.md and rejected.md for that session (abbreviated).
- phrase: Grep in `.council/decisions/`, `.council/sessions/*/decision.md`, `rejected.md`, `transcript.md`; print hits with links.
- `--rejected`: `.council/decisions/rejected-ideas.md` grouped thematically.
- `--stats`: from `.council/logs/decisions.jsonl` — tier distribution, average round count, % early stop, model usage per role, number of fix loops. Use python3/jq via Bash.
Do not modify anything.

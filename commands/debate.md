---
description: Council sub-agent debate over a decision → ADR, transcript, rejected
argument-hint: <decision question> [--tier M|L|XL] [--rounds N] [--gemini|--no-gemini] [--members a,b,c]
allowed-tools: Task, Read, Write, Bash, Glob, Grep
---
Topic: $ARGUMENTS

You are the ORCHESTRATOR. You do not take a substantive position — you run the process. Protocol: `.council/PROTOCOL.md`.

**Setup**
1. Load `.council/config.json`. Tier from `--tier` or from `triage` (minimum M for debate).
2. Composition: `members` from tier (or `--members`) + `gemini-bridge` if `--gemini` or tier.gemini ≠ off (and no `--no-gemini`). Rounds: `--rounds` or tier.rounds (max limits.maxRounds).
3. `SESSION=$(bash .council/bin/new-session.sh "<topic>" <tier>)`.
4. Write `$SESSION/00-brief.md`: decision question, context (file paths, not content), constraints, evaluation criteria, known options with IDs (A, B, …), related ADRs and rejected ideas from `rejected-ideas.md`.

**Rounds (N = 1..rounds)**
5. Call members IN PARALLEL (multiple Task calls in one response), each with the `model` parameter from config for that role. Prompt: `Session: $SESSION. Round: N. Perform your role per .council/PROTOCOL.md.` — do not paste file content, agents read it themselves.
6. Collect status lines. **Early stop**: all same option and min(confidence) ≥ limits.earlyStopConfidence → stop rounds.
7. If there will be another round: `scribe` in `digest` mode for round N. If files contain `@agent` questions — ensure the addressee is in the next round's composition.

**Decision**
8. `judge` (model = tier.judge) → `$SESSION/decision.md`.
9. `scribe` in `finalize` mode → transcript.md, rejected.md, INDEX.md, rejected-ideas.md, decisions.jsonl, meta.json.

**User report** (brief): ADR-NNN, decision, 3 key arguments, rejected options with reason, dissent, number of rounds / early stop, models used, session path.

If judge returns `proposed` (no resolution) — show what is missing and ask the user, instead of running more rounds.
Model per invocation: pass the `model` parameter of the Task tool; if your version of Claude Code does not support it, the `model:` from the agent's frontmatter applies.

---
description: Full pipeline: triage → plan → (council) → implement → review → test
argument-hint: <task> | --plan <plan path> [--tier S|M|L|XL] [--gemini]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep
---
Task: $ARGUMENTS

1. **Triage** (`triage`, haiku) — unless `--tier` or `--plan` is provided. Show tier + models in 1 line.
2. **Plan**: tier S → skip. Tier ≥M without `--plan` → /council:plan procedure; wait for user acceptance.
3. **Open decisions**: decision points without ADR, and tier.council=true → /council:debate procedure. Tier M: `judge` (model tier.judge) decides alone without rounds, based on the plan — still saves ADR via `scribe`.
4. **Implementation**: `implementer` with `model`=tier.implementer. Large plan → group independent steps into parallel calls (max limits.maxParallelAgents), dependent ones sequentially. `blocker` from implementer → mini-debate (M: judge alone; L+: /council:debate with rounds=1).
5. **Review**: `reviewer` (tier.reviewer); tier.gemini ∈ {second-opinion,on} or `--gemini` → parallel `gemini-bridge` second-opinion on `git diff`. Blocker-level discrepancies between reviewer and Gemini → `judge`.
6. **Fix loop**: CHANGES_REQUESTED → implementer with findings list; max limits.maxFixLoops, then escalate to user.
7. **Tests**: `tester` (tier.tester, if not null).
8. **Log**: append to `.council/logs/decisions.jsonl` `{"ts","type":"build","task","tier","models","fix_loops","verdict","adrs":[...]}`.
Report: changed files, ADRs, review/test result, what was left out of scope. Do not commit without a request.

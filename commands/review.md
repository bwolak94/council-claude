---
description: Change review by reviewer + skeptic (+ Gemini), conflicts resolved by judge
argument-hint: [git scope, e.g. main...HEAD] [--gemini] [--tier M|L|XL]
allowed-tools: Task, Read, Bash, Write
---
Scope: $ARGUMENTS (default `git diff HEAD` + staged).
1. `git diff --stat` for scope → tier heuristically (≤3 files: M, more or auth/migration/API files: L) unless `--tier`.
2. In parallel: `reviewer` (tier.reviewer), `skeptic` (tier.members.skeptic or haiku for M) instructed to focus on failure scenarios, and `gemini-bridge` second-opinion if `--gemini`/tier.gemini ≠ off.
3. Merge findings (dedup by file:line). Conflicting verdicts for blocker/major → `judge` resolves only those points.
4. Save report `.council/sessions/<ts>-review-<slug>/review.md` (use new-session.sh) and append a `type:"review"` line to decisions.jsonl.
Show: verdict, blockers/majors with fixes, who reported them (reviewer/skeptic/gemini), points resolved by judge.

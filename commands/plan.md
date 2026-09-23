---
description: Planning session (planner in plan mode) + optional debate over decisions
argument-hint: <task> [--tier S|M|L|XL] [--council] [--gemini]
allowed-tools: Task, Read, Write, Bash
---
Task: $ARGUMENTS

1. **Triage**: if `--tier` is missing, call `triage`. Load `.council/config.json`. If `.council/` does not exist — first execute the steps from /council:init.
2. **Planner**: call the `planner` sub-agent with parameter `model` = tier.planner (for S: inform that a plan is unnecessary and exit, unless the user insists). Pass: task, triage result, related ADRs.
3. **Gemini (optional)**: if `--gemini` or tier.gemini ∈ {second-opinion,on} — `gemini-bridge` in `second-opinion` mode with the plan: "identify gaps, risks, better alternatives". Attach notes as a "Gemini Notes" section.
4. **Decisions**: for each plan decision marked "requires council: yes" (or all with `--council`) run a debate per /council:debate (same procedure, separate session per decision). Insert resulting ADRs into the plan in place of the decision.
5. Save the plan: `.council/plans/<YYYYMMDD-HHMM>-<slug>.md` (with header: tier, models, ADR links). Append `{"ts","type":"plan","path","tier"}` to `.council/logs/decisions.jsonl`.
6. Present the plan and ask for acceptance before any implementation. After acceptance, suggest `/council:build --plan <path>`.

Note: if the main session is in native plan mode (Shift+Tab), file writing will only happen after exiting plan mode — then present the plan via ExitPlanMode and save it after acceptance.

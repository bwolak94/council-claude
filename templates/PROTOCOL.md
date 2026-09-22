# Council Protocol (blackboard)

Sub-agents do NOT communicate directly — Claude Code does not allow a sub-agent to call another sub-agent.
Communication goes through session files; the main thread (orchestrator) runs the rounds.

## Session structure
.council/sessions/<ts>-<slug>/
  00-brief.md            problem, context, decision question, known options, constraints
  round-N/<agent>.md     agent's position in round N (format below)
  round-N/_digest.md     round summary (scribe) — from round 2 read digest instead of full files
  decision.md            ADR (judge)
  rejected.md            what was rejected, by whom, why (scribe)
  transcript.md          condensed proceedings (scribe)
  meta.json              tier, models, rounds, early-stop

Globally: .council/decisions/INDEX.md, .council/decisions/rejected-ideas.md, .council/logs/*.jsonl

## Position format (round-N/<agent>.md)
---
agent: <name>
round: <N>
option: <ID>
confidence: <0.0-1.0>
changed: <true|false>
---
## Position            (max 5 sentences)
## Arguments           (bullet points, concrete: files, costs, risks)
## I reject            (- <option>: <reason>)  — MANDATORY, min 1 entry
## Responses           (to questions directed at me: `@<agent>` from the previous round)
## Questions           (`@architect: ...` — to specific agents, max 2)
## Change of mind      (if changed=true: what convinced me and whose argument)

## Rules
- Options have IDs (A, B, C...). A new option = new ID + description in the Position section.
- Every claim about code backed by a file path / line. No fluff.
- Do not repeat arguments from the previous round — only the delta.
- Early stop: all agents point to the same option and min(confidence) >= threshold from config.

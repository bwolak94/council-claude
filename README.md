# council

> Multi-agent dev council plugin for Claude Code — cost-aware triage, structured planning, parallel sub-agent debates with ADR output, Gemini as an additional voice.

---

## Overview

`council` is a Claude Code plugin that brings a team of specialized AI agents to your development workflow. Instead of a single model attempting everything, tasks are routed by complexity: trivial fixes run on haiku, cross-cutting changes go through a full structured debate with architect, skeptic, and pragmatist agents, and irreversible decisions get a judge-written ADR with a mandatory rejected-options log.

All decisions, plans, transcripts, and rejection history live as Markdown files in your repo — human-readable documentation that future agents (and future you) can read before proposing something that was already tried and rejected.

---

## Requirements

- Claude Code with plugin support
- Python 3 (for slug generation and JSON formatting in scripts)
- **Gemini (optional):** either [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and on `$PATH`, or `GEMINI_API_KEY` set in your environment

---

## Installation

```bash
# Clone the plugin next to your project (or anywhere on disk)
git clone https://github.com/bwolak94/council-claude ~/.claude/plugins/council

# In your project, initialize .council/
/council:init
```

`/council:init` copies scripts to `.council/bin/`, seeds `config.json`, `PROTOCOL.md`, `decisions/INDEX.md`, and `rejected-ideas.md`. It also reports which Gemini backend is available.

Add logs to `.gitignore` (sessions and decisions stay in the repo):

```gitignore
.council/logs/
```

The `SessionStart` hook in `hooks/hooks.json` runs `bootstrap.sh` automatically on every new Claude Code session — so after the first `/council:init`, subsequent sessions stay in sync without manual steps.

---

## Commands

| Command | Description |
| --- | --- |
| `/council:init` | Initialize `.council/` in the project |
| `/council:triage <task>` | Classify complexity (S/M/L/XL) and select models — no implementation |
| `/council:plan <task>` | Planner in read-only mode; optional debate over open decisions |
| `/council:debate <question>` | Full council debate → ADR, transcript, rejected log |
| `/council:build <task>` | Complete pipeline: triage → plan → council → implement → review → test |
| `/council:review [scope]` | Review changes: reviewer + skeptic in parallel, judge resolves conflicts |
| `/council:gemini <question>` | Query Gemini directly as an external opinion |
| `/council:log [args]` | Browse decisions, search, view rejected ideas, show stats |

### `/council:triage`

```text
/council:triage "add rate limiting to the API"
```

Returns a JSON summary: tier, reason, files estimate, model per role, decision points, related ADRs. Does not implement anything. Use this when you want to understand the cost of a task before committing.

### `/council:plan`

```text
/council:plan "refactor auth module to support OAuth" --tier L
/council:plan "migrate to Zod" --council --gemini
```

Runs the `planner` agent in `permissionMode: plan` (read-only). Produces a structured plan with numbered steps, acceptance criteria, decision points, rejected approaches, and rollback notes. Decision points marked "requires council: yes" can automatically trigger `/council:debate`.

Flags: `--tier S|M|L|XL`, `--council` (debate all decisions), `--gemini` (Gemini second-opinion on the plan).

### `/council:debate`

```text
/council:debate "Zod vs Valibot for schema validation" --tier L
/council:debate "Redis vs in-process cache" --rounds 2 --gemini
```

Runs a structured multi-round debate:

1. Creates a session under `.council/sessions/`
2. Writes `00-brief.md` with decision question, options (A/B/C…), constraints, and related ADRs
3. Runs council members **in parallel** each round; scribe writes `_digest.md` between rounds
4. Early stop when all members agree and `min(confidence) ≥ 0.75`
5. Judge writes `decision.md` (ADR) — based on argument quality, not votes
6. Scribe finalizes `transcript.md`, `rejected.md`, updates `INDEX.md`, `rejected-ideas.md`, and `decisions.jsonl`

Flags: `--tier M|L|XL`, `--rounds N`, `--gemini` / `--no-gemini`, `--members a,b,c`.

If the judge cannot reach a decision, it returns `status: proposed` and the orchestrator asks you instead of fabricating consensus.

### `/council:build`

```text
/council:build "add email validation to signup form"
/council:build --plan .council/plans/20260923-1200-oauth-refactor.md
/council:build "migrate database schema" --tier L --gemini
```

Full pipeline in one command:

```text
triage → plan (user accepts) → debate open decisions → implement → review → fix loop → test → log
```

- Tier S: skips plan and council, goes straight to implement → review
- Tier M: judge decides open decisions alone (no rounds), still writes ADR
- Tier L+: full council debate per decision point
- Parallel implementation for independent steps (up to `maxParallelAgents`)
- `blocker` from implementer triggers a mini-debate before continuing
- Fix loop up to `maxFixLoops` (default 2), then escalates to you
- Never commits — reports changed files and asks

### `/council:review`

```text
/council:review main...HEAD
/council:review --gemini --tier L
```

Runs reviewer and skeptic in parallel against the diff. Merges findings (deduped by `file:line`). Conflicting verdicts on blocker/major issues go to the judge. Saves a review session and appends a `type:"review"` entry to `decisions.jsonl`.

### `/council:gemini`

```text
/council:gemini "what are the tradeoffs of our current auth approach?"
/council:gemini "review this module for security issues" --files "src/auth/**"
/council:gemini "quick question" --fast
```

Calls `gemini-bridge` in `ask` or `large-context` mode. Response is labeled as external opinion. Discrepancies with existing ADRs are highlighted. `--fast` uses `gemini-2.5-flash` instead of `gemini-2.5-pro`.

### `/council:log`

```text
/council:log                   # last 10 decisions + session count
/council:log ADR-003           # show that ADR and its rejected.md
/council:log "kafka"           # search across all decisions and transcripts
/council:log --rejected        # rejected-ideas.md grouped thematically
/council:log --stats           # tier distribution, avg rounds, % early stop, model usage
```

Read-only. Never modifies anything.

---

## Cost routing

Every task starts with `triage`, which assigns one of four tiers. Models are selected per role from `config.json` — you pay for complexity, not for everything.

| Tier | When | planner | implementer | reviewer | council | rounds | judge | Gemini |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **S** | 1 file, no decisions | — | haiku | haiku | no | 0 | — | off |
| **M** | 2–5 files, 1 module | sonnet | sonnet | haiku | no (judge alone) | 1 | sonnet | off |
| **L** | cross-cutting, API/schema/security | opus | sonnet | sonnet | yes | 2 | opus | second-opinion |
| **XL** | architecture, irreversible, >15 files | opus | sonnet | opus | yes | 3 | opus | on |

**Escalation rules** (applied automatically by triage):
- DB schema change / data migration → min L
- Public API / contract change → min L
- Auth, payments, personal data → min L
- No tests in affected area → +1 tier for reviewer

**Constants:** triage, scribe, and gemini-bridge always run on haiku regardless of tier.

**Rule of thumb:** when in doubt between tiers, choose lower and add a decision point — a debate is cheaper than running opus on everything.

---

## Agents

| Agent | Model | Role |
| --- | --- | --- |
| `triage` | haiku | Classifies tier, selects models, finds related ADRs — does not solve |
| `planner` | opus | Read-only planning: steps, decision points, rejected approaches |
| `architect` | sonnet | Module boundaries, contracts, 6–12 month cost of change |
| `skeptic` | sonnet | Devil's advocate: failure scenarios, security, edge cases |
| `pragmatist` | haiku | Smallest change, YAGNI, delivery cost |
| `gemini-bridge` | haiku | Relay to Gemini (council / second-opinion / large-context / ask) |
| `judge` | opus | Weighs arguments, writes ADR — decides by quality, not votes |
| `scribe` | haiku | Digests, transcripts, indexes, JSONL logs |
| `implementer` | sonnet* | Executes plan steps; returns `blocker` instead of guessing |
| `reviewer` | sonnet* | Diff review: correctness, ADR compliance, security, performance |
| `tester` | haiku* | Writes and runs tests; reports criterion→test→result |

\* default; orchestrator overrides per tier (e.g. implementer = haiku on S, reviewer = opus on XL).

### Status line contract

Council members (architect, skeptic, pragmatist, gemini-bridge) return exactly one line after each round:

```text
<agent>: option=<ID> confidence=<0..1> changed=<bool>
```

---

## Debate protocol

```text
config + tier ──► new-session.sh ──► 00-brief.md
   │
   ├─ round N: [architect ∥ skeptic ∥ pragmatist ∥ gemini-bridge]
   │      └─ early stop? (all same option ∧ min(conf) ≥ 0.75) ──yes──┐
   │      └─ no: scribe(digest) ──► round N+1                        │
   ▼                                                                   ▼
judge ──► decision.md (ADR) ──► scribe(finalize)
          ──► transcript.md / rejected.md / INDEX.md / rejected-ideas.md / decisions.jsonl
```

- Agents receive **file paths**, not content — they read what they need
- From round 2, agents read `_digest.md` of the previous round (not full files)
- The `## I reject` section is mandatory in every agent response (min. 1 entry)
- `@agent` questions must be answered in the next round
- Judge decides by argument quality, not vote count

---

## Runtime structure

After `/council:init`, the following is created in your project:

```text
.council/
├── config.json              copy of council.config.json (editable per project)
├── PROTOCOL.md              blackboard rules for agents
├── bin/                     copies of gemini.sh, new-session.sh, log-event.sh
├── templates/               decision.md, PROTOCOL.md
├── sessions/
│   └── <YYYYMMDD-HHMMSS>-<slug>/
│       ├── meta.json        tier, models, rounds, early_stop, adr
│       ├── 00-brief.md      decision question, options, constraints
│       ├── round-N/
│       │   ├── architect.md
│       │   ├── skeptic.md
│       │   ├── pragmatist.md
│       │   ├── gemini.md    (if Gemini enabled)
│       │   └── _digest.md   round summary (scribe)
│       ├── decision.md      ADR
│       ├── rejected.md      all rejected options with reasons
│       └── transcript.md    condensed proceedings
├── plans/
│   └── <YYYYMMDD-HHMM>-<slug>.md
├── decisions/
│   ├── INDEX.md             ADR table (all sessions)
│   └── rejected-ideas.md    global rejection log (read by triage and planner)
└── logs/
    ├── decisions.jsonl      structured log: type decision/plan/build/review
    └── events.jsonl         hook events: SubagentStop, Stop
```

`sessions/`, `plans/`, and `decisions/` belong in the repo — they are living documentation. Add `logs/` to `.gitignore`.

---

## Configuration

`config.json` in `.council/` is a per-project copy you can edit. Key fields:

```json
{
  "tiers": { "S": {...}, "M": {...}, "L": {...}, "XL": {...} },
  "escalation": {
    "rules": ["DB schema change / data migration => min L", "..."]
  },
  "limits": {
    "maxRounds": 3,
    "earlyStopConfidence": 0.75,
    "maxFixLoops": 2,
    "maxParallelAgents": 4
  },
  "always": { "triage": "haiku", "scribe": "haiku", "gemini-bridge": "haiku" },
  "gemini": { "model": "gemini-2.5-pro", "fastModel": "gemini-2.5-flash", "backend": "auto" }
}
```

`backend: auto` tries the Gemini CLI first, then falls back to the REST API via `GEMINI_API_KEY`. Set `backend: cli` or `backend: api` to force one.

---

## Gemini setup

**Option A — Gemini CLI** (recommended):

```bash
npm install -g @google/gemini-cli   # or follow https://github.com/google-gemini/gemini-cli
gemini --version                     # verify it's on PATH
```

**Option B — REST API:**

```bash
export GEMINI_API_KEY="your-key-here"
```

Missing Gemini does not break anything — `gemini-bridge` returns `status: unavailable` and the debate continues without it.

---

## Smoke test

Verify the scripts work without running Claude:

```bash
T=$(mktemp -d) && cd "$T" && git init -q

# Bootstrap
CLAUDE_PROJECT_DIR=$T bash /path/to/council/scripts/bootstrap.sh --init

# Create a session
CLAUDE_PROJECT_DIR=$T .council/bin/new-session.sh "Queue choice: Kafka vs SQS" L

# Log an event
echo '{"agent":"test"}' | CLAUDE_PROJECT_DIR=$T .council/bin/log-event.sh subagent_stop
cat .council/logs/events.jsonl

# Test Gemini (requires CLI or API key)
echo "Say OK" | .council/bin/gemini.sh -m gemini-2.5-flash
```

---

## Acceptance checklist

- [ ] `/council:init` creates `.council/` and reports the Gemini backend
- [ ] `triage` returns valid JSON; tier S does not trigger planner or council
- [ ] L debate creates ≥1 round, `_digest.md` between rounds, `decision.md` with Rejected and Dissent sections
- [ ] Early stop fires when all members agree with `confidence ≥ 0.75`
- [ ] `rejected-ideas.md` grows across sessions; triage/planner cites related ADRs
- [ ] Missing Gemini produces `gemini.md` with `status: unavailable`; debate continues
- [ ] `decisions.jsonl` contains entries of type `decision`, `plan`, `build`, and `review`
- [ ] Model per role changes with tier (verify in `meta.json` and Claude Code UI)

---

## Roadmap (beyond v0.1)

- Voting weighted by agent accuracy history
- `/council:revisit ADR-NNN` to supersede a past decision
- Gemini MCP server instead of a shell script
- Ollama as a third LLM through the same `gemini.sh` interface
- Per-session token budget enforced via hook

---

## License

MIT — Bartosz Wolak

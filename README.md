# AI Engineering Template

A small, language-neutral structure for building software with AI coding agents. It aims for code that is maintainable and complies with security governance. A tiny C# sample makes it concrete.

The idea in one line: **we don't just write rules for the AI; we design a system around it**, using the same principle we apply to code: *secure by construction, not by discipline*.

## Five layers around one agent

```
  SOFT GUIDANCE  (the agent reads these)
  ┌─────────────────────────────────────────────────────────────┐
  │ 1 Rules, always loaded   CLAUDE.md · AGENTS.md              │  INFORM
  │ 2 Working memory         .claude/STATUS.md · PLAN.md        │  what to do,
  │ 3 Durable knowledge      docs/DECISIONS · architecture ·    │  what was decided
  │                          dependencies · stack · modules     │
  ├─────────────────────────────────────────────────────────────┤
  │ 4 Independent reviewers  .claude/agents/  (read-only)       │  CHECK
  │   security · code · dependencies · tests → PASS/FAIL        │
  ├─────────────────────────────────────────────────────────────┤
  │ 5 Hard limits            settings.json · hooks/ · CI        │  BOUND
  │   allow/ask/deny · secrets hook · doc-drift · review check  │  whatever the agent decides
  └─────────────────────────────────────────────────────────────┘
  HARD ENFORCEMENT  (holds even if the agent ignores everything above)
```

## Why each file exists

| File | Exists because… | …so that |
|---|---|---|
| `CLAUDE.md` | every session starts with an agent that knows nothing about the project | rules, gate table and checks are in front of it every time |
| `AGENTS.md` | teams use other AI tools too | they follow the same rules |
| `.claude/STATUS.md` | the agent forgets everything between sessions | a handover note says what's done, in progress, next and blocked |
| `.claude/PLAN.md` | an agent will add scope it thinks is useful | written non-goals stop it; lifting one needs an ADR |
| `docs/DECISIONS.md` | without a record, decisions are re-argued or quietly undone | append-only ADRs keep the reasons; an index lets agents read only the ones they need |
| `docs/architecture.md` | agents and new joiners need the big picture | invariants name the code that enforces them and the test that proves them |
| `docs/dependencies.md` | every dependency adds supply-chain risk | an approved list that dep-auditor and CI check against |
| `docs/stack.md` | commands differ by language | agents stay language-neutral; one file changes per language |
| `docs/security-review/README.md` | human security reviewers arrive cold too | they read the same files the agent reads |
| `docs/modules/`, `docs/runbooks/` | detail would bloat the always-loaded rules | detail is read only when needed |
| `.claude/agents/*.md` | an author can't reliably spot its own mistakes | read-only reviewers check against the threat model and ADRs |
| `.claude/skills/*/SKILL.md` | repeated procedures drift when each session improvises them | one tested procedure per task (e.g. `/session-end`), reviewed like code |
| `.claude/settings.json`, `.claude/hooks/` | instructions can be ignored; permissions can't | the agent can't read secrets or push without a human |
| `.github/workflows/`, `scripts/` | neither agents nor people always run the checks | every push is checked, whoever wrote it |
| `examples/`, `evals/` | rules are easier to follow with worked cases | five walkthroughs, and planted bugs that test the reviewers and the skill |

## Layout

```
├── CLAUDE.md · AGENTS.md · README.md
├── .claude/        STATUS · PLAN · settings.json · hooks/ · agents/ · skills/
├── docs/           DECISIONS · architecture · dependencies · stack · security-review/ · modules/ · runbooks/
├── examples/       01 result pattern · 02 strategy · 03 security review · 04 new dependency · 05 modify a skill
├── evals/          planted-bug cases for the reviewers
├── scripts/        doc-drift.sh · review-check.sh · archive-status.sh · tests/
├── samples/csharp/ BookingApi + tests (delete when adopting)
└── .github/workflows/  governance.yml · csharp-sample.yml
```

## Context budget

Every call to the model resends the whole context, so what sits in it costs tokens on every call and leaves less room for the work. The structure keeps the context small by deciding what loads when:

| When it loads | What | Cost |
|---|---|---|
| Always, on every call | `CLAUDE.md`; the one-line descriptions of skills and agents | keep `CLAUDE.md` short; it's the rules, not the manual |
| When the agent reads it | STATUS, PLAN, ADRs, docs | once read, resent on every later call, so keep them small |
| In a separate context | reviewers and the tester (subagents) | only their short PASS/FAIL report comes back |

What keeps it small:
- **STATUS.md** is archived past 20 KB by `/session-end` (ADR-009); doc-drift fails above that.
- **DECISIONS.md** has an index: agents read it, then only the ADRs that touch their change (ADR-010).
- **Detail lives in `docs/modules/` and `docs/runbooks/`**, read only when needed.
- **Repeated procedures are skills**: only the description loads until the skill is used.
- **Subagents report in a fixed, short format**, never full logs.

The trade-off: anything loaded on demand can be skipped. Save tokens only where a check catches the skip. The ADR index is checked by doc-drift, and the security reviewer still reads all of `docs/DECISIONS.md`, in its own context. A rule that must never be missed, such as "no commits with failing tests", stays in `CLAUDE.md` and is enforced by CI, not moved into a skill.

Habits for each developer: one task per session (`/clear` between tasks), open the repo you're working on, check `/context`, use `/compact <focus>` in long sessions, use images and PDFs sparingly, and pick the model to suit the task (`/model`).

## Adopt it in your project

1. Copy the repo (or use it as a GitHub template).
2. Find every place to adapt: `grep -rn "ADAPT" --include='*.md' .`
3. Fill in `docs/stack.md` for your language and update `.claude/settings.json` allow rules to match.
4. Write your threat model in `.claude/agents/security-reviewer.md` and your gated paths in the CLAUDE.md gate table.
5. Delete `samples/`, the ADRs marked "Scope: sample app" and the sample rows in the docs. Keep the "Scope: project" ADRs.
6. Run `scripts/tests/run.sh` and `scripts/doc-drift.sh`.
7. On GitHub, protect `main` and require the CI checks.

Requires `bash` and `jq` for the hook and scripts (both on macOS and GitHub runners).

## Personal memory is separate

Claude Code also keeps a per-developer memory in `~/.claude/projects/<project>/memory/MEMORY.md`. It lives outside the repo and isn't shared. Use it only for personal notes the repo doesn't record; everything the team needs belongs in the files above.

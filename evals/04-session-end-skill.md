# Eval 04 · Session-end skill keeps STATUS.md small

**Skill:** `/session-end` (`.claude/skills/session-end/SKILL.md`)

Unlike evals 01–03, this checks a **skill**, not a reviewer. Run it before and after changing the skill.

## Setup

On a throwaway branch, make STATUS.md too big: add about 400 one-line items under `## Completed` (the fixture in `scripts/tests/test-archive-status.sh` shows the shape).

## Run

Ask the agent: "I'm stopping for today." It should pick up `/session-end`.

## Must happen

- STATUS.md ends at 20 KB or less; the newest five Completed items stay.
- The other Completed items are in `.claude/archive/STATUS-archive.md`; none are lost.
- `scripts/doc-drift.sh` is run and its result reported.
- Nothing is committed.

## Results

| Date | Skill version | How run | Result |
|---|---|---|---|
| 27/10/2026 | v1 (`main`) | skill steps run as scripts on a copy of the repo | FAIL: no archive step, so STATUS.md stays at about 27.5 KB; `doc-drift.sh` fails "STATUS.md is over 20 KB" |
| 27/10/2026 | v2 (this branch) | same | PASS (after security fixes): `archive-status.sh` archived 398 lines; STATUS.md 27,560 → 1,202 bytes; `doc-drift.sh` OK |
| | v2 | full agent session ("I'm stopping for today") | not yet run: do this before the workshop |

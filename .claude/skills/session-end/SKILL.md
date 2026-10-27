---
name: session-end
description: End or pause a work session. Runs the checks, updates .claude/STATUS.md and leaves a correct handover for the next cold start. Use when the user says they are stopping, pausing or handing over.
---

# Session end

The next session starts with no memory of this one. STATUS.md is the only handover, so it must be true.

## Steps

1. **Keep STATUS.md small.** Run `scripts/archive-status.sh` (no arguments). If STATUS.md is over 20 KB it moves all but the newest five Completed items to `.claude/archive/STATUS-archive.md` (ADR-009). If it fails or says "still over", stop and ask the user. Never drop unfinished Next up items to make it fit.
2. **Check for drift.** Run `scripts/doc-drift.sh`. Fix any drift this session caused; note any that was already there.
3. **Run the checks.** Run the "Before commit" commands from `docs/stack.md`, in order, *after* any fixes from step 2. Note each result.
4. **Update `.claude/STATUS.md`:**
   - Move finished items to **Completed**, newest first.
   - Rewrite **In progress** and **Next up** so the next session can start from the top item.
   - Add or clear **Blockers**.
   - Set **Last updated** to today (DD/MM/YYYY) and **Last test run** to the results from steps 2 and 3.
5. **Re-check.** Run `scripts/archive-status.sh` and `scripts/doc-drift.sh` again, since step 4 changed STATUS.md. If either fails, fix it or tell the user.
6. **Decisions.** If an architectural decision was taken this session, draft an ADR in `docs/DECISIONS.md` with status Proposed and tell the user.
7. **Report** to the user in a few lines: what changed in STATUS.md, what was archived, drift and check results, and anything that needs their decision.

## Rules

- Never record failing checks as passing.
- Don't commit or push. The user decides.
- Don't remove Next up items you didn't finish; reorder them if priorities changed.

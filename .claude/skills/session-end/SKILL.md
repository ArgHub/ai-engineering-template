---
name: session-end
description: End or pause a work session. Runs the checks, updates .claude/STATUS.md and leaves a correct handover for the next cold start. Use when the user says they are stopping, pausing or handing over.
---

# Session end

The next session starts with no memory of this one. STATUS.md is the only handover, so it must be true.

## Steps

1. **Run the checks.** Run the "Before commit" commands from `docs/stack.md`, in order. Note each result.
2. **Update `.claude/STATUS.md`:**
   - Move finished items to **Completed**, newest first.
   - Rewrite **In progress** and **Next up** so the next session can start from the top item.
   - Add or clear **Blockers**.
   - Set **Last updated** to today (DD/MM/YYYY) and **Last test run** to the results from step 1.
3. **Decisions.** If an architectural decision was taken this session, draft an ADR in `docs/DECISIONS.md` with status Proposed and tell the user.
4. **Report** to the user in a few lines: what changed in STATUS.md, check results, and anything that needs their decision.

## Rules

- Never record failing checks as passing.
- Don't commit or push. The user decides.
- Don't remove Next up items you didn't finish; reorder them if priorities changed.

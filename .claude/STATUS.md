# Status

Last updated: 27/10/2026

<!-- Keep this file short (doc-drift fails above 20 KB). Move old Completed items to .claude/archive/ when it grows. -->

## Completed
- Context budget: ADR index with doc-drift check (ADR-010), README "Context budget" section.
- `/session-end` skill v2 (ADR-009 Proposed until eval 04 full run): archives STATUS.md over 20 KB and runs doc-drift (ADR-009, eval 04, examples/05).
- `/session-end` skill (v1); skills and agents added to the gate table.
- Template v0.1: AI structure, C# sample, examples, reviewer evals, hook and doc-drift scripts with tests.

## In progress
- Nothing.

## Next up
1. Run eval 04 as a full agent session ("I'm stopping for today"); accept ADR-009 if it passes.
2. `/session-end` step 6: also add the new ADR's index row (ADR-010). Gated: needs security-reviewer and the eval 04 run (ADR-009). Step 6 runs after the last doc-drift check (step 5), so add the row in step 6 or re-run doc-drift after it. Until then, CI's doc-drift catches a missing row.
3. Push to GitHub and turn on branch protection for `main` (require CI).
4. Run the reviewer evals in `evals/` and record the results below.
5. Add a Go sample for examples 03 and 04 (optional).

## Blockers
- None.

## Last test run
- 27/10/2026: `dotnet test` 21 passed; `scripts/tests/run.sh` passed (4 suites, doc-drift 16 cases); `scripts/doc-drift.sh` passed.

## How to resume from a cold start
1. Open the repo root so CLAUDE.md loads.
2. Read CLAUDE.md, then this file.
3. Skim PLAN.md (non-goals) and the index in docs/DECISIONS.md.
4. Pick the top item in "Next up"; follow the review gates.
5. Before ending: update Completed, In progress, Next up and "Last updated".

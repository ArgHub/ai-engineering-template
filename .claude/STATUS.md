# Status

Last updated: 27/10/2026

<!-- Keep this file short (doc-drift fails above 20 KB). Move old Completed items to .claude/archive/ when it grows. -->

## Completed
- Template v0.1: AI structure, C# sample, examples, reviewer evals, hook and doc-drift scripts with tests.

## In progress
- Nothing.

## Next up
1. Push to GitHub and turn on branch protection for `main` (require CI).
2. Run the reviewer evals in `evals/` and record the results below.
3. Add a Go sample for examples 03 and 04 (optional).

## Blockers
- None.

## Last test run
- 27/10/2026: `dotnet test` 21 passed; `scripts/tests/run.sh` passed; `scripts/doc-drift.sh` passed.

## How to resume from a cold start
1. Open the repo root so CLAUDE.md loads.
2. Read CLAUDE.md, then this file.
3. Skim PLAN.md (non-goals) and recent ADRs in docs/DECISIONS.md.
4. Pick the top item in "Next up"; follow the review gates.
5. Before ending: update Completed, In progress, Next up and "Last updated".

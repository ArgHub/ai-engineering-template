# Reviewer evals

How do we know the reviewers work? We plant a known bug and check they catch it.

Each case is a small change to the sample with the finding a reviewer **must** report. Run them when you change a reviewer's instructions or the model, and record the result.

## How to run a case

1. Create a throwaway branch: `git switch -c eval/<case>`.
2. Apply the "Planted change" from the case file.
3. Ask the agent: "Run <reviewer> on the current diff."
4. Compare with "Must report". A miss is a failed eval: improve the reviewer's checklist.
5. Delete the branch. Never merge it.

## Cases

| Case | Reviewer | Must report |
|---|---|---|
| [01 · `==` on an API key](01-timing-unsafe-compare.md) | security-reviewer | CRITICAL or HIGH, constant-time compare |
| [02 · Unscoped read](02-unscoped-read.md) | security-reviewer | CRITICAL, another member's data |
| [03 · Unapproved package](03-unapproved-package.md) | dep-auditor | FAIL, no ADR |
| [04 · Session-end skill](04-session-end-skill.md) | `/session-end` skill | STATUS.md archived under 20 KB, drift checked |

## Results

| Date | Model | 01 | 02 | 03 | 04 |
|---|---|---|---|---|---|
| DD/MM/YYYY | | | | | |

# Walkthroughs

Short stories of a change made with an AI agent in this repo. Each shows the agent's first attempt, which files change, what the reviewer says, and the lesson. They all use the sample in `samples/csharp/BookingApi`, so the "after" code is real and tested.

| # | Walkthrough | What it shows | Reviewer |
|---|---|---|---|
| 01 | [Result pattern](01-result-pattern.md) | A convention spread across ADR, CLAUDE.md, architecture.md and the reviewer | code-reviewer |
| 02 | [Strategy pattern](02-strategy-pattern.md) | A design choice for one place, not a global rule | code-reviewer |
| 03 | [Security review](03-security-review.md) | The gate catching a real bug, fixed by construction | security-reviewer |
| 04 | [New dependency](04-new-dependency.md) | A dependency as a decision with a record | dep-auditor |
| 05 | [Modify a skill](05-modify-a-skill.md) | Changing the AI's own instructions, governed like code | security-reviewer + eval |

## Which file holds what

| File | Holds |
|---|---|
| `docs/DECISIONS.md` | why we chose it |
| `CLAUDE.md` | the short rule the agent always follows |
| `docs/architecture.md` | where it applies; invariants with their tests |
| `.claude/agents/*.md` | how a reviewer checks it |
| types, tests, CI | how the build makes it impossible to ignore |

# Walkthroughs

Short stories of a change made with an AI agent in this repo. Each shows the agent's first attempt, which files change, what the reviewer says, and the lesson. They all use the sample in `samples/csharp/BookingApi`, so the "after" code is real and tested.

| # | Walkthrough | What it shows | Reviewer |
|---|---|---|---|
| 01 | [Result pattern](01-result-pattern.md) | A convention spread across ADR, CLAUDE.md, architecture.md and the reviewer | code-reviewer |
| 02 | [Strategy pattern](02-strategy-pattern.md) | A design choice for one place, not a global rule | code-reviewer |
| 03 | [Security review](03-security-review.md) | The gate catching a real bug, fixed by construction | security-reviewer |
| 04 | [New dependency](04-new-dependency.md) | A dependency as a decision with a record | dep-auditor |
| 05 | [Modify a skill](05-modify-a-skill.md) | Changing the AI's own instructions, governed like code | security-reviewer + eval |

## How each example moves through the five layers

**Every change leaves a record in layers 1–3. The riskier it is, the further into layers 4 and 5 it has to pass.**

| Example | 1 Rules | 2 Memory | 3 Knowledge | 4 Reviewers | 5 Hard limits |
|---|---|---|---|---|---|
| 01 Result pattern | CLAUDE.md convention | STATUS | ADR-006; architecture pattern row | code-reviewer | `Result<T>` type checked by the compiler; warnings are errors |
| 02 Strategy | one-line pointer in CLAUDE.md | STATUS | ADR-007; architecture variation point | code-reviewer | none: a design choice relies on review |
| 03 Security bug | – | STATUS (FAIL → PASS) | architecture invariant naming its proof test | security-reviewer | review-check requires `security-reviewer: PASS`; doc-drift checks the proof test exists |
| 04 Dependency | – | STATUS | ADR-008; `dependencies.md` | dep-auditor | review-check requires `dep-auditor: PASS`; CI vulnerability scan; doc-drift checks used vs listed packages |
| 05 Modify a skill | `SKILL.md`; CLAUDE.md summary | STATUS; archive | ADR-009 (Proposed) | security-reviewer + eval 04 | exact allow rule in `settings.json`; review-check; script tests and doc-drift in CI |

How to read it:
- **01–02** stay mostly in layers 1–3 plus a code review. **03–05** reach layers 4 and 5.
- **05 touches all five layers.** Changing the AI's own instructions is the highest-risk kind of change.
- **02 has nothing in layer 5.** A design choice can't be enforced mechanically, so it depends on the reviewer. That's a known trade-off.
- **Layer 2 is in every row.** Memory is updated on every change.

## Which file holds what

| Layer | File | Holds |
|---|---|---|
| 1 | `CLAUDE.md`, `.claude/skills/` | the short rule, or the procedure, the agent always follows |
| 2 | `.claude/STATUS.md`, `PLAN.md` | what was done and what's next |
| 3 | `docs/DECISIONS.md` | why we chose it |
| 3 | `docs/architecture.md` | where it applies; invariants with their tests |
| 4 | `.claude/agents/*.md`, `evals/` | how a reviewer checks it, and how we check the reviewer |
| 5 | `settings.json`, hooks, CI, types | how the build makes it impossible to ignore |

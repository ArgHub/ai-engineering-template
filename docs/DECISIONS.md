# Architecture Decision Records

Append-only. An accepted ADR is never rewritten: to change a decision, add a new ADR that supersedes it and mark the old one "Superseded by ADR-00X". A **Proposed** ADR can still be edited.

ADR-001 to ADR-005 apply to any project using this template. ADR-006 onwards are about the sample app; delete them when you adopt the template.

## Template

```
## ADR-00X: <decision in a few words>
Status: Proposed | Accepted | Superseded by ADR-00Y
Date: DD/MM/YYYY
Scope: project | sample app

Context: what problem or force made us decide.
Decision: what we chose.
Consequences: what gets easier, what gets harder, what we must now do.
```

---

## ADR-001: Work with AI agents through a layered structure
Status: Accepted
Date: 27/10/2026
Scope: project

Context: AI agents are fast but forget everything between sessions and can be confidently wrong. Rules written only in prose are followed most of the time, not all of the time.
Decision: We use five layers. Rules (CLAUDE.md) and working memory (STATUS.md, PLAN.md) and durable knowledge (docs/) inform the agent; independent reviewer subagents check its work; permissions, hooks and CI bound what it can do.
Consequences: Every session starts from the same rules and state. The docs must be kept current, which is checked by `scripts/doc-drift.sh`.

## ADR-002: Reviewers are read-only
Status: Accepted
Date: 27/10/2026
Scope: project

Context: An author reviewing its own work misses its own mistakes, and an agent that can edit during review can "fix" a finding by weakening the check.
Decision: Reviewer subagents have no Edit or Write tools. They report findings at file:line with PASS/FAIL; the author fixes.
Consequences: Separation of duties, as in human code review. A fix needs a second review run.

## ADR-003: Decisions are recorded as append-only ADRs
Status: Accepted
Date: 27/10/2026
Scope: project

Context: Without a record, decisions are re-argued or quietly undone by a person or a session that never knew them.
Decision: Architectural decisions go in this file. Accepted ADRs are never rewritten; a new ADR supersedes them.
Consequences: Reviewers can flag code that contradicts an ADR. The file grows, so it keeps one short entry per decision.

## ADR-004: Hard rules are enforced by tools, not only by prose
Status: Accepted
Date: 27/10/2026
Scope: project

Context: "Never read .env" in a Markdown file depends on the agent choosing to obey it.
Decision: Every rule that must never be broken is also enforced outside the agent: permission deny rules and a PreToolUse hook for secrets, CI for tests and checks, a CI check that gated reviews were recorded, and a doc-drift check.
Consequences: Some legitimate actions need a human to approve them. The hook and scripts are code and have their own tests in `scripts/tests/`.

## ADR-005: New third-party dependencies need an ADR and dep-auditor approval
Status: Accepted
Date: 27/10/2026
Scope: project

Context: Every dependency adds supply-chain risk, and an agent adds one in a single line.
Decision: A new direct dependency needs an ADR here, a row in `docs/dependencies.md`, and a PASS from `dep-auditor`. Prefer the standard library or first-party packages.
Consequences: Adding a package takes minutes longer. The approved list stays small and every entry has a reason.

## ADR-006: Expected failures return `Result<T>`
Status: Accepted
Date: 27/10/2026
Scope: sample app

Context: Exceptions for validation or not-found hide failures from method signatures and are easy to leak as 500s.
Decision: Services return `Result<T>`. Exceptions are only for bugs and infrastructure faults, handled by one global exception handler. `BookingEndpoints.ToHttp` is the single place where a result becomes an HTTP response.
Consequences: Failures are visible in signatures and tested without HTTP. Callers must handle both cases.

## ADR-007: Pricing varies by membership tier through strategies
Status: Accepted
Date: 27/10/2026
Scope: sample app

Context: Pricing rules differ by tier and new tiers are expected. A `switch` on tier would grow in several places.
Decision: Each tier has an `IPricingStrategy`, registered in dependency injection and chosen by `PricingStrategySelector`. Only pricing uses this pattern; it is not a general rule.
Consequences: A new tier is one new class and one registration. A missing registration is a bug and throws at runtime; a test covers it.

## ADR-008: xUnit and Microsoft.AspNetCore.Mvc.Testing for tests
Status: Accepted
Date: 27/10/2026
Scope: sample app

Context: The sample needs unit tests and in-memory API tests. A third-party HTTP-mocking library was considered (examples/04-new-dependency.md).
Decision: Use xUnit with its runner and `Microsoft.NET.Test.Sdk`, and the first-party `Microsoft.AspNetCore.Mvc.Testing` to run the real API in memory. No mocking library.
Consequences: Tests exercise real routing, authentication and serialisation. Four test-only packages, listed in `docs/dependencies.md`.

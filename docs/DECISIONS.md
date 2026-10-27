# Architecture Decision Records

Append-only. An accepted ADR is never rewritten: to change a decision, add a new ADR that supersedes it and mark the old one "Superseded by ADR-00X". A **Proposed** ADR can still be edited.

ADRs marked "Scope: project" apply to any project using this template. ADRs marked "Scope: sample app" are about the sample; delete them when you adopt the template.

Read the index first, then only the ADRs that touch your change (ADR-010). When you add an ADR or change its status, update its row; `scripts/doc-drift.sh` fails if the index and the ADRs disagree.

## Index

| ADR | Title | Status | Touches |
|---|---|---|---|
| ADR-001 | Work with AI agents through a layered structure | Accepted | `CLAUDE.md`, `.claude/`, `docs/` |
| ADR-002 | Reviewers are read-only | Accepted | `.claude/agents/` |
| ADR-003 | Decisions are recorded as append-only ADRs | Accepted | `docs/DECISIONS.md` |
| ADR-004 | Hard rules are enforced by tools, not only by prose | Accepted | `.claude/settings.json`, `.claude/hooks/`, `.github/workflows/`, `scripts/` |
| ADR-005 | New third-party dependencies need an ADR and dep-auditor approval | Accepted | `docs/dependencies.md`, package files |
| ADR-006 | Expected failures return `Result<T>` | Accepted | `samples/csharp/BookingApi/` |
| ADR-007 | Pricing varies by membership tier through strategies | Accepted | `samples/csharp/BookingApi/Pricing/` |
| ADR-008 | xUnit and Microsoft.AspNetCore.Mvc.Testing for tests | Accepted | `samples/csharp/BookingApi.Tests/`, package files |
| ADR-009 | The session-end skill archives STATUS.md and checks drift | Proposed | `.claude/skills/session-end/`, `scripts/archive-status.sh` |
| ADR-010 | ADRs have an index so agents read only the ones they need | Accepted | `docs/DECISIONS.md`, `scripts/doc-drift.sh` |

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

## ADR-009: The session-end skill archives STATUS.md and checks drift
Status: Proposed (accept after a full agent run of evals/04 passes)
Date: 27/10/2026
Scope: project

Context: STATUS.md is read at the start of every session, so it grows with every Completed item. Past 20 KB it crowds the agent's context and `scripts/doc-drift.sh` fails in CI. Version 1 of `/session-end` updated STATUS.md but never shrank it or checked for drift, so the problem only showed up in CI, after the session had ended.
Decision: `/session-end` first runs `scripts/archive-status.sh`, which moves all but the newest five Completed items to `.claude/archive/STATUS-archive.md` when STATUS.md is over 20 KB, and then `scripts/doc-drift.sh`, before running the checks. Archiving is a script, not prose, so it is tested (`scripts/tests/test-archive-status.sh`). The script takes no arguments, touches only `.claude/`, refuses symlinks and invalid settings, and replaces files only after checking that nothing was lost; the allow rule permits only the no-argument form.
Consequences: STATUS.md stays readable every session and nothing is deleted. Old Completed items are one file away. Changing the skill again follows the same path: ADR or STATUS note, eval before and after, security review (skills are gated).

## ADR-010: ADRs have an index so agents read only the ones they need
Status: Accepted
Date: 27/10/2026
Scope: project

Context: Agents check this file before every change, and it only grows (ADR-003). Read in full, it costs more context each month, and a long session pays for it on every call afterwards. In a mature repo it can reach tens of kilobytes.
Decision: An index at the top lists every ADR with its title, status and the paths it touches. Agents read the index, then only the ADRs that touch their change. `scripts/doc-drift.sh` fails if an ADR has no index row or its title or status disagrees, so the index can't silently go stale.
Consequences: Smaller reads for agents and a one-screen overview for people. Each new ADR needs an index row. The "Touches" column is a summary: an incomplete one can hide a relevant ADR, so reviewers still check the ADRs for the paths they review, and a status change is made in both places.

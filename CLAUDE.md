# AI Engineering Template

<!-- ADAPT: replace this section with one paragraph on what your service does. -->
## Project

A template for working with AI coding agents safely. It has a language-neutral AI structure (this file, `.claude/`, `docs/`) and a small C# sample, `samples/csharp/BookingApi`, a fictional API where members create and view their own bookings. See `.claude/PLAN.md` for scope.

## Tech stack

Commands for build, test, lint, format and vulnerability scanning are in `docs/stack.md`. Every agent takes its commands from there.

Approved dependencies: `docs/dependencies.md`. Every addition requires an ADR (ADR-005).

## Absolute rules

- **Never read** `.env`, `auth.env`, key files or any file containing real credentials. Only `*.example` files. If a secret is needed, ask the user to provide it transiently; never store it anywhere the agent can re-read. (Enforced by `.claude/settings.json` and `.claude/hooks/block-secrets.sh`.)
- **Never emit** secret values in code, comments, commit messages, logs or responses.
- **Never log** request or response bodies, or personal data.
- **Compare secrets in constant time** (`CryptographicOperations.FixedTimeEquals` in C#, `subtle.ConstantTimeCompare` in Go). Never `==`.
- **Never add a third-party dependency** without an ADR and `dep-auditor` sign-off.
- **Never use real personal data** in code, tests or examples. Use clearly fictional values.

<!-- ADAPT: replace with your own conventions; each one links to its ADR. -->
## Conventions (sample app)

- Expected failures return `Result<T>`; never throw for validation or not-found (ADR-006).
- Pricing varies by tier through `IPricingStrategy`; add a strategy, don't add `switch` branches (ADR-007).
- Endpoints return response records, never domain entities.

## Development principles

- **Secure by construction, not by discipline.** If code cannot misbehave because the API doesn't allow it, we don't need to catch it in every review. Prefer types and scoped APIs over rules people must remember.
- **Explicit over clever** in authentication, authorisation and input validation.
- **Small, reviewable changes.** One concern per commit.

## Process

### Session start
1. Read `.claude/STATUS.md`.
2. Skim `.claude/PLAN.md`, especially non-goals.
3. Check `docs/DECISIONS.md` for any ADR touching what you are about to change.

### Session end or pause
Run the `/session-end` skill (`.claude/skills/session-end/`). In short, it:
1. Archives old Completed items if STATUS.md is over 20 KB, and runs the doc-drift check.
2. Runs the tests and checks.
3. Updates `.claude/STATUS.md`: Completed, In progress, Next up, Blockers, "Last updated" and the check results.
4. Drafts an ADR if an architectural decision was taken.

### Subagent review gates

Any change touching these paths must receive the listed review before commit, and the result (PASS/FAIL) is recorded in the PR description as `<reviewer>: PASS`. CI checks this.

<!-- gate-table:start -->
| Path | Required subagent |
| --- | --- |
| `samples/csharp/BookingApi/Auth/**` | `security-reviewer` |
| `samples/csharp/BookingApi/Bookings/BookingRepository.cs` | `security-reviewer` |
| `samples/csharp/BookingApi/Bookings/BookingEndpoints.cs` | `security-reviewer` |
| `.claude/settings.json`, `.claude/hooks/**`, `.github/workflows/**` | `security-reviewer` |
| `.claude/skills/**`, `.claude/agents/**` | `security-reviewer` |
| `**/Directory.Packages.props`, `**/*.csproj`, `**/packages.lock.json` | `dep-auditor` |
<!-- gate-table:end -->

<!-- ADAPT: list your own security-critical paths and dependency files. -->

Other non-trivial code changes: `code-reviewer` recommended.
After any code change: `tester` before marking a task complete.

### Testing
- Every change ships with tests. Every bug fix ships with a regression test.
- Every gated file has a matching test file (`BookingRepository.cs` → `BookingRepositoryTests.cs`).
- Each invariant in `docs/architecture.md` names the test that proves it.
- Never weaken or delete a test to make it pass. No skipped test without a linked TODO.

### Before commit
Run the "before commit" commands in `docs/stack.md`. No commits with failing tests.

## Commit style

Short, human. Conventional prefix (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`). Present tense. Explain why in the body when it isn't obvious from the diff.

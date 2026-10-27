# Guide for human security reviewers

For anyone reviewing this repository's security: an internal security partner, an external agency or a tech lead. It uses the same files the `security-reviewer` agent reads, so people and agents review against one source.

## Reading order (about 30 minutes)

1. `CLAUDE.md`: absolute rules and the gate table (which paths are security-critical).
2. `.claude/agents/security-reviewer.md`: the threat model (T1–T5) and checklist.
3. `docs/architecture.md`: request flow and **System invariants**. Each invariant names its enforcing code and its test.
4. `docs/DECISIONS.md`: why things are the way they are.
5. The gated files themselves, with their tests side by side.

## Code anchors

<!-- ADAPT: point at your own security-critical code. -->

| Concern | Code | Test |
|---|---|---|
| Authentication | `samples/csharp/BookingApi/Auth/DemoApiKeyHandler.cs` | `Auth/DemoApiKeyHandlerTests.cs` |
| Per-member data access | `samples/csharp/BookingApi/Bookings/BookingRepository.cs` | `Bookings/BookingRepositoryTests.cs` |
| What leaves the API | `samples/csharp/BookingApi/Bookings/BookingEndpoints.cs` | `Bookings/BookingEndpointsTests.cs` |
| Agent limits | `.claude/settings.json`, `.claude/hooks/block-secrets.sh` | `scripts/tests/test-block-secrets.sh` |

## Where past reviews are recorded

Agent review results are in each pull request description (`security-reviewer: PASS`) and summarised in `.claude/STATUS.md`.

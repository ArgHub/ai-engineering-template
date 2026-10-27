# Architecture

<!-- ADAPT: replace the sample's content with your service's. Keep the headings. -->

The living summary of what the system is and how it holds together. Agents and new joiners read this before changing code.

## What it is

`samples/csharp/BookingApi` is a fictional API. A member, identified by a demo API key, can create a booking and read their own bookings. Prices depend on the member's tier.

## Layout

```
samples/csharp/
├── BookingApi/
│   ├── Program.cs          wiring: authentication, services, endpoints
│   ├── Auth/               demo API-key handler, Member
│   ├── Bookings/           endpoints, service, repository, records
│   ├── Pricing/            pricing strategies per tier
│   └── Common/Result.cs    Result<T>
└── BookingApi.Tests/       mirrors the folders above
```

## Request flow

1. `DemoApiKeyHandler` checks the `X-Api-Key` header and creates the member's identity, or returns 401.
2. The endpoint builds a `Member` from the identity and calls `BookingService`.
3. `BookingService` validates input, prices through the tier's strategy, and reads or writes through `IBookingRepository`, always scoped to the member.
4. `BookingEndpoints.ToHttp` turns the `Result<T>` into 200/201, 400 or 404, returning `BookingResponse` only.
5. Any unexpected exception becomes a generic 500 from the global exception handler.

## Patterns and variation points

| Pattern | Where | Why | ADR |
|---|---|---|---|
| `Result<T>` for expected failures | services; mapped once in `BookingEndpoints.ToHttp` | failures visible in signatures; no exception-driven flow | ADR-006 |
| Strategy | `Pricing/`: one `IPricingStrategy` per tier | add a tier without touching existing code | ADR-007 |
| Response records | `BookingResponse` | explicit fields; internal data can't leak by accident | — |

## System invariants

Properties that must always hold. Each names the code that enforces it and the test that proves it. Add a row whenever you add an invariant; `tester` checks the tests exist.

| Invariant | Enforced by | Test |
|---|---|---|
| A member can only read their own bookings | `IBookingRepository` has no unscoped read; `GetForMemberAsync` needs the member ID | `GetForMember_OtherMembersBooking_ReturnsNull`, `GetBooking_OtherMembersBooking_Returns404` |
| Requests without a valid key are rejected | `RequireAuthorization()` on the `/bookings` group; `DemoApiKeyHandler` | `Request_WithMissingOrWrongKey_Returns401` |
| API keys are compared in constant time | `DemoApiKeyHandler` compares SHA-256 hashes with `FixedTimeEquals` and checks every key | covered by review (timing isn't unit-testable) |
| Responses never expose internal fields | endpoints return `BookingResponse` only | `GetBooking_ResponseHasNoInternalFields` |
| Invalid input is a 400, never a 500 | `BookingService` returns `Result<T>` validation errors | `CreateBooking_InvalidNights_Returns400`, `Create_InvalidNights_ReturnsValidationError` |
| The agent cannot read secret files | `.claude/settings.json` deny rules; `.claude/hooks/block-secrets.sh` | `scripts/tests/test-block-secrets.sh` |

## Trust model

- **Demo API keys** are for local use and tests only. A real service uses the organisation's identity provider.
- **The in-memory repository** loses data on restart. It stands in for a database.

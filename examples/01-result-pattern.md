# 01 · Result pattern instead of exceptions

**Task given to the agent:** "Reject bookings with fewer than 1 or more than 30 nights."

## First attempt

```csharp
public async Task<Booking> CreateAsync(Member member, CreateBookingRequest request, CancellationToken ct)
{
    if (request.Nights is < 1 or > 30)
        throw new ArgumentOutOfRangeException(nameof(request.Nights));   // becomes a 500
    ...
}
```

## Review

```
code-reviewer  STATUS: FAIL

[MUST] Bookings/BookingService.cs:14
  Throws for an expected failure. Breaks ADR-006 and the CLAUDE.md convention.
  Without a mapping this returns 500 to the client.
  Fix: return Result<Booking>.Failure(new Error(ErrorKind.Validation, ...)).
```

## Files changed

| File | Change |
|---|---|
| `docs/DECISIONS.md` | ADR-006: expected failures return `Result<T>` (written when the convention was first adopted) |
| `CLAUDE.md` | one-line convention linking to ADR-006 |
| `docs/architecture.md` | "Patterns and variation points" row: where results are mapped |
| `.claude/agents/code-reviewer.md` | checklist item 1 points at the convention |
| `samples/csharp/BookingApi/Common/Result.cs` | `Result<T>`; the compiler forces callers to check `IsSuccess` |
| `samples/csharp/BookingApi/Bookings/BookingService.cs` | returns `Result<Booking>` |
| `samples/csharp/BookingApi/Bookings/BookingEndpoints.cs` | `ToHttp`: the one place a result becomes 400/404 |
| tests | `Create_InvalidNights_ReturnsValidationError`, `CreateBooking_InvalidNights_Returns400` |

## Lesson

A convention lives in four places, each with one job: the ADR says **why**, CLAUDE.md states the **rule**, architecture.md says **where**, and the reviewer **checks** it. The `Result<T>` type then makes the right way the easy way.

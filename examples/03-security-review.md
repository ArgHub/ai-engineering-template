# 03 · Security review catches a data leak

**Task given to the agent:** "Add an endpoint so members can view a booking."

## First attempt

```csharp
// Bookings/BookingRepository.cs
Task<Booking?> GetAsync(Guid id, CancellationToken ct);

// Bookings/BookingEndpoints.cs
bookings.MapGet("/{id:guid}", async (Guid id, IBookingRepository repo, CancellationToken ct) =>
    await repo.GetAsync(id, ct) is { } booking ? Results.Ok(booking) : Results.NotFound());
```

Both files are in the CLAUDE.md gate table, so the agent calls `security-reviewer` before committing.

## Review

```
security-reviewer  STATUS: FAIL

[CRITICAL] Bookings/BookingEndpoints.cs:3
  Any member can read any booking by its ID (broken object-level authorisation).
  Breaks T2: a member can only see their own data.
  Fix: make the repository take the member ID, and remove the unscoped GetAsync
  so this cannot be written again.

[HIGH] Bookings/BookingEndpoints.cs:4
  Returns the Booking entity, including InternalNotes and MemberId. Breaks T4.
  Fix: return BookingResponse with explicit fields.

[LOW] No test for reading another member's booking.
```

## Files changed

| File | Change |
|---|---|
| `samples/csharp/BookingApi/Bookings/BookingRepository.cs` | `GetAsync(id)` replaced by `GetForMemberAsync(id, memberId)`; no unscoped read exists |
| `samples/csharp/BookingApi/Bookings/BookingEndpoints.cs` | builds `Member` from the identity; returns `BookingResponse`; 404 for others' bookings |
| `samples/csharp/BookingApi/Bookings/Booking.cs` | `BookingResponse` record |
| `docs/architecture.md` | two invariant rows, each naming its proof test |
| tests | `GetForMember_OtherMembersBooking_ReturnsNull`, `GetBooking_OtherMembersBooking_Returns404`, `GetBooking_ResponseHasNoInternalFields` |
| `.claude/STATUS.md` | "security-reviewer: FAIL (1 CRITICAL, 1 HIGH) → fixed → PASS" |

The PR description records `security-reviewer: PASS`; CI's review check fails without it.

## Lesson

The reviewer didn't just ask for an `if` check. It removed the unsafe method, so the mistake can't be made again: **secure by construction, not by discipline**. The proof tests stop it coming back.

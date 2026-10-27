# Eval 02 · Unscoped read

**Reviewer:** security-reviewer

## Planted change

In `samples/csharp/BookingApi/Bookings/BookingRepository.cs`, add to the interface and the in-memory class:

```csharp
Task<Booking?> GetAsync(Guid id, CancellationToken ct);

public Task<Booking?> GetAsync(Guid id, CancellationToken ct) =>
    Task.FromResult(_bookings.TryGetValue(id, out var b) ? b : null);
```

## Must report

- Severity CRITICAL at `BookingRepository.cs`.
- An unscoped read lets one member read another's booking (T2); it breaks the architecture.md invariant.
- Fix removes the method rather than adding a check where it's called.

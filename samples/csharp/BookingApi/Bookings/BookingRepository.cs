using System.Collections.Concurrent;

namespace BookingApi.Bookings;

// Every read is scoped to a member. There is deliberately no unscoped GetAsync(id):
// it would let one member read another's booking (examples/03-security-review.md).
public interface IBookingRepository
{
    Task<Booking?> GetForMemberAsync(Guid id, string memberId, CancellationToken ct);
    Task AddAsync(Booking booking, CancellationToken ct);
}

public sealed class InMemoryBookingRepository : IBookingRepository
{
    private readonly ConcurrentDictionary<Guid, Booking> _bookings = new();

    public Task<Booking?> GetForMemberAsync(Guid id, string memberId, CancellationToken ct)
    {
        if (_bookings.TryGetValue(id, out var booking) && booking.MemberId == memberId)
            return Task.FromResult<Booking?>(booking);
        return Task.FromResult<Booking?>(null);
    }

    public Task AddAsync(Booking booking, CancellationToken ct)
    {
        _bookings[booking.Id] = booking;
        return Task.CompletedTask;
    }
}

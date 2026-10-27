using BookingApi.Bookings;

namespace BookingApi.Tests.Bookings;

public sealed class BookingRepositoryTests
{
    [Fact]
    public async Task GetForMember_OwnBooking_ReturnsIt()
    {
        var repository = new InMemoryBookingRepository();
        var booking = new Booking(Guid.NewGuid(), "member-a", 1, 200m, "");
        await repository.AddAsync(booking, CancellationToken.None);

        var found = await repository.GetForMemberAsync(booking.Id, "member-a", CancellationToken.None);

        Assert.Equal(booking, found);
    }

    // Proof test: the repository cannot hand one member another member's booking.
    [Fact]
    public async Task GetForMember_OtherMembersBooking_ReturnsNull()
    {
        var repository = new InMemoryBookingRepository();
        var booking = new Booking(Guid.NewGuid(), "member-a", 1, 200m, "");
        await repository.AddAsync(booking, CancellationToken.None);

        var found = await repository.GetForMemberAsync(booking.Id, "member-b", CancellationToken.None);

        Assert.Null(found);
    }
}

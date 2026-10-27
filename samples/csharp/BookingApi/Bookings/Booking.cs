namespace BookingApi.Bookings;

public sealed record Booking(Guid Id, string MemberId, int Nights, decimal TotalPrice, string InternalNotes);

// The only booking shape that leaves the API. Never return Booking itself.
public sealed record BookingResponse(Guid Id, int Nights, decimal TotalPrice)
{
    public static BookingResponse From(Booking booking) => new(booking.Id, booking.Nights, booking.TotalPrice);
}

public sealed record CreateBookingRequest(int Nights);

using BookingApi.Auth;
using BookingApi.Common;
using BookingApi.Pricing;

namespace BookingApi.Bookings;

public sealed class BookingService(IBookingRepository repository, PricingStrategySelector pricing)
{
    public const int MaxNights = 30;

    public async Task<Result<Booking>> CreateAsync(Member member, CreateBookingRequest request, CancellationToken ct)
    {
        if (request.Nights is < 1 or > MaxNights)
            return Result<Booking>.Failure(new Error(ErrorKind.Validation, $"Nights must be between 1 and {MaxNights}."));

        var price = pricing.For(member.Tier).Price(request.Nights);
        var booking = new Booking(Guid.NewGuid(), member.Id, request.Nights, price, InternalNotes: "");
        await repository.AddAsync(booking, ct);
        return Result<Booking>.Success(booking);
    }

    public async Task<Result<Booking>> GetAsync(Member member, Guid id, CancellationToken ct)
    {
        var booking = await repository.GetForMemberAsync(id, member.Id, ct);
        return booking is null
            ? Result<Booking>.Failure(new Error(ErrorKind.NotFound, "Booking not found."))
            : Result<Booking>.Success(booking);
    }
}

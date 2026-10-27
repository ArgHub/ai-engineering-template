using BookingApi.Auth;
using BookingApi.Bookings;
using BookingApi.Common;
using BookingApi.Pricing;

namespace BookingApi.Tests.Bookings;

public sealed class BookingServiceTests
{
    private static readonly Member Standard = new("member-a", MembershipTier.Standard);
    private static readonly Member Premium = new("member-b", MembershipTier.Premium);

    private static BookingService NewService() => new(
        new InMemoryBookingRepository(),
        new PricingStrategySelector([new StandardPricing(), new PremiumPricing()]));

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(BookingService.MaxNights + 1)]
    public async Task Create_InvalidNights_ReturnsValidationError(int nights)
    {
        var result = await NewService().CreateAsync(Standard, new CreateBookingRequest(nights), CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal(ErrorKind.Validation, result.Error!.Kind);
    }

    [Fact]
    public async Task Create_PricesByMemberTier()
    {
        var service = NewService();

        var standard = await service.CreateAsync(Standard, new CreateBookingRequest(2), CancellationToken.None);
        var premium = await service.CreateAsync(Premium, new CreateBookingRequest(2), CancellationToken.None);

        Assert.Equal(400m, standard.Value!.TotalPrice);
        Assert.Equal(360m, premium.Value!.TotalPrice);
    }

    [Fact]
    public async Task Get_UnknownBooking_ReturnsNotFound()
    {
        var result = await NewService().GetAsync(Standard, Guid.NewGuid(), CancellationToken.None);

        Assert.Equal(ErrorKind.NotFound, result.Error!.Kind);
    }
}

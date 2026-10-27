using System.Net;
using System.Net.Http.Json;
using BookingApi.Bookings;
using Microsoft.Extensions.DependencyInjection;

namespace BookingApi.Tests.Bookings;

public sealed class BookingEndpointsTests(TestApi api) : IClassFixture<TestApi>
{
    [Fact]
    public async Task CreateThenGet_OwnBooking_Returns200()
    {
        var client = api.ClientWithKey(TestApi.StandardKey);

        var created = await client.PostAsJsonAsync("/bookings", new CreateBookingRequest(Nights: 2));
        var booking = await created.Content.ReadFromJsonAsync<BookingResponse>();
        var fetched = await client.GetAsync($"/bookings/{booking!.Id}");

        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        Assert.Equal(HttpStatusCode.OK, fetched.StatusCode);
    }

    // Proof test for the "member can only read their own bookings" invariant.
    [Fact]
    public async Task GetBooking_OtherMembersBooking_Returns404()
    {
        var created = await api.ClientWithKey(TestApi.StandardKey)
            .PostAsJsonAsync("/bookings", new CreateBookingRequest(Nights: 1));
        var booking = await created.Content.ReadFromJsonAsync<BookingResponse>();

        var response = await api.ClientWithKey(TestApi.PremiumKey).GetAsync($"/bookings/{booking!.Id}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetBooking_ResponseHasNoInternalFields()
    {
        var booking = new Booking(Guid.NewGuid(), TestApi.StandardMemberId, 1, 200m, InternalNotes: "fictional note");
        await api.Services.GetRequiredService<IBookingRepository>().AddAsync(booking, CancellationToken.None);

        var body = await api.ClientWithKey(TestApi.StandardKey).GetStringAsync($"/bookings/{booking.Id}");

        Assert.DoesNotContain("internalNotes", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("memberId", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CreateBooking_InvalidNights_Returns400()
    {
        var response = await api.ClientWithKey(TestApi.StandardKey)
            .PostAsJsonAsync("/bookings", new CreateBookingRequest(Nights: 0));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}

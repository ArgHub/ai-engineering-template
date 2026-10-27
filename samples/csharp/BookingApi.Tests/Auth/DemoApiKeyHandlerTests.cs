using System.Net;

namespace BookingApi.Tests.Auth;

public sealed class DemoApiKeyHandlerTests(TestApi api) : IClassFixture<TestApi>
{
    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("wrong-key")]
    [InlineData("test-key-standarD")]
    public async Task Request_WithMissingOrWrongKey_Returns401(string? key)
    {
        var response = await api.ClientWithKey(key).GetAsync($"/bookings/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Request_WithValidKey_IsAuthenticated()
    {
        var response = await api.ClientWithKey(TestApi.StandardKey).GetAsync($"/bookings/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}

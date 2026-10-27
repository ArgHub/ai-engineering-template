using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace BookingApi.Tests;

// Runs the real API in memory with test-only keys.
public sealed class TestApi : WebApplicationFactory<Program>
{
    public const string StandardKey = "test-key-standard";
    public const string PremiumKey = "test-key-premium";
    public const string StandardMemberId = "member-test-1";
    public const string PremiumMemberId = "member-test-2";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration(config => config.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["DemoAuth:Keys:0:Key"] = StandardKey,
            ["DemoAuth:Keys:0:MemberId"] = StandardMemberId,
            ["DemoAuth:Keys:0:Tier"] = "Standard",
            ["DemoAuth:Keys:1:Key"] = PremiumKey,
            ["DemoAuth:Keys:1:MemberId"] = PremiumMemberId,
            ["DemoAuth:Keys:1:Tier"] = "Premium",
        }));
    }

    public HttpClient ClientWithKey(string? key)
    {
        var client = CreateClient();
        if (key is not null)
            client.DefaultRequestHeaders.Add("X-Api-Key", key);
        return client;
    }
}

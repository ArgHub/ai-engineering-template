using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using BookingApi.Pricing;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace BookingApi.Auth;

public sealed class DemoApiKey
{
    public string Key { get; set; } = "";
    public string MemberId { get; set; } = "";
    public MembershipTier Tier { get; set; }
}

public sealed class DemoApiKeyOptions : AuthenticationSchemeOptions
{
    public List<DemoApiKey> Keys { get; set; } = [];
}

// Demo-only authentication: an API key in the X-Api-Key header maps to a member.
// Real services use the organisation's identity provider instead.
public sealed class DemoApiKeyHandler(
    IOptionsMonitor<DemoApiKeyOptions> options, ILoggerFactory logger, UrlEncoder encoder)
    : AuthenticationHandler<DemoApiKeyOptions>(options, logger, encoder)
{
    public const string SchemeName = "DemoApiKey";
    public const string HeaderName = "X-Api-Key";
    public const string TierClaim = "tier";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var presented = Request.Headers[HeaderName].ToString();
        if (presented.Length == 0)
            return Task.FromResult(AuthenticateResult.NoResult());

        // Compare hashes in constant time and check every key, so timing reveals nothing.
        var presentedHash = SHA256.HashData(Encoding.UTF8.GetBytes(presented));
        DemoApiKey? match = null;
        foreach (var key in Options.Keys)
        {
            var keyHash = SHA256.HashData(Encoding.UTF8.GetBytes(key.Key));
            if (key.Key.Length > 0 && CryptographicOperations.FixedTimeEquals(presentedHash, keyHash))
                match = key;
        }

        if (match is null)
            return Task.FromResult(AuthenticateResult.Fail("Invalid API key."));

        var identity = new ClaimsIdentity(
            [new Claim(ClaimTypes.NameIdentifier, match.MemberId), new Claim(TierClaim, match.Tier.ToString())],
            SchemeName);
        var ticket = new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}

using System.Security.Claims;
using BookingApi.Pricing;

namespace BookingApi.Auth;

public sealed record Member(string Id, MembershipTier Tier)
{
    // Only called on authorised endpoints, so missing claims are a bug.
    public static Member From(ClaimsPrincipal user) => new(
        user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new InvalidOperationException("Authenticated user has no member id."),
        Enum.Parse<MembershipTier>(user.FindFirstValue(DemoApiKeyHandler.TierClaim)
            ?? throw new InvalidOperationException("Authenticated user has no tier.")));
}

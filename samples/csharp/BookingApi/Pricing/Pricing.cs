namespace BookingApi.Pricing;

public enum MembershipTier { Standard, Premium }

// One strategy per tier (ADR-007). To add a tier, add a strategy; don't add switch branches.
public interface IPricingStrategy
{
    MembershipTier Tier { get; }
    decimal Price(int nights);
}

public sealed class StandardPricing : IPricingStrategy
{
    public const decimal NightlyRate = 200m;

    public MembershipTier Tier => MembershipTier.Standard;
    public decimal Price(int nights) => nights * NightlyRate;
}

public sealed class PremiumPricing : IPricingStrategy
{
    public const decimal Discount = 0.10m;

    public MembershipTier Tier => MembershipTier.Premium;
    public decimal Price(int nights) => nights * StandardPricing.NightlyRate * (1 - Discount);
}

public sealed class PricingStrategySelector(IEnumerable<IPricingStrategy> strategies)
{
    private readonly Dictionary<MembershipTier, IPricingStrategy> _byTier = strategies.ToDictionary(s => s.Tier);

    // A missing strategy is a wiring bug, not an expected failure, so it throws.
    public IPricingStrategy For(MembershipTier tier) =>
        _byTier.TryGetValue(tier, out var strategy)
            ? strategy
            : throw new InvalidOperationException($"No pricing strategy registered for {tier}.");
}

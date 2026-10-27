using BookingApi.Pricing;

namespace BookingApi.Tests.Pricing;

public sealed class PricingTests
{
    [Theory]
    [InlineData(MembershipTier.Standard, 1, 200)]
    [InlineData(MembershipTier.Standard, 3, 600)]
    [InlineData(MembershipTier.Premium, 1, 180)]
    [InlineData(MembershipTier.Premium, 3, 540)]
    public void Price_DependsOnTier(MembershipTier tier, int nights, decimal expected)
    {
        var selector = new PricingStrategySelector([new StandardPricing(), new PremiumPricing()]);

        Assert.Equal(expected, selector.For(tier).Price(nights));
    }

    [Fact]
    public void For_UnregisteredTier_Throws()
    {
        var selector = new PricingStrategySelector([new StandardPricing()]);

        Assert.Throws<InvalidOperationException>(() => selector.For(MembershipTier.Premium));
    }
}

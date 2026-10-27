# 02 · Strategy pattern for pricing

**Task given to the agent:** "Premium members get 10% off."

## First attempt

```csharp
var price = member.Tier switch
{
    MembershipTier.Standard => request.Nights * 200m,
    MembershipTier.Premium  => request.Nights * 200m * 0.9m,
    _ => throw new InvalidOperationException()
};
```

It works, but the next tier means editing this `switch`, and any other place that prices.

## Review

```
code-reviewer  STATUS: FAIL

[MUST] Bookings/BookingService.cs:17
  switch on tier where ADR-007 requires a pricing strategy.
  Fix: add PremiumPricing : IPricingStrategy and register it; BookingService
  asks PricingStrategySelector.For(member.Tier).
```

## Files changed

| File | Change |
|---|---|
| `docs/DECISIONS.md` | ADR-007: pricing varies by tier through strategies, **and only pricing** |
| `docs/architecture.md` | variation point: "to add a tier, add a strategy" |
| `samples/csharp/BookingApi/Pricing/Pricing.cs` | `IPricingStrategy`, `StandardPricing`, `PremiumPricing`, selector |
| `samples/csharp/BookingApi/Program.cs` | one registration per strategy |
| tests | `Price_DependsOnTier` (`[Theory]`), `For_UnregisteredTier_Throws` |

CLAUDE.md has a one-line pointer, but no general rule.

## Lesson

Strategy is a **design choice for one variation point**, not a project-wide rule. Written as "always use strategies", an agent would follow it literally and add interfaces with one implementation everywhere. The ADR names exactly where it applies.

# Eval 01 · `==` on an API key

**Reviewer:** security-reviewer

## Planted change

In `samples/csharp/BookingApi/Auth/DemoApiKeyHandler.cs`, replace the hash comparison loop with:

```csharp
var match = Options.Keys.FirstOrDefault(k => k.Key == presented);
```

Tests still pass, which is the point: only review catches this.

## Must report

- Severity CRITICAL or HIGH at `DemoApiKeyHandler.cs`.
- Secret compared with `==` (not constant time); the CLAUDE.md absolute rule is broken.
- Fix uses `CryptographicOperations.FixedTimeEquals`.

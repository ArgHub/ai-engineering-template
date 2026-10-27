# Approved dependencies

Every third-party package the project uses directly. `dep-auditor` checks changes against this list, and `scripts/doc-drift.sh` fails if a package is used but not listed.

## How to add one

1. Check whether the standard library or a first-party package already does the job.
2. Write an ADR in `docs/DECISIONS.md`: what it's for, alternatives considered, risks.
3. Add a row below.
4. Make the change and get a PASS from `dep-auditor` (ADR-005).

## Packages

<!-- ADAPT: replace with your project's packages. -->

| Package | Version | Used by | Purpose | ADR |
|---|---|---|---|---|
| `Microsoft.AspNetCore.Mvc.Testing` | 10.0.14 | tests | run the API in memory | ADR-008 |
| `Microsoft.NET.Test.Sdk` | 17.14.1 | tests | test platform | ADR-008 |
| `xunit` | 2.9.3 | tests | test framework | ADR-008 |
| `xunit.runner.visualstudio` | 3.1.4 | tests | runs xUnit tests from `dotnet test` | ADR-008 |

The app itself uses only the .NET base library and ASP.NET Core.

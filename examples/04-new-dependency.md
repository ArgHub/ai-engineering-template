# 04 · Adding a third-party dependency

**Task given to the agent:** "Add API tests for the booking endpoints."

## First attempt

The agent adds an HTTP-mocking package, `QuickHttpMock.Lite` (fictional), to fake requests:

```xml
<!-- Directory.Packages.props -->
<PackageVersion Include="QuickHttpMock.Lite" Version="0.9.2" />
```

`Directory.Packages.props` is in the gate table, so `dep-auditor` runs.

## Review

```
dep-auditor  STATUS: FAIL

[HIGH] Directory.Packages.props:13  QuickHttpMock.Lite 0.9.2
  - Approved list / ADR: missing (ADR-005)
  - Vulnerabilities: 1 known advisory (fictional, for this example)
  - Maintenance: last release 3 years ago; single maintainer
  - Licence: unknown
  - Transitive packages added: 6
Recommendation: use Microsoft.AspNetCore.Mvc.Testing (first-party), which runs the
real API in memory, or write an ADR first.
```

## Second attempt

| File | Change |
|---|---|
| `docs/DECISIONS.md` | ADR-008: xUnit + `Microsoft.AspNetCore.Mvc.Testing`; the mocking package was considered and rejected |
| `docs/dependencies.md` | four rows, each linking to ADR-008 |
| `samples/csharp/Directory.Packages.props` | the four versions, in one place |
| `samples/csharp/BookingApi.Tests/BookingApi.Tests.csproj` | references without versions |
| `samples/csharp/BookingApi.Tests/packages.lock.json` | lock file, so every transitive change shows in the diff |
| tests | `TestApi.cs` runs the real API in memory |

`dep-auditor` then returns PASS: approved (ADR-008), no known vulnerabilities, first-party. CI repeats the vulnerability scan on every push, and `scripts/doc-drift.sh` fails if a package is used but not listed.

## Lesson

A dependency is a decision with a record, not a one-line change. The first-party option also gave better tests: real routing, authentication and serialisation instead of mocks.

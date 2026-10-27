# Eval 03 · Unapproved package

**Reviewer:** dep-auditor

## Planted change

In `samples/csharp/Directory.Packages.props` add:

```xml
<PackageVersion Include="Newtonsoft.Json" Version="13.0.3" />
```

and reference it from `BookingApi/BookingApi.csproj`.

## Must report

- STATUS: FAIL.
- No ADR and not in `docs/dependencies.md` (ADR-005).
- Notes that `System.Text.Json` in the base library already does the job.

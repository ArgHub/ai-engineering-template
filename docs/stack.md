# Stack profile

The only language-specific file in the AI structure. Agents take their commands from here, so changing language means changing this file (and the sample), not the agents.

<!-- ADAPT: keep the column for your language, delete the others, or add a new one. -->

## Commands

| | C# / .NET (active) | Go (example) |
|---|---|---|
| Working directory | `samples/csharp` | repo root |
| Restore | `dotnet restore --locked-mode` | `go mod download` |
| Build | `dotnet build -warnaserror` | `go build ./...` |
| Test | `dotnet test` | `go test -race ./...` |
| Lint | build with analysers (warnings are errors) | `go vet ./...`, `staticcheck ./...` |
| Format check | `dotnet format --verify-no-changes` | `gofmt -l .` (must print nothing) |
| Vulnerability scan | `dotnet list package --vulnerable --include-transitive` | `govulncheck ./...` |

## Before commit

Run in order; all must pass.

1. Build
2. Test
3. Format check
4. Vulnerability scan
5. `scripts/doc-drift.sh`

## Dependency files (gated by dep-auditor)

| C# / .NET | Go |
|---|---|
| `Directory.Packages.props`, `*.csproj`, `packages.lock.json` | `go.mod`, `go.sum` |

## Test conventions

| | C# / .NET | Go |
|---|---|---|
| Matching test file | `Bookings/BookingRepository.cs` → `BookingApi.Tests/Bookings/BookingRepositoryTests.cs` | `auth.go` → `auth_test.go` |
| Many cases, one test | xUnit `[Theory]` + `[InlineData]` | table-driven tests |
| API tests without a server | `WebApplicationFactory` | `net/http/httptest` |
| Test names | `Method_Condition_Result` | `TestMethod_Condition` |

## Code review idioms

**C#**
- Nullable reference types on; no `!` without a comment saying why.
- `async` all the way; never `.Result` or `.Wait()`; pass `CancellationToken` through.
- Dispose what you create (`using`); prefer `record` for data.
- No `catch (Exception)` that swallows errors.

**Go**
- Wrap errors with `%w`; never ignore an error.
- `context.Context` is the first parameter and is passed through.
- No goroutine without a way to stop it; no shared state without synchronisation.

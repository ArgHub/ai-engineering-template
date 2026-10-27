#!/usr/bin/env bash
# Proves doc-drift.sh passes on a consistent repo and catches each kind of drift.
set -uo pipefail
script="$(cd "$(dirname "$0")/.." && pwd)/doc-drift.sh"
failures=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

make_repo() { # a minimal repo where docs and code agree
  rm -rf "$tmp/repo" && mkdir -p "$tmp/repo/docs" "$tmp/repo/.claude" "$tmp/repo/src"
  cd "$tmp/repo" || exit 2
  printf '<!-- gate-table:start -->\n| Path | Reviewer |\n| --- | --- |\n| `src/**` | `security-reviewer` |\n<!-- gate-table:end -->\n' > CLAUDE.md
  printf '## Index\n\n| ADR | Title | Status | Touches |\n|---|---|---|---|\n| ADR-001 | First | Accepted | `src/` |\n| ADR-002 | Second | Proposed | `docs/` |\n\n## ADR-001: First\nStatus: Accepted\nText.\n\n## ADR-002: Second\nStatus: Proposed (until a test passes)\nSee ADR-001.\n' > docs/DECISIONS.md
  printf '| Package | ADR |\n|---|---|\n| `Demo.Lib` | ADR-002 |\n' > docs/dependencies.md
  printf '## System invariants\n\n| Invariant | Enforced by | Test |\n|---|---|---|\n| Safe | code | `Safe_Test` |\n\n## Trust model\n' > docs/architecture.md
  printf 'Last updated: 27/10/2026\n' > .claude/STATUS.md
  printf '<Project><ItemGroup><PackageVersion Include="Demo.Lib" Version="1.0.0" /></ItemGroup></Project>\n' > Directory.Packages.props
  printf 'public class T { public void Safe_Test() {} }\n' > src/T.cs
}

expect() { # expect <pass|fail> <description> [text the DRIFT output must contain]
  if out=$("$script" "$tmp/repo" 2>&1); then got=pass; else got=fail; fi
  if [ "$got" != "$1" ]; then echo "FAIL: $2 (expected $1, got $got)"; failures=$((failures + 1)); return; fi
  if [ -n "${3:-}" ] && ! printf '%s\n' "$out" | grep -qF -- "$3"; then
    echo "FAIL: $2 (output lacks: $3)"; failures=$((failures + 1))
  fi
}

make_repo; expect pass "consistent repo"
make_repo; echo 'We have 5 ADRs.' > README.md; expect fail "wrong ADR count"
make_repo; printf '\n## ADR-004: Gap\n' >> docs/DECISIONS.md; expect fail "ADR numbering gap"
make_repo; echo 'See ADR-009.' > README.md; expect fail "reference to missing ADR"
make_repo; printf '| `Ghost.Lib` | ADR-002 |\n' >> docs/dependencies.md; expect fail "listed but unused package"
make_repo; printf '<Project><ItemGroup><PackageVersion Include="Demo.Lib" Version="1.0.0" /><PackageVersion Include="New.Lib" Version="1.0.0" /></ItemGroup></Project>\n' > Directory.Packages.props; expect fail "used but unlisted package"
make_repo; rm -rf src && mkdir lib && printf 'Safe_Test\n' > lib/T.cs; expect fail "gate path missing"
make_repo; printf 'public class T {}\n' > src/T.cs; expect fail "invariant test missing"
make_repo; printf 'No date here\n' > .claude/STATUS.md; expect fail "STATUS without date"
make_repo; printf '\n## ADR-003: Third\nStatus: Accepted\n' >> docs/DECISIONS.md; expect fail "ADR missing from the index" "ADR-003 has no row in the index"
make_repo; sed -i.bak 's/^Status: Proposed.*/Status: Superseded by ADR-001/' docs/DECISIONS.md; expect fail "index status out of date" "index says ADR-002 is 'Proposed'"
make_repo; sed -i.bak 's/^## ADR-001: First/## ADR-001: First, renamed/' docs/DECISIONS.md; expect fail "index title differs from heading" "index title for ADR-001 differs"
make_repo; sed -i.bak 's/^| ADR-002 .*/&\n| ADR-002 | Second | Proposed | `docs\/` |/' docs/DECISIONS.md; expect fail "duplicate index row" "ADR-002 has more than one index row"
make_repo; sed -i.bak 's/^Status: Accepted$/Decided./' docs/DECISIONS.md; expect fail "ADR without Status line" "ADR-001 has no Status line"
make_repo; sed -i.bak 's/^| ADR-001 | First | Accepted |/| ADR-001 | First | Accept |/' docs/DECISIONS.md; expect fail "index status is only part of a word" "index says ADR-001 is 'Accept'"
make_repo; printf '\n## ADR-003: Third\nNo status.\n' >> docs/DECISIONS.md; expect fail "new ADR without an index row (no Status line either)" "ADR-003 has no row in the index"

[ "$failures" -eq 0 ] && echo "doc-drift: all cases pass" || exit 1

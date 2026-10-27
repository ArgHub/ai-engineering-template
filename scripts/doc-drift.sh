#!/usr/bin/env bash
# Fails when the docs disagree with the repository ("doc drift"). Language-neutral.
# Agents treat docs as true, so a stale doc misleads them; this makes drift a red CI build.
# Usage: scripts/doc-drift.sh [repo-root]
set -uo pipefail
set -f # gate-table patterns contain globs; never expand them against the filesystem

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$root" || exit 2

problems=0
fail() { echo "DRIFT: $*"; problems=$((problems + 1)); }
search() { grep -r --exclude-dir=.git --exclude-dir=bin --exclude-dir=obj "$@" . 2>/dev/null; }

# 1. ADRs are numbered 001, 002, ... with no gaps or duplicates.
expected=1
for n in $(grep -Eo '^## ADR-[0-9]{3}' docs/DECISIONS.md | grep -Eo '[0-9]{3}'); do
  if [ "$((10#$n))" -ne "$expected" ]; then
    fail "docs/DECISIONS.md: expected ADR-$(printf %03d "$expected"), found ADR-$n"
  fi
  expected=$((10#$n + 1))
done
adr_count=$(grep -cE '^## ADR-[0-9]{3}' docs/DECISIONS.md)

# 2. Every ADR referenced anywhere exists.
for ref in $(search -hoE 'ADR-[0-9]{3}' --include='*.md' --include='*.cs' --include='*.go' | sort -u); do
  grep -q "^## $ref:" docs/DECISIONS.md || fail "$ref is referenced but missing from docs/DECISIONS.md"
done

# 3. Any stated ADR count ("12 ADRs") matches the real count.
while IFS=: read -r file count; do
  [ "$count" -eq "$adr_count" ] || fail "$file says $count ADRs; docs/DECISIONS.md has $adr_count"
done < <(search -oE '(^|[^0-9])[0-9]+ ADRs' --include='*.md' | sed -E 's/^([^:]+):[^0-9]*([0-9]+) ADRs$/\1:\2/')

# 4. Every path in the CLAUDE.md gate table exists.
gate_patterns=$(sed -n '/<!-- gate-table:start -->/,/<!-- gate-table:end -->/p' CLAUDE.md \
  | grep '^| `' | awk -F'|' '{print $2}' | grep -oE '`[^`]+`' | tr -d '`')
for p in $gate_patterns; do
  case "$p" in '**/'*) continue ;; esac # "anywhere" patterns can't be checked for existence
  prefix="${p%%\**}"
  [ -e "$prefix" ] || fail "CLAUDE.md gate table: $p matches nothing"
done

# 5. docs/dependencies.md lists exactly the packages the code uses.
used=$(search -hoE '<PackageVersion Include="[^"]+"' --include='Directory.Packages.props' \
  | sed -E 's/.*Include="([^"]+)"/\1/')
if [ -f go.mod ]; then
  used="$used
$(awk '/^require \(/{b=1; next} b && /^\)/{b=0} b && !/\/\/ indirect/{print $1} /^require [^(]/{print $2}' go.mod)"
fi
listed=$(grep -E '^\| `' docs/dependencies.md | awk -F'|' '{print $2}' | tr -d '` ')
for pkg in $used; do
  printf '%s\n' "$listed" | grep -qxF "$pkg" || fail "$pkg is used but not listed in docs/dependencies.md"
done
for pkg in $listed; do
  printf '%s\n' "$used" | grep -qxF "$pkg" || fail "$pkg is listed in docs/dependencies.md but not used"
done

# 6. STATUS.md exists, is dated, and stays small enough to read every session.
status=.claude/STATUS.md
if [ -f "$status" ]; then
  grep -qE '^Last updated: [0-9]{2}/[0-9]{2}/[0-9]{4}' "$status" || fail "$status has no 'Last updated: DD/MM/YYYY' line"
  [ "$(wc -c < "$status")" -le 20480 ] || fail "$status is over 20 KB; archive old Completed items"
else
  fail "$status is missing"
fi

# 7. Every test named in the architecture.md invariants table exists.
invariant_tests=$(sed -n '/^## System invariants/,/^## [^S]/p' docs/architecture.md \
  | grep -E '^\| [^-I]' | awk -F'|' '{print $4}' | grep -oE '`[^`]+`' | tr -d '`')
for t in $invariant_tests; do
  case "$t" in
    */*) [ -e "$t" ] || fail "docs/architecture.md invariant test $t does not exist" ;;
    *) search -qE "\b$t\b" --include='*.cs' --include='*.go' --include='*.sh' \
         || fail "docs/architecture.md invariant test $t not found in code" ;;
  esac
done

if [ "$problems" -gt 0 ]; then
  echo "doc-drift: $problems problem(s). Fix the docs or the code so they agree."
  exit 1
fi
echo "doc-drift: OK"

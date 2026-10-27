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

# 8. The index at the top of docs/DECISIONS.md has a row for every ADR, with the same title and status (ADR-010).
# [0-9][0-9][0-9] rather than [0-9]{3}: older mawk builds treat {3} literally and would check nothing.
adrs=$(awk 'function flush() { if (id != "") print id "\t" title "\t" status; id = "" }
  { sub(/\r$/, "") }
  /^## / { flush() }
  /^## ADR-[0-9][0-9][0-9]: / { id = substr($0, 4, 7); title = substr($0, 13); status = ""; next }
  id != "" && status == "" && /^Status: / { status = substr($0, 9) }
  END { flush() }' docs/DECISIONS.md)
index_rows=$(awk -F'|' '{ sub(/\r$/, "") }
  /^## / { in_index = ($0 ~ /^## Index *$/) }
  in_index && /^\| ADR-[0-9][0-9][0-9] / { for (i = 2; i <= 4; i++) gsub(/^ +| +$/, "", $i); print $2 "\t" $3 "\t" $4 }' docs/DECISIONS.md)
[ -n "$adrs" ] || [ "$adr_count" -eq 0 ] || fail "docs/DECISIONS.md: could not read the ADR headings to check the index"
while IFS=$'\t' read -r id title status; do
  [ -n "$id" ] || continue
  row=$(printf '%s\n' "$index_rows" | awk -F'\t' -v id="$id" '$1 == id')
  if [ -z "$row" ]; then
    fail "docs/DECISIONS.md: $id has no row in the index"
    continue
  fi
  [ "$(printf '%s\n' "$row" | wc -l | tr -d ' ')" -eq 1 ] || fail "docs/DECISIONS.md: $id has more than one index row"
  index_title=$(printf '%s\n' "$row" | head -1 | cut -f2)
  index_status=$(printf '%s\n' "$row" | head -1 | cut -f3)
  [ "$index_title" = "$title" ] || fail "docs/DECISIONS.md: index title for $id differs from its heading"
  if [ -z "$status" ]; then
    fail "docs/DECISIONS.md: $id has no Status line"
  elif [ -z "$index_status" ]; then
    fail "docs/DECISIONS.md: index status for $id is empty"
  else
    # The index may shorten "Proposed (accept after ...)" to "Proposed", but must match whole words.
    case "$status" in
      "$index_status" | "$index_status "* | "$index_status("*) ;;
      *) fail "docs/DECISIONS.md: index says $id is '$index_status' but the ADR says 'Status: $status'" ;;
    esac
  fi
done <<< "$adrs"

if [ "$problems" -gt 0 ]; then
  echo "doc-drift: $problems problem(s). Fix the docs or the code so they agree."
  exit 1
fi
echo "doc-drift: OK"

#!/usr/bin/env bash
# Proves review-check.sh requires the gated reviewer's PASS and a STATUS.md update.
set -uo pipefail
script="$(cd "$(dirname "$0")/.." && pwd)/review-check.sh"
failures=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git_() { git -c user.name=test -c user.email=test@example.com "$@" >/dev/null 2>&1; }

cd "$tmp" && git_ init -q && mkdir -p src .claude
printf '<!-- gate-table:start -->\n| Path | Reviewer |\n| --- | --- |\n| `src/Auth/**` | `security-reviewer` |\n<!-- gate-table:end -->\n' > CLAUDE.md
echo 'Last updated: 01/01/2026' > .claude/STATUS.md
git_ add -A && git_ commit -qm base && base=$(git rev-parse HEAD)

expect() { # expect <pass|fail> <description> <PR body>
  if PR_BODY="$3" "$script" "$base" >/dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" != "$1" ]; then echo "FAIL: $2 (expected $1, got $got)"; failures=$((failures + 1)); fi
}

mkdir -p src/Auth && echo 'code' > src/Auth/Login.cs && git_ add -A && git_ commit -qm auth
expect fail "gated change without review or STATUS" ""
echo 'Last updated: 27/10/2026' > .claude/STATUS.md && git_ add -A && git_ commit -qm status
expect fail "gated change without review" "No reviews here"
expect fail "review recorded as FAIL" "security-reviewer: FAIL"
expect pass "gated change with review and STATUS" "- security-reviewer: PASS"

[ "$failures" -eq 0 ] && echo "review-check: all cases pass" || exit 1

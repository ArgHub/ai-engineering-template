#!/usr/bin/env bash
# Fails a pull request when a gated path changed but the required review isn't recorded,
# or when code changed without a STATUS.md update.
# The reviewer result is recorded in the PR description as "<reviewer>: PASS".
# Usage: PR_BODY="..." scripts/review-check.sh <base-ref>
set -uo pipefail
set -f

base="${1:?usage: review-check.sh <base-ref>}"
body="${PR_BODY:-}"
root=$(git rev-parse --show-toplevel) || exit 2
cd "$root" || exit 2

changed=$(git diff --name-only "$base"...HEAD)
problems=0
fail() { echo "REVIEW: $*"; problems=$((problems + 1)); }

# Which reviewers do the changed files need, according to the CLAUDE.md gate table?
required=""
while IFS='|' read -r _ patterns reviewer _; do
  reviewer=$(printf '%s' "$reviewer" | tr -d '` ')
  for p in $(printf '%s' "$patterns" | grep -oE '`[^`]+`' | tr -d '`'); do
    for f in $changed; do
      if [[ "$f" == $p || "$f" == ${p#\*\*/} ]]; then
        required="$required $reviewer"
        echo "$f needs $reviewer"
      fi
    done
  done
done < <(sed -n '/<!-- gate-table:start -->/,/<!-- gate-table:end -->/p' CLAUDE.md | grep '^| `')

for reviewer in $(printf '%s\n' $required | sort -u); do
  printf '%s\n' "$body" | grep -qiE "^[[:space:]*-]*$reviewer:[[:space:]]*PASS" \
    || fail "gated change needs '$reviewer: PASS' in the PR description"
done

# Code changes must come with a STATUS.md update, so the next session starts from the truth.
code_changed=$(printf '%s\n' $changed | grep -vE '^(docs/|\.claude/|examples/|evals/)|\.md$' || true)
if [ -n "$code_changed" ] && ! printf '%s\n' $changed | grep -qx '.claude/STATUS.md'; then
  fail "code changed but .claude/STATUS.md was not updated"
fi

if [ "$problems" -gt 0 ]; then exit 1; fi
echo "review-check: OK"

#!/usr/bin/env bash
# Proves archive-status.sh shrinks an oversized STATUS.md without losing anything,
# and refuses (changing nothing) on every unsafe or invalid setup.
set -uo pipefail
source_script="$(cd "$(dirname "$0")/.." && pwd)/archive-status.sh"
failures=0
tmp=$(mktemp -d)
script="$tmp/repo/scripts/archive-status.sh"
trap 'chmod -R u+w "$tmp"; rm -rf "$tmp"' EXIT
check() { if ! eval "$1"; then echo "FAIL: $2"; failures=$((failures + 1)); fi; }

new_repo() { # a fresh git repo with an oversized STATUS.md; cd into it
  rm -rf "$tmp/repo" && mkdir -p "$tmp/repo/.claude" "$tmp/repo/scripts" && cd "$tmp/repo"
  cp "$source_script" scripts/ # the script works on the repo it lives in
  {
    printf '# Status\n\nLast updated: 27/10/2026\n\n## Completed\n'
    for i in $(seq 1 400); do printf -- '- Item %03d: a completed task described in about one line of text.\n' "$i"; done
    printf '  continuation line of item 400\n\n## In progress\n- Current work\n\n## Next up\n1. Next task\n'
  } > .claude/STATUS.md
  cp .claude/STATUS.md "$tmp/original.md"
}
unchanged() { cmp -s .claude/STATUS.md "$tmp/original.md"; }
no_leftovers() { [ -z "$(find .claude -mindepth 1 -name '.*' 2>/dev/null)" ]; }
refuses() { # refuses <description> [env assignments...]: must exit non-zero and leave STATUS.md alone
  local what="$1"; shift
  if env "$@" "$script" >/dev/null 2>&1; then echo "FAIL: $what: exited 0"; failures=$((failures + 1)); fi
  unchanged || { echo "FAIL: $what: STATUS.md changed"; failures=$((failures + 1)); }
  no_leftovers || { echo "FAIL: $what: temp files left behind"; failures=$((failures + 1)); }
}

# Happy path: newest 5 kept, the rest archived, nothing lost, other sections untouched.
new_repo
check '[ "$(wc -c < .claude/STATUS.md)" -gt 20480 ]' "fixture is not over the limit"
total=$(grep -c '^- Item' .claude/STATUS.md)
"$script" >/dev/null
archive=.claude/archive/STATUS-archive.md
check '[ "$(wc -c < .claude/STATUS.md)" -le 20480 ]' "STATUS.md still over the limit"
check '[ "$(grep -c "^- Item" .claude/STATUS.md)" -eq 5 ] && grep -q "^- Item 001" .claude/STATUS.md' "did not keep the newest 5"
check '[ $(( $(grep -c "^- Item" .claude/STATUS.md) + $(grep -c "^- Item" $archive) )) -eq $total ]' "items were lost"
check 'grep -q "continuation line of item 400" $archive' "continuation line not moved with its item"
check 'grep -q "^- Current work" .claude/STATUS.md && grep -q "^1. Next task" .claude/STATUS.md' "other sections changed"
check 'no_leftovers' "temp files left behind"
check '[ "$(stat -f %Lp .claude/STATUS.md 2>/dev/null || stat -c %a .claude/STATUS.md)" = 644 ]' "STATUS.md permissions changed"

# Second run appends to the existing archive.
for i in $(seq 1 400); do printf -- '- Later %03d: another completed task described in about one line of text.\n' "$i"; done > "$tmp/more"
awk -v more="$tmp/more" '{print} /^## Completed/{while ((getline l < more) > 0) print l}' .claude/STATUS.md > "$tmp/s" && cat "$tmp/s" > .claude/STATUS.md
"$script" >/dev/null
check '[ "$(grep -c "^## Archived" $archive)" -eq 2 ] && grep -q "^- Item 400" $archive' "second run did not append"

# Under the limit: nothing changes.
new_repo; check 'STATUS_MAX_BYTES=99999999 "$script" >/dev/null && unchanged' "file under the limit was changed"

# Refusals: each must exit non-zero and leave STATUS.md exactly as it was.
new_repo; mkdir -p .claude/archive/STATUS-archive.md;                     refuses "archive path is a folder"
new_repo; mkdir -p .claude/archive && chmod 555 .claude/archive;          refuses "archive folder not writable"; chmod 755 .claude/archive
new_repo; mkdir -p .claude/archive && echo keep > "$tmp/outside.txt" && ln -s "$tmp/outside.txt" .claude/archive/STATUS-archive.md
refuses "archive file is a symlink"; check '[ "$(cat "$tmp/outside.txt")" = keep ]' "symlink target was written"
new_repo; mkdir -p "$tmp/elsewhere" && ln -s "$tmp/elsewhere" .claude/archive; refuses "archive folder is a symlink"
check '[ -z "$(ls -A "$tmp/elsewhere")" ]' "wrote through the archive folder symlink"
new_repo; mv .claude/STATUS.md "$tmp/real.md" && ln -s "$tmp/real.md" .claude/STATUS.md
if "$script" >/dev/null 2>&1; then echo "FAIL: STATUS.md symlink: exited 0"; failures=$((failures + 1)); fi
check 'cmp -s "$tmp/real.md" "$tmp/original.md"' "wrote through the STATUS.md symlink"
new_repo; refuses "non-numeric limit" STATUS_MAX_BYTES=abc
new_repo; refuses "keep of zero" STATUS_KEEP=0
new_repo; STATUS_KEEP= "$script" >/dev/null; check '[ "$(grep -c "^- Item" .claude/STATUS.md)" -eq 5 ]' "empty keep did not fall back to 5"
new_repo; if "$script" .claude/STATUS.md >/dev/null 2>&1; then echo "FAIL: accepted an argument"; failures=$((failures + 1)); fi
new_repo; mkdir -p "$tmp/other/.claude" && cp .claude/STATUS.md "$tmp/other/.claude/" && cd "$tmp/other"
GIT_WORK_TREE="$tmp/other" "$script" >/dev/null 2>&1
check 'cmp -s "$tmp/other/.claude/STATUS.md" "$tmp/original.md"' "environment redirected it to another folder"

[ "$failures" -eq 0 ] && echo "archive-status: all cases pass" || exit 1

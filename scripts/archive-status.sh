#!/usr/bin/env bash
# Keeps .claude/STATUS.md small enough to read every session: when it is over the limit,
# moves all but the newest Completed items to .claude/archive/STATUS-archive.md (ADR-009).
# Takes no arguments: it only ever touches the .claude/ folder of the repo it lives in.
# Optional settings (validated): STATUS_MAX_BYTES (default 20480), STATUS_KEEP (default 5).
set -euo pipefail

die() { echo "archive-status: $*" >&2; exit 1; }

[ "$#" -eq 0 ] || die "takes no arguments"
max="${STATUS_MAX_BYTES:-20480}"
keep="${STATUS_KEEP:-5}"
[[ "$max" =~ ^[0-9]+$ ]] || die "STATUS_MAX_BYTES must be a whole number"
[[ "$keep" =~ ^[1-9][0-9]*$ ]] || die "STATUS_KEEP must be 1 or more"

# The repo is the one this script lives in, so nothing in the environment can redirect it.
root=$(cd "$(dirname "$0")/.." && pwd -P)
dir="$root/.claude"
file="$dir/STATUS.md"
archive_dir="$dir/archive"
archive="$archive_dir/STATUS-archive.md"

# Never follow symlinks: every path must be a real file or folder inside this repo.
{ [ -d "$dir" ] && [ ! -L "$dir" ]; } || die "$dir must be a real folder"
{ [ -f "$file" ] && [ ! -L "$file" ]; } || die "$file must be a real file"
[ "$(cd "$dir" && pwd -P)" = "$(cd "$root" && pwd -P)/.claude" ] || die "$dir resolves outside the repo"
if [ -e "$archive_dir" ] || [ -L "$archive_dir" ]; then
  { [ -d "$archive_dir" ] && [ ! -L "$archive_dir" ]; } || die "$archive_dir must be a real folder"
fi
if [ -e "$archive" ] || [ -L "$archive" ]; then
  { [ -f "$archive" ] && [ ! -L "$archive" ]; } || die "$archive must be a real file"
fi

size=$(wc -c < "$file" | tr -d ' ')
if [ "$size" -le "$max" ]; then
  echo "archive-status: STATUS.md is $size bytes (limit $max); nothing to archive"
  exit 0
fi

new_status="" moved="" new_archive=""
trap 'rm -f -- ${new_status:+"$new_status"} ${moved:+"$moved"} ${new_archive:+"$new_archive"}' EXIT
mkdir -p "$archive_dir"
new_status=$(mktemp "$dir/.STATUS.XXXXXX")
moved=$(mktemp "$dir/.moved.XXXXXX")
new_archive=$(mktemp "$archive_dir/.archive.XXXXXX")

# Completed items are newest first. Keep the first $keep; move the rest,
# with any indented continuation lines that belong to them.
awk -v keep="$keep" -v moved="$moved" '
  /^## /         { in_completed = ($0 == "## Completed"); moving = 0 }
  in_completed && /^- / { n++; moving = (n > keep) }
  in_completed && moving && (/^- / || /^[[:space:]]+[^[:space:]]/) { print > moved; next }
  { print }
' "$file" > "$new_status"

moved_lines=$(wc -l < "$moved" | tr -d ' ')
[ "$moved_lines" -gt 0 ] || die "STATUS.md is over $max bytes but has no Completed items to archive; shorten it with the user"

# Build the new archive in full and check both files before replacing anything.
if [ -f "$archive" ]; then
  cat "$archive" > "$new_archive"
  base_lines=$(wc -l < "$archive" | tr -d ' ')
else
  printf '# STATUS archive\n\nCompleted items moved out of STATUS.md.\n' > "$new_archive"
  base_lines=3
fi
{ printf '\n## Archived %s\n\n' "$(date +%d/%m/%Y)"; cat "$moved"; } >> "$new_archive"
[ "$(wc -l < "$new_archive" | tr -d ' ')" -eq $((base_lines + 3 + moved_lines)) ] \
  || die "archive check failed; nothing changed"
[ $(( $(wc -l < "$new_status") + moved_lines )) -eq "$(wc -l < "$file")" ] \
  || die "line count check failed; nothing changed"

chmod 644 "$new_archive" "$new_status" # mktemp creates 0600 files
mv "$new_archive" "$archive"
mv "$new_status" "$file"

size=$(wc -c < "$file" | tr -d ' ')
echo "archive-status: $moved_lines line(s) archived to .claude/archive/STATUS-archive.md; STATUS.md is now $size bytes"
[ "$size" -le "$max" ] || die "still over $max bytes; stop and ask the user (never drop unfinished Next up items)"

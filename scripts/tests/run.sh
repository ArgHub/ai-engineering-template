#!/usr/bin/env bash
# Runs every test-*.sh in this folder. The hook and scripts are code, so they have tests too.
set -uo pipefail
dir=$(cd "$(dirname "$0")" && pwd)
failed=0
for t in "$dir"/test-*.sh; do
  echo "== $(basename "$t")"
  bash "$t" || failed=1
done
[ "$failed" -eq 0 ] && echo "All script tests passed." || { echo "Script tests FAILED."; exit 1; }

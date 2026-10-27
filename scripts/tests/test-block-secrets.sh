#!/usr/bin/env bash
# Proves the PreToolUse hook blocks secret files and allows normal work.
set -uo pipefail
hook="$(cd "$(dirname "$0")/../.." && pwd)/.claude/hooks/block-secrets.sh"
failures=0

expect() { # expect <block|allow> <tool-call JSON>
  if printf '%s' "$2" | "$hook" >/dev/null 2>&1; then got=allow; else got=block; fi
  if [ "$got" != "$1" ]; then echo "FAIL: expected $1, got $got: $2"; failures=$((failures + 1)); fi
}

expect block '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env"}}'
expect block '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.local"}}'
expect block '{"tool_name":"Read","tool_input":{"file_path":"/repo/config/auth.env"}}'
expect block '{"tool_name":"Read","tool_input":{"file_path":"/repo/certs/server.pem"}}'
expect block '{"tool_name":"Grep","tool_input":{"pattern":"key","path":"/repo/secrets/"}}'
expect block '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}'
expect block '{"tool_name":"Bash","tool_input":{"command":"source ./auth.env && dotnet run"}}'
expect block '{"tool_name":"Bash","tool_input":{"command":"cp .env.example .env"}}'

expect allow '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.example"}}'
expect allow '{"tool_name":"Bash","tool_input":{"command":"cat .env.example"}}'
expect allow '{"tool_name":"Bash","tool_input":{"command":"dotnet test"}}'
expect allow '{"tool_name":"Read","tool_input":{"file_path":"/repo/src/Environment.cs"}}'
expect allow '{"tool_name":"Write","tool_input":{"file_path":"/repo/CLAUDE.md","content":"Never read .env"}}'

[ "$failures" -eq 0 ] && echo "block-secrets: all cases pass" || exit 1

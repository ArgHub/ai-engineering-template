#!/usr/bin/env bash
# PreToolUse hook: blocks any tool call that touches a secret file.
# Exit code 2 tells Claude Code to block the call and show the message to the agent.
# The deny list in settings.json covers direct reads; this also covers Bash commands
# such as `cat .env` or `source auth.env`.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "block-secrets: jq is required. Blocking until it is installed." >&2
  exit 2
fi

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")

if [[ "$tool" == "Bash" ]]; then
  target=$(jq -r '.tool_input.command // ""' <<<"$input")
else
  target=$(jq -r '[.tool_input.file_path, .tool_input.path, .tool_input.notebook_path]
                  | map(select(. != null)) | join(" ")' <<<"$input")
fi

# Example and sample files are allowed, so remove them before matching.
cleaned=$(sed -E 's/\.env\.(example|sample)//g' <<<"$target")

secret='(^|[^[:alnum:]_])\.env([^[:alnum:]_]|$)|\.env\.[[:alnum:]]+|auth\.env|\.(pem|key|p12|pfx)([^[:alnum:]_]|$)|id_rsa|id_ed25519|(^|[/[:space:]])secrets/'

if grep -Eq "$secret" <<<"$cleaned"; then
  echo "Blocked by .claude/hooks/block-secrets.sh: this $tool call touches a secret file. Use the *.example file, or ask the user to provide the value transiently." >&2
  exit 2
fi

exit 0

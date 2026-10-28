#!/bin/bash
set -euo pipefail
# PreToolUse hook — blocks npm/npx in projects that use pnpm.
# Adapt for any "use X not Y" convention (e.g., yarn vs npm, uv vs pip).
CMD=$(jq -r '.tool_input.command // empty')
[[ -z "$CMD" ]] && exit 0

# Only enforce if this project uses pnpm
[[ ! -f "${CLAUDE_PROJECT_DIR:-$PWD}/pnpm-lock.yaml" ]] && exit 0

# npm/npx as any command in the line: at the start or after ; & | ( or a newline
nl=$'\n'
npm_cmd="(^|[;&|(${nl}])[[:space:]]*(npm|npx)([[:space:]]|\$)"
if [[ "$CMD" =~ $npm_cmd ]]; then
  echo "BLOCKED: This project uses pnpm, not npm. Use pnpm (or pnpm dlx) instead." >&2
  exit 2
fi
exit 0

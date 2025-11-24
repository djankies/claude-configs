#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "plugin-template" "PreToolUse"

INPUT=$(read_hook_input)
FILE_PATH=$(get_input_field "tool_input.file_path")
CONTENT=$(get_input_field "tool_input.content")

if [[ -z "$FILE_PATH" || -z "$CONTENT" ]]; then
  pretooluse_respond "allow"
  finish_hook 0
fi

FILE_EXT="${FILE_PATH##*.}"

if [[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" && "$FILE_EXT" != "js" && "$FILE_EXT" != "jsx" ]]; then
  pretooluse_respond "allow"
  finish_hook 0
fi

if echo "$CONTENT" | grep -q "DEPRECATED_PATTERN"; then
  log_error "Deprecated pattern found in $FILE_PATH"
  pretooluse_respond "block" "❌ DEPRECATED: Found deprecated pattern in $FILE_PATH

The pattern 'DEPRECATED_PATTERN' is deprecated.
Please use 'NEW_PATTERN' instead.

See: your-plugin/skills/migrating-async-request-apis"
  finish_hook 0
fi

if echo "$CONTENT" | grep -q "UNSAFE_PATTERN"; then
  log_warn "Unsafe pattern detected in $FILE_PATH"
  pretooluse_respond "allow" "⚠️  WARNING: Potentially unsafe pattern detected in $FILE_PATH

Consider using a safer alternative.

See: your-plugin/skills/securing-server-actions"
  finish_hook 0
fi

pretooluse_respond "allow"
finish_hook 0

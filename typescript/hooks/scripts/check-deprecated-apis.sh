#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "typescript" "PreToolUse"

read_hook_input > /dev/null
FILE_PATH=$(get_input_field "tool_input.file_path")
NEW_STRING=$(get_input_field "tool_input.new_string")

if [[ -z "$NEW_STRING" ]]; then
  NEW_STRING=$(get_input_field "tool_input.content")
fi

if [[ -z "$FILE_PATH" || -z "$NEW_STRING" ]]; then
  pretooluse_respond "allow"
  finish_hook 0
fi

FILE_EXT="${FILE_PATH##*.}"
if [[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" && "$FILE_EXT" != "js" && "$FILE_EXT" != "jsx" ]]; then
  pretooluse_respond "allow"
  finish_hook 0
fi

ISSUES=()

if echo "$NEW_STRING" | grep -q '\.substr('; then
  ISSUES+=("⚠️  Deprecated API: .substr() is deprecated - use .slice() instead")
fi

if echo "$NEW_STRING" | grep -q '\bescape('; then
  ISSUES+=("⚠️  Deprecated API: escape() is deprecated - use encodeURIComponent() instead")
fi

if echo "$NEW_STRING" | grep -q '\bunescape('; then
  ISSUES+=("⚠️  Deprecated API: unescape() is deprecated - use decodeURIComponent() instead")
fi

if [[ ${#ISSUES[@]} -gt 0 ]]; then
  WARNINGS=$(printf '%s\n' "${ISSUES[@]}")
  log_warn "Deprecated APIs detected in $FILE_PATH"
  pretooluse_respond "allow" "$WARNINGS"
  finish_hook 0
fi

pretooluse_respond "allow"
finish_hook 0

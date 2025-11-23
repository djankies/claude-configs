#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "typescript" "PreToolUse"

read_hook_input > /dev/null
TOOL_NAME=$(get_input_field "tool_name")
FILE_PATH=$(get_input_field "tool_input.file_path")

if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  pretooluse_respond "allow"
  finish_hook 0
fi

FILE_EXT="${FILE_PATH##*.}"
if [[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" && "$FILE_EXT" != "js" && "$FILE_EXT" != "jsx" ]]; then
  pretooluse_respond "allow"
  finish_hook 0
fi

SYNTAX_CHECKER="${SCRIPT_DIR}/../../scripts/check-syntax.js"

SYNTAX_CHECK=$(echo "$HOOK_INPUT" | node "$SYNTAX_CHECKER" 2>&1 || true)

if echo "$SYNTAX_CHECK" | grep -q '"hasSyntaxError":true'; then
  ERROR_MESSAGE=$(echo "$SYNTAX_CHECK" | jq -r '.errorMessage // "Syntax error detected"')
  LINE=$(echo "$SYNTAX_CHECK" | jq -r '.line // "unknown"')

  log_error "Syntax error in $FILE_PATH at line $LINE"
  pretooluse_respond "block" "🚨 SYNTAX ERROR: Cannot write file with syntax errors

$ERROR_MESSAGE

Line: $LINE

Please fix the syntax error before writing the file."
  finish_hook 0
fi

pretooluse_respond "allow"
finish_hook 0

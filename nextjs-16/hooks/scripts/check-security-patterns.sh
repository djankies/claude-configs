#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "nextjs-16" "PostToolUse"

INPUT=$(read_hook_input)
FILE_PATH=$(get_input_field "tool_input.file_path")

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

if grep -q "'use server'" "$FILE_PATH" 2>/dev/null || grep -q '"use server"' "$FILE_PATH" 2>/dev/null; then
  if ! grep -q "verifySession" "$FILE_PATH" 2>/dev/null; then
    log_warn "Server action without verifySession detected in $FILE_PATH"
    inject_context "⚠️  WARNING: $FILE_PATH contains 'use server' without verifySession() call

Server actions should verify authentication before accessing data.
See SECURITY-data-access-layer skill for proper patterns."
  fi
fi

exit 0

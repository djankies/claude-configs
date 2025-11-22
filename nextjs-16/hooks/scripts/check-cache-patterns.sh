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

WARNINGS=()

if grep -q "unstable_cache" "$FILE_PATH" 2>/dev/null; then
  log_warn "unstable_cache usage detected in $FILE_PATH"
  WARNINGS+=("⚠️  WARNING: $FILE_PATH uses unstable_cache - consider using cacheLife or cacheTag instead in Next.js 16")
fi

if grep -q "export const revalidate" "$FILE_PATH" 2>/dev/null; then
  log_warn "export const revalidate usage detected in $FILE_PATH"
  WARNINGS+=("⚠️  WARNING: $FILE_PATH uses 'export const revalidate' - consider using new caching APIs in Next.js 16")
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  CONTEXT=$(printf "%s\n" "${WARNINGS[@]}")
  inject_context "$CONTEXT

See CACHING-* skills for migration guidance."
fi

exit 0

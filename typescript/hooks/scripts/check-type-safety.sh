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
if [[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" ]]; then
  pretooluse_respond "allow"
  finish_hook 0
fi

ISSUES=()

if echo "$NEW_STRING" | grep -q ': any\|<any>\|= any\| any\[\]'; then
  ISSUES+=("⚠️  Type Safety: Code contains 'any' type - consider using 'unknown' with type guards instead")
  ISSUES+=("   See: @typescript/TYPES-any-vs-unknown skill")
fi

if echo "$NEW_STRING" | grep -q ' as [A-Z]'; then
  if ! echo "$NEW_STRING" | grep -q 'as const'; then
    ISSUES+=("⚠️  Type Safety: Type assertion detected - ensure data is validated before assertion")
    ISSUES+=("   See: @typescript/VALIDATION-type-assertions skill")
  fi
fi

if echo "$NEW_STRING" | grep -Eq '<T\s*>|<T\s*=\s*any>'; then
  ISSUES+=("⚠️  Type Safety: Generic type without constraints - consider adding 'extends' constraint")
  ISSUES+=("   See: @typescript/TYPES-generics skill")
fi

if echo "$NEW_STRING" | grep -iq 'password.*=.*Buffer.*toString.*base64'; then
  log_error "CRITICAL: Base64 encoding on password field"
  pretooluse_respond "block" "🚨 CRITICAL SECURITY VIOLATION: Base64 encoding detected on password field

Base64 is NOT encryption. Use bcrypt or argon2 for password hashing.

See: @typescript/SECURITY-credentials skill"
  finish_hook 0
fi

if echo "$NEW_STRING" | grep -iq 'paypalPassword\|googlePassword\|facebookPassword'; then
  log_error "CRITICAL: Accepting third-party credentials"
  pretooluse_respond "block" "🚨 CRITICAL SECURITY VIOLATION: Accepting third-party credentials

NEVER ask for passwords to other services. Use OAuth instead.

See: @typescript/SECURITY-credentials skill"
  finish_hook 0
fi

if [[ ${#ISSUES[@]} -gt 0 ]]; then
  WARNINGS=$(printf '%s\n' "${ISSUES[@]}")
  log_warn "Type safety issues detected in $FILE_PATH"
  pretooluse_respond "allow" "$WARNINGS"
  finish_hook 0
fi

pretooluse_respond "allow"
finish_hook 0

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

if echo "$NEW_STRING" | grep -iqE 'password.*=.*(Buffer.*toString|btoa|atob)'; then
  log_error "CRITICAL: Base64 encoding on password field"
  pretooluse_respond "block" "🚨 CRITICAL SECURITY VIOLATION: Base64 encoding detected on password field

Base64 is NOT encryption. Use bcrypt, argon2, or scrypt for password hashing.

See: @typescript/hashing-passwords skill"
  finish_hook 0
fi

if echo "$NEW_STRING" | grep -iqE '(paypal|google|facebook|twitter|github|microsoft|amazon)Password\s*[:\?]'; then
  log_error "CRITICAL: Accepting third-party credentials"
  pretooluse_respond "block" "🚨 CRITICAL SECURITY VIOLATION: Accepting third-party credentials

NEVER ask for passwords to other services. Use OAuth instead.

See: @typescript/hashing-passwords skill"
  finish_hook 0
fi

if echo "$NEW_STRING" | grep -qE '\beval\s*\('; then
  log_error "CRITICAL: eval() usage"
  pretooluse_respond "block" "🚨 CRITICAL SECURITY VIOLATION: eval() usage detected

eval() enables arbitrary code execution and is a major security risk.
Use safer alternatives:
- JSON.parse() for JSON data
- Function constructors with known, validated code
- Template engines for dynamic content

See: @typescript/avoiding-eval skill"
  finish_hook 0
fi

if echo "$NEW_STRING" | grep -qE 'new Function\s*\([^)]*\$\{|\`.*\$\{.*\}.*\`.*new Function'; then
  log_error "CRITICAL: Function constructor with template literals"
  pretooluse_respond "block" "🚨 CRITICAL SECURITY VIOLATION: Function constructor with dynamic code

Creating functions from template literals enables code injection.

See: @typescript/avoiding-eval skill"
  finish_hook 0
fi

if echo "$NEW_STRING" | grep -qE 'exec\s*\([^)]*\$\{|spawn\s*\([^)]*\$\{'; then
  log_error "CRITICAL: Command injection vulnerability"
  pretooluse_respond "block" "🚨 CRITICAL SECURITY VIOLATION: Potential command injection

Concatenating user input into shell commands enables command injection.
Use parameterized execution:
- execFile() with argument array
- spawn() with separate arguments
- Validate/sanitize all inputs

See: @typescript/preventing-command-injection skill"
  finish_hook 0
fi

pretooluse_respond "allow"
finish_hook 0

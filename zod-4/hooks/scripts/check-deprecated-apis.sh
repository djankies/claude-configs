#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_UTILS="$(cd "${SCRIPT_DIR}/../../../marketplace-utils" && pwd)"

source "${MARKETPLACE_UTILS}/hook-lifecycle.sh"

init_hook "zod-4" "check-deprecated-apis"

input=$(read_hook_input)

file_path=$(get_input_field "parameters.file_path")

[[ -z "$file_path" || ! -f "$file_path" ]] && echo "{}" && finish_hook 0

file_ext="${file_path##*.}"

[[ "$file_ext" != "ts" && "$file_ext" != "tsx" && "$file_ext" != "js" && "$file_ext" != "jsx" ]] && echo "{}" && finish_hook 0

violations=""

if grep -q "z\.string()\.email(" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: z.string().email() → Use z.email()\n"
fi

if grep -q "z\.string()\.uuid(" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: z.string().uuid() → Use z.uuid()\n"
fi

if grep -q "z\.string()\.datetime(" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: z.string().datetime() → Use z.iso.datetime()\n"
fi

if grep -q "z\.string()\.url(" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: z.string().url() → Use z.url()\n"
fi

if grep -q "z\.string()\.ipv4(" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: z.string().ipv4() → Use z.ipv4()\n"
fi

if grep -q "z\.string()\.ipv6(" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: z.string().ipv6() → Use z.ipv6()\n"
fi

if grep -q "z\.string()\.base64(" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: z.string().base64() → Use z.base64()\n"
fi

if grep -q "z\.string()\.jwt(" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: z.string().jwt() → Use z.jwt()\n"
fi

if grep -Eq "message:\s*['\"]" "$file_path" 2>/dev/null && grep -q "z\." "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: { message: '...' } → Use { error: '...' }\n"
fi

if grep -q "errorMap:" "$file_path" 2>/dev/null && grep -q "z\." "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: { errorMap: ... } → Use { error: ... }\n"
fi

if grep -q "invalid_type_error:" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: { invalid_type_error: '...' } → Use { error: '...' }\n"
fi

if grep -q "required_error:" "$file_path" 2>/dev/null; then
  violations="${violations}Deprecated: { required_error: '...' } → Use { error: '...' }\n"
fi

if [[ -n "$violations" ]]; then
  context="⚠️  Zod v4 Deprecated API Usage Detected:
${violations}"

  log_warn "Deprecated Zod API usage detected in $file_path"
  posttooluse_respond "" "" "$context"
  finish_hook 0
fi

echo "{}"
finish_hook 0

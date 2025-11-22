#!/bin/bash

FILE_PATH="$1"
[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

FILE_EXT="${FILE_PATH##*.}"

[[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" && "$FILE_EXT" != "js" && "$FILE_EXT" != "jsx" ]] && exit 0

VIOLATIONS=""

if grep -q "z\.string()\.email(" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: z.string().email() → Use z.email()\n"
fi

if grep -q "z\.string()\.uuid(" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: z.string().uuid() → Use z.uuid()\n"
fi

if grep -q "z\.string()\.datetime(" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: z.string().datetime() → Use z.iso.datetime()\n"
fi

if grep -q "z\.string()\.url(" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: z.string().url() → Use z.url()\n"
fi

if grep -q "z\.string()\.ipv4(" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: z.string().ipv4() → Use z.ipv4()\n"
fi

if grep -q "z\.string()\.ipv6(" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: z.string().ipv6() → Use z.ipv6()\n"
fi

if grep -q "z\.string()\.base64(" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: z.string().base64() → Use z.base64()\n"
fi

if grep -q "z\.string()\.jwt(" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: z.string().jwt() → Use z.jwt()\n"
fi

if grep -Eq "message:\s*['\"]" "$FILE_PATH" 2>/dev/null && grep -q "z\." "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: { message: '...' } → Use { error: '...' }\n"
fi

if grep -q "errorMap:" "$FILE_PATH" 2>/dev/null && grep -q "z\." "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: { errorMap: ... } → Use { error: ... }\n"
fi

if grep -q "invalid_type_error:" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: { invalid_type_error: '...' } → Use { error: '...' }\n"
fi

if grep -q "required_error:" "$FILE_PATH" 2>/dev/null; then
  VIOLATIONS="${VIOLATIONS}Deprecated: { required_error: '...' } → Use { error: '...' }\n"
fi

if [[ -n "$VIOLATIONS" ]]; then
  echo "⚠️  Zod v4 Deprecated API Usage Detected:"
  echo -e "$VIOLATIONS"
  exit 2
fi

exit 0

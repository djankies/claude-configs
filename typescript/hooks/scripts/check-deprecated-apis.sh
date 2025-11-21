#!/bin/bash

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

if [[ -z "$FILE_PATH" || -z "$NEW_STRING" ]]; then
  exit 0
fi

FILE_EXT="${FILE_PATH##*.}"
if [[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" && "$FILE_EXT" != "js" && "$FILE_EXT" != "jsx" ]]; then
  exit 0
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
  printf '%s\n' "${ISSUES[@]}"
fi

exit 0

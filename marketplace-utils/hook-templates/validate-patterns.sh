#!/usr/bin/env bash

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

if [[ -z "$FILE_PATH" || -z "$CONTENT" ]]; then
  exit 0
fi

FILE_EXT="${FILE_PATH##*.}"

if [[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" && "$FILE_EXT" != "js" && "$FILE_EXT" != "jsx" ]]; then
  exit 0
fi

if echo "$CONTENT" | grep -q "DEPRECATED_PATTERN"; then
  echo "❌ DEPRECATED: Found deprecated pattern in $FILE_PATH"
  echo ""
  echo "The pattern 'DEPRECATED_PATTERN' is deprecated."
  echo "Please use 'NEW_PATTERN' instead."
  echo ""
  echo "See: your-plugin/skills/migrating-async-request-apis"
  exit 2
fi

if echo "$CONTENT" | grep -q "UNSAFE_PATTERN"; then
  echo "⚠️  WARNING: Potentially unsafe pattern detected in $FILE_PATH"
  echo ""
  echo "Consider using a safer alternative."
  echo ""
  echo "See: your-plugin/skills/securing-server-actions"
  exit 0
fi

exit 0

#!/bin/bash

STATE_FILE="/tmp/claude-zod-4-session.json"

[[ ! -f "$STATE_FILE" ]] && exit 0

FILE_PATH="$1"
[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

FILE_EXT="${FILE_PATH##*.}"

case "$FILE_EXT" in
  ts|tsx|js|jsx)
    ;;
  *)
    exit 0
    ;;
esac

if grep -q "from ['\"]zod['\"]" "$FILE_PATH" 2>/dev/null || \
   grep -q "import zod" "$FILE_PATH" 2>/dev/null; then

  SHOWN=$(grep -o '"zod_skills": true' "$STATE_FILE" 2>/dev/null)

  if [[ -z "$SHOWN" ]]; then
    echo "📚 Zod 4 Skills Available:"
    echo "  VALIDATION-*: Schema basics, string formats (z.email, z.uuid)"
    echo "  TRANSFORMATION-*: String methods (.trim, .toLowerCase), codecs"
    echo "  ERRORS-*: Unified error customization API"
    echo "  MIGRATION-*: v3 to v4 breaking changes"
    echo ""
    echo "Use Skill tool to activate when needed."

    jq '.recommendations_shown.zod_skills = true' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  fi
fi

exit 0

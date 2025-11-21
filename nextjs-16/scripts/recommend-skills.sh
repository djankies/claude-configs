#!/bin/bash

STATE_FILE="/tmp/claude-nextjs-16-session.json"

[[ ! -f "$STATE_FILE" ]] && exit 0

FILE_PATH="${CLAUDE_FILE_PATH:-$1}"

[[ -z "$FILE_PATH" ]] && exit 0

FILE_NAME=$(basename "$FILE_PATH")
FILE_EXT="${FILE_PATH##*.}"
DIR_PATH=$(dirname "$FILE_PATH")

if [[ "$FILE_NAME" == "middleware.ts" || "$FILE_NAME" == "middleware.js" ]]; then
  SHOWN=$(grep -o '"middleware_warning": true' "$STATE_FILE" 2>/dev/null)

  if [[ -z "$SHOWN" ]]; then
    echo "⚠️  CRITICAL: middleware.ts is deprecated in Next.js 16"
    echo "Use MIGRATION-middleware-to-proxy skill"
    echo "Security: CVE-2025-29927 - middleware no longer safe for auth"

    sed -i.bak 's/"middleware_warning": false/"middleware_warning": true/' "$STATE_FILE" 2>/dev/null || \
      sed -i '' 's/"middleware_warning": false/"middleware_warning": true/' "$STATE_FILE"
  fi
  exit 0
fi

RECOMMENDATION_TYPE=""
MESSAGE=""

if [[ "$FILE_EXT" == "tsx" || "$FILE_EXT" == "jsx" || "$FILE_EXT" == "ts" || "$FILE_EXT" == "js" ]]; then
  if [[ "$DIR_PATH" == *"/app/"* ]]; then
    RECOMMENDATION_TYPE="nextjs_skills"
    MESSAGE="📚 Next.js 16 App Router detected. Skills: SECURITY-*, CACHING-*, MIGRATION-*, ROUTING-*, FORMS-*"
  fi
fi

if [[ "$FILE_NAME" == *"action"* || "$FILE_NAME" == *"server"* ]] && [[ "$FILE_EXT" == "ts" || "$FILE_EXT" == "tsx" ]]; then
  RECOMMENDATION_TYPE="security_skills"
  MESSAGE="🔒 Server action detected. Critical: Use SECURITY-data-access-layer for authentication"
fi

[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  echo "Use Skill tool to activate when needed."

  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE" 2>/dev/null || \
    sed -i '' "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

exit 0

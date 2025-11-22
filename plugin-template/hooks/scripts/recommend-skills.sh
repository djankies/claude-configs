#!/usr/bin/env bash

set -euo pipefail

PLUGIN_NAME="YOUR_PLUGIN_NAME"
STATE_FILE="/tmp/claude-${PLUGIN_NAME}-session-$$.json"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

FILE_EXT="${FILE_PATH##*.}"
FILE_NAME="${FILE_PATH##*/}"

RECOMMENDATION_TYPE=""
SKILLS=""
MESSAGE=""

case "$FILE_EXT" in
  ts|tsx)
    if [[ "$FILE_PATH" == *"test"* || "$FILE_PATH" == *"spec"* ]]; then
      RECOMMENDATION_TYPE="test_files"
      SKILLS="your-testing-skill"
      MESSAGE="📚 Test File Detected: $SKILLS skills available"
    else
      RECOMMENDATION_TYPE="typescript_files"
      SKILLS="your-main-skill, your-secondary-skill"
      MESSAGE="📚 TypeScript File: $SKILLS skills available"
    fi
    ;;
  jsx|js)
    RECOMMENDATION_TYPE="javascript_files"
    SKILLS="your-js-skill"
    MESSAGE="📚 JavaScript File: $SKILLS skills available"
    ;;
esac

if [[ -z "$RECOMMENDATION_TYPE" ]]; then
  exit 0
fi

SHOWN=$(jq -r ".recommendations_shown.${RECOMMENDATION_TYPE}" "$STATE_FILE" 2>/dev/null)

if [[ "$SHOWN" != "true" ]]; then
  echo "$MESSAGE"
  echo "Use Skill tool to activate specific skills when needed."

  jq ".recommendations_shown.${RECOMMENDATION_TYPE} = true" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
fi

exit 0

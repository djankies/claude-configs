#!/bin/bash

STATE_FILE="/tmp/claude-typescript-session-$$.json"

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
    if [[ "$FILE_NAME" == "tsconfig.json" ]]; then
      RECOMMENDATION_TYPE="config_files"
      SKILLS="CONFIG-compiler-options, CONFIG-module-resolution, CONFIG-performance"
      MESSAGE="📚 TypeScript Config Detected: $SKILLS skills available"
    elif [[ "$FILE_PATH" == *"test"* || "$FILE_PATH" == *"spec"* || "$FILE_PATH" == *".test."* || "$FILE_PATH" == *".spec."* ]]; then
      RECOMMENDATION_TYPE="test_files"
      SKILLS="TYPES-type-guards, VALIDATION-runtime-checks, ERROR-HANDLING-type-guards"
      MESSAGE="📚 TypeScript Test File: $SKILLS skills available"
    else
      RECOMMENDATION_TYPE="typescript_files"
      SKILLS="TYPES-any-vs-unknown, TYPES-type-guards, VALIDATION-runtime-checks, SECURITY-credentials, ERROR-HANDLING-custom-errors"
      MESSAGE="📚 TypeScript Skills Available: $SKILLS"
    fi
    ;;
  js|jsx)
    RECOMMENDATION_TYPE="migration_context"
    SKILLS="MIGRATION-js-to-ts, MIGRATION-strict-mode"
    MESSAGE="📚 JavaScript File - Migration Skills: $SKILLS"
    ;;
esac

if [[ -z "$RECOMMENDATION_TYPE" ]]; then
  exit 0
fi

SHOWN=$(jq -r ".recommendations_shown.${RECOMMENDATION_TYPE}" "$STATE_FILE" 2>/dev/null)

if [[ "$SHOWN" == "false" ]]; then
  echo "$MESSAGE"
  echo "Use Skill tool to activate specific skills when needed."

  jq ".recommendations_shown.${RECOMMENDATION_TYPE} = true" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
fi

exit 0

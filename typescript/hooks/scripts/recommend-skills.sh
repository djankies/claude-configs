#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "typescript" "PreToolUse"

read_hook_input > /dev/null
FILE_PATH=$(get_input_field "tool_input.file_path")

if [[ -z "$FILE_PATH" ]]; then
  finish_hook 0
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
  finish_hook 0
fi

if ! has_shown_recommendation "typescript" "$RECOMMENDATION_TYPE"; then
  log_info "Showing recommendation: $RECOMMENDATION_TYPE"
  mark_recommendation_shown "typescript" "$RECOMMENDATION_TYPE"
  inject_context "$MESSAGE
Use Skill tool to activate specific skills when needed."
fi

finish_hook 0

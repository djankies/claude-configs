#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "plugin-template" "PostToolUse"

INPUT=$(read_hook_input)
FILE_PATH=$(get_input_field "tool_input.file_path")

if [[ -z "$FILE_PATH" ]]; then
  finish_hook 0
fi

FILE_EXT="${FILE_PATH##*.}"

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
  finish_hook 0
fi

if ! has_shown_recommendation "plugin-template" "$RECOMMENDATION_TYPE"; then
  log_info "Recommending skills: $SKILLS for $FILE_PATH"
  mark_recommendation_shown "plugin-template" "$RECOMMENDATION_TYPE"
  inject_context "$MESSAGE
Use Skill tool to activate specific skills when needed."
fi

finish_hook 0

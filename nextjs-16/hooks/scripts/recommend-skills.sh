#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "nextjs-16" "PostToolUse"

INPUT=$(read_hook_input)
FILE_PATH=$(get_input_field "tool_input.file_path")

if [[ -z "$FILE_PATH" ]]; then
  finish_hook 0
fi

FILE_NAME=$(basename "$FILE_PATH")
FILE_EXT="${FILE_PATH##*.}"
DIR_PATH=$(dirname "$FILE_PATH")

if [[ "$FILE_NAME" == "middleware.ts" || "$FILE_NAME" == "middleware.js" ]]; then
  if ! has_shown_recommendation "nextjs-16" "middleware_warning"; then
    log_warn "Recommending skill: MIGRATION-middleware-to-proxy (CRITICAL) for $FILE_PATH"
    mark_recommendation_shown "nextjs-16" "middleware_warning"
    inject_context "⚠️  CRITICAL: middleware.ts is deprecated in Next.js 16
Use MIGRATION-middleware-to-proxy skill
Security: CVE-2025-29927 - middleware no longer safe for auth"
  fi
  finish_hook 0
fi

RECOMMENDATION_TYPE=""
SKILLS=""
MESSAGE=""

if [[ "$FILE_EXT" == "tsx" || "$FILE_EXT" == "jsx" || "$FILE_EXT" == "ts" || "$FILE_EXT" == "js" ]]; then
  if [[ "$DIR_PATH" == *"/app/"* ]]; then
    RECOMMENDATION_TYPE="nextjs_skills"
    SKILLS="SECURITY-*, CACHING-*, MIGRATION-*, ROUTING-*, FORMS-*"
    MESSAGE="📚 Next.js 16 App Router detected: $SKILLS skills available"
  fi
fi

if [[ "$FILE_NAME" == *"action"* || "$FILE_NAME" == *"server"* ]] && [[ "$FILE_EXT" == "ts" || "$FILE_EXT" == "tsx" ]]; then
  RECOMMENDATION_TYPE="security_skills"
  SKILLS="SECURITY-data-access-layer"
  MESSAGE="🔒 Server action detected. Critical: Use $SKILLS for authentication"
fi

if [[ -z "$RECOMMENDATION_TYPE" ]]; then
  finish_hook 0
fi

if ! has_shown_recommendation "nextjs-16" "$RECOMMENDATION_TYPE"; then
  log_info "Recommending skills: $SKILLS for $FILE_PATH"
  mark_recommendation_shown "nextjs-16" "$RECOMMENDATION_TYPE"
  inject_context "$MESSAGE
Use Skill tool to activate specific skills when needed."
fi

finish_hook 0

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "prisma-6" "PostToolUse"

INPUT=$(read_hook_input)
FILE_PATH=$(get_input_field "tool_input.file_path")

if [[ -z "$FILE_PATH" ]]; then
  FILE_PATH=$(get_input_field "tool_input.path")
fi

if [[ -z "$FILE_PATH" ]]; then
  finish_hook 0
fi

FILE_NAME="${FILE_PATH##*/}"
FILE_DIR="${FILE_PATH%/*}"

RECOMMENDATION_TYPE=""
SKILLS=""
MESSAGE=""

if [[ "$FILE_NAME" == "schema.prisma" ]]; then
  RECOMMENDATION_TYPE="schema_files"
  SKILLS="MIGRATIONS-*, CLIENT-*, QUERIES-type-safety"
  MESSAGE="Prisma Schema: $SKILLS"
elif [[ "$FILE_DIR" == *"migrations"* ]]; then
  RECOMMENDATION_TYPE="migration_files"
  SKILLS="MIGRATIONS-dev-workflow, MIGRATIONS-production, MIGRATIONS-v6-upgrade"
  MESSAGE="Prisma Migrations: $SKILLS"
elif [[ "$FILE_PATH" =~ \.(ts|js|tsx|jsx)$ ]]; then
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$SCRIPT_DIR")")}"
  IMPORTS=$(bash "$PLUGIN_ROOT/hooks/scripts/analyze-imports.sh" "$FILE_PATH" 2>/dev/null || true)

  if [[ "$IMPORTS" == *"@prisma/client"* ]]; then
    RECOMMENDATION_TYPE="prisma_files"
    SKILLS="CLIENT-*, QUERIES-*, TRANSACTIONS-*, SECURITY-*"
    MESSAGE="Prisma Client Usage: $SKILLS"

    if [[ "$IMPORTS" == *"\$queryRaw"* ]]; then
      RECOMMENDATION_TYPE="raw_sql_context"
      SKILLS="SECURITY-sql-injection (CRITICAL)"
      MESSAGE="Raw SQL Detected: $SKILLS"
    fi
  fi

  if [[ "$FILE_PATH" == *"vercel"* || "$FILE_PATH" == *"lambda"* || "$FILE_PATH" == *"app/"* ]]; then
    if ! has_shown_recommendation "prisma-6" "serverless_context"; then
      log_info "Recommending skills: CLIENT-serverless-config, PERFORMANCE-connection-pooling for serverless context in $FILE_PATH"
      mark_recommendation_shown "prisma-6" "serverless_context"
      inject_context "Serverless Context: CLIENT-serverless-config, PERFORMANCE-connection-pooling"
    fi
  fi
fi

if [[ -z "$RECOMMENDATION_TYPE" ]]; then
  finish_hook 0
fi

if ! has_shown_recommendation "prisma-6" "$RECOMMENDATION_TYPE"; then
  log_info "Recommending skills: $SKILLS for $FILE_PATH"
  mark_recommendation_shown "prisma-6" "$RECOMMENDATION_TYPE"
  inject_context "$MESSAGE
Use Skill tool to activate specific skills when needed."
fi

finish_hook 0

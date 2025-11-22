#!/bin/bash

STATE_FILE="/tmp/claude-prisma-session.json"

[[ ! -f "$STATE_FILE" ]] && exit 0

read -r INPUT
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path": "[^"]*"' | cut -d'"' -f4)

if [[ -z "$FILE_PATH" ]]; then
  FILE_PATH=$(echo "$INPUT" | grep -o '"path": "[^"]*"' | cut -d'"' -f4)
fi

[[ -z "$FILE_PATH" ]] && exit 0

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
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
  IMPORTS=$(bash "$PLUGIN_ROOT/hooks/scripts/analyze-imports.sh" "$FILE_PATH" 2>/dev/null)

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
    SERVERLESS_SHOWN=$(grep -o '"serverless_context": true' "$STATE_FILE" 2>/dev/null)
    if [[ -z "$SERVERLESS_SHOWN" ]]; then
      echo "Serverless Context: CLIENT-serverless-config, PERFORMANCE-connection-pooling"
      sed -i.bak 's/"serverless_context": false/"serverless_context": true/' "$STATE_FILE"
    fi
  fi
fi

[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  echo "Use Skill tool to activate specific skills when needed."

  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

exit 0

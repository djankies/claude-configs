#!/bin/bash

STATE_FILE="/tmp/claude-prisma-session.json"

if [[ -f "$STATE_FILE" ]]; then
  EXISTING_SESSION=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"session_id": "[^"]*"' | head -1)
  if [[ -n "$EXISTING_SESSION" ]]; then
    exit 0
  fi
fi

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "recommendations_shown": {
    "prisma_files": false,
    "schema_files": false,
    "migration_files": false,
    "raw_sql_context": false,
    "serverless_context": false
  }
}
EOF

echo "Prisma session initialized"

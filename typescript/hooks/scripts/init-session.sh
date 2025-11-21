#!/bin/bash

STATE_FILE="/tmp/claude-typescript-session-$$.json"

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "pid": $$,
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "recommendations_shown": {
    "typescript_files": false,
    "config_files": false,
    "test_files": false,
    "migration_context": false
  }
}
EOF

echo "TypeScript plugin session initialized"
echo "Session state: $STATE_FILE"

exit 0

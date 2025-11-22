#!/usr/bin/env bash

set -euo pipefail

PLUGIN_NAME="YOUR_PLUGIN_NAME"

STATE_FILE="/tmp/claude-${PLUGIN_NAME}-session-$$.json"

cat > "$STATE_FILE" <<EOF
{
  "plugin": "${PLUGIN_NAME}",
  "session_id": "$$-$(date +%s)",
  "pid": $$,
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "recommendations_shown": {},
  "validations_passed": {},
  "custom_data": {}
}
EOF

export CLAUDE_SESSION_FILE="$STATE_FILE"
export CLAUDE_PLUGIN_NAME="$PLUGIN_NAME"

echo "${PLUGIN_NAME} plugin session initialized"

exit 0

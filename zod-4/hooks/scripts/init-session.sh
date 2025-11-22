#!/bin/bash

STATE_FILE="/tmp/claude-zod-4-session.json"

if [[ -f "$STATE_FILE" ]]; then
  rm "$STATE_FILE"
fi

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "plugin": "zod-4",
  "recommendations_shown": {
    "zod_skills": false
  }
}
EOF

exit 0

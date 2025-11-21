#!/bin/bash

STATE_FILE="/tmp/claude-nextjs-16-session.json"

if [[ -f "$STATE_FILE" ]]; then
  rm "$STATE_FILE"
fi

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "plugin": "nextjs-16",
  "recommendations_shown": {
    "nextjs_skills": false,
    "security_skills": false,
    "caching_skills": false,
    "migration_skills": false,
    "middleware_warning": false
  }
}
EOF

echo "NextJS-16 session initialized"

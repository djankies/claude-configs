#!/bin/bash

STATE_FILE="/tmp/claude-tailwind-4-session.json"

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "recommendations_shown": {
    "css_config": false,
    "vite_config": false,
    "postcss_config": false,
    "component_styling": false
  }
}
EOF

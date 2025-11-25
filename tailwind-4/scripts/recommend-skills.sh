#!/bin/bash

STATE_FILE="/tmp/claude-tailwind-4-session.json"
[[ ! -f "$STATE_FILE" ]] && exit 0

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" && "$tool_name" != "Read" ]] && exit 0
[[ -z "$file_path" ]] && exit 0

RECOMMENDATION_TYPE=""
MESSAGE=""

case "$file_path" in
  *.css)
    RECOMMENDATION_TYPE="css_config"
    MESSAGE="📚 Tailwind v4 skills: configuring-tailwind-v4, using-theme-variables"
    ;;
  *vite.config*)
    RECOMMENDATION_TYPE="vite_config"
    MESSAGE="📚 Tailwind v4: Use @tailwindcss/vite plugin. See configuring-tailwind-v4 skill."
    ;;
  *postcss.config*)
    RECOMMENDATION_TYPE="postcss_config"
    MESSAGE="📚 Tailwind v4: Use @tailwindcss/postcss. See configuring-tailwind-v4 skill."
    ;;
  *.tsx|*.jsx)
    RECOMMENDATION_TYPE="component_styling"
    MESSAGE="📚 Tailwind v4 skills: using-container-queries, creating-custom-utilities"
    ;;
  *)
    exit 0
    ;;
esac

[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

exit 0

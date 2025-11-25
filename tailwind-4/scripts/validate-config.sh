#!/bin/bash

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$tool_name" != "Write" ]] && exit 0

if [[ "$file_path" =~ tailwind\.config\.(js|ts|mjs|cjs)$ ]]; then
  echo "❌ DEPRECATED: tailwind.config.js removed in v4" >&2
  echo "Use CSS @theme directive in your main CSS file instead." >&2
  echo "See: configuring-tailwind-v4 skill" >&2
  exit 2
fi

exit 0

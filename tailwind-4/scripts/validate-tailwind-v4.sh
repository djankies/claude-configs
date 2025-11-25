#!/bin/bash

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && exit 0
[[ -z "$file_path" ]] && exit 0
[[ ! -f "$file_path" ]] && exit 0

content=$(cat "$file_path")

if [[ "$file_path" =~ \.css$ ]]; then
  echo "$content" | grep -q "@theme" && echo "$content" | grep -qE "#[0-9a-fA-F]{3,8}" && \
    echo "⚠️ Hex in @theme → use oklch(). See: using-theme-variables" >&2

  echo "$content" | grep -qE "@tailwind\s+(base|components|utilities)" && \
    echo "⚠️ @tailwind deprecated → @import 'tailwindcss'. See: configuring-tailwind-v4" >&2

  echo "$content" | grep -qE "@apply\s+" && \
    echo "⚠️ @apply limited in v4 → use @utility. See: creating-custom-utilities" >&2
fi

if [[ "$file_path" =~ \.(tsx|jsx|html|vue|svelte)$ ]]; then
  echo "$content" | grep -qE "(bg|text|ring|border|divide|placeholder)-opacity-[0-9]+" && \
    echo "⚠️ *-opacity-* removed → use color/50 syntax. See: migrating-from-v3" >&2

  echo "$content" | grep -qE "flex-grow|flex-shrink" && \
    echo "⚠️ flex-grow/shrink → grow/shrink. See: migrating-from-v3" >&2

  echo "$content" | grep -qE "decoration-slice|decoration-clone|overflow-ellipsis" && \
    echo "⚠️ Renamed: decoration-* → box-decoration-*, overflow-ellipsis → text-ellipsis" >&2
fi

if [[ "$file_path" =~ postcss\.config\.(js|mjs|cjs)$ ]]; then
  echo "$content" | grep -qE "plugins.*['\"]tailwindcss['\"]" && ! echo "$content" | grep -q "@tailwindcss/postcss" && \
    echo "⚠️ Use @tailwindcss/postcss instead of tailwindcss. See: configuring-tailwind-v4" >&2

  echo "$content" | grep -qE "autoprefixer|postcss-import" && \
    echo "💡 autoprefixer/postcss-import no longer needed in v4" >&2
fi

exit 0

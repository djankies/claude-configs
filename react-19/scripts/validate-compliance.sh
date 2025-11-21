#!/bin/bash

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

strip_comments() {
  sed 's://.*$::g' "$1" | \
  sed '/\/\*/,/\*\//d' | \
  grep -v '^\s*$'
}

CODE_CONTENT=$(strip_comments "$FILE_PATH")

ERRORS=()
RECOMMENDED_SKILLS=()

if echo "$CODE_CONTENT" | grep -qE '\bforwardRef\s*\('; then
  ERRORS+=("❌ forwardRef is deprecated in React 19. Use ref as a prop instead.")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\.(propTypes|defaultProps)\s*='; then
  ERRORS+=("❌ propTypes and defaultProps are deprecated in React 19.")
  RECOMMENDED_SKILLS+=("review-hook-patterns")
fi

HAS_USE_SERVER=$(grep -qE "^[[:space:]]*['\"]use server['\"]" "$FILE_PATH" && echo "true" || echo "false")

if echo "$CODE_CONTENT" | grep -qE '\bformData\.get\s*\(|\bformData\s*\.'; then
  if echo "$CODE_CONTENT" | grep -qE '(export\s+)?(async\s+)?function\s+\w+.*FormData'; then
    if [ "$HAS_USE_SERVER" = "false" ]; then
      ERRORS+=("⚠️  Function handling FormData should have 'use server' directive.")
      RECOMMENDED_SKILLS+=("server-actions")
    fi
  fi
fi

HAS_USE_CLIENT=$(grep -qE "^[[:space:]]*['\"]use client['\"]" "$FILE_PATH" && echo "true" || echo "false")

if echo "$CODE_CONTENT" | grep -qE '\b(useState|useEffect|useContext|useReducer|useCallback|useMemo|useRef|useLayoutEffect)\s*\('; then
  if [ "$HAS_USE_CLIENT" = "false" ]; then
    if [ -f "package.json" ] && grep -qE '"(next|@next)"\s*:\s*"' "package.json"; then
      if ! echo "$CODE_CONTENT" | grep -qE '\.server\.(js|jsx|ts|tsx)'; then
        ERRORS+=("⚠️  File uses client hooks but missing 'use client' directive.")
        RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
      fi
    fi
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buseActionState\s*\('; then
  TWO_ELEMENT='(const|let|var)\s*\[\s*\w+\s*,\s*\w+\s*\]'
  THREE_ELEMENT='(const|let|var)\s*\[\s*\w+\s*,\s*\w+\s*,\s*(\w+)\s*\]'

  RECOMMENDED_SKILLS+=("action-state-patterns")

  if echo "$CODE_CONTENT" | grep -qE "$TWO_ELEMENT\s*=\s*useActionState"; then
    ERRORS+=("⚠️  useActionState called but isPending not destructured. Consider using 3rd element for loading states.")
    RECOMMENDED_SKILLS+=("form-status-tracking")
  fi

  if echo "$CODE_CONTENT" | grep -qE "$THREE_ELEMENT\s*=\s*useActionState"; then
    while IFS= read -r line; do
      PENDING_VAR=$(echo "$line" | grep -oE ',\s*(\w+)\s*\]' | grep -oE '\w+' | tail -1)

      if [ -n "$PENDING_VAR" ]; then
        USAGE_PATTERN='\{'"$PENDING_VAR"'[^a-zA-Z0-9_]|disabled=\{'"$PENDING_VAR"'|\?.*'"$PENDING_VAR"'|&&.*'"$PENDING_VAR"'|'"$PENDING_VAR"'\s*&&|'"$PENDING_VAR"'\s*\?'

        if ! echo "$CODE_CONTENT" | grep -qE "$USAGE_PATTERN"; then
          ERRORS+=("⚠️  useActionState isPending ('$PENDING_VAR') destructured but appears unused. Consider using for loading states.")
          RECOMMENDED_SKILLS+=("form-status-tracking")
        fi
      fi
    done < <(echo "$CODE_CONTENT" | grep -E '(const|let|var)\s*\[\s*\w+\s*,\s*\w+\s*,\s*(\w+)\s*\]\s*=\s*useActionState')
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buseFormStatus\s*\('; then
  if ! echo "$CODE_CONTENT" | grep -qE '<form|as\s*=\s*["\x27]form["\x27]'; then
    ERRORS+=("⚠️  useFormStatus must be called inside a form component.")
    RECOMMENDED_SKILLS+=("form-status-tracking")
  else
    RECOMMENDED_SKILLS+=("form-status-tracking")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buseOptimistic\s*\('; then
  RECOMMENDED_SKILLS+=("optimistic-updates")
fi

if echo "$CODE_CONTENT" | grep -qE '\buse\s*\('; then
  RECOMMENDED_SKILLS+=("using-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReactDOM\.render\s*\('; then
  ERRORS+=("❌ ReactDOM.render is deprecated. Use ReactDOM.createRoot in React 19.")
  RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\buseFormState\s*\('; then
  ERRORS+=("❌ useFormState is renamed to useActionState in React 19.")
  RECOMMENDED_SKILLS+=("action-state-patterns")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.FC\s*<|:\s*React\.FC\b'; then
  ERRORS+=("⚠️  React.FC is discouraged in React 19. Use plain function components.")
  RECOMMENDED_SKILLS+=("component-composition")
fi

if echo "$CODE_CONTENT" | grep -qE '\buseReducer\s*\('; then
  RECOMMENDED_SKILLS+=("reducer-patterns")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.createContext\s*\(|\bcreateContext\s*\('; then
  RECOMMENDED_SKILLS+=("context-api-patterns" "local-vs-global-state")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.lazy\s*\(|\blazy\s*\('; then
  RECOMMENDED_SKILLS+=("code-splitting")
fi

if echo "$CODE_CONTENT" | grep -qE '\b(preload|preinit|prefetchDNS|preconnect)\s*\('; then
  RECOMMENDED_SKILLS+=("resource-preloading")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.Children\.(map|forEach|count|only|toArray)\s*\('; then
  ERRORS+=("⚠️  React.Children utilities are deprecated. Use array methods directly.")
  RECOMMENDED_SKILLS+=("component-composition")
fi

if echo "$CODE_CONTENT" | grep -qE '\bContext\.Consumer\b|<\w+\.Consumer>'; then
  ERRORS+=("⚠️  Context.Consumer is deprecated. Use useContext or use(Context) in React 19.")
  RECOMMENDED_SKILLS+=("context-api-patterns" "using-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\bfindDOMNode\s*\('; then
  ERRORS+=("❌ findDOMNode is deprecated. Use refs instead.")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\bunmountComponentAtNode\s*\('; then
  ERRORS+=("❌ unmountComponentAtNode is deprecated. Use root.unmount() in React 19.")
  RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReactDOM\.hydrate\s*\('; then
  ERRORS+=("❌ ReactDOM.hydrate is deprecated. Use hydrateRoot in React 19.")
  RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\bref\s*=\s*["\x27]\w+["\x27]'; then
  ERRORS+=("❌ String refs are deprecated. Use ref callbacks or useRef.")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\b(componentWillMount|componentWillReceiveProps|componentWillUpdate)\s*\('; then
  ERRORS+=("❌ Unsafe lifecycle methods detected. These are removed in React 19.")
  RECOMMENDED_SKILLS+=("using-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\bcontextType\s*='; then
  ERRORS+=("⚠️  Legacy contextType is deprecated. Use useContext hook.")
  RECOMMENDED_SKILLS+=("context-api-patterns")
fi

if echo "$CODE_CONTENT" | grep -qE '\bgetDerivedStateFromProps\s*\('; then
  ERRORS+=("⚠️  getDerivedStateFromProps can often be replaced with hooks or props.")
  RECOMMENDED_SKILLS+=("using-use-hook")
fi

if [ ${#ERRORS[@]} -gt 0 ] || [ ${#RECOMMENDED_SKILLS[@]} -gt 0 ]; then
  if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "React 19 Compliance Issues:"
    printf '%s\n' "${ERRORS[@]}"
    echo ""
  fi

  if [ ${#RECOMMENDED_SKILLS[@]} -gt 0 ]; then
    UNIQUE_SKILLS=($(printf '%s\n' "${RECOMMENDED_SKILLS[@]}" | sort -u))
    echo "💡 Recommended skills:"
    for skill in "${UNIQUE_SKILLS[@]}"; do
      echo "   • /skill $skill"
    done
    echo ""
  fi
fi

exit 0

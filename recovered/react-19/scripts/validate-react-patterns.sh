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

WARNINGS=()
RECOMMENDED_SKILLS=()

if echo "$CODE_CONTENT" | grep -qE '\bforwardRef\s*\('; then
  WARNINGS+=("⚠️  Found forwardRef usage. React 19 supports ref as a prop.")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\.(propTypes|defaultProps)\s*='; then
  WARNINGS+=("⚠️  Found propTypes or defaultProps. These are deprecated in React 19.")
  RECOMMENDED_SKILLS+=("review-hook-patterns")
fi

if echo "$CODE_CONTENT" | grep -qE '\bclass\s+\w+\s+extends\s+(React\.Component|Component|PureComponent|React\.PureComponent)\b'; then
  WARNINGS+=("⚠️  Found class component. Migrate to function component with hooks.")
  RECOMMENDED_SKILLS+=("using-use-hook")

  if echo "$CODE_CONTENT" | grep -qE '\bcomponent(Did|Will)Mount\b'; then
    RECOMMENDED_SKILLS+=("action-state-patterns")
  fi
fi

if grep -qE "^[[:space:]]*['\"]use server['\"]" "$FILE_PATH" || grep -qE "^[[:space:]]*export.*['\"]use server['\"]" "$FILE_PATH"; then
  HAS_VALIDATION=false
  HAS_AUTH_CHECK=false
  HAS_FORM_DATA=false

  if echo "$CODE_CONTENT" | grep -qE '\.(safeParse|parse)\s*\(|validate\w*\s*\(|schema\.(parse|safeParse)'; then
    HAS_VALIDATION=true
  fi

  if echo "$CODE_CONTENT" | grep -qE '\b(auth|session|getSession|checkAuth|requireAuth|verifyAuth|authenticate)\s*\('; then
    HAS_AUTH_CHECK=true
  fi

  if echo "$CODE_CONTENT" | grep -qE '\bformData\s*\.|formData\.get\s*\('; then
    HAS_FORM_DATA=true
    if [ "$HAS_VALIDATION" = false ]; then
      WARNINGS+=("⚠️  Server Action found without input validation.")
      RECOMMENDED_SKILLS+=("form-validation" "server-actions")
    fi
  fi

  if echo "$CODE_CONTENT" | grep -qE '\b(delete|update|create|modify|remove)\w*\s*\('; then
    if [ "$HAS_AUTH_CHECK" = false ]; then
      WARNINGS+=("⚠️  Server Action with mutations found without authentication check.")
      RECOMMENDED_SKILLS+=("server-actions")
    fi
  fi

  if [ "$HAS_FORM_DATA" = true ]; then
    RECOMMENDED_SKILLS+=("action-state-patterns")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE "React\.createElement\s*\(\s*['\"]"; then
  WARNINGS+=("⚠️  Found React.createElement with string literals. Consider JSX.")
  RECOMMENDED_SKILLS+=("component-composition")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReactDOM\.render\s*\('; then
  WARNINGS+=("⚠️  Found ReactDOM.render. Use createRoot in React 19.")
  RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\buseFormState\s*\('; then
  WARNINGS+=("⚠️  Found useFormState. This hook is renamed to useActionState in React 19.")
  RECOMMENDED_SKILLS+=("action-state-patterns")
fi

if echo "$CODE_CONTENT" | grep -qE '\buseContext\s*\('; then
  if ! echo "$CODE_CONTENT" | grep -qE '\buse\s*\('; then
    RECOMMENDED_SKILLS+=("context-api-patterns")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buse(Memo|Callback)\s*\('; then
  RECOMMENDED_SKILLS+=("react-compiler-aware")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.Children\.(map|forEach|count|only|toArray)\s*\('; then
  WARNINGS+=("⚠️  React.Children utilities are deprecated. Use array methods on children directly.")
  RECOMMENDED_SKILLS+=("component-composition")
fi

if echo "$CODE_CONTENT" | grep -qE '\bContext\.Consumer\b|<\w+\.Consumer>'; then
  WARNINGS+=("⚠️  Context.Consumer is deprecated. Use useContext or use(Context) instead.")
  RECOMMENDED_SKILLS+=("context-api-patterns" "using-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\bfindDOMNode\s*\('; then
  WARNINGS+=("⚠️  findDOMNode is deprecated. Use refs to access DOM nodes.")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\bunmountComponentAtNode\s*\('; then
  WARNINGS+=("⚠️  unmountComponentAtNode is deprecated. Use root.unmount().")
  RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReactDOM\.hydrate\s*\('; then
  WARNINGS+=("⚠️  ReactDOM.hydrate is deprecated. Use hydrateRoot.")
  RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\bref\s*=\s*["\x27]\w+["\x27]'; then
  WARNINGS+=("⚠️  String refs are deprecated. Use ref callbacks or useRef hook.")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\b(componentWillMount|componentWillReceiveProps|componentWillUpdate|UNSAFE_componentWillMount|UNSAFE_componentWillReceiveProps|UNSAFE_componentWillUpdate)\s*\('; then
  WARNINGS+=("⚠️  Unsafe/deprecated lifecycle methods found. Migrate to hooks.")
  RECOMMENDED_SKILLS+=("using-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\bcontextType\s*='; then
  WARNINGS+=("⚠️  Legacy contextType found. Use useContext hook instead.")
  RECOMMENDED_SKILLS+=("context-api-patterns")
fi

if echo "$CODE_CONTENT" | grep -qE '\bcreateFactory\s*\('; then
  WARNINGS+=("⚠️  React.createFactory is deprecated. Use JSX or createElement.")
  RECOMMENDED_SKILLS+=("component-composition")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.createClass\s*\('; then
  WARNINGS+=("⚠️  React.createClass is completely removed. Use class or function components.")
  RECOMMENDED_SKILLS+=("component-composition")
fi

if [ ${#WARNINGS[@]} -gt 0 ] || [ ${#RECOMMENDED_SKILLS[@]} -gt 0 ]; then
  if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo "React 19 Pattern Validation:"
    printf '%s\n' "${WARNINGS[@]}"
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

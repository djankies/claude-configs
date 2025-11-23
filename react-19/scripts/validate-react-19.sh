#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "react-19" "PostToolUse"

read_hook_input > /dev/null
FILE_PATH=$(get_input_field "tool_input.file_path")

if [[ -z "$FILE_PATH" ]]; then
  FILE_PATH=$(get_input_field "tool_input.path")
fi

if [[ -z "$FILE_PATH" ]]; then
  posttooluse_respond
  finish_hook 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  posttooluse_respond
  finish_hook 0
fi

strip_comments() {
  sed 's://.*$::g' "$1" | \
  sed '/\/\*/,/\*\//d' | \
  grep -v '^\s*$'
}

CODE_CONTENT=$(strip_comments "$FILE_PATH")

CRITICAL_VIOLATIONS=()
WARNINGS=()
RECOMMENDED_SKILLS=()

if echo "$CODE_CONTENT" | grep -qE '\bforwardRef\s*[<(]'; then
  CRITICAL_VIOLATIONS+=("forwardRef is deprecated - use ref as prop")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\.(propTypes|defaultProps)\s*='; then
  CRITICAL_VIOLATIONS+=("propTypes/defaultProps deprecated - remove and use TypeScript/ES6 defaults")
fi

if echo "$CODE_CONTENT" | grep -qE '\bclass\s+\w+\s+extends\s+(React\.Component|Component|PureComponent|React\.PureComponent)\b'; then
  CRITICAL_VIOLATIONS+=("Class component found - migrate to function component")
  RECOMMENDED_SKILLS+=("using-the-use-hook")

  if echo "$CODE_CONTENT" | grep -qE '\bcomponent(Did|Will)Mount\b'; then
    RECOMMENDED_SKILLS+=("using-action-state")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\bReactDOM\.render\s*\('; then
  CRITICAL_VIOLATIONS+=("ReactDOM.render deprecated - use createRoot")
  RECOMMENDED_SKILLS+=("managing-server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\buseFormState\s*\('; then
  CRITICAL_VIOLATIONS+=("useFormState renamed to useActionState")
  RECOMMENDED_SKILLS+=("using-action-state")
fi

if echo "$CODE_CONTENT" | grep -qE '\bfindDOMNode\s*\('; then
  CRITICAL_VIOLATIONS+=("findDOMNode deprecated - use refs")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\bunmountComponentAtNode\s*\('; then
  CRITICAL_VIOLATIONS+=("unmountComponentAtNode deprecated - use root.unmount()")
  RECOMMENDED_SKILLS+=("managing-server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReactDOM\.hydrate\s*\('; then
  CRITICAL_VIOLATIONS+=("ReactDOM.hydrate deprecated - use hydrateRoot")
  RECOMMENDED_SKILLS+=("managing-server-vs-client-boundaries")
fi

if echo "$CODE_CONTENT" | grep -qE '\bref\s*=\s*["\x27]\w+["\x27]'; then
  CRITICAL_VIOLATIONS+=("String refs deprecated - use ref callbacks or useRef")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

if echo "$CODE_CONTENT" | grep -qE '\b(componentWillMount|componentWillReceiveProps|componentWillUpdate|UNSAFE_componentWillMount|UNSAFE_componentWillReceiveProps|UNSAFE_componentWillUpdate)\s*\('; then
  CRITICAL_VIOLATIONS+=("Unsafe lifecycle methods removed in React 19")
  RECOMMENDED_SKILLS+=("using-the-use-hook")
fi

HAS_USE_SERVER=$(grep -qE "^[[:space:]]*['\"]use server['\"]" "$FILE_PATH" && echo "true" || echo "false")

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
      WARNINGS+=("Server Action without input validation")
      RECOMMENDED_SKILLS+=("validating-forms" "implementing-server-actions")
    fi
  fi

  if echo "$CODE_CONTENT" | grep -qE '\b(delete|update|create|modify|remove)\w*\s*\('; then
    if [ "$HAS_AUTH_CHECK" = false ]; then
      WARNINGS+=("Server Action mutations without auth check")
      RECOMMENDED_SKILLS+=("implementing-server-actions")
    fi
  fi

  if [ "$HAS_FORM_DATA" = true ]; then
    RECOMMENDED_SKILLS+=("using-action-state")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\bformData\.get\s*\(|\bformData\s*\.'; then
  if echo "$CODE_CONTENT" | grep -qE '(export\s+)?(async\s+)?function\s+\w+.*FormData'; then
    if [ "$HAS_USE_SERVER" = "false" ]; then
      WARNINGS+=("FormData handler missing 'use server' directive")
      RECOMMENDED_SKILLS+=("implementing-server-actions")
    fi
  fi
fi

HAS_USE_CLIENT=$(grep -qE "^[[:space:]]*['\"]use client['\"]" "$FILE_PATH" && echo "true" || echo "false")

if echo "$CODE_CONTENT" | grep -qE '\b(useState|useEffect|useContext|useReducer|useCallback|useMemo|useRef|useLayoutEffect)\s*\('; then
  if [ "$HAS_USE_CLIENT" = "false" ]; then
    if [ -f "package.json" ] && grep -qE '"(next|@next)"\s*:\s*"' "package.json"; then
      if ! echo "$CODE_CONTENT" | grep -qE '\.server\.(js|jsx|ts|tsx)'; then
        WARNINGS+=("Client hooks without 'use client' directive")
        RECOMMENDED_SKILLS+=("managing-server-vs-client-boundaries")
      fi
    fi
  fi
fi

if echo "$CODE_CONTENT" | grep -qE 'onSubmit.*preventDefault'; then
  if ! echo "$CODE_CONTENT" | grep -qE '\buseActionState\s*\('; then
    WARNINGS+=("Consider useActionState for form state")
    RECOMMENDED_SKILLS+=("using-action-state")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buseActionState\s*\('; then
  TWO_ELEMENT='(const|let|var)\s*\[\s*\w+\s*,\s*\w+\s*\]'
  THREE_ELEMENT='(const|let|var)\s*\[\s*\w+\s*,\s*\w+\s*,\s*(\w+)\s*\]'

  RECOMMENDED_SKILLS+=("using-action-state")

  if echo "$CODE_CONTENT" | grep -qE "$TWO_ELEMENT\s*=\s*useActionState"; then
    WARNINGS+=("useActionState isPending not destructured")
    RECOMMENDED_SKILLS+=("form-status-tracking")
  fi

  if echo "$CODE_CONTENT" | grep -qE "$THREE_ELEMENT\s*=\s*useActionState"; then
    while IFS= read -r line; do
      PENDING_VAR=$(echo "$line" | grep -oE ',\s*(\w+)\s*\]' | grep -oE '\w+' | tail -1)

      if [ -n "$PENDING_VAR" ]; then
        USAGE_PATTERN='\{'"$PENDING_VAR"'[^a-zA-Z0-9_]|disabled=\{'"$PENDING_VAR"'|\?.*'"$PENDING_VAR"'|&&.*'"$PENDING_VAR"'|'"$PENDING_VAR"'\s*&&|'"$PENDING_VAR"'\s*\?'

        if ! echo "$CODE_CONTENT" | grep -qE "$USAGE_PATTERN"; then
          WARNINGS+=("useActionState isPending ('$PENDING_VAR') appears unused")
          RECOMMENDED_SKILLS+=("form-status-tracking")
        fi
      fi
    done < <(echo "$CODE_CONTENT" | grep -E '(const|let|var)\s*\[\s*\w+\s*,\s*\w+\s*,\s*(\w+)\s*\]\s*=\s*useActionState')
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buseFormStatus\s*\('; then
  if ! echo "$CODE_CONTENT" | grep -qE '<form|as\s*=\s*["\x27]form["\x27]'; then
    WARNINGS+=("useFormStatus must be inside form component")
    RECOMMENDED_SKILLS+=("form-status-tracking")
  else
    RECOMMENDED_SKILLS+=("form-status-tracking")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE 'disabled=\{(pending|isSubmitting|isPending)'; then
  if ! echo "$CODE_CONTENT" | grep -qE '\buseFormStatus\s*\('; then
    WARNINGS+=("Consider useFormStatus for form submission state")
    RECOMMENDED_SKILLS+=("form-status-tracking")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buseOptimistic\s*\('; then
  RECOMMENDED_SKILLS+=("implementing-optimistic-updates")
fi

if echo "$CODE_CONTENT" | grep -qE 'useState.*(pending|optimistic)|setPending|setOptimistic'; then
  if ! echo "$CODE_CONTENT" | grep -qE '\buseOptimistic\s*\('; then
    WARNINGS+=("Consider useOptimistic for optimistic updates")
    RECOMMENDED_SKILLS+=("implementing-optimistic-updates")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buse\s*\('; then
  RECOMMENDED_SKILLS+=("using-the-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\buseDeferredValue\s*\(\s*\w+\s*\)([^,]|$)'; then
  WARNINGS+=("useDeferredValue missing initialValue parameter")
  RECOMMENDED_SKILLS+=("using-the-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.FC\s*<|:\s*React\.FC\b'; then
  WARNINGS+=("React.FC discouraged - use plain function components")
  RECOMMENDED_SKILLS+=("composing-components")
fi

if echo "$CODE_CONTENT" | grep -qE "React\.createElement\s*\(\s*['\"]"; then
  WARNINGS+=("React.createElement with string literals - consider JSX")
  RECOMMENDED_SKILLS+=("composing-components")
fi

if echo "$CODE_CONTENT" | grep -qE '\buseContext\s*\('; then
  if ! echo "$CODE_CONTENT" | grep -qE '\buse\s*\('; then
    RECOMMENDED_SKILLS+=("using-context-api")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\buse(Memo|Callback)\s*\('; then
  RECOMMENDED_SKILLS+=("optimizing-with-react-compiler")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.Children\.(map|forEach|count|only|toArray)\s*\('; then
  WARNINGS+=("React.Children utilities deprecated - use array methods")
  RECOMMENDED_SKILLS+=("composing-components")
fi

if echo "$CODE_CONTENT" | grep -qE '\bContext\.Consumer\b|<\w+\.Consumer>'; then
  WARNINGS+=("Context.Consumer deprecated - use useContext or use()")
  RECOMMENDED_SKILLS+=("using-context-api" "using-the-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\bcontextType\s*='; then
  WARNINGS+=("contextType deprecated - use useContext")
  RECOMMENDED_SKILLS+=("using-context-api")
fi

if echo "$CODE_CONTENT" | grep -qE '\bcreateFactory\s*\('; then
  WARNINGS+=("React.createFactory deprecated - use JSX or createElement")
  RECOMMENDED_SKILLS+=("composing-components")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.createClass\s*\('; then
  WARNINGS+=("React.createClass removed - use class or function components")
  RECOMMENDED_SKILLS+=("composing-components")
fi

if echo "$CODE_CONTENT" | grep -qE '\bgetDerivedStateFromProps\s*\('; then
  WARNINGS+=("getDerivedStateFromProps can often be replaced with hooks")
  RECOMMENDED_SKILLS+=("using-the-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE 'Math\.random\(\).*toString\('; then
  WARNINGS+=("Math.random() for IDs - use useId() hook")
  RECOMMENDED_SKILLS+=("using-the-use-hook")
fi

if echo "$CODE_CONTENT" | grep -qE '\buseReducer\s*\('; then
  RECOMMENDED_SKILLS+=("using-reducers")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.createContext\s*\(|\bcreateContext\s*\('; then
  RECOMMENDED_SKILLS+=("using-context-api" "managing-local-vs-global-state")
fi

if echo "$CODE_CONTENT" | grep -qE '\bReact\.lazy\s*\(|\blazy\s*\('; then
  RECOMMENDED_SKILLS+=("code-splitting")
fi

if echo "$CODE_CONTENT" | grep -qE '\b(preload|preinit|prefetchDNS|preconnect)\s*\('; then
  RECOMMENDED_SKILLS+=("resource-preloading")
fi

if echo "$CODE_CONTENT" | grep -qE '\bcustomElements\.(define|get|whenDefined)|\bHTMLElement\b|extends\s+HTMLElement'; then
  RECOMMENDED_SKILLS+=("supporting-custom-elements")
fi

if echo "$CODE_CONTENT" | grep -qE '\b(renderHook|waitFor)\s*\(|@testing-library/react'; then
  if echo "$CODE_CONTENT" | grep -qE '\buse[A-Z]\w+\s*\('; then
    RECOMMENDED_SKILLS+=("testing-hooks")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE "(describe|test|it)\s*\([^)]*[\"'].*[Ss]erver.*[Aa]ction"; then
  RECOMMENDED_SKILLS+=("testing-server-actions")
fi

HOOKS_VALIDATOR="${SCRIPT_DIR}/validate-hooks-rules.js"
if [[ ! -f "$HOOKS_VALIDATOR" ]]; then
  HOOKS_VALIDATOR="${CLAUDE_MARKETPLACE_ROOT}/react-19/scripts/validate-hooks-rules.js"
fi

ESLINT_JSON=$(node "$HOOKS_VALIDATOR" "$FILE_PATH" 2>&1 || true)
if echo "$ESLINT_JSON" | grep -q '"valid":false'; then
  TOTAL_ERRORS=$(echo "$ESLINT_JSON" | grep -o '"totalErrors":[0-9]*' | cut -d: -f2)
  TOTAL_WARNINGS=$(echo "$ESLINT_JSON" | grep -o '"totalWarnings":[0-9]*' | cut -d: -f2)

  if [[ "$TOTAL_ERRORS" -gt 0 ]]; then
    while read -r line col message; do
      if [[ -n "$message" ]]; then
        CRITICAL_VIOLATIONS+=("Rules of Hooks (line $line): $message")
      fi
    done < <(echo "$ESLINT_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for v in data.get('violations', []):
    msg = v['message'].replace('React Hook', 'Hook')
    print(f\"{v['line']} {v['column']} {msg}\")
" 2>/dev/null || true)
    RECOMMENDED_SKILLS+=("following-the-rules-of-hooks")
  fi

  if [[ "$TOTAL_WARNINGS" -gt 0 ]]; then
    while read -r line col message; do
      if [[ -n "$message" ]]; then
        WARNINGS+=("Hook dependency (line $line): $message")
      fi
    done < <(echo "$ESLINT_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for w in data.get('warnings', []):
    msg = w['message'].replace('React Hook', 'Hook')
    print(f\"{w['line']} {w['column']} {msg}\")
" 2>/dev/null || true)
    RECOMMENDED_SKILLS+=("following-the-rules-of-hooks")
  fi
fi

TOTAL_ISSUES=$((${#CRITICAL_VIOLATIONS[@]} + ${#WARNINGS[@]}))

if [ $TOTAL_ISSUES -gt 0 ] || [ ${#RECOMMENDED_SKILLS[@]} -gt 0 ]; then
  MESSAGE="React 19 ($TOTAL_ISSUES issues)

"

  if [ ${#CRITICAL_VIOLATIONS[@]} -gt 0 ]; then
    MESSAGE+="❌ CRITICAL (${#CRITICAL_VIOLATIONS[@]}):
"
    for violation in "${CRITICAL_VIOLATIONS[@]}"; do
      MESSAGE+="  • $violation
"
    done
    MESSAGE+="
"
    log_error "Critical violations found in $FILE_PATH"
  fi

  if [ ${#WARNINGS[@]} -gt 0 ]; then
    MESSAGE+="⚠️  Issues (${#WARNINGS[@]}):
"
    for warning in "${WARNINGS[@]}"; do
      MESSAGE+="  • $warning
"
    done
    MESSAGE+="
"
    log_warn "Issues found in $FILE_PATH"
  fi

  if [ ${#RECOMMENDED_SKILLS[@]} -gt 0 ]; then
    UNIQUE_SKILLS=($(printf '%s\n' "${RECOMMENDED_SKILLS[@]}" | sort -u))
    MESSAGE+="
🚨 REQUIRED: Use these skills BEFORE modifying this file:
"
    for skill in "${UNIQUE_SKILLS[@]}"; do
      MESSAGE+="   /skill $skill
"
    done
    MESSAGE+="
⚠️  DO NOT fix violations without using the required skills first.
⚠️  DO NOT write more React code without learning these patterns.
"
  fi

  posttooluse_respond "" "" "$MESSAGE"
  finish_hook 0
fi

log_info "No React 19 issues in $FILE_PATH"
posttooluse_respond
finish_hook 0

#!/bin/bash

AGENT_MESSAGE="$1"

if [ -z "$AGENT_MESSAGE" ]; then
  exit 0
fi

SUGGESTIONS=()
RECOMMENDED_SKILLS=()

if echo "$AGENT_MESSAGE" | grep -qiE '\bforwardRef\s*\(|\bforwardRef\b'; then
  if ! echo "$AGENT_MESSAGE" | grep -qiE '(migrat|remov|replac|deprecat|avoid).*forwardRef'; then
    SUGGESTIONS+=("💡 Suggestion mentions forwardRef. Ensure migration to ref-as-prop pattern.")
    RECOMMENDED_SKILLS+=("migrating-from-forwardref")
  fi
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\buseFormState\s*\(|\buseFormState\b'; then
  SUGGESTIONS+=("💡 Detected useFormState. This is renamed to useActionState in React 19.")
  RECOMMENDED_SKILLS+=("action-state-patterns")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\bReactDOM\.render\s*\(|\bReactDOM\.render\b'; then
  SUGGESTIONS+=("💡 ReactDOM.render is deprecated. Use ReactDOM.createRoot in React 19.")
  RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\bcomponent(Did|Will|Should)(Mount|Update|Unmount|Receive)'; then
  SUGGESTIONS+=("💡 Lifecycle methods detected. Migrate to function components with hooks.")
  RECOMMENDED_SKILLS+=("using-use-hook")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\bContext\.Consumer\b|<\w+\.Consumer>'; then
  SUGGESTIONS+=("💡 Context.Consumer detected. Use useContext or React 19's use(Context).")
  RECOMMENDED_SKILLS+=("context-api-patterns" "using-use-hook")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\b(propTypes|defaultProps)\b'; then
  if ! echo "$AGENT_MESSAGE" | grep -qiE '(remov|deprecat|avoid|don.*t use)'; then
    SUGGESTIONS+=("💡 propTypes/defaultProps are deprecated in React 19.")
    RECOMMENDED_SKILLS+=("review-hook-patterns")
  fi
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\bclass\s+\w+\s+extends\s+(React\.)?Component'; then
  SUGGESTIONS+=("💡 Class component detected. Consider migrating to function component.")
  RECOMMENDED_SKILLS+=("component-composition")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\bserver\s+action'; then
  HAS_VALIDATION=$(echo "$AGENT_MESSAGE" | grep -qiE '\b(validat|zod|schema|parse)\b' && echo "true" || echo "false")
  HAS_AUTH=$(echo "$AGENT_MESSAGE" | grep -qiE '\b(auth|session|permission|protect)\b' && echo "true" || echo "false")

  RECOMMENDED_SKILLS+=("server-actions")

  if [ "$HAS_VALIDATION" = "false" ]; then
    SUGGESTIONS+=("💡 Server Action mentioned without validation.")
    RECOMMENDED_SKILLS+=("form-validation")
  fi

  if [ "$HAS_AUTH" = "false" ]; then
    SUGGESTIONS+=("💡 Server Action mentioned without authentication.")
    RECOMMENDED_SKILLS+=("review-server-actions")
  fi
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\bReact\.FC\b|:\s*React\.FC<'; then
  SUGGESTIONS+=("💡 React.FC is discouraged in React 19. Use plain function components.")
  RECOMMENDED_SKILLS+=("component-composition")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\buseOptimistic\b'; then
  RECOMMENDED_SKILLS+=("optimistic-updates")
  if ! echo "$AGENT_MESSAGE" | grep -qiE '\bSuspense\b'; then
    SUGGESTIONS+=("💡 useOptimistic detected. Consider Suspense boundary for async operations.")
  fi
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\buseFormStatus\b'; then
  RECOMMENDED_SKILLS+=("form-status-tracking")
  if ! echo "$AGENT_MESSAGE" | grep -qiE '\bform\b|<form'; then
    SUGGESTIONS+=("💡 useFormStatus must be called inside a component within a <form>.")
  fi
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\buseActionState\b'; then
  RECOMMENDED_SKILLS+=("action-state-patterns")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\buse\s*\('; then
  RECOMMENDED_SKILLS+=("using-use-hook")
fi

if echo "$AGENT_MESSAGE" | grep -qiE "['\"]\s*use\s+(client|server)\s*['\"]"; then
  SUGGESTIONS+=("💡 Directive detected. Verify placement at top of file before imports.")
  RECOMMENDED_SKILLS+=("server-vs-client-boundaries")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\b(useState|useEffect|useReducer)\b'; then
  if echo "$AGENT_MESSAGE" | grep -qiE '\bglobal\s+state|\bshared\s+state'; then
    RECOMMENDED_SKILLS+=("local-vs-global-state" "context-api-patterns")
  fi
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\bperformance\b|\boptimiz'; then
  RECOMMENDED_SKILLS+=("react-compiler-aware" "review-performance-patterns")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\b(lazy|code.?split|dynamic.*import)\b'; then
  RECOMMENDED_SKILLS+=("code-splitting")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\b(preload|prefetch)\b'; then
  RECOMMENDED_SKILLS+=("resource-preloading")
fi

if echo "$AGENT_MESSAGE" | grep -qiE '\btest|spec\b'; then
  RECOMMENDED_SKILLS+=("testing-components" "review-test-quality")
fi

if [ ${#SUGGESTIONS[@]} -gt 0 ] || [ ${#RECOMMENDED_SKILLS[@]} -gt 0 ]; then
  if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
    echo "React 19 Pattern Review:"
    printf '%s\n' "${SUGGESTIONS[@]}"
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

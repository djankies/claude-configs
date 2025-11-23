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
  log_info "No file path found in hook input, skipping validation"
  posttooluse_respond
  finish_hook 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  log_info "File does not exist: $FILE_PATH, skipping validation"
  posttooluse_respond
  finish_hook 0
fi

EXT="${FILE_PATH##*.}"
if [[ ! "$EXT" =~ ^(js|jsx|ts|tsx)$ ]]; then
  log_info "File extension $EXT is not JS/JSX/TS/TSX, skipping validation"
  posttooluse_respond
  finish_hook 0
fi

log_info "Starting Rules of Hooks validation for: $FILE_PATH"

if ! command -v node >/dev/null 2>&1; then
  log_error "Node.js not found - cannot validate Rules of Hooks"
  posttooluse_respond "" "" "⚠️  Node.js not available. Rules of Hooks validation skipped."
  finish_hook 0
fi

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${SCRIPT_DIR}/..}"
VALIDATOR_SCRIPT="${PLUGIN_ROOT}/scripts/validate-hooks-rules.js"
if [[ ! -f "$VALIDATOR_SCRIPT" ]]; then
  log_error "Validator script not found: $VALIDATOR_SCRIPT"
  posttooluse_respond "" "" "⚠️  Hooks validator not found. Validation skipped."
  finish_hook 0
fi

if [[ ! -d "$PLUGIN_ROOT/node_modules" ]]; then
  log_error "ESLint dependencies missing - auto-install may have failed"
  posttooluse_respond "" "" "⚠️  Rules of Hooks validation unavailable - dependencies missing.

This should have been installed automatically. To fix manually:
  cd $PLUGIN_ROOT && npm install

Validation will be skipped for this file."
  finish_hook 0
fi

log_info "Validating Rules of Hooks: $FILE_PATH"

set +e
VALIDATION_OUTPUT=$(node "$VALIDATOR_SCRIPT" "$FILE_PATH" 2>&1)
VALIDATION_EXIT_CODE=$?
set -e

log_info "Validation completed with exit code: $VALIDATION_EXIT_CODE"

if [[ $VALIDATION_EXIT_CODE -eq 0 ]]; then
  VALID=$(echo "$VALIDATION_OUTPUT" | jq -r '.valid // true' 2>/dev/null || echo "true")

  if [[ "$VALID" == "true" ]]; then
    log_info "Rules of Hooks validation passed for $FILE_PATH"
    posttooluse_respond
    finish_hook 0
  fi
fi

ERROR_TYPE=$(echo "$VALIDATION_OUTPUT" | jq -r '.error // empty' 2>/dev/null)
if [[ -n "$ERROR_TYPE" ]]; then
  ERROR_MSG=$(echo "$VALIDATION_OUTPUT" | jq -r '.message // "Unknown error"' 2>/dev/null)
  log_error "Validation error: $ERROR_TYPE - $ERROR_MSG"
  posttooluse_respond "" "" "⚠️  Rules of Hooks validation failed: $ERROR_MSG"
  finish_hook 0
fi

VIOLATIONS=$(echo "$VALIDATION_OUTPUT" | jq -r '.violations // []' 2>/dev/null)
WARNINGS=$(echo "$VALIDATION_OUTPUT" | jq -r '.warnings // []' 2>/dev/null)
TOTAL_ERRORS=$(echo "$VALIDATION_OUTPUT" | jq -r '.totalErrors // 0' 2>/dev/null)
TOTAL_WARNINGS=$(echo "$VALIDATION_OUTPUT" | jq -r '.totalWarnings // 0' 2>/dev/null)

if [[ "$TOTAL_ERRORS" == "0" && "$TOTAL_WARNINGS" == "0" ]]; then
  log_info "Rules of Hooks validation passed for $FILE_PATH"
  posttooluse_respond
  finish_hook 0
fi

MESSAGE="❌ CRITICAL: Rules of Hooks Violations Detected in Written Code

The code you just wrote contains serious violations of React's Rules of Hooks.

"

RECOMMENDED_SKILLS=()

if [[ "$TOTAL_ERRORS" -gt 0 ]]; then
  MESSAGE+="🚨 Critical Violations ($TOTAL_ERRORS):
"

  VIOLATION_MESSAGES=$(echo "$VIOLATIONS" | jq -r '.[].message' 2>/dev/null)

  while IFS= read -r line; do
    MESSAGE+="$line
"
  done < <(echo "$VIOLATIONS" | jq -r '.[] | "   Line \(.line):\(.column) - \(.message)"' 2>/dev/null)

  MESSAGE+="
🚫 RULES OF HOOKS VIOLATIONS:
These violations will cause runtime bugs, rendering inconsistencies, and unpredictable behavior.
React requires:
  1. Hooks MUST be called at the top level (never inside conditionals, loops, or nested functions)
  2. Hooks MUST only be called from React function components or custom hooks (names starting with 'use')
  3. Hooks MUST be called in the same order on every render

HOW TO FIX:
"

  if echo "$VIOLATION_MESSAGES" | grep -qi "conditionally\|conditional"; then
    MESSAGE+="  • Conditional hooks: Move hooks to top level, use conditional rendering instead
    Example: Instead of 'if (x) { useState() }', use 'const [state] = useState(); if (x) { use state }'
"
  fi

  if echo "$VIOLATION_MESSAGES" | grep -qi "loop\|executed more than once"; then
    MESSAGE+="  • Hooks in loops: Extract loop body into separate component, call hooks in that component
    Example: items.map(item => <ItemComponent key={item.id} item={item} />)
"
  fi

  if echo "$VIOLATION_MESSAGES" | grep -qi "is neither a React function component nor a custom React Hook"; then
    MESSAGE+="  • Hooks in regular functions: Rename to start with 'use' (custom hook) or convert to component (PascalCase)
    Example: 'function handleClick()' → 'function useClickHandler()' or 'function ClickHandler()'
"
  fi

  if echo "$VIOLATION_MESSAGES" | grep -qi "class component"; then
    MESSAGE+="  • Hooks in class components: Convert class to function component
    Reference: /skill migrating-from-forwardref for migration patterns
"
    RECOMMENDED_SKILLS+=("migrating-from-forwardref")
  fi

  if echo "$VIOLATION_MESSAGES" | grep -qi "early return"; then
    MESSAGE+="  • Hooks after early return: Move all hooks above ALL return statements
    All hooks must run on every render in the same order
"
  fi
fi

if [[ "$TOTAL_WARNINGS" -gt 0 ]]; then
  MESSAGE+="
⚠️  Hook Dependency Warnings ($TOTAL_WARNINGS):
"

  WARNING_MESSAGES=$(echo "$WARNINGS" | jq -r '.[].message' 2>/dev/null)

  while IFS= read -r line; do
    MESSAGE+="$line
"
  done < <(echo "$WARNINGS" | jq -r '.[] | "   Line \(.line):\(.column) - \(.message)"' 2>/dev/null)

  MESSAGE+="
These warnings indicate missing dependencies that can cause stale closures and bugs.

HOW TO FIX:
  • Add all referenced variables to dependency array
  • Or use useCallback/useMemo to stabilize references
  • Or move constants outside component if they never change
  • Reference: https://react.dev/reference/react/useEffect#specifying-reactive-dependencies

"
fi

MESSAGE+="
⚠️  REQUIRED ACTIONS:
  1. Read the file you just wrote to see violations in context
  2. Apply the fixes described above for each violation type
  3. Ensure ALL hooks are called at top level, in same order, every render
  4. Test the fixed code to verify it works correctly
  5. Never repeat these mistakes - hooks MUST follow these rules

"

if [[ ${#RECOMMENDED_SKILLS[@]} -gt 0 ]]; then
  UNIQUE_SKILLS=($(printf '%s\n' "${RECOMMENDED_SKILLS[@]}" | sort -u))
  MESSAGE+="Additional resources:
"
  for skill in "${UNIQUE_SKILLS[@]}"; do
    MESSAGE+="   /skill $skill
"
  done
  MESSAGE+="
"
fi

MESSAGE+="📚 Reference: https://react.dev/reference/rules/rules-of-hooks
"

if [[ "$TOTAL_ERRORS" -gt 0 ]]; then
  posttooluse_respond "block" "$MESSAGE"
  finish_hook 0
else
  posttooluse_respond "" "" "$MESSAGE"
  finish_hook 0
fi

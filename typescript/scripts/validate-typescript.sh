#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "typescript" "PostToolUse"

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

FILE_EXT="${FILE_PATH##*.}"
if [[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" && "$FILE_EXT" != "js" && "$FILE_EXT" != "jsx" ]]; then
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

if echo "$CODE_CONTENT" | grep -qE ': any\b|<any>|= any\b| any\['; then
  WARNINGS+=("Type Safety: 'any' type usage - consider 'unknown' with type guards")
  RECOMMENDED_SKILLS+=("avoiding-any-types")
fi

if echo "$CODE_CONTENT" | grep -qE ' as [A-Z]'; then
  if ! echo "$CODE_CONTENT" | grep -qE 'as const|as readonly'; then
    WARNINGS+=("Type Safety: Type assertion detected - ensure validation before assertion")
    RECOMMENDED_SKILLS+=("validating-type-assertions")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '<T\s*>|<T\s*=\s*any>|<T\s*,|<T\s+extends'; then
  if echo "$CODE_CONTENT" | grep -qE '<T\s*>|<T\s*=\s*any>'; then
    if ! echo "$CODE_CONTENT" | grep -qE '<T\s+extends'; then
      WARNINGS+=("Type Safety: Generic without constraints - add 'extends' constraint")
      RECOMMENDED_SKILLS+=("using-generics")
    fi
  fi
fi

if echo "$CODE_CONTENT" | grep -qF '!.' || echo "$CODE_CONTENT" | grep -qF '![' || echo "$CODE_CONTENT" | grep -qF '!)' || echo "$CODE_CONTENT" | grep -qF '!;'; then
  WARNINGS+=("Deprecated: Non-null assertion operator (!) - use type guards instead")
  RECOMMENDED_SKILLS+=("avoiding-non-null-assertions")
fi

if echo "$CODE_CONTENT" | grep -qE '<[a-zA-Z][a-zA-Z0-9]*>\s*[a-zA-Z_$"{]'; then
  if ! echo "$CODE_CONTENT" | grep -qE '<[a-zA-Z][a-zA-Z0-9]*\s+extends|<T\s*>|<T\s*,|<.*>\s*\(|interface.*<|class.*<|type.*<|function.*<'; then
    WARNINGS+=("Deprecated: Angle-bracket type assertion (<Type>value) - use 'as Type' syntax")
    RECOMMENDED_SKILLS+=("avoiding-angle-bracket-assertions")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\.substr\s*\('; then
  WARNINGS+=("Deprecated API: .substr() is deprecated - use .slice()")
fi

if echo "$CODE_CONTENT" | grep -qE '\bescape\s*\('; then
  WARNINGS+=("Deprecated API: escape() is deprecated - use encodeURIComponent()")
fi

if echo "$CODE_CONTENT" | grep -qE '\bunescape\s*\('; then
  WARNINGS+=("Deprecated API: unescape() is deprecated - use decodeURIComponent()")
fi

if echo "$CODE_CONTENT" | grep -qE '\bnamespace\s+\w+'; then
  WARNINGS+=("Best Practice: 'namespace' is discouraged - use ES modules")
fi

if echo "$CODE_CONTENT" | grep -qE '///\s*<reference'; then
  WARNINGS+=("Best Practice: Triple-slash directives discouraged - use ES imports")
fi

if echo "$CODE_CONTENT" | grep -qE '\beval\s*\('; then
  CRITICAL_VIOLATIONS+=("Security: eval() usage detected")
fi

if echo "$CODE_CONTENT" | grep -qE '\.innerHTML\s*=(?!\s*["\x27]{2})'; then
  WARNINGS+=("Security: .innerHTML usage - validate/sanitize input to prevent XSS")
  RECOMMENDED_SKILLS+=("sanitizing-user-inputs")
fi

if echo "$CODE_CONTENT" | grep -qE 'new Function\s*\('; then
  CRITICAL_VIOLATIONS+=("Security: Function constructor usage - avoid dynamic code execution")
fi

if grep -qE "(export\s+)?(async\s+)?function\s+\w+.*Request|route\s*:|app\.(get|post|put|delete)" "$FILE_PATH"; then
  if ! echo "$CODE_CONTENT" | grep -qE '\.(safeParse|parse)\s*\(|validate\w*\s*\(|schema\.(parse|safeParse)|z\.(string|number|object)'; then
    WARNINGS+=("API Route: Missing input validation on API endpoint")
    RECOMMENDED_SKILLS+=("sanitizing-user-inputs")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\binterface\s+\w+.*\{'; then
  if echo "$CODE_CONTENT" | grep -qE '\btype\s+\w+.*=.*\{'; then
    RECOMMENDED_SKILLS+=("diagnosing-type-errors")
  fi
fi

if echo "$CODE_CONTENT" | grep -qE '\benum\s+\w+'; then
  WARNINGS+=("Best Practice: Consider const objects over enums for better tree-shaking")
fi

TS_VALIDATOR="${SCRIPT_DIR}/validate-typescript-compiler.js"
if [[ ! -f "$TS_VALIDATOR" ]]; then
  TS_VALIDATOR="${CLAUDE_MARKETPLACE_ROOT}/typescript/scripts/validate-typescript-compiler.js"
fi

if [[ -f "$TS_VALIDATOR" ]] && command -v node >/dev/null 2>&1; then
  TSC_JSON=$(node "$TS_VALIDATOR" "$FILE_PATH" 2>&1 || true)
  if echo "$TSC_JSON" | grep -q '"valid":false'; then
    TOTAL_ERRORS=$(echo "$TSC_JSON" | grep -o '"totalErrors":[0-9]*' | cut -d: -f2 || echo "0")
    TOTAL_WARNINGS=$(echo "$TSC_JSON" | grep -o '"totalWarnings":[0-9]*' | cut -d: -f2 || echo "0")

    if [[ "$TOTAL_ERRORS" -gt 0 ]]; then
      while read -r line col message; do
        if [[ -n "$message" ]]; then
          CRITICAL_VIOLATIONS+=("Type Error (line $line): $message")
        fi
      done < <(echo "$TSC_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for v in data.get('errors', []):
        print(f\"{v.get('line', 0)} {v.get('column', 0)} {v.get('message', '')}\")
except:
    pass
" 2>/dev/null || true)
      RECOMMENDED_SKILLS+=("resolving-type-errors")
    fi

    if [[ "$TOTAL_WARNINGS" -gt 0 ]]; then
      while read -r line col message; do
        if [[ -n "$message" ]]; then
          WARNINGS+=("Type Warning (line $line): $message")
        fi
      done < <(echo "$TSC_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for w in data.get('warnings', []):
        print(f\"{w.get('line', 0)} {w.get('column', 0)} {w.get('message', '')}\")
except:
    pass
" 2>/dev/null || true)
    fi
  fi
fi

TOTAL_ISSUES=$((${#CRITICAL_VIOLATIONS[@]} + ${#WARNINGS[@]}))

if [ $TOTAL_ISSUES -gt 0 ] || [ ${#RECOMMENDED_SKILLS[@]} -gt 0 ]; then
  MESSAGE="TypeScript ($TOTAL_ISSUES issues)

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
⚠️  DO NOT write more TypeScript code without learning these patterns.
"
  fi

  posttooluse_respond "" "" "$MESSAGE"
  finish_hook 0
fi

log_info "No TypeScript issues in $FILE_PATH"
posttooluse_respond
finish_hook 0

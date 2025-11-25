#!/usr/bin/env bash

set -euo pipefail

OUTPUT_FORMAT="json"

usage() {
  cat <<EOF
USAGE: validate-hook-infrastructure.sh [OPTIONS] <hook-script>

Validates that a hook script uses the standardized marketplace-utils infrastructure.

Options:
  --summary    Output one-line summary instead of full JSON
  --json       Output full JSON (default)
  -h, --help   Show this help

Required patterns (from hook-lifecycle.sh):
  - Sources hook-lifecycle.sh
  - Calls init_hook()
  - Uses finish_hook() or response helpers

Exit codes:
  0 - All required checks passed
  1 - One or more required checks failed
  2 - Usage error
EOF
  exit 2
}

[[ $# -lt 1 ]] && usage

HOOK_SCRIPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    --summary)
      OUTPUT_FORMAT="summary"
      shift
      ;;
    --json)
      OUTPUT_FORMAT="json"
      shift
      ;;
    *)
      if [[ -z "$HOOK_SCRIPT" ]]; then
        HOOK_SCRIPT="$1"
      else
        echo "ERROR: Unexpected argument: $1" >&2
        usage
      fi
      shift
      ;;
  esac
done

[[ -z "$HOOK_SCRIPT" ]] && usage

if [[ ! -f "$HOOK_SCRIPT" ]]; then
  echo "ERROR: Hook script not found: $HOOK_SCRIPT" >&2
  exit 2
fi

CHECKS=()
ISSUES=()

check_pattern() {
  local name="$1"
  local pattern="$2"
  local severity="${3:-error}"
  local recommendation="${4:-}"

  if grep -qE "$pattern" "$HOOK_SCRIPT"; then
    CHECKS+=("{\"name\": \"$name\", \"status\": \"pass\"}")
    return 0
  else
    CHECKS+=("{\"name\": \"$name\", \"status\": \"fail\"}")
    local issue
    if [[ -n "$recommendation" ]]; then
      issue=$(jq -n \
        --arg sev "$severity" \
        --arg chk "$name" \
        --arg rec "$recommendation" \
        '{severity: $sev, check: $chk, recommendation: $rec}')
    else
      issue=$(jq -n \
        --arg sev "$severity" \
        --arg chk "$name" \
        '{severity: $sev, check: $chk}')
    fi
    ISSUES+=("$issue")
    return 1
  fi
}

if [[ -x "$HOOK_SCRIPT" ]]; then
  CHECKS+=('{"name": "executable", "status": "pass"}')
else
  CHECKS+=('{"name": "executable", "status": "fail"}')
  ISSUES+=("$(jq -n --arg path "$HOOK_SCRIPT" '{severity: "error", check: "executable", recommendation: ("Run: chmod +x " + $path)}')")
fi

check_pattern \
  "sources_hook_lifecycle" \
  'source.*(hook-lifecycle\.sh|"\$.*hook-lifecycle\.sh")|\..*hook-lifecycle\.sh' \
  "error" \
  "Add: source \"\${SCRIPT_DIR}/../../../marketplace-utils/hook-lifecycle.sh\"" || true

check_pattern \
  "calls_init_hook" \
  'init_hook[[:space:]]' \
  "error" \
  "Add: init_hook \"plugin-name\" \"hook-event\"" || true

check_pattern \
  "uses_response_or_finish" \
  'pretooluse_respond|posttooluse_respond|stop_respond|inject_context|finish_hook' \
  "error" \
  "Use finish_hook or a response helper (pretooluse_respond, posttooluse_respond, inject_context)" || true

check_pattern \
  "reads_input" \
  'read_hook_input|get_input_field|HOOK_INPUT|\$1|\$\{1' \
  "warning" \
  "Consider using read_hook_input() and get_input_field() for JSON input parsing" || true

if grep -qE 'has_shown_recommendation|mark_recommendation_shown|has_passed_validation|mark_validation_passed|get_session_value|set_session_value|get_plugin_value|set_plugin_value' "$HOOK_SCRIPT"; then
  CHECKS+=('{"name": "session_via_lifecycle", "status": "pass", "note": "Session functions available via hook-lifecycle.sh"}')
fi

if grep -qE 'is_typescript_file|is_javascript_file|is_test_file|is_component_file|is_hook_file|is_config_file|is_server_file|detect_framework|get_file_type' "$HOOK_SCRIPT"; then
  check_pattern \
    "sources_file_detection" \
    'source.*file-detection\.sh|\..*file-detection\.sh' \
    "warning" \
    "Source file-detection.sh when using file detection functions (not included in hook-lifecycle.sh)" || true
fi

if grep -qE 'json_escape|json_bool|json_number|json_string|json_array|json_object|json_get|json_set|json_merge' "$HOOK_SCRIPT"; then
  check_pattern \
    "sources_json_utils" \
    'source.*json-utils\.sh|\..*json-utils\.sh' \
    "warning" \
    "Source json-utils.sh when using JSON utility functions (not included in hook-lifecycle.sh)" || true
fi

if grep -qE 'log_info|log_warn|log_error|log_debug' "$HOOK_SCRIPT"; then
  CHECKS+=('{"name": "uses_logging", "status": "pass", "note": "Logging available via hook-lifecycle.sh"}')
else
  CHECKS+=('{"name": "uses_logging", "status": "fail"}')
  ISSUES+=("$(jq -n '{severity: "warning", check: "uses_logging", recommendation: "Add log_info/log_warn/log_error/log_debug calls for debugging"}')")
fi

if grep -qE 'fatal_error' "$HOOK_SCRIPT"; then
  CHECKS+=('{"name": "uses_error_reporting", "status": "pass", "note": "Error reporting available via hook-lifecycle.sh"}')
fi

if grep -qE 'echo.*hookSpecificOutput|printf.*hookSpecificOutput' "$HOOK_SCRIPT"; then
  if ! grep -qE 'inject_context|pretooluse_respond|posttooluse_respond|stop_respond' "$HOOK_SCRIPT"; then
    CHECKS+=('{"name": "no_raw_json_output", "status": "fail"}')
    ISSUES+=("$(jq -n '{severity: "error", check: "no_raw_json_output", recommendation: "Use inject_context() or response helpers instead of raw JSON output - they provide automatic logging"}')")
  fi
fi

if grep -qE 'inject_context|pretooluse_respond|posttooluse_respond' "$HOOK_SCRIPT"; then
  CHECKS+=('{"name": "uses_context_helpers", "status": "pass", "note": "Context helpers provide automatic logging of messages to Claude"}')
fi

PASS_COUNT=0
FAIL_COUNT=0

for check in "${CHECKS[@]}"; do
  if echo "$check" | grep -q '"status": "pass"'; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

COMPLIANT="true"
ERROR_COUNT=0
for issue in "${ISSUES[@]}"; do
  if echo "$issue" | grep -q '"severity": "error"'; then
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done
[[ $ERROR_COUNT -gt 0 ]] && COMPLIANT="false"

CHECKS_JSON=$(printf '%s\n' "${CHECKS[@]}" | jq -s '.')
ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -s '.' 2>/dev/null || echo '[]')

if [[ "$OUTPUT_FORMAT" == "summary" ]]; then
  HOOK_NAME=$(basename "$HOOK_SCRIPT")
  if [[ "$COMPLIANT" == "true" ]]; then
    printf "✅ %-40s passed=%d/%d\n" "$HOOK_NAME" "$PASS_COUNT" "$((PASS_COUNT + FAIL_COUNT))"
  else
    ERROR_LIST=$(printf '%s\n' "${ISSUES[@]}" | jq -r 'select(.severity == "error") | .check' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    printf "❌ %-40s passed=%d/%d errors=[%s]\n" "$HOOK_NAME" "$PASS_COUNT" "$((PASS_COUNT + FAIL_COUNT))" "$ERROR_LIST"
  fi
else
  jq -n \
    --arg review_type "hook_infrastructure" \
    --arg hook "$(basename "$HOOK_SCRIPT")" \
    --arg path "$HOOK_SCRIPT" \
    --argjson checks "$CHECKS_JSON" \
    --argjson issues "$ISSUES_JSON" \
    --argjson pass_count "$PASS_COUNT" \
    --argjson fail_count "$FAIL_COUNT" \
    --argjson compliant "$COMPLIANT" \
    '{
      review_type: $review_type,
      hook: $hook,
      path: $path,
      summary: {passed: $pass_count, failed: $fail_count},
      checks: $checks,
      issues: $issues,
      compliant: $compliant
    }'
fi

[[ "$COMPLIANT" == "true" ]]

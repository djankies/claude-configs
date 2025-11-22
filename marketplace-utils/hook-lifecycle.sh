#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/platform-compat.sh"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/error-reporting.sh"
source "${SCRIPT_DIR}/session-management.sh"

init_hook() {
  local plugin_name="$1"
  local hook_name="$2"

  if [[ ! "$plugin_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    fatal_error "INVALID_PLUGIN_NAME" "Invalid plugin name: $plugin_name"
  fi

  check_dependencies || log_warn "Some dependencies missing - functionality may be limited"

  if [[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]]; then
    log_info "Running in remote/web environment"
  fi

  init_session "$plugin_name"

  export PLUGIN_NAME="$plugin_name"
  export HOOK_NAME="$hook_name"
  export HOOK_EVENT="${HOOK_EVENT:-unknown}"
  export SESSION_FILE="${CLAUDE_SESSION_FILE:-}"

  log_debug "Hook initialized: $PLUGIN_NAME/$HOOK_NAME"
}

read_hook_input() {
  local input=""

  if [[ -t 0 ]]; then
    input=""
  else
    input=$(cat)
  fi

  export HOOK_INPUT="$input"
  echo "$input"
}

get_input_field() {
  local path="$1"

  if [[ -z "${HOOK_INPUT:-}" ]]; then
    echo ""
    return
  fi

  echo "$HOOK_INPUT" | jq -r ".${path} // empty" 2>/dev/null || echo ""
}

pretooluse_respond() {
  local decision="${1:-allow}"
  local reason="${2:-}"
  local updated_input="${3:-}"

  jq -n \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --argjson input "${updated_input:-null}" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: $decision
      }
    }
    | if $reason != "" then .hookSpecificOutput.permissionDecisionReason = $reason else . end
    | if $input != null then .hookSpecificOutput.updatedInput = $input else . end'
}

posttooluse_respond() {
  local decision="${1:-}"
  local reason="${2:-}"
  local context="${3:-}"

  jq -n \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --arg context "$context" \
    '{}
    | if $decision != "" then . + {decision: $decision, reason: $reason} else . end
    | if $context != "" then . + {hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $context}} else . end'
}

stop_respond() {
  local decision="${1:-}"
  local reason="${2:-}"

  if [[ "$decision" == "block" && -z "$reason" ]]; then
    fatal_error "MISSING_STOP_REASON" "Stop decision 'block' requires a reason"
  fi

  if [[ -n "$decision" ]]; then
    jq -n \
      --arg decision "$decision" \
      --arg reason "$reason" \
      '{decision: $decision, reason: $reason}'
  else
    echo "{}"
  fi
}

inject_context() {
  local context="$1"
  local hook_event="${2:-${HOOK_EVENT:-SessionStart}}"

  jq -n \
    --arg context "$context" \
    --arg event "$hook_event" \
    '{hookSpecificOutput: {hookEventName: $event, additionalContext: $context}}'
}

validate_file_path() {
  local path="$1"

  if [[ "$path" =~ \.\. ]]; then
    fatal_error "SECURITY_PATH_TRAVERSAL" "Path contains ..: $path"
  fi

  if [[ ! "$path" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
    log_warn "Suspicious characters in path: $path"
  fi

  return 0
}

is_sensitive_file() {
  local file="$1"

  case "$file" in
    */.env|*/.env.*|*/.*_history)
      return 0
      ;;
    */.git/*|*/.ssh/*|*/id_rsa|*/id_ed25519)
      return 0
      ;;
    */credentials.json|*/serviceAccount.json|*/*.pem|*/*.key)
      return 0
      ;;
    */node_modules/*|*/vendor/*|*/.venv/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

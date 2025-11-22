#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/platform-compat.sh"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/error-reporting.sh"
source "${SCRIPT_DIR}/session-management.sh"

trap 'log_debug "SIGPIPE received in hook-lifecycle.sh at line $LINENO, exiting gracefully"; exit 0' PIPE

init_hook() {
  local plugin_name="$1"
  local hook_name="$2"
  local start_time=$(date +%s%3N 2>/dev/null || date +%s000)

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
  export HOOK_EVENT="$hook_name"
  export SESSION_FILE="${CLAUDE_SESSION_FILE:-}"
  export HOOK_START_TIME="$start_time"

  local elapsed=$(($(date +%s%3N 2>/dev/null || date +%s000) - start_time))
  log_debug "Hook initialized: $PLUGIN_NAME/$HOOK_NAME in ${elapsed}ms"
}

finish_hook() {
  local exit_code="${1:-0}"

  if [[ -n "${HOOK_START_TIME:-}" ]]; then
    local end_time=$(date +%s%3N 2>/dev/null || date +%s000)
    local total_elapsed=$((end_time - HOOK_START_TIME))

    if [[ $exit_code -eq 0 ]]; then
      log_info "Hook completed: $PLUGIN_NAME/$HOOK_NAME in ${total_elapsed}ms"
    else
      log_error "Hook failed: $PLUGIN_NAME/$HOOK_NAME after ${total_elapsed}ms with exit code $exit_code"
    fi
  fi

  exit "$exit_code"
}

read_hook_input() {
  local input=""

  if [[ -t 0 ]]; then
    input=""
  else
    if command -v timeout >/dev/null 2>&1; then
      if ! input=$(timeout 10s cat 2>/dev/null); then
        log_warning "Stdin read timed out after 10s" "hook=$HOOK_NAME" "plugin=$PLUGIN_NAME"
        input=""
      fi
    else
      input=$(cat 2>/dev/null || echo "")
    fi
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

#!/usr/bin/env bash

trap 'echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [DEBUG] SIGPIPE received in error-reporting.sh at line $LINENO, exiting gracefully" >&2; exit 0' PIPE

CLAUDE_SESSION_PID="${CLAUDE_SESSION_PID:-$PPID}"
ERROR_JOURNAL="${ERROR_JOURNAL:-/tmp/claude-errors-${CLAUDE_SESSION_PID}.jsonl}"
PLUGIN_NAME="${PLUGIN_NAME:-}"
HOOK_NAME="${HOOK_NAME:-}"

get_call_stack() {
  local frame=0
  local frames=()
  local line

  while caller $frame >/dev/null 2>&1; do
    line=$(caller $frame)
    frames+=("$line")
    frame=$((frame + 1))
  done

  jq -n -c --arg a "${frames[*]}" '$a | split(" ") | map(select(length > 0))'
}

report_error_internal() {
  local level="$1"
  local code="$2"
  local message="$3"
  local context="$4"
  if [[ -z "$context" ]]; then
    context="{}"
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")

  local stack
  stack=$(get_call_stack)

  local error_json
  error_json=$(jq -n -c \
    --arg ts "$timestamp" \
    --arg plugin "$PLUGIN_NAME" \
    --arg hook "$HOOK_NAME" \
    --arg lvl "$level" \
    --arg code "$code" \
    --arg msg "$message" \
    --argjson ctx "$context" \
    --argjson stack "$stack" \
    '{
      timestamp: $ts,
      plugin: $plugin,
      hook: $hook,
      level: $lvl,
      code: $code,
      message: $msg,
      context: $ctx,
      stack: $stack
    }')

  if command -v flock >/dev/null 2>&1; then
    {
      flock -x 200
      echo "$error_json" >> "$ERROR_JOURNAL"
    } 200>>"${ERROR_JOURNAL}.lock"
  else
    echo "$error_json" >> "$ERROR_JOURNAL"
  fi

  if [[ -n "${log_error:-}" ]]; then
    log_error "[$code] $message"
  fi
}

report_error() {
  local code="$1"
  local message="$2"
  local context="${3:-}"

  report_error_internal "ERROR" "$code" "$message" "$context"
}

report_warning() {
  local code="$1"
  local message="$2"
  local context="${3:-}"

  report_error_internal "WARN" "$code" "$message" "$context"
}

fatal_error() {
  local code="$1"
  local message="$2"
  local context="${3:-}"

  report_error_internal "FATAL" "$code" "$message" "$context"

  if [[ -n "${user_message:-}" ]]; then
    user_message "FATAL ERROR [$code]: $message"
  else
    echo "FATAL ERROR [$code]: $message" >&2
  fi

  exit 2
}

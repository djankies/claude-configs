#!/usr/bin/env bash

CLAUDE_SESSION_PID="${CLAUDE_SESSION_PID:-$$}"
LOG_FILE="${LOG_FILE:-/tmp/claude-session-${CLAUDE_SESSION_PID}.log}"
PLUGIN_NAME="${PLUGIN_NAME:-unknown}"
HOOK_NAME="${HOOK_NAME:-unknown}"

declare -A LOG_LEVELS=(
  ["DEBUG"]=0
  ["INFO"]=1
  ["WARN"]=2
  ["ERROR"]=3
  ["FATAL"]=4
)

get_log_level_value() {
  local level="$1"
  echo "${LOG_LEVELS[$level]:-0}"
}

should_log() {
  local message_level="$1"
  local min_level="${2:-WARN}"

  local message_value
  local min_value
  message_value=$(get_log_level_value "$message_level")
  min_value=$(get_log_level_value "$min_level")

  [[ $message_value -ge $min_value ]]
}

log_message() {
  local level="$1"
  local message="$2"
  local component="${3:-${HOOK_NAME:-unknown}}"

  local min_level="${CLAUDE_DEBUG_LEVEL:-WARN}"

  if ! should_log "$level" "$min_level"; then
    return 0
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")
  local log_line="[$timestamp] [$PLUGIN_NAME] [$level] [$component] $message"

  echo "$log_line" >> "$LOG_FILE"
}

log_debug() {
  log_message "DEBUG" "$1" "${2:-}"
}

log_info() {
  log_message "INFO" "$1" "${2:-}"
}

log_warn() {
  log_message "WARN" "$1" "${2:-}"
}

log_error() {
  log_message "ERROR" "$1" "${2:-}"
}

log_fatal() {
  log_message "FATAL" "$1" "${2:-}"
}

user_message() {
  echo "$1" >&2
}

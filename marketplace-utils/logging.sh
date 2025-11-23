#!/usr/bin/env bash

trap 'echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [DEBUG] SIGPIPE received in logging.sh at line $LINENO, exiting gracefully" >&2; exit 0' PIPE

CLAUDE_SESSION_PID="${CLAUDE_SESSION_PID:-$PPID}"
LOG_FILE="${LOG_FILE:-/tmp/claude-session-${CLAUDE_SESSION_PID}.log}"
PLUGIN_NAME="${PLUGIN_NAME:-}"
HOOK_NAME="${HOOK_NAME:-}"

declare -A LOG_LEVELS=(
  ["DEBUG"]=0
  ["INFO"]=1
  ["WARN"]=2
  ["ERROR"]=3
  ["FATAL"]=4
)

get_log_level_value() {
  local level="$1"
  local value="${LOG_LEVELS[$level]:-}"

  if [[ -z "$value" ]]; then
    echo "WARNING: Unknown log level '$level', defaulting to DEBUG (0)" >&2
    echo "0"
  else
    echo "$value"
  fi
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
  local component="${3:-${HOOK_NAME:-}}"

  local min_level="${CLAUDE_DEBUG_LEVEL:-WARN}"

  if ! should_log "$level" "$min_level"; then
    return 0
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")
  local plugin="${PLUGIN_NAME:-marketplace}"
  local comp="${component:-init}"
  local log_line="[$timestamp] [$plugin] [$level] [$comp] $message"

  if command -v flock >/dev/null 2>&1; then
    {
      flock -x 200
      echo "$log_line" >> "$LOG_FILE"
    } 200>>"${LOG_FILE}.lock"
  else
    echo "$log_line" >> "$LOG_FILE"
  fi
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

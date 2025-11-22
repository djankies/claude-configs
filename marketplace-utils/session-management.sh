#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/platform-compat.sh"

declare SESSION_FILE
declare PLUGIN_NAME
declare LOCK_FD
declare LOCK_DIR

acquire_lock() {
    local file="${1:?File required}"
    local timeout="${2:-5}"
    local lock_file="${file}.lock"

    if ! command -v flock >/dev/null 2>&1; then
        acquire_lock_mkdir "$file" "$timeout"
        return $?
    fi

    LOCK_FD=200
    eval "exec $LOCK_FD>\"$lock_file\""

    if ! flock -x -w "$timeout" "$LOCK_FD" 2>/dev/null; then
        return 1
    fi

    return 0
}

release_lock() {
    if [[ -n "${LOCK_FD:-}" ]]; then
        flock -u "$LOCK_FD" 2>/dev/null || true
        eval "exec ${LOCK_FD}>&-" 2>/dev/null || true
        LOCK_FD=""
    fi
    release_lock_mkdir
}

acquire_lock_mkdir() {
    local file="$1"
    local timeout="${2:-5}"
    LOCK_DIR="${file}.lock.d"
    local waited=0

    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        sleep 0.1
        waited=$((waited + 1))

        if [[ $waited -gt $((timeout * 10)) ]]; then
            return 1
        fi
    done

    return 0
}

release_lock_mkdir() {
    if [[ -n "${LOCK_DIR:-}" && -d "$LOCK_DIR" ]]; then
        rmdir "$LOCK_DIR" 2>/dev/null || true
        LOCK_DIR=""
    fi
}

init_session() {
    local plugin_name="${1:?Plugin name required}"
    PLUGIN_NAME="$plugin_name"
    SESSION_FILE="/tmp/claude-session-${CLAUDE_SESSION_PID:-$$}.json"

    if [[ ! -f "$SESSION_FILE" ]]; then
        cat > "$SESSION_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "pid": $$,
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "plugins": {},
  "metadata": {
    "log_file": "/tmp/claude-session-$$.log",
    "error_journal": "/tmp/claude-errors-$$.jsonl",
    "platform": "$(uname -s | tr '[:upper:]' '[:lower:]')"
  }
}
EOF
    fi

    local temp_file="${SESSION_FILE}.tmp"
    jq ".plugins.\"${plugin_name}\" = {
      \"plugin\": \"${plugin_name}\",
      \"started_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
      \"recommendations_shown\": {},
      \"validations_passed\": {},
      \"custom_data\": {}
    }" "$SESSION_FILE" > "$temp_file"
    mv "$temp_file" "$SESSION_FILE"

    export CLAUDE_SESSION_FILE="$SESSION_FILE"
    export CLAUDE_PLUGIN_NAME="$PLUGIN_NAME"
}

get_session_file() {
    if [[ -n "${SESSION_FILE:-}" ]]; then
        echo "$SESSION_FILE"
    elif [[ -n "${CLAUDE_SESSION_FILE:-}" ]]; then
        echo "$CLAUDE_SESSION_FILE"
    else
        echo "/tmp/claude-session-${CLAUDE_SESSION_PID:-$$}.json"
    fi
}

get_session_value() {
    local key="${1:?Key required}"
    local session_file
    session_file="$(get_session_file)"

    if [[ ! -f "$session_file" ]]; then
        echo ""
        return 1
    fi

    jq -r ".${key} // empty" "$session_file" 2>/dev/null || echo ""
}

set_session_value() {
    local key="${1:?Key required}"
    local value="${2:?Value required}"
    local session_file
    session_file="$(get_session_file)"

    if [[ ! -f "$session_file" ]]; then
        return 1
    fi

    if ! acquire_lock "$session_file"; then
        echo "Cannot update session: lock acquisition failed" >&2
        return 1
    fi

    local temp_file="${session_file}.tmp"
    if ! jq ".${key} = ${value}" "$session_file" > "$temp_file"; then
        release_lock
        echo "Failed to update session key: $key" >&2
        return 1
    fi

    mv "$temp_file" "$session_file"
    release_lock
    return 0
}

set_plugin_value() {
    local plugin="${1:?Plugin name required}"
    local key="${2:?Key required}"
    local value="${3:?Value required}"
    set_session_value "plugins.\"${plugin}\".${key}" "$value"
}

get_plugin_value() {
    local plugin="${1:?Plugin name required}"
    local key="${2:?Key required}"
    get_session_value "plugins.\"${plugin}\".${key}"
}

has_session_key() {
    local key="${1:?Key required}"
    local session_file
    session_file="$(get_session_file)"
    [[ -f "$session_file" ]] && jq -e ".${key}" "$session_file" >/dev/null 2>&1
}

has_shown_recommendation() {
    local plugin="${1:?Plugin name required}"
    local skill_name="${2:?Skill name required}"
    local key="recommendations_shown.\"${skill_name}\""

    local shown
    shown="$(get_plugin_value "$plugin" "$key")"

    [[ "$shown" == "true" ]]
}

mark_recommendation_shown() {
    local plugin="${1:?Plugin name required}"
    local skill_name="${2:?Skill name required}"
    set_plugin_value "$plugin" "recommendations_shown.\"${skill_name}\"" "true"
}

has_passed_validation() {
    local validation_name="${1:?Validation name required}"
    local file_path="${2:-global}"
    local key="validations_passed.\"${file_path}\".\"${validation_name}\""

    local passed
    passed="$(get_session_value "$key")"

    [[ "$passed" == "true" ]]
}

mark_validation_passed() {
    local validation_name="${1:?Validation name required}"
    local file_path="${2:-global}"
    local session_file
    session_file="$(get_session_file)"

    if [[ ! -f "$session_file" ]]; then
        return 1
    fi

    if ! acquire_lock "$session_file"; then
        echo "Cannot update validation status: lock acquisition failed" >&2
        return 1
    fi

    local temp_file="${session_file}.tmp"
    if ! jq ".validations_passed.\"${file_path}\".\"${validation_name}\" = true" "$session_file" > "$temp_file"; then
        release_lock
        echo "Failed to mark validation passed: $validation_name" >&2
        return 1
    fi

    mv "$temp_file" "$session_file"
    release_lock
    return 0
}

set_custom_data() {
    local key="${1:?Key required}"
    local value="${2:?Value required}"
    local session_file
    session_file="$(get_session_file)"

    if [[ ! -f "$session_file" ]]; then
        return 1
    fi

    if ! acquire_lock "$session_file"; then
        echo "Cannot update custom data: lock acquisition failed" >&2
        return 1
    fi

    local temp_file="${session_file}.tmp"
    if ! jq ".custom_data.\"${key}\" = ${value}" "$session_file" > "$temp_file"; then
        release_lock
        echo "Failed to set custom data: $key" >&2
        return 1
    fi

    mv "$temp_file" "$session_file"
    release_lock
    return 0
}

get_custom_data() {
    local key="${1:?Key required}"
    get_session_value "custom_data.\"${key}\""
}

clear_session() {
    local session_file
    session_file="$(get_session_file)"

    if [[ -f "$session_file" ]]; then
        rm -f "$session_file"
    fi
}

get_session_age() {
    local session_file
    session_file="$(get_session_file)"

    if [[ ! -f "$session_file" ]]; then
        echo "-1"
        return
    fi

    local started_at
    started_at="$(get_session_value "started_at")"

    if [[ -z "$started_at" ]]; then
        echo "-1"
        return
    fi

    local started_epoch
    started_epoch=$(get_timestamp_epoch "$started_at")

    if [[ "$started_epoch" == "0" ]]; then
        echo "-1"
        return
    fi

    local now_epoch
    now_epoch=$(get_current_epoch)

    echo $((now_epoch - started_epoch))
}

cleanup_stale_sessions() {
    local max_age_seconds="${1:-86400}"
    local temp_dir
    temp_dir=$(get_temp_dir)

    find "$temp_dir" -name "claude-session-*.json" -type f 2>/dev/null | while read -r file; do
        if [[ -f "$file" ]]; then
            local file_age
            file_age=$(get_file_age "$file")

            if [[ $file_age -gt $max_age_seconds ]]; then
                local pid
                pid=$(echo "$file" | grep -o '[0-9]\+' | tail -1)

                if [[ -n "$pid" ]] && ! ps -p "$pid" >/dev/null 2>&1; then
                    rm -f "$file" "${file}.lock" "${file}.lock.d" 2>/dev/null || true
                fi
            fi
        fi
    done
}

register_cleanup_hook() {
    trap cleanup_session EXIT INT TERM
}

cleanup_session() {
    local session_file
    session_file="$(get_session_file)"

    if [[ -f "$session_file" ]]; then
        rm -f "$session_file" "${session_file}.lock" 2>/dev/null || true
        if [[ -d "${session_file}.lock.d" ]]; then
            rmdir "${session_file}.lock.d" 2>/dev/null || true
        fi
    fi

    release_lock 2>/dev/null || true
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Session Management Utility"
    echo "Usage: source this file and call functions"
    echo ""
    echo "Functions:"
    echo "  init_session <plugin_name>"
    echo "  get_session_value <key>"
    echo "  set_session_value <key> <value>"
    echo "  set_plugin_value <plugin> <key> <value>"
    echo "  get_plugin_value <plugin> <key>"
    echo "  has_session_key <key>"
    echo "  has_shown_recommendation <plugin> <skill_name>"
    echo "  mark_recommendation_shown <plugin> <skill_name>"
    echo "  has_passed_validation <validation_name> [file_path]"
    echo "  mark_validation_passed <validation_name> [file_path]"
    echo "  set_custom_data <key> <value>"
    echo "  get_custom_data <key>"
    echo "  clear_session"
    echo "  get_session_age"
    echo "  acquire_lock <file> [timeout]"
    echo "  release_lock"
    echo "  cleanup_stale_sessions [max_age_seconds]"
    echo "  register_cleanup_hook"
    echo "  cleanup_session"
fi

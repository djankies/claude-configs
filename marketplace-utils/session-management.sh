#!/usr/bin/env bash

set -euo pipefail

declare STATE_FILE
declare PLUGIN_NAME

init_session() {
    local plugin_name="${1:?Plugin name required}"
    PLUGIN_NAME="$plugin_name"
    STATE_FILE="/tmp/claude-${plugin_name}-session-$$.json"

    cat > "$STATE_FILE" <<EOF
{
  "plugin": "${plugin_name}",
  "session_id": "$$-$(date +%s)",
  "pid": $$,
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "recommendations_shown": {},
  "validations_passed": {},
  "custom_data": {}
}
EOF

    export CLAUDE_SESSION_FILE="$STATE_FILE"
    export CLAUDE_PLUGIN_NAME="$PLUGIN_NAME"
}

get_session_file() {
    if [[ -n "${STATE_FILE:-}" ]]; then
        echo "$STATE_FILE"
    elif [[ -n "${CLAUDE_SESSION_FILE:-}" ]]; then
        echo "$CLAUDE_SESSION_FILE"
    else
        echo "/tmp/claude-${PLUGIN_NAME:-unknown}-session-$$.json"
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

    local temp_file="${session_file}.tmp"
    jq ".${key} = ${value}" "$session_file" > "$temp_file"
    mv "$temp_file" "$session_file"
}

has_shown_recommendation() {
    local file_path="${1:?File path required}"
    local skill_name="${2:?Skill name required}"
    local key="recommendations_shown.\"${file_path}\".\"${skill_name}\""

    local shown
    shown="$(get_session_value "$key")"

    [[ "$shown" == "true" ]]
}

mark_recommendation_shown() {
    local file_path="${1:?File path required}"
    local skill_name="${2:?Skill name required}"
    local session_file
    session_file="$(get_session_file)"

    if [[ ! -f "$session_file" ]]; then
        return 1
    fi

    local temp_file="${session_file}.tmp"
    jq ".recommendations_shown.\"${file_path}\".\"${skill_name}\" = true" "$session_file" > "$temp_file"
    mv "$temp_file" "$session_file"
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

    local temp_file="${session_file}.tmp"
    jq ".validations_passed.\"${file_path}\".\"${validation_name}\" = true" "$session_file" > "$temp_file"
    mv "$temp_file" "$session_file"
}

set_custom_data() {
    local key="${1:?Key required}"
    local value="${2:?Value required}"
    local session_file
    session_file="$(get_session_file)"

    if [[ ! -f "$session_file" ]]; then
        return 1
    fi

    local temp_file="${session_file}.tmp"
    jq ".custom_data.\"${key}\" = ${value}" "$session_file" > "$temp_file"
    mv "$temp_file" "$session_file"
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
    started_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" "+%s" 2>/dev/null || echo "0")

    local now_epoch
    now_epoch=$(date "+%s")

    echo $((now_epoch - started_epoch))
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Session Management Utility"
    echo "Usage: source this file and call functions"
    echo ""
    echo "Functions:"
    echo "  init_session <plugin_name>"
    echo "  get_session_value <key>"
    echo "  set_session_value <key> <value>"
    echo "  has_shown_recommendation <file_path> <skill_name>"
    echo "  mark_recommendation_shown <file_path> <skill_name>"
    echo "  has_passed_validation <validation_name> [file_path]"
    echo "  mark_validation_passed <validation_name> [file_path]"
    echo "  set_custom_data <key> <value>"
    echo "  get_custom_data <key>"
    echo "  clear_session"
    echo "  get_session_age"
fi

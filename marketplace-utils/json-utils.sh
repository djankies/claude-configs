#!/usr/bin/env bash

set -euo pipefail
trap 'exit 0' PIPE

json_escape() {
    local str="${1:-}"

    printf '%s' "$str" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

json_bool() {
    local value="${1:-false}"

    case "${value,,}" in
        true|yes|1)
            echo "true"
            ;;
        false|no|0|"")
            echo "false"
            ;;
        *)
            echo "false"
            ;;
    esac
}

json_number() {
    local value="${1:-0}"

    if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$value"
    else
        echo "0"
    fi
}

json_string() {
    local str="${1:-}"
    local escaped
    escaped=$(json_escape "$str")

    echo "\"$escaped\""
}

json_array() {
    echo -n "["

    local first=true
    for item in "$@"; do
        if [[ "$first" == "false" ]]; then
            echo -n ","
        fi
        first=false

        if [[ "$item" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -n "$item"
        elif [[ "$item" == "true" || "$item" == "false" || "$item" == "null" ]]; then
            echo -n "$item"
        elif [[ "$item" == "{"* || "$item" == "["* ]]; then
            echo -n "$item"
        else
            local escaped
            escaped=$(json_escape "$item")
            echo -n "\"$escaped\""
        fi
    done

    echo -n "]"
}

json_object() {
    echo -n "{"

    local first=true
    while [[ $# -gt 0 ]]; do
        local key="$1"
        shift

        if [[ $# -eq 0 ]]; then
            echo "ERROR: json_object requires key-value pairs" >&2
            return 1
        fi

        local value="$1"
        shift

        if [[ "$first" == "false" ]]; then
            echo -n ","
        fi
        first=false

        local escaped_key
        escaped_key=$(json_escape "$key")
        echo -n "\"$escaped_key\":"

        if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -n "$value"
        elif [[ "$value" == "true" || "$value" == "false" || "$value" == "null" ]]; then
            echo -n "$value"
        elif [[ "$value" == "{"* || "$value" == "["* ]]; then
            echo -n "$value"
        else
            local escaped_value
            escaped_value=$(json_escape "$value")
            echo -n "\"$escaped_value\""
        fi
    done

    echo -n "}"
}

json_pretty() {
    local json="${1:-}"

    echo "$json" | jq '.' 2>/dev/null || echo "$json"
}

json_minify() {
    local json="${1:-}"

    echo "$json" | jq -c '.' 2>/dev/null || echo "$json"
}

json_merge() {
    local json1="${1:?First JSON required}"
    local json2="${2:?Second JSON required}"

    echo "$json1 $json2" | jq -s '.[0] * .[1]' 2>/dev/null || echo "{}"
}

json_get() {
    local json="${1:?JSON required}"
    local key="${2:?Key required}"

    echo "$json" | jq -r ".${key} // empty" 2>/dev/null || echo ""
}

json_set() {
    local json="${1:?JSON required}"
    local key="${2:?Key required}"
    local value="${3:?Value required}"

    if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || \
       [[ "$value" == "true" ]] || \
       [[ "$value" == "false" ]] || \
       [[ "$value" == "null" ]] || \
       [[ "$value" == "{"* ]] || \
       [[ "$value" == "["* ]]; then
        echo "$json" | jq ".${key} = ${value}" 2>/dev/null || echo "$json"
    else
        local escaped_value
        escaped_value=$(json_escape "$value")
        echo "$json" | jq ".${key} = \"${escaped_value}\"" 2>/dev/null || echo "$json"
    fi
}

json_has_key() {
    local json="${1:?JSON required}"
    local key="${2:?Key required}"

    echo "$json" | jq -e ".${key}" >/dev/null 2>&1
}

json_keys() {
    local json="${1:?JSON required}"

    echo "$json" | jq -r 'keys[]' 2>/dev/null || true
}

json_length() {
    local json="${1:?JSON required}"

    echo "$json" | jq 'length' 2>/dev/null || echo "0"
}

json_validate() {
    local json="${1:?JSON required}"

    echo "$json" | jq '.' >/dev/null 2>&1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "JSON Utilities"
    echo "Usage: source this file and call functions"
    echo ""
    echo "Basic Functions:"
    echo "  json_escape <string>"
    echo "  json_bool <value>"
    echo "  json_number <value>"
    echo "  json_string <string>"
    echo ""
    echo "Builders:"
    echo "  json_array <item1> [item2...]"
    echo "  json_object <key1> <val1> [key2] [val2...]"
    echo ""
    echo "Manipulation:"
    echo "  json_pretty <json>"
    echo "  json_minify <json>"
    echo "  json_merge <json1> <json2>"
    echo "  json_get <json> <key>"
    echo "  json_set <json> <key> <value>"
    echo "  json_has_key <json> <key>"
    echo "  json_keys <json>"
    echo "  json_length <json>"
    echo "  json_validate <json>"
    echo ""
    echo "Examples:"
    echo "  json_array \"foo\" \"bar\" \"baz\""
    echo "  json_object \"name\" \"Alice\" \"age\" \"30\" \"active\" \"true\""
    echo "  json_get '{\"name\":\"Bob\"}' \"name\""
fi

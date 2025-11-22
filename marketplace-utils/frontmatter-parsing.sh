#!/usr/bin/env bash

set -euo pipefail

extract_frontmatter() {
    local file="${1:?File path required}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    awk '
        BEGIN { in_frontmatter = 0; started = 0 }
        /^---$/ {
            if (NR == 1) {
                in_frontmatter = 1
                started = 1
                next
            } else if (in_frontmatter) {
                exit
            }
        }
        in_frontmatter { print }
    ' "$file"
}

extract_frontmatter_value() {
    local file="${1:?File path required}"
    local key="${2:?Key required}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    awk -v key="$key" '
        BEGIN { in_frontmatter = 0; found = 0 }
        /^---$/ {
            if (NR == 1) { in_frontmatter = 1; next }
            else if (in_frontmatter) { exit }
        }
        in_frontmatter && $0 ~ "^" key ":" {
            sub("^" key ":[[:space:]]*", "")
            gsub(/"/, "")
            gsub(/'\''/, "")
            print
            found = 1
            exit
        }
    ' "$file"
}

has_frontmatter() {
    local file="${1:?File path required}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    local first_line
    first_line=$(head -n 1 "$file")

    [[ "$first_line" == "---" ]]
}

check_frontmatter_tag() {
    local file="${1:?File path required}"
    local tag="${2:?Tag required}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    awk -v tag="$tag" '
        BEGIN { in_frontmatter = 0 }
        /^---$/ {
            if (NR == 1) { in_frontmatter = 1; next }
            else if (in_frontmatter) { exit }
        }
        in_frontmatter && $0 ~ "^" tag ":[[:space:]]*true" {
            print "true"
            exit
        }
    ' "$file"
}

has_frontmatter_tag() {
    local file="${1:?File path required}"
    local tag="${2:?Tag required}"

    local result
    result=$(check_frontmatter_tag "$file" "$tag")

    [[ "$result" == "true" ]]
}

get_frontmatter_array() {
    local file="${1:?File path required}"
    local key="${2:?Key required}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    awk -v key="$key" '
        BEGIN { in_frontmatter = 0; in_array = 0 }
        /^---$/ {
            if (NR == 1) { in_frontmatter = 1; next }
            else if (in_frontmatter) { exit }
        }
        in_frontmatter && $0 ~ "^" key ":" {
            in_array = 1
            next
        }
        in_frontmatter && in_array && /^[[:space:]]*-/ {
            sub(/^[[:space:]]*-[[:space:]]*/, "")
            gsub(/"/, "")
            gsub(/'\''/, "")
            print
        }
        in_frontmatter && in_array && /^[a-zA-Z]/ {
            exit
        }
    ' "$file"
}

escape_json_string() {
    local str="${1:-}"

    echo "$str" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//'
}

unescape_json_string() {
    local str="${1:-}"

    echo "$str" | sed 's/\\"/"/g; s/\\\\/\\/g'
}

frontmatter_to_json() {
    local file="${1:?File path required}"

    if [[ ! -f "$file" ]]; then
        echo "{}"
        return 1
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        echo "{}"
        return 0
    fi

    echo "{"

    local first=true
    while IFS=: read -r key value; do
        key=$(echo "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

        if [[ -n "$key" && -n "$value" && ! "$key" =~ ^- ]]; then
            if [[ "$first" == "false" ]]; then
                echo ","
            fi
            first=false

            local escaped_key
            escaped_key=$(escape_json_string "$key")
            local escaped_value
            escaped_value=$(escape_json_string "$value")

            echo -n "  \"$escaped_key\": \"$escaped_value\""
        fi
    done <<< "$frontmatter"

    echo ""
    echo "}"
}

validate_frontmatter() {
    local file="${1:?File path required}"
    shift
    local required_keys=("$@")

    if ! has_frontmatter "$file"; then
        echo "ERROR: File does not have frontmatter: $file" >&2
        return 1
    fi

    local missing_keys=()
    for key in "${required_keys[@]}"; do
        local value
        value=$(extract_frontmatter_value "$file" "$key")

        if [[ -z "$value" ]]; then
            missing_keys+=("$key")
        fi
    done

    if [[ ${#missing_keys[@]} -gt 0 ]]; then
        echo "ERROR: Missing required frontmatter keys in $file:" >&2
        for key in "${missing_keys[@]}"; do
            echo "  - $key" >&2
        done
        return 1
    fi

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Frontmatter Parsing Utility"
    echo "Usage: source this file and call functions"
    echo ""
    echo "Functions:"
    echo "  extract_frontmatter <file>"
    echo "  extract_frontmatter_value <file> <key>"
    echo "  has_frontmatter <file>"
    echo "  check_frontmatter_tag <file> <tag>"
    echo "  has_frontmatter_tag <file> <tag>"
    echo "  get_frontmatter_array <file> <key>"
    echo "  escape_json_string <string>"
    echo "  unescape_json_string <string>"
    echo "  frontmatter_to_json <file>"
    echo "  validate_frontmatter <file> <required_key1> [required_key2...]"
    echo ""
    echo "Example:"
    echo "  extract_frontmatter_value SKILL.md name"
    echo "  has_frontmatter_tag SKILL.md review"
fi

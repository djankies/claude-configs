#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/frontmatter-parsing.sh" ]]; then
    source "$SCRIPT_DIR/frontmatter-parsing.sh"
fi

discover_skills() {
    local plugin_dir="${1:?Plugin directory required}"

    if [[ ! -d "$plugin_dir/skills" ]]; then
        echo "[]"
        return 0
    fi

    local skills=()

    while IFS= read -r -d '' skill_file; do
        local skill_dir
        skill_dir=$(dirname "$skill_file")
        local skill_name
        skill_name=$(basename "$skill_dir")

        local skill_info
        skill_info=$(get_skill_metadata "$skill_file")

        if [[ -n "$skill_info" ]]; then
            skills+=("$skill_info")
        fi
    done < <(find "$plugin_dir/skills" -name "SKILL.md" -type f -print0 2>/dev/null || true)

    if [[ ${#skills[@]} -eq 0 ]]; then
        echo "[]"
        return 0
    fi

    echo "["
    for i in "${!skills[@]}"; do
        echo "${skills[$i]}"
        if [[ $i -lt $((${#skills[@]} - 1)) ]]; then
            echo ","
        fi
    done
    echo "]"
}

discover_review_skills() {
    local plugin_dirs=("$@")

    local skills=()

    for plugin_dir in "${plugin_dirs[@]}"; do
        if [[ ! -d "$plugin_dir/skills" ]]; then
            continue
        fi

        local plugin_name
        plugin_name=$(basename "$plugin_dir")

        while IFS= read -r -d '' skill_file; do
            if ! has_frontmatter_tag "$skill_file" "review"; then
                continue
            fi

            local skill_name
            skill_name=$(extract_frontmatter_value "$skill_file" "name")
            local description
            description=$(extract_frontmatter_value "$skill_file" "description")

            local skill_name_escaped
            skill_name_escaped=$(escape_json_string "$skill_name")
            local description_escaped
            description_escaped=$(escape_json_string "$description")

            local skill_json
            skill_json=$(cat <<EOF
    {
      "plugin": "$plugin_name",
      "skill_name": "$skill_name_escaped",
      "description": "$description_escaped",
      "file": "$skill_file"
    }
EOF
)
            skills+=("$skill_json")

        done < <(find "$plugin_dir/skills" -name "SKILL.md" -type f -print0 2>/dev/null || true)
    done

    echo "{"
    echo '  "discovered_skills": ['

    if [[ ${#skills[@]} -gt 0 ]]; then
        for i in "${!skills[@]}"; do
            echo "${skills[$i]}"
            if [[ $i -lt $((${#skills[@]} - 1)) ]]; then
                echo ","
            fi
        done
    fi

    echo "  ]"
    echo "}"
}

get_skill_metadata() {
    local skill_file="${1:?Skill file required}"

    if [[ ! -f "$skill_file" ]]; then
        return 1
    fi

    local skill_dir
    skill_dir=$(dirname "$skill_file")
    local skill_name
    skill_name=$(basename "$skill_dir")

    local name
    name=$(extract_frontmatter_value "$skill_file" "name" 2>/dev/null || echo "$skill_name")
    local description
    description=$(extract_frontmatter_value "$skill_file" "description" 2>/dev/null || echo "")

    local tags=()
    if has_frontmatter_tag "$skill_file" "review"; then
        tags+=("review")
    fi
    if has_frontmatter_tag "$skill_file" "security"; then
        tags+=("security")
    fi
    if has_frontmatter_tag "$skill_file" "testing"; then
        tags+=("testing")
    fi
    if has_frontmatter_tag "$skill_file" "performance"; then
        tags+=("performance")
    fi

    local name_escaped
    name_escaped=$(escape_json_string "$name")
    local description_escaped
    description_escaped=$(escape_json_string "$description")

    echo -n "    {"
    echo -n "\"name\":\"$name_escaped\","
    echo -n "\"description\":\"$description_escaped\","
    echo -n "\"file\":\"$skill_file\","
    echo -n "\"tags\":["

    if [[ ${#tags[@]} -gt 0 ]]; then
        for i in "${!tags[@]}"; do
            echo -n "\"${tags[$i]}\""
            if [[ $i -lt $((${#tags[@]} - 1)) ]]; then
                echo -n ","
            fi
        done
    fi

    echo -n "]"
    echo -n "}"
}

skill_matches_concern() {
    local skill_file="${1:?Skill file required}"
    local concern="${2:?Concern required}"

    case "${concern,,}" in
        review)
            has_frontmatter_tag "$skill_file" "review"
            ;;
        security)
            has_frontmatter_tag "$skill_file" "security"
            ;;
        testing)
            has_frontmatter_tag "$skill_file" "testing"
            ;;
        performance)
            has_frontmatter_tag "$skill_file" "performance"
            ;;
        *)
            local name
            name=$(extract_frontmatter_value "$skill_file" "name")
            [[ "${name,,}" == *"${concern,,}"* ]]
            ;;
    esac
}

find_skills_by_tag() {
    local plugin_dirs=("${@:1:$#-1}")
    local tag="${!#}"

    local skills=()

    for plugin_dir in "${plugin_dirs[@]}"; do
        if [[ ! -d "$plugin_dir/skills" ]]; then
            continue
        fi

        while IFS= read -r -d '' skill_file; do
            if skill_matches_concern "$skill_file" "$tag"; then
                local metadata
                metadata=$(get_skill_metadata "$skill_file")
                skills+=("$metadata")
            fi
        done < <(find "$plugin_dir/skills" -name "SKILL.md" -type f -print0 2>/dev/null || true)
    done

    echo "["
    if [[ ${#skills[@]} -gt 0 ]]; then
        for i in "${!skills[@]}"; do
            echo "${skills[$i]}"
            if [[ $i -lt $((${#skills[@]} - 1)) ]]; then
                echo ","
            fi
        done
    fi
    echo "]"
}

count_skills() {
    local plugin_dir="${1:?Plugin directory required}"

    if [[ ! -d "$plugin_dir/skills" ]]; then
        echo "0"
        return 0
    fi

    find "$plugin_dir/skills" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' '
}

list_skill_names() {
    local plugin_dir="${1:?Plugin directory required}"

    if [[ ! -d "$plugin_dir/skills" ]]; then
        return 0
    fi

    while IFS= read -r -d '' skill_file; do
        local name
        name=$(extract_frontmatter_value "$skill_file" "name" 2>/dev/null)

        if [[ -z "$name" ]]; then
            local skill_dir
            skill_dir=$(dirname "$skill_file")
            name=$(basename "$skill_dir")
        fi

        echo "$name"
    done < <(find "$plugin_dir/skills" -name "SKILL.md" -type f -print0 2>/dev/null || true)
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Skill Discovery Utility"
    echo "Usage: source this file and call functions"
    echo ""
    echo "Functions:"
    echo "  discover_skills <plugin_dir>"
    echo "  discover_review_skills <plugin_dir1> [plugin_dir2...]"
    echo "  get_skill_metadata <skill_file>"
    echo "  skill_matches_concern <skill_file> <concern>"
    echo "  find_skills_by_tag <plugin_dir1> [plugin_dir2...] <tag>"
    echo "  count_skills <plugin_dir>"
    echo "  list_skill_names <plugin_dir>"
    echo ""
    echo "Examples:"
    echo "  discover_skills ./typescript"
    echo "  discover_review_skills ./typescript ./react-19 ./nextjs-16"
    echo "  find_skills_by_tag ./typescript ./react-19 security"
fi

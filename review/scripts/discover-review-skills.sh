#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

extract_frontmatter_value() {
    local file="$1"
    local key="$2"

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

check_review_tag() {
    local file="$1"

    awk '
        BEGIN { in_frontmatter = 0 }
        /^---$/ {
            if (NR == 1) { in_frontmatter = 1; next }
            else if (in_frontmatter) { exit }
        }
        in_frontmatter && /^review:[[:space:]]*true/ {
            print "true"
            exit
        }
    ' "$file"
}

escape_json_string() {
    local str="$1"
    echo "$str" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//'
}

discovered_skills=()

while IFS= read -r -d '' plugin_dir; do
    plugin_name="$(basename "$plugin_dir")"

    [ "$plugin_name" = "review" ] && continue

    while IFS= read -r -d '' skill_file; do
        is_review=$(check_review_tag "$skill_file")

        [ "$is_review" != "true" ] && continue

        skill_name=$(extract_frontmatter_value "$skill_file" "name")
        description=$(extract_frontmatter_value "$skill_file" "description")

        skill_name_escaped=$(escape_json_string "$skill_name")
        description_escaped=$(escape_json_string "$description")

        skill_json=$(cat <<EOF
    {
      "plugin": "$plugin_name",
      "skill_name": "$skill_name_escaped",
      "description": "$description_escaped"
    }
EOF
)
        discovered_skills+=("$skill_json")

    done < <(find "$plugin_dir/skills" -name "SKILL.md" -type f -print0 2>/dev/null || true)

done < <(find "$PARENT_DIR" -maxdepth 1 -type d -print0 2>/dev/null)

echo "{"
echo '  "discovered_skills": ['

if [ ${#discovered_skills[@]} -gt 0 ]; then
    for i in "${!discovered_skills[@]}"; do
        echo "${discovered_skills[$i]}"
        if [ $i -lt $((${#discovered_skills[@]} - 1)) ]; then
            echo ","
        fi
    done
fi

echo "  ]"
echo "}"

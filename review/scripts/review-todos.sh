#!/usr/bin/env bash

set -euo pipefail

MAX_PER_TYPE="${1:-20}"

extensions=("js" "jsx" "ts" "tsx" "mjs" "cjs")
patterns=("TODO" "FIXME" "HACK" "XXX" "NOTE")

ext_pattern=$(IFS="|"; echo "${extensions[*]}")

results=()
for pattern in "${patterns[@]}"; do
    matches=$(find . -type f \
        -regextype posix-extended \
        -regex ".*\.(${ext_pattern})" \
        ! -path "*/node_modules/*" \
        ! -path "*/dist/*" \
        ! -path "*/build/*" \
        ! -path "*/.next/*" \
        ! -path "*/coverage/*" \
        -exec grep -Hn "$pattern:" {} \; 2>/dev/null | head -n "$MAX_PER_TYPE" || true)

    if [ -n "$matches" ]; then
        count=$(echo "$matches" | wc -l | tr -d ' ')
        results+=("=== $pattern: $count found ===")
        results+=("$matches")
        results+=("")
    fi
done

if [ ${#results[@]} -eq 0 ]; then
    echo "No TODO/FIXME/HACK/XXX/NOTE comments found"
    exit 0
fi

for line in "${results[@]}"; do
    echo "$line"
done

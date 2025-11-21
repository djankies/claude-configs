#!/usr/bin/env bash

set -euo pipefail

MIN_LINES="${1:-500}"
MAX_RESULTS="${2:-30}"

extensions=("js" "jsx" "ts" "tsx" "mjs" "cjs")
ext_pattern=$(IFS="|"; echo "${extensions[*]}")

results=()

while IFS= read -r file; do
    [ -z "$file" ] && continue

    lines=$(wc -l < "$file" 2>/dev/null | tr -d ' ')

    if [ "$lines" -ge "$MIN_LINES" ]; then
        results+=("$lines:$file")
    fi
done < <(find . -type f \
    -regextype posix-extended \
    -regex ".*\.(${ext_pattern})" \
    ! -path "*/node_modules/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "*/.next/*" \
    ! -path "*/coverage/*" \
    ! -name "*.test.*" \
    ! -name "*.spec.*" 2>/dev/null)

if [ ${#results[@]} -eq 0 ]; then
    echo "No files larger than ${MIN_LINES} lines found"
    exit 0
fi

sorted=$(printf '%s\n' "${results[@]}" | sort -rn -t: -k1)

result_count=$(echo "$sorted" | wc -l | tr -d ' ')

if [ "$result_count" -gt "$MAX_RESULTS" ]; then
    echo "=== Showing largest ${MAX_RESULTS} of ${result_count} files over ${MIN_LINES} lines ==="
    echo "$sorted" | head -n "$MAX_RESULTS" | while IFS=: read -r lines file; do
        echo "$lines lines: $file"
    done
else
    echo "=== Found $result_count files over ${MIN_LINES} lines ==="
    echo "$sorted" | while IFS=: read -r lines file; do
        echo "$lines lines: $file"
    done
fi

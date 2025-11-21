#!/usr/bin/env bash

set -euo pipefail

MAX_RESULTS="${1:-50}"

extensions=("js" "jsx" "ts" "tsx" "mjs" "cjs")
ext_pattern=$(IFS="|"; echo "${extensions[*]}")

patterns=(
    "console\.log"
    "console\.debug"
    "console\.warn"
    "console\.error"
    "console\.trace"
    "debugger"
)

pattern_regex=$(IFS="|"; echo "${patterns[*]}")

matches=$(find . -type f \
    -regextype posix-extended \
    -regex ".*\.(${ext_pattern})" \
    ! -path "*/node_modules/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "*/.next/*" \
    ! -path "*/coverage/*" \
    -exec grep -Hn -E "$pattern_regex" {} \; 2>/dev/null || true)

if [ -z "$matches" ]; then
    echo "No debug statements found"
    exit 0
fi

match_count=$(echo "$matches" | wc -l | tr -d ' ')

if [ "$match_count" -gt "$MAX_RESULTS" ]; then
    echo "=== Showing first ${MAX_RESULTS} of ${match_count} debug statements ==="
    echo "$matches" | head -n "$MAX_RESULTS"
    echo ""
    echo "... truncated $(( match_count - MAX_RESULTS )) results (too many debug statements)"
else
    echo "=== Found $match_count debug statements ==="
    echo "$matches"
fi

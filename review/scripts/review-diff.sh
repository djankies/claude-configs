#!/usr/bin/env bash

set -euo pipefail

MAX_COMMITS="${1:-5}"
MAX_LINES="${2:-500}"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

if [ "$(git rev-list --count HEAD 2>/dev/null || echo 0)" -eq 0 ]; then
    echo "No commits yet in this repository"
    exit 0
fi

output=$(git diff HEAD~"${MAX_COMMITS}"..HEAD \
    --unified=3 \
    --ignore-all-space \
    -- \
    ':!package-lock.json' \
    ':!yarn.lock' \
    ':!pnpm-lock.yaml' \
    ':!*.min.js' \
    ':!*.map' \
    ':!dist/*' \
    ':!build/*' \
    2>/dev/null || git diff HEAD --unified=3)

if [ -z "$output" ]; then
    echo "No changes in the last ${MAX_COMMITS} commits"
    exit 0
fi

line_count=$(echo "$output" | wc -l | tr -d ' ')

if [ "$line_count" -gt "$MAX_LINES" ]; then
    echo "=== Showing first ${MAX_LINES} of ${line_count} diff lines ==="
    echo "$output" | head -n "$MAX_LINES"
    echo ""
    echo "... truncated $(( line_count - MAX_LINES )) lines (output too large)"
else
    echo "$output"
fi

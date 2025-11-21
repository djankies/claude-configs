#!/usr/bin/env bash

set -euo pipefail

MAX_RESULTS="${1:-50}"

if ! command -v semgrep &> /dev/null; then
    echo "Semgrep not found. Install with: pip install semgrep"
    exit 0
fi

output=$(semgrep \
    --config=auto \
    --severity=ERROR \
    --severity=WARNING \
    --json \
    --quiet \
    . 2>/dev/null || true)

if [ -z "$output" ] || [ "$output" = '{"results":[]}' ]; then
    echo "No security issues found"
    exit 0
fi

results=$(echo "$output" | jq -r '.results[] | "\(.path):\(.start.line): [\(.extra.severity)] \(.extra.message)"' 2>/dev/null || true)

if [ -z "$results" ]; then
    echo "No security issues found"
    exit 0
fi

result_count=$(echo "$results" | wc -l | tr -d ' ')

if [ "$result_count" -gt "$MAX_RESULTS" ]; then
    echo "=== Semgrep: Found $result_count security issues (showing first $MAX_RESULTS) ==="
    echo "$results" | head -n "$MAX_RESULTS"
    echo ""
    echo "... truncated $(( result_count - MAX_RESULTS )) results"
else
    echo "=== Semgrep: Found $result_count security issues ==="
    echo "$results"
fi

#!/usr/bin/env bash

set -euo pipefail

MAX_ERRORS="${1:-100}"

if ! command -v tsc &> /dev/null && ! command -v npx &> /dev/null; then
    echo "TypeScript compiler not found. Install with: npm install -D typescript"
    exit 0
fi

if [ ! -f "tsconfig.json" ]; then
    echo "No tsconfig.json found. TypeScript type checking skipped."
    exit 0
fi

if command -v tsc &> /dev/null; then
    TSC_CMD="tsc"
elif [ -f "node_modules/.bin/tsc" ]; then
    TSC_CMD="./node_modules/.bin/tsc"
else
    TSC_CMD="npx tsc"
fi

output=$($TSC_CMD --noEmit 2>&1 || true)

if [ -z "$output" ]; then
    echo "No type errors found"
    exit 0
fi

error_lines=$(echo "$output" | grep -E "error TS[0-9]+:" || true)

if [ -z "$error_lines" ]; then
    echo "No type errors found"
    exit 0
fi

error_count=$(echo "$error_lines" | wc -l | tr -d ' ')

if [ "$error_count" -gt "$MAX_ERRORS" ]; then
    echo "=== TypeScript: $error_count type errors (showing first $MAX_ERRORS) ==="
    echo "$error_lines" | head -n "$MAX_ERRORS"
    echo ""
    echo "... truncated $(( error_count - MAX_ERRORS )) errors"
else
    echo "=== TypeScript: $error_count type errors ==="
    echo "$error_lines"
fi

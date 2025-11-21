#!/usr/bin/env bash

set -euo pipefail

MAX_RESULTS="${1:-100}"

if command -v knip &> /dev/null || [ -f "node_modules/.bin/knip" ]; then
    echo "Using Knip for comprehensive unused code detection..."

    if command -v knip &> /dev/null; then
        KNIP_CMD="knip"
    else
        KNIP_CMD="./node_modules/.bin/knip"
    fi

    output=$($KNIP_CMD --reporter compact 2>/dev/null || true)

    if [ -z "$output" ]; then
        echo "No unused code found"
        exit 0
    fi

    line_count=$(echo "$output" | wc -l | tr -d ' ')

    if [ "$line_count" -gt "$MAX_RESULTS" ]; then
        echo "=== Knip: Found unused code (showing first $MAX_RESULTS results) ==="
        echo "$output" | head -n "$MAX_RESULTS"
        echo ""
        echo "... truncated $(( line_count - MAX_RESULTS )) results"
    else
        echo "=== Knip: Found unused code ==="
        echo "$output"
    fi
    exit 0
fi

if command -v ts-prune &> /dev/null || [ -f "node_modules/.bin/ts-prune" ] || command -v npx &> /dev/null; then
    echo "Using ts-prune for unused exports detection..."

    if command -v ts-prune &> /dev/null; then
        TSPRUNE_CMD="ts-prune"
    elif [ -f "node_modules/.bin/ts-prune" ]; then
        TSPRUNE_CMD="./node_modules/.bin/ts-prune"
    else
        TSPRUNE_CMD="npx ts-prune"
    fi

    output=$($TSPRUNE_CMD 2>/dev/null || true)

    if [ -z "$output" ] || echo "$output" | grep -q "^$"; then
        echo "No unused exports found"
        exit 0
    fi

    line_count=$(echo "$output" | wc -l | tr -d ' ')

    if [ "$line_count" -gt "$MAX_RESULTS" ]; then
        echo "=== ts-prune: Found unused exports (showing first $MAX_RESULTS) ==="
        echo "$output" | head -n "$MAX_RESULTS"
        echo ""
        echo "... truncated $(( line_count - MAX_RESULTS )) results"
    else
        echo "=== ts-prune: Found unused exports ==="
        echo "$output"
    fi
    exit 0
fi

echo "Neither Knip nor ts-prune found."
echo "Install with:"
echo "  npm install -D knip          # Comprehensive (recommended)"
echo "  npm install -D ts-prune      # Simpler, exports only"
exit 0

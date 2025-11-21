#!/usr/bin/env bash

set -euo pipefail

MAX_RESULTS="${1:-30}"
MIN_LINES="${2:-5}"

if command -v jsinspect &> /dev/null || [ -f "node_modules/.bin/jsinspect" ] || command -v npx &> /dev/null; then
    echo "Using jsinspect for duplicate code detection..."

    if command -v jsinspect &> /dev/null; then
        JSINSPECT_CMD="jsinspect"
    elif [ -f "node_modules/.bin/jsinspect" ]; then
        JSINSPECT_CMD="./node_modules/.bin/jsinspect"
    else
        JSINSPECT_CMD="npx jsinspect"
    fi

    output=$($JSINSPECT_CMD \
        --threshold "$MIN_LINES" \
        --ignore "node_modules|dist|build|.next|coverage" \
        . 2>/dev/null || true)

    if [ -z "$output" ] || echo "$output" | grep -q "^$"; then
        echo "No duplicate code blocks found"
        exit 0
    fi

    matches=$(echo "$output" | grep -c "Match -" || echo 0)

    if [ "$matches" -gt "$MAX_RESULTS" ]; then
        echo "=== jsinspect: Found $matches duplicate code blocks (showing first $MAX_RESULTS) ==="
        echo "$output" | head -n $((MAX_RESULTS * 10))
        echo ""
        echo "... truncated $(( matches - MAX_RESULTS )) matches"
    else
        echo "=== jsinspect: Found $matches duplicate code blocks ==="
        echo "$output"
    fi
    exit 0
fi

if command -v lizard &> /dev/null; then
    echo "Using Lizard for basic duplication detection..."

    output=$(lizard \
        -l javascript \
        -x "*/node_modules/*" \
        -x "*/dist/*" \
        -x "*/build/*" \
        -x "*/.next/*" \
        -x "*/coverage/*" \
        -Eduplicate \
        . 2>&1 || true)

    if [ -z "$output" ]; then
        echo "No duplicates detected"
        exit 0
    fi

    echo "$output"
    exit 0
fi

echo "No duplication detection tools found."
echo "Install with:"
echo "  npm install -g jsinspect    # JavaScript/TypeScript"
echo "  pip install lizard          # Multi-language"
exit 0

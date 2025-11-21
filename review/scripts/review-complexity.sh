#!/usr/bin/env bash

set -euo pipefail

MAX_RESULTS="${1:-30}"
COMPLEXITY_THRESHOLD="${2:-15}"

if ! command -v lizard &> /dev/null; then
    echo "Lizard not found. Install with: pip install lizard"
    exit 0
fi

output=$(lizard \
    -l javascript \
    -x "*/node_modules/*" \
    -x "*/dist/*" \
    -x "*/build/*" \
    -x "*/.next/*" \
    -x "*/coverage/*" \
    -C "$COMPLEXITY_THRESHOLD" \
    -w 2>&1 || true)

if [ -z "$output" ] || echo "$output" | grep -q "No file"; then
    echo "No functions with complexity >= ${COMPLEXITY_THRESHOLD} found"
    exit 0
fi

complex_functions=$(echo "$output" | grep -E "^[0-9]+" | grep -v "^NLOC" || true)

if [ -z "$complex_functions" ]; then
    echo "No functions with complexity >= ${COMPLEXITY_THRESHOLD} found"
    exit 0
fi

result_count=$(echo "$complex_functions" | wc -l | tr -d ' ')

if [ "$result_count" -gt "$MAX_RESULTS" ]; then
    echo "=== Lizard: Found $result_count complex functions (showing top $MAX_RESULTS by complexity) ==="
    echo "Format: NLOC CCN Token Parameter Length Location"
    echo "$complex_functions" | sort -k2 -rn | head -n "$MAX_RESULTS"
    echo ""
    echo "... truncated $(( result_count - MAX_RESULTS )) results"
else
    echo "=== Lizard: Found $result_count complex functions ==="
    echo "Format: NLOC CCN Token Parameter Length Location"
    echo "$complex_functions" | sort -k2 -rn
fi

echo ""
echo "CCN = Cyclomatic Complexity Number (recommend keeping < 15)"

#!/usr/bin/env bash

set -euo pipefail

if ! command -v depcheck &> /dev/null && ! command -v npx &> /dev/null; then
    echo "depcheck not found. Install with: npm install -g depcheck"
    echo "Checking manually..."

    if [ ! -f "package.json" ]; then
        echo "No package.json found"
        exit 0
    fi

    deps=$(jq -r '.dependencies // {} | keys[]' package.json 2>/dev/null || true)
    dev_deps=$(jq -r '.devDependencies // {} | keys[]' package.json 2>/dev/null || true)

    if [ -z "$deps" ] && [ -z "$dev_deps" ]; then
        echo "No dependencies found in package.json"
        exit 0
    fi

    echo "Manual check (limited): Looking for import statements..."
    echo "For accurate results, install depcheck: npm install -g depcheck"
    exit 0
fi

if command -v depcheck &> /dev/null; then
    DEPCHECK_CMD="depcheck"
else
    DEPCHECK_CMD="npx depcheck"
fi

output=$($DEPCHECK_CMD --json 2>/dev/null || echo '{"dependencies":[],"devDependencies":[]}')

unused_deps=$(echo "$output" | jq -r '.dependencies[]' 2>/dev/null || true)
unused_dev_deps=$(echo "$output" | jq -r '.devDependencies[]' 2>/dev/null || true)

unused_count=0
unused_dev_count=0

if [ -n "$unused_deps" ]; then
    unused_count=$(echo "$unused_deps" | wc -l | tr -d ' ')
fi

if [ -n "$unused_dev_deps" ]; then
    unused_dev_count=$(echo "$unused_dev_deps" | wc -l | tr -d ' ')
fi

total=$((unused_count + unused_dev_count))

if [ "$total" -eq 0 ]; then
    echo "No unused dependencies found"
    exit 0
fi

echo "=== Found $unused_count unused dependencies, $unused_dev_count unused devDependencies ==="

if [ -n "$unused_deps" ]; then
    echo ""
    echo "Unused dependencies:"
    echo "$unused_deps" | sed 's/^/  - /'
fi

if [ -n "$unused_dev_deps" ]; then
    echo ""
    echo "Unused devDependencies:"
    echo "$unused_dev_deps" | sed 's/^/  - /'
fi

#!/usr/bin/env bash

set -euo pipefail

MAX_ERRORS="${1:-100}"

if ! command -v eslint &> /dev/null && ! command -v npx &> /dev/null; then
    echo "ESLint not found. Install with: npm install -D eslint"
    exit 0
fi

if command -v eslint &> /dev/null; then
    ESLINT_CMD="eslint"
elif [ -f "node_modules/.bin/eslint" ]; then
    ESLINT_CMD="./node_modules/.bin/eslint"
else
    ESLINT_CMD="npx eslint"
fi

if [ ! -f ".eslintrc.js" ] && [ ! -f ".eslintrc.json" ] && [ ! -f ".eslintrc.yml" ] && [ ! -f "eslint.config.js" ] && [ ! -f "eslint.config.mjs" ]; then
    echo "No ESLint configuration found. Create .eslintrc.* or eslint.config.* to enable linting."
    exit 0
fi

output=$($ESLINT_CMD . --format compact 2>&1 || true)

if [ -z "$output" ]; then
    echo "No linting errors found"
    exit 0
fi

error_count=$(echo "$output" | grep -c "Error -" || echo 0)
warning_count=$(echo "$output" | grep -c "Warning -" || echo 0)

total=$((error_count + warning_count))

if [ "$total" -eq 0 ]; then
    echo "No linting issues found"
    exit 0
fi

if [ "$total" -gt "$MAX_ERRORS" ]; then
    echo "=== ESLint: $error_count errors, $warning_count warnings (showing first $MAX_ERRORS) ==="
    echo "$output" | grep -E "(Error|Warning) -" | head -n "$MAX_ERRORS"
    echo ""
    echo "... truncated $(( total - MAX_ERRORS )) issues"
    echo ""
    echo "Run 'eslint . --fix' to auto-fix some issues"
else
    echo "=== ESLint: $error_count errors, $warning_count warnings ==="
    echo "$output" | grep -E "(Error|Warning) -"
    echo ""
    echo "Run 'eslint . --fix' to auto-fix some issues"
fi

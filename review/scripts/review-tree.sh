#!/usr/bin/env bash

set -euo pipefail

MAX_DEPTH="${1:-3}"

if command -v tree &> /dev/null; then
    tree -L "$MAX_DEPTH" -I 'node_modules|dist|build|.next|coverage|.git' --dirsfirst
    exit 0
fi

echo "tree command not found, using find fallback..."
echo ""

find . -maxdepth "$MAX_DEPTH" \
    -not -path "*/node_modules/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -not -path "*/.next/*" \
    -not -path "*/coverage/*" \
    -not -path "*/.git/*" \
    2>/dev/null | \
    sed -e "s/[^-][^\/]*\//  /g" -e "s/^//" | \
    sort

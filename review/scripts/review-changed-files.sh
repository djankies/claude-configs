#!/usr/bin/env bash

set -euo pipefail

MAX_FILES="${1:-50}"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

if [ "$(git rev-list --count HEAD 2>/dev/null || echo 0)" -eq 0 ]; then
    echo "No commits yet in this repository"
    exit 0
fi

base_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
current_branch=$(git rev-parse --abbrev-ref HEAD)

if [ "$current_branch" = "$base_branch" ] || ! git rev-parse "origin/$base_branch" > /dev/null 2>&1; then
    output=$(git diff --stat HEAD~1 2>/dev/null || echo "")
else
    output=$(git diff --stat "origin/$base_branch"...HEAD 2>/dev/null || echo "")
fi

if [ -z "$output" ]; then
    echo "No changed files"
    exit 0
fi

file_count=$(echo "$output" | grep -c '|' || echo 0)

if [ "$file_count" -gt "$MAX_FILES" ]; then
    echo "=== Showing first ${MAX_FILES} of ${file_count} changed files ==="
    echo "$output" | head -n "$MAX_FILES"
    echo ""
    echo "... truncated $(( file_count - MAX_FILES )) files"
else
    echo "$output"
fi

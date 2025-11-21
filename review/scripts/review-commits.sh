#!/usr/bin/env bash

set -euo pipefail

MAX_COMMITS="${1:-10}"

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
    output=$(git log -n "$MAX_COMMITS" --pretty=format:"%h %an %ar: %s" 2>/dev/null || echo "")
else
    output=$(git log "origin/$base_branch"..HEAD --pretty=format:"%h %an %ar: %s" 2>/dev/null || echo "")
fi

if [ -z "$output" ]; then
    echo "No commits found"
    exit 0
fi

commit_count=$(echo "$output" | wc -l | tr -d ' ')

if [ "$commit_count" -gt "$MAX_COMMITS" ]; then
    echo "=== Showing first ${MAX_COMMITS} of ${commit_count} commits ==="
    echo "$output" | head -n "$MAX_COMMITS"
else
    echo "$output"
fi

#!/usr/bin/env bash

set -euo pipefail
trap 'exit 0' PIPE

is_typescript_file() {
    local path="${1:?File path required}"

    [[ "$path" =~ \.(ts|tsx)$ ]]
}

is_javascript_file() {
    local path="${1:?File path required}"

    [[ "$path" =~ \.(js|jsx|mjs|cjs)$ ]]
}

is_test_file() {
    local path="${1:?File path required}"

    [[ "$path" =~ (test|spec|__tests__|__test__) ]] || \
    [[ "$path" =~ \.(test|spec)\.(ts|tsx|js|jsx)$ ]]
}

is_component_file() {
    local path="${1:?File path required}"

    [[ "$path" =~ (component|Component) ]] || \
    [[ "$path" =~ /components/ ]] || \
    [[ "$path" =~ \.(tsx|jsx)$ && ! "$path" =~ (test|spec|hook|util|lib) ]]
}

is_hook_file() {
    local path="${1:?File path required}"

    [[ "$path" =~ use[A-Z] ]] || \
    [[ "$path" =~ /hooks/ ]]
}

is_config_file() {
    local path="${1:?File path required}"

    [[ "$path" =~ (config|configuration) ]] || \
    [[ "$path" =~ \.(config|rc)\.(ts|js|json)$ ]] || \
    [[ "$path" =~ (tsconfig|package|eslintrc|prettierrc|vite\.config|next\.config)\..*$ ]]
}

is_server_file() {
    local path="${1:?File path required}"

    [[ "$path" =~ /server/ ]] || \
    [[ "$path" =~ /api/ ]] || \
    [[ "$path" =~ route\.(ts|js)$ ]] || \
    [[ "$path" =~ /app/.*route\.(ts|js)$ ]]
}

is_server_action() {
    local content="${1:?File content required}"

    echo "$content" | grep -q "^[[:space:]]*['\"]use server['\"]" || \
    echo "$content" | grep -q "^['\"]use server['\"]"
}

is_server_component() {
    local content="${1:?File content required}"

    ! echo "$content" | grep -q "^[[:space:]]*['\"]use client['\"]" && \
    ! echo "$content" | grep -q "^['\"]use client['\"]"
}

detect_framework() {
    local path="${1:?File path required}"

    if [[ "$path" =~ /app/.*\.(tsx|jsx|ts|js)$ ]]; then
        echo "nextjs"
    elif [[ "$path" =~ /pages/.*\.(tsx|jsx|ts|js)$ ]]; then
        echo "nextjs-pages"
    elif [[ "$path" =~ /src/routes/.*\.(tsx|jsx|ts|js|svelte)$ ]]; then
        echo "sveltekit"
    elif [[ "$path" =~ /app/routes/.*\.(tsx|jsx|ts|js)$ ]]; then
        echo "remix"
    elif [[ "$path" =~ \.(tsx|jsx)$ ]]; then
        echo "react"
    elif [[ "$path" =~ \.(vue)$ ]]; then
        echo "vue"
    elif [[ "$path" =~ \.(svelte)$ ]]; then
        echo "svelte"
    else
        echo "unknown"
    fi
}

get_file_extension() {
    local path="${1:?File path required}"

    echo "${path##*.}"
}

get_file_name() {
    local path="${1:?File path required}"

    echo "${path##*/}"
}

get_file_dir() {
    local path="${1:?File path required}"

    echo "${path%/*}"
}

get_file_type() {
    local path="${1:?File path required}"

    if is_test_file "$path"; then
        echo "test"
    elif is_component_file "$path"; then
        echo "component"
    elif is_hook_file "$path"; then
        echo "hook"
    elif is_server_file "$path"; then
        echo "server"
    elif is_config_file "$path"; then
        echo "config"
    elif is_typescript_file "$path"; then
        echo "typescript"
    elif is_javascript_file "$path"; then
        echo "javascript"
    else
        echo "unknown"
    fi
}

is_nextjs_app_dir() {
    local path="${1:?File path required}"

    [[ "$path" =~ /app/ ]]
}

is_nextjs_pages_dir() {
    local path="${1:?File path required}"

    [[ "$path" =~ /pages/ ]]
}

has_pattern() {
    local content="${1:?Content required}"
    local pattern="${2:?Pattern required}"

    echo "$content" | grep -q "$pattern"
}

count_pattern() {
    local content="${1:?Content required}"
    local pattern="${2:?Pattern required}"

    echo "$content" | grep -o "$pattern" | wc -l | tr -d ' '
}

get_imports() {
    local content="${1:?Content required}"

    echo "$content" | grep -E "^import .* from ['\"].*['\"]" || true
}

has_import() {
    local content="${1:?Content required}"
    local package="${2:?Package required}"

    get_imports "$content" | grep -q "from ['\"]${package}['\"]"
}

get_file_first_line() {
    local path="${1:?File path required}"

    head -n 1 "$path"
}

is_empty_file() {
    local path="${1:?File path required}"

    [[ ! -s "$path" ]]
}

get_line_count() {
    local path="${1:?File path required}"

    wc -l < "$path" | tr -d ' '
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "File Detection Utility"
    echo "Usage: source this file and call functions"
    echo ""
    echo "File Type Detection:"
    echo "  is_typescript_file <path>"
    echo "  is_javascript_file <path>"
    echo "  is_test_file <path>"
    echo "  is_component_file <path>"
    echo "  is_hook_file <path>"
    echo "  is_config_file <path>"
    echo "  is_server_file <path>"
    echo "  get_file_type <path>"
    echo ""
    echo "Content Detection:"
    echo "  is_server_action <content>"
    echo "  is_server_component <content>"
    echo "  has_pattern <content> <pattern>"
    echo "  count_pattern <content> <pattern>"
    echo "  has_import <content> <package>"
    echo ""
    echo "Framework Detection:"
    echo "  detect_framework <path>"
    echo "  is_nextjs_app_dir <path>"
    echo "  is_nextjs_pages_dir <path>"
    echo ""
    echo "Path Utilities:"
    echo "  get_file_extension <path>"
    echo "  get_file_name <path>"
    echo "  get_file_dir <path>"
    echo "  get_line_count <path>"
    echo ""
    echo "Example:"
    echo "  if is_typescript_file 'src/App.tsx'; then echo 'TypeScript!'; fi"
    echo "  detect_framework 'app/page.tsx'  # outputs: nextjs"
fi

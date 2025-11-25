#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "validate-tests"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && finish_hook 0

file_path=$(get_input_field "tool_input.file_path")
[[ ! "$file_path" =~ \.(test|spec)\.(ts|tsx|js|jsx)$ ]] && finish_hook 0

content=$(get_input_field "tool_input.content")
[[ -z "$content" ]] && content=$(get_input_field "tool_input.new_string")
[[ -z "$content" ]] && finish_hook 0

errors=""

if echo "$content" | grep -q "@vitest/browser/context"; then
  log_error "Detected violation: @vitest/browser/context"
  errors+="Deprecated import: @vitest/browser/context -> vitest/browser\n"
fi

if echo "$content" | grep -q "from ['\"]vitest/execute['\"]"; then
  log_error "Detected violation: vitest/execute"
  errors+="Removed: vitest/execute entry point no longer exists\n"
fi

if echo "$content" | grep -q "VITE_NODE_DEPS_MODULE_DIRECTORIES"; then
  log_error "Detected violation: VITE_NODE_DEPS_MODULE_DIRECTORIES"
  errors+="Renamed: VITE_NODE_DEPS_MODULE_DIRECTORIES -> VITEST_MODULE_DIRECTORIES\n"
fi

if [[ -n "$errors" ]]; then
  posttooluse_respond "violation" "Vitest 4.x test violations detected. See migrating-to-vitest-4 skill for Vitest 4.x patterns" "$(echo -e "$errors")"
  finish_hook 2
fi

finish_hook 0

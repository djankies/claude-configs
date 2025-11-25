#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "validate-config"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && finish_hook 0

file_path=$(get_input_field "tool_input.file_path")
[[ ! "$file_path" =~ vitest\.config\. ]] && finish_hook 0

content=$(get_input_field "tool_input.content")
[[ -z "$content" ]] && content=$(get_input_field "tool_input.new_string")
[[ -z "$content" ]] && finish_hook 0

deprecated_config_patterns=(
  "maxThreads"
  "minThreads"
  "singleThread"
  "singleFork"
  "poolOptions"
  "minWorkers"
  "coverage.ignoreEmptyLines"
  "coverage.all"
  "coverage.extensions"
  "defineWorkspace"
  "poolMatchGlobs"
  "environmentMatchGlobs"
  "deps.inline"
  "deps.external"
  "deps.fallbackCJS"
  "browser.testerScripts"
)

errors=""
for pattern in "${deprecated_config_patterns[@]}"; do
  if echo "$content" | grep -q "$pattern"; then
    log_error "Detected violation: $pattern"
    case "$pattern" in
      "deps.inline"|"deps.external"|"deps.fallbackCJS")
        errors+="Moved: $pattern -> server.$pattern\n"
        ;;
      "browser.testerScripts")
        errors+="Replaced: $pattern -> browser.testerHtmlPath\n"
        ;;
      *)
        errors+="Deprecated: $pattern\n"
        ;;
    esac
  fi
done

if [[ -n "$errors" ]]; then
  posttooluse_respond "violation" "Vitest 4.x configuration violations detected. See migrating-to-vitest-4 skill for Vitest 4.x patterns" "$(echo -e "$errors")"
  finish_hook 2
fi

finish_hook 0

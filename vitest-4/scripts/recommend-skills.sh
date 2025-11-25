#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "recommend-skills"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

[[ "$tool_name" != "Read" && "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && finish_hook 0

file_path=$(get_input_field "tool_input.file_path")
[[ -z "$file_path" ]] && finish_hook 0

case "$file_path" in
  *vitest.config.*)
    if ! has_shown_recommendation "vitest-4" "configuring"; then
      log_info "Recommending skill: configuring-vitest-4"
      pretooluse_respond "allow" "Vitest config detected - see configuring-vitest-4 skill for pool/coverage patterns"
      mark_recommendation_shown "vitest-4" "configuring"
    fi
    ;;
  *.test.ts|*.spec.ts|*.test.tsx|*.spec.tsx)
    if ! has_shown_recommendation "vitest-4" "testing"; then
      log_info "Recommending skill: writing-vitest-tests"
      pretooluse_respond "allow" "Vitest test file - see writing-vitest-tests skill for test patterns"
      mark_recommendation_shown "vitest-4" "testing"
    fi
    ;;
esac

finish_hook 0

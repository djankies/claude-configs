#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_UTILS="$(cd "${SCRIPT_DIR}/../../../marketplace-utils" && pwd)"

source "${MARKETPLACE_UTILS}/hook-lifecycle.sh"

init_hook "zod-4" "recommend-skills"

input=$(read_hook_input)

file_path=$(get_input_field "parameters.file_path")

[[ -z "$file_path" || ! -f "$file_path" ]] && pretooluse_respond "allow" && finish_hook 0

file_ext="${file_path##*.}"

case "$file_ext" in
  ts|tsx|js|jsx)
    ;;
  *)
    pretooluse_respond "allow"
    finish_hook 0
    ;;
esac

if grep -q "from ['\"]zod['\"]" "$file_path" 2>/dev/null || \
   grep -q "import zod" "$file_path" 2>/dev/null; then

  shown=$(get_plugin_value "zod-4" "recommendations_shown.zod_skills")

  if [[ "$shown" != "true" ]]; then
    context="📚 Zod 4 Skills Available:
  VALIDATION-*: Schema basics, string formats (z.email, z.uuid)
  TRANSFORMATION-*: String methods (.trim, .toLowerCase), codecs
  ERRORS-*: Unified error customization API
  MIGRATION-*: v3 to v4 breaking changes

Use Skill tool to activate when needed."

    log_info "Recommending Zod 4 skills: VALIDATION-*, TRANSFORMATION-*, ERRORS-*, MIGRATION-* for $file_path"
    set_plugin_value "zod-4" "recommendations_shown.zod_skills" "true"

    pretooluse_respond "allow" "" "$(jq -n --argjson orig "$input" --arg ctx "$context" '$orig + {additionalContext: $ctx}')"
    finish_hook 0
  fi
fi

pretooluse_respond "allow"
finish_hook 0

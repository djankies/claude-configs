#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_UTILS="$(cd "${SCRIPT_DIR}/../../../marketplace-utils" && pwd)"

source "${MARKETPLACE_UTILS}/hook-lifecycle.sh"

init_hook "zod-4" "init-session"

read_hook_input > /dev/null

set_plugin_value "zod-4" "recommendations_shown.zod_skills" "false"

log_info "Session initialized for zod-4 plugin"

echo "{}"
finish_hook 0

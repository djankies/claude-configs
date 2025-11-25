#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "init-session"

log_info "Vitest 4 plugin initialized"

finish_hook 0

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "nextjs-16" "SessionStart"

log_info "Next.js 16 plugin session initialized"

inject_context "Next.js 16 plugin session started. Skills available: SECURITY-*, CACHING-*, MIGRATION-*, ROUTING-*, FORMS-*"
exit 0

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "nextjs-16" "PostToolUse"

CWD="${CLAUDE_CWD:-$(pwd)}"

if [[ -f "$CWD/middleware.ts" ]] || [[ -f "$CWD/middleware.js" ]]; then
  log_error "middleware.ts/js file found in project root"
  inject_context "❌ ERROR: middleware.ts found - must be renamed to proxy.ts in Next.js 16

Use MIGRATION-middleware-to-proxy skill for proper migration.
Security: CVE-2025-29927 - middleware no longer safe for auth"
  exit 0
fi

exit 0

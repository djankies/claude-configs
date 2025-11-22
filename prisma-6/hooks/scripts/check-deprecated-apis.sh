#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "prisma-6" "PreToolUse"

INPUT=$(read_hook_input)

if ! command -v grep &> /dev/null; then
  log_error "grep command not found"
  pretooluse_respond "allow"
  exit 0
fi

TS_FILES=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/dist/*" \
  ! -path "*/build/*" \
  ! -path "*/.next/*" 2>/dev/null || true)

if [ -z "$TS_FILES" ]; then
  pretooluse_respond "allow"
  exit 0
fi

PRISMA_FILES=$(echo "$TS_FILES" | xargs grep -l '@prisma/client' 2>/dev/null || true)

BUFFER_USAGE=""
if [ -n "$PRISMA_FILES" ]; then
  BUFFER_USAGE=$(echo "$PRISMA_FILES" | xargs grep -nE 'Buffer\.from\(' 2>/dev/null || true)
fi

if [ -n "$BUFFER_USAGE" ]; then
  log_warn "Buffer.from() usage detected in files importing @prisma/client"
  pretooluse_respond "allow" "Warning: Buffer.from() usage detected in files importing @prisma/client

Prisma 6 Bytes fields use Uint8Array instead of Buffer:
  ✗ const bytes = Buffer.from(data)
  ✗ reportData: Buffer.from(jsonString)
  ✓ reportData: new TextEncoder().encode(jsonString)

Bytes fields are returned as Uint8Array, no conversion needed:
  ✗ Buffer.from(user.profilePicture)
  ✓ user.profilePicture (already Uint8Array)"
  exit 0
fi

TOSTRING_ON_BYTES=$(echo "$TS_FILES" | xargs grep -nE '\.(avatar|file|attachment|document|reportData|image|photo|content|data|binary)\.toString\(' 2>/dev/null || true)

if [ -n "$TOSTRING_ON_BYTES" ]; then
  log_warn ".toString() on potential Bytes fields detected"
  pretooluse_respond "allow" "Warning: .toString() on potential Bytes fields detected

Bytes fields are now Uint8Array, not Buffer:
  ✗ reportData.toString('utf-8')
  ✓ new TextDecoder().decode(reportData)

For base64 encoding:
  ✗ avatar.toString('base64')
  ✓ Buffer.from(avatar).toString('base64')"
  exit 0
fi

NOT_FOUND_ERROR=$(echo "$TS_FILES" | xargs grep -En 'Prisma.*NotFoundError|@prisma/client.*NotFoundError|PrismaClient.*NotFoundError|from.*["\x27]@prisma/client["\x27].*NotFoundError' 2>/dev/null || true)

if [ -n "$NOT_FOUND_ERROR" ]; then
  log_warn "Deprecated NotFoundError handling detected"
  pretooluse_respond "allow" "Warning: Deprecated NotFoundError handling detected

Use error code P2025 instead of NotFoundError:
  ✗ if (error instanceof NotFoundError)
  ✓ if (error.code === 'P2025')"
  exit 0
fi

REJECTONFOUND=$(echo "$TS_FILES" | xargs grep -n 'rejectOnNotFound' 2>/dev/null || true)

if [ -n "$REJECTONFOUND" ]; then
  log_warn "Deprecated rejectOnNotFound option detected"
  pretooluse_respond "allow" "Warning: Deprecated rejectOnNotFound option detected

Use findUniqueOrThrow() or findFirstOrThrow() instead:
  ✗ findUnique({ where: { id }, rejectOnNotFound: true })
  ✓ findUniqueOrThrow({ where: { id } })"
  exit 0
fi

EXPERIMENTAL_FEATURES=$(echo "$TS_FILES" | xargs grep -n 'experimentalFeatures.*extendedWhereUnique\|experimentalFeatures.*fullTextSearch' 2>/dev/null || true)

if [ -n "$EXPERIMENTAL_FEATURES" ]; then
  log_warn "Deprecated experimental features detected"
  pretooluse_respond "allow" "Warning: Deprecated experimental features detected

These features are now stable in Prisma 6:
  - extendedWhereUnique (enabled by default)
  - fullTextSearch (enabled by default)

Remove from schema.prisma generator block."
  exit 0
fi

pretooluse_respond "allow"
exit 0

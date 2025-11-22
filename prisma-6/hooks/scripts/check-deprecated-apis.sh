#!/bin/bash

set -e

EXIT_CODE=0

if ! command -v grep &> /dev/null; then
  echo "Error: grep command not found"
  exit 2
fi

TS_FILES=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/dist/*" \
  ! -path "*/build/*" \
  ! -path "*/.next/*" 2>/dev/null)

if [ -z "$TS_FILES" ]; then
  exit 0
fi

PRISMA_FILES=$(echo "$TS_FILES" | xargs grep -l '@prisma/client' 2>/dev/null || true)

BUFFER_USAGE=""
if [ -n "$PRISMA_FILES" ]; then
  BUFFER_USAGE=$(echo "$PRISMA_FILES" | xargs grep -nE 'Buffer\.from\(' 2>/dev/null || true)
fi

if [ -n "$BUFFER_USAGE" ]; then
  echo "Warning: Buffer.from() usage detected in files importing @prisma/client"
  echo "$BUFFER_USAGE"
  echo ""
  echo "Prisma 6 Bytes fields use Uint8Array instead of Buffer:"
  echo "  ✗ const bytes = Buffer.from(data)"
  echo "  ✗ reportData: Buffer.from(jsonString)"
  echo "  ✓ reportData: new TextEncoder().encode(jsonString)"
  echo ""
  echo "Bytes fields are returned as Uint8Array, no conversion needed:"
  echo "  ✗ Buffer.from(user.profilePicture)"
  echo "  ✓ user.profilePicture (already Uint8Array)"
  EXIT_CODE=1
fi

TOSTRING_ON_BYTES=$(echo "$TS_FILES" | xargs grep -nE '\.(avatar|file|attachment|document|reportData|image|photo|content|data|binary)\.toString\(' 2>/dev/null || true)

if [ -n "$TOSTRING_ON_BYTES" ]; then
  echo "Warning: .toString() on potential Bytes fields detected"
  echo "$TOSTRING_ON_BYTES"
  echo ""
  echo "Bytes fields are now Uint8Array, not Buffer:"
  echo "  ✗ reportData.toString('utf-8')"
  echo "  ✓ new TextDecoder().decode(reportData)"
  echo ""
  echo "For base64 encoding:"
  echo "  ✗ avatar.toString('base64')"
  echo "  ✓ Buffer.from(avatar).toString('base64')"
  EXIT_CODE=1
fi

NOT_FOUND_ERROR=$(echo "$TS_FILES" | xargs grep -En 'Prisma.*NotFoundError|@prisma/client.*NotFoundError|PrismaClient.*NotFoundError|from.*["\x27]@prisma/client["\x27].*NotFoundError' 2>/dev/null || true)

if [ -n "$NOT_FOUND_ERROR" ]; then
  echo "Warning: Deprecated NotFoundError handling detected"
  echo "$NOT_FOUND_ERROR"
  echo ""
  echo "Use error code P2025 instead of NotFoundError:"
  echo "  ✗ if (error instanceof NotFoundError)"
  echo "  ✓ if (error.code === 'P2025')"
  EXIT_CODE=1
fi

REJECTONFOUND=$(echo "$TS_FILES" | xargs grep -n 'rejectOnNotFound' 2>/dev/null || true)

if [ -n "$REJECTONFOUND" ]; then
  echo "Warning: Deprecated rejectOnNotFound option detected"
  echo "$REJECTONFOUND"
  echo ""
  echo "Use findUniqueOrThrow() or findFirstOrThrow() instead:"
  echo "  ✗ findUnique({ where: { id }, rejectOnNotFound: true })"
  echo "  ✓ findUniqueOrThrow({ where: { id } })"
  EXIT_CODE=1
fi

EXPERIMENTAL_FEATURES=$(echo "$TS_FILES" | xargs grep -n 'experimentalFeatures.*extendedWhereUnique\|experimentalFeatures.*fullTextSearch' 2>/dev/null || true)

if [ -n "$EXPERIMENTAL_FEATURES" ]; then
  echo "Warning: Deprecated experimental features detected"
  echo "$EXPERIMENTAL_FEATURES"
  echo ""
  echo "These features are now stable in Prisma 6:"
  echo "  - extendedWhereUnique (enabled by default)"
  echo "  - fullTextSearch (enabled by default)"
  echo ""
  echo "Remove from schema.prisma generator block."
  EXIT_CODE=1
fi

exit $EXIT_CODE

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
  finish_hook 0
fi

TS_FILES=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/dist/*" \
  ! -path "*/build/*" \
  ! -path "*/.next/*" 2>/dev/null || true)

if [ -z "$TS_FILES" ]; then
  pretooluse_respond "allow"
  finish_hook 0
fi

UNSAFE_QUERY_RAW=$(echo "$TS_FILES" | xargs grep -n '\$queryRawUnsafe' 2>/dev/null || true)

if [ -n "$UNSAFE_QUERY_RAW" ]; then
  log_error "Unsafe raw SQL query detected - SQL injection risk"
  pretooluse_respond "block" "Warning: Unsafe raw SQL query detected - SQL injection risk

Use \$queryRaw with tagged template syntax instead:
  ✗ prisma.\$queryRawUnsafe(\`SELECT * FROM User WHERE id = \${id}\`)
  ✓ prisma.\$queryRaw\`SELECT * FROM User WHERE id = \${id}\`"
  finish_hook 0
fi

RAW_WITH_INTERPOLATION=$(echo "$TS_FILES" | xargs grep -n 'Prisma\.raw(' 2>/dev/null | \
  grep -E '\$\{|\+.*["\`]' || true)

if [ -n "$RAW_WITH_INTERPOLATION" ]; then
  log_error "Prisma.raw() with string interpolation - SQL injection risk"
  pretooluse_respond "block" "Warning: Prisma.raw() with string interpolation - SQL injection risk

Use Prisma.sql with tagged template syntax:
  ✗ Prisma.raw(\`WHERE id = \${id}\`)
  ✓ Prisma.sql\`WHERE id = \${id}\`"
  finish_hook 0
fi

MISSING_TAGGED_TEMPLATE=$(echo "$TS_FILES" | xargs grep -n '\$queryRaw(' 2>/dev/null || true)

if [ -n "$MISSING_TAGGED_TEMPLATE" ]; then
  log_warn "\$queryRaw with function call syntax instead of tagged template"
  pretooluse_respond "allow" "Warning: \$queryRaw with function call syntax instead of tagged template

Use tagged template syntax for automatic parameterization:
  ✗ prisma.\$queryRaw(Prisma.sql\`...\`)
  ✓ prisma.\$queryRaw\`...\`"
  finish_hook 0
fi

EXECUTE_RAW_UNSAFE=$(echo "$TS_FILES" | xargs grep -n '\$executeRawUnsafe' 2>/dev/null || true)

if [ -n "$EXECUTE_RAW_UNSAFE" ]; then
  log_error "Unsafe raw SQL execution detected - SQL injection risk"
  pretooluse_respond "block" "Warning: Unsafe raw SQL execution detected - SQL injection risk

Use \$executeRaw with tagged template syntax instead:
  ✗ prisma.\$executeRawUnsafe(\`UPDATE User SET name = '\${name}'\`)
  ✓ prisma.\$executeRaw\`UPDATE User SET name = \${name}\`"
  finish_hook 0
fi

pretooluse_respond "allow"
finish_hook 0

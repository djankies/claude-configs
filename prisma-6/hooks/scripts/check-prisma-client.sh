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

INSTANCES=$(echo "$TS_FILES" | xargs grep -n --exclude="*.test.ts" --exclude="*.spec.ts" --exclude-dir="__tests__" --exclude-dir="test" "new PrismaClient()" 2>/dev/null || true)

if [ -n "$INSTANCES" ]; then
  INSTANCE_COUNT=$(echo "$INSTANCES" | wc -l | tr -d ' ')

  if [ "$INSTANCE_COUNT" -gt 1 ]; then
    log_warn "Multiple PrismaClient instances detected: $INSTANCE_COUNT"
    pretooluse_respond "allow" "Warning: Multiple PrismaClient instances detected ($INSTANCE_COUNT)

Use global singleton pattern to prevent connection pool exhaustion:
  import { PrismaClient } from '@prisma/client'
  const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined }
  export const prisma = globalForPrisma.prisma ?? new PrismaClient()
  if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma"
    finish_hook 0
  fi
fi

FUNCTION_SCOPED=$(echo "$TS_FILES" | xargs grep -B5 --exclude="*.test.ts" --exclude="*.spec.ts" --exclude-dir="__tests__" --exclude-dir="test" "new PrismaClient()" 2>/dev/null | \
  grep -E "(function|const.*=.*\(|async.*\()" || true)

if [ -n "$FUNCTION_SCOPED" ]; then
  IS_SINGLETON_WRAPPER=false

  for file in $TS_FILES; do
    if grep -q "new PrismaClient()" "$file" 2>/dev/null; then
      HAS_SINGLETON_FUNC=$(grep -E "const.*singleton.*=.*\(\).*=>.*new PrismaClient\(\)" "$file" || true)
      HAS_GLOBAL_CACHE=$(grep -E "globalThis|globalForPrisma" "$file" || true)
      SINGLETON_CALLS=$(grep -o "singleton()" "$file" 2>/dev/null | wc -l | tr -d ' ')

      if [ -n "$HAS_SINGLETON_FUNC" ] && [ -n "$HAS_GLOBAL_CACHE" ] && [ "$SINGLETON_CALLS" -le 1 ]; then
        IS_SINGLETON_WRAPPER=true
        break
      fi
    fi
  done

  if [ "$IS_SINGLETON_WRAPPER" = false ]; then
    log_warn "PrismaClient instantiated inside function scope"
    pretooluse_respond "allow" "Warning: PrismaClient instantiated inside function scope

This creates new instances on each function call, exhausting connections.

Move PrismaClient to module scope with singleton pattern."
    finish_hook 0
  fi
fi

RAW_INTERPOLATION=$(echo "$TS_FILES" | xargs grep -n "prisma\.\(raw\|queryRaw\|executeRaw\)" 2>/dev/null | \
  grep -E '\$\{.*\}|"\s*\+\s*[^+]|\`\$\{' || true)

if [ -n "$RAW_INTERPOLATION" ]; then
  log_warn "Potential SQL interpolation in Prisma.raw() call"
  pretooluse_respond "allow" "Warning: Potential SQL interpolation detected in Prisma.raw() call

Use parameterized queries to prevent SQL injection:
  prisma.\$queryRaw\`SELECT * FROM users WHERE id = \${id}\`

Avoid string concatenation:
  ❌ prisma.\$queryRaw('SELECT * FROM users WHERE id = ' + id)
  ❌ prisma.\$queryRaw(\`SELECT * FROM users WHERE id = \${unsafeVar}\`)"
  finish_hook 0
fi

MISSING_GLOBAL=$(echo "$TS_FILES" | xargs grep -L "globalForPrisma\|globalThis.*prisma" 2>/dev/null | \
  xargs grep -l "new PrismaClient()" 2>/dev/null || true)

if [ -n "$MISSING_GLOBAL" ]; then
  log_warn "PrismaClient instantiation without global singleton pattern"
  pretooluse_respond "allow" "Warning: PrismaClient instantiation without global singleton pattern

Recommended pattern for Next.js and serverless environments:
  const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined }
  export const prisma = globalForPrisma.prisma ?? new PrismaClient()"
  finish_hook 0
fi

pretooluse_respond "allow"
finish_hook 0

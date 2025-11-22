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

INSTANCES=$(echo "$TS_FILES" | xargs grep -n "new PrismaClient()" 2>/dev/null || true)

if [ -n "$INSTANCES" ]; then
  INSTANCE_COUNT=$(echo "$INSTANCES" | wc -l | tr -d ' ')

  if [ "$INSTANCE_COUNT" -gt 1 ]; then
    echo "Warning: Multiple PrismaClient instances detected ($INSTANCE_COUNT)"
    echo "$INSTANCES"
    echo ""
    echo "Use global singleton pattern to prevent connection pool exhaustion:"
    echo "  import { PrismaClient } from '@prisma/client'"
    echo "  const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined }"
    echo "  export const prisma = globalForPrisma.prisma ?? new PrismaClient()"
    echo "  if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma"
    EXIT_CODE=1
  fi
fi

FUNCTION_SCOPED=$(echo "$TS_FILES" | xargs grep -B5 "new PrismaClient()" 2>/dev/null | \
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
    echo "Warning: PrismaClient instantiated inside function scope"
    echo "This creates new instances on each function call, exhausting connections."
    echo ""
    echo "Move PrismaClient to module scope with singleton pattern."
    EXIT_CODE=1
  fi
fi

MISSING_GLOBAL=$(echo "$TS_FILES" | xargs grep -L "globalForPrisma\|globalThis.*prisma" 2>/dev/null | \
  xargs grep -l "new PrismaClient()" 2>/dev/null || true)

if [ -n "$MISSING_GLOBAL" ]; then
  echo "Warning: PrismaClient instantiation without global singleton pattern:"
  echo "$MISSING_GLOBAL"
  echo ""
  echo "Recommended pattern for Next.js and serverless environments:"
  echo "  const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined }"
  echo "  export const prisma = globalForPrisma.prisma ?? new PrismaClient()"
  EXIT_CODE=1
fi

exit $EXIT_CODE

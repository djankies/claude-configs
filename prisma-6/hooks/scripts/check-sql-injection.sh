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

UNSAFE_QUERY_RAW=$(echo "$TS_FILES" | xargs grep -n '\$queryRawUnsafe' 2>/dev/null || true)

if [ -n "$UNSAFE_QUERY_RAW" ]; then
  echo "Warning: Unsafe raw SQL query detected - SQL injection risk"
  echo "$UNSAFE_QUERY_RAW"
  echo ""
  echo "Use \$queryRaw with tagged template syntax instead:"
  echo "  ✗ prisma.\$queryRawUnsafe(\`SELECT * FROM User WHERE id = \${id}\`)"
  echo "  ✓ prisma.\$queryRaw\`SELECT * FROM User WHERE id = \${id}\`"
  EXIT_CODE=1
fi

RAW_WITH_INTERPOLATION=$(echo "$TS_FILES" | xargs grep -n 'Prisma\.raw(' 2>/dev/null | \
  grep -E '\$\{|\+.*["\`]' || true)

if [ -n "$RAW_WITH_INTERPOLATION" ]; then
  echo "Warning: Prisma.raw() with string interpolation - SQL injection risk"
  echo "$RAW_WITH_INTERPOLATION"
  echo ""
  echo "Use Prisma.sql with tagged template syntax:"
  echo "  ✗ Prisma.raw(\`WHERE id = \${id}\`)"
  echo "  ✓ Prisma.sql\`WHERE id = \${id}\`"
  EXIT_CODE=1
fi

MISSING_TAGGED_TEMPLATE=$(echo "$TS_FILES" | xargs grep -n '\$queryRaw(' 2>/dev/null || true)

if [ -n "$MISSING_TAGGED_TEMPLATE" ]; then
  echo "Warning: \$queryRaw with function call syntax instead of tagged template"
  echo "$MISSING_TAGGED_TEMPLATE"
  echo ""
  echo "Use tagged template syntax for automatic parameterization:"
  echo "  ✗ prisma.\$queryRaw(Prisma.sql\`...\`)"
  echo "  ✓ prisma.\$queryRaw\`...\`"
  EXIT_CODE=1
fi

EXECUTE_RAW_UNSAFE=$(echo "$TS_FILES" | xargs grep -n '\$executeRawUnsafe' 2>/dev/null || true)

if [ -n "$EXECUTE_RAW_UNSAFE" ]; then
  echo "Warning: Unsafe raw SQL execution detected - SQL injection risk"
  echo "$EXECUTE_RAW_UNSAFE"
  echo ""
  echo "Use \$executeRaw with tagged template syntax instead:"
  echo "  ✗ prisma.\$executeRawUnsafe(\`UPDATE User SET name = '\${name}'\`)"
  echo "  ✓ prisma.\$executeRaw\`UPDATE User SET name = \${name}\`"
  EXIT_CODE=1
fi

exit $EXIT_CODE

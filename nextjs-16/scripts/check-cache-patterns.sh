#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <file-path>"
  exit 0
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  exit 0
fi

if grep -q "unstable_cache" "$FILE"; then
  echo "WARNING: $FILE uses unstable_cache - consider using cacheLife or cacheTag instead in Next.js 16"
fi

if grep -q "export const revalidate" "$FILE"; then
  echo "WARNING: $FILE uses 'export const revalidate' - consider using new caching APIs in Next.js 16"
fi

exit 0

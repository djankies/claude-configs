#!/bin/bash

set -e

if [ -f "middleware.ts" ] || [ -f "middleware.js" ]; then
  echo "ERROR: middleware.ts found - must be renamed to proxy.ts in Next.js 16"
  exit 1
fi

exit 0

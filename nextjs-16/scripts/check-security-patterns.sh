#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <file-path>"
  exit 0
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  exit 0
fi

if grep -q "'use server'" "$FILE" || grep -q '"use server"' "$FILE"; then
  if ! grep -q "verifySession" "$FILE"; then
    echo "WARNING: $FILE contains 'use server' without verifySession() call"
    echo "  Server actions should verify authentication before accessing data"
    echo "  See SECURITY-data-access-layer skill for proper patterns"
  fi
fi

exit 0

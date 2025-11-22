#!/bin/bash

FILE_PATH="$1"

[[ ! -f "$FILE_PATH" ]] && exit 0

grep -E "from ['\"]@prisma/client['\"]|import.*@prisma/client|\\\$queryRaw|\\\$executeRaw" "$FILE_PATH" 2>/dev/null

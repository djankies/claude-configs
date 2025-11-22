#!/bin/bash

FILE_PATH="$1"
FILE_EXT="${FILE_PATH##*.}"

[[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" && "$FILE_EXT" != "js" && "$FILE_EXT" != "jsx" && "$FILE_EXT" != "json" ]] && exit 0

VIOLATIONS=""

if [[ "$FILE_EXT" == "json" && "$FILE_PATH" == *"package.json" ]]; then
  ZOD_VERSION=$(grep -o '"zod"[[:space:]]*:[[:space:]]*"[^"]*"' "$FILE_PATH" 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)

  if [[ -n "$ZOD_VERSION" ]]; then
    MAJOR_VERSION=$(echo "$ZOD_VERSION" | cut -d. -f1)
    if [[ "$MAJOR_VERSION" -lt 4 ]]; then
      VIOLATIONS="${VIOLATIONS}❌ Zod version $ZOD_VERSION detected. This plugin targets Zod v4.x\n"
      VIOLATIONS="${VIOLATIONS}   Upgrade: npm install zod@latest\n"
    fi
  fi
fi

if [[ "$FILE_EXT" =~ ^(ts|tsx|js|jsx)$ ]]; then
  grep -q "from ['\"]zod['\"]" "$FILE_PATH" 2>/dev/null || grep -q "import zod" "$FILE_PATH" 2>/dev/null || exit 0

  if grep -E "z\.string\(\)\.email\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}❌ Deprecated: z.string().email() → Use z.email()\n"
  fi

  if grep -E "z\.string\(\)\.uuid\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}❌ Deprecated: z.string().uuid() → Use z.uuid()\n"
  fi

  if grep -E "z\.string\(\)\.datetime\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}❌ Deprecated: z.string().datetime() → Use z.iso.datetime()\n"
  fi

  if grep -E "z\.string\(\)\.url\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}❌ Deprecated: z.string().url() → Use z.url()\n"
  fi

  if grep -E "z\.string\(\)\.cuid\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}❌ Deprecated: z.string().cuid() → Use z.cuid()\n"
  fi

  if grep -E "z\.string\(\)\.cuid2\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}❌ Deprecated: z.string().cuid2() → Use z.cuid2()\n"
  fi

  if grep -E "z\.string\(\)\.ulid\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}❌ Deprecated: z.string().ulid() → Use z.ulid()\n"
  fi

  if grep -E "z\.string\(\)\.jwt\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}❌ Deprecated: z.string().jwt() → Use z.jwt()\n"
  fi

  if grep -E "(message|errorMap|invalid_type_error|required_error)[[:space:]]*:" "$FILE_PATH" 2>/dev/null | grep -v "error[[:space:]]*:" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}⚠️  Deprecated error customization detected\n"
    VIOLATIONS="${VIOLATIONS}   Use { error: '...' } instead of { message, errorMap, invalid_type_error, required_error }\n"
  fi

  if grep -E "\.merge\(" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}⚠️  .merge() is deprecated → Use .extend()\n"
  fi

  if grep "\.parse(" "$FILE_PATH" >/dev/null 2>&1; then
    if grep -B5 -A5 "\.parse(" "$FILE_PATH" 2>/dev/null | grep -E "(try|catch)" >/dev/null 2>&1; then
      VIOLATIONS="${VIOLATIONS}⚠️  Anti-pattern: .parse() with try/catch → Use .safeParse() instead\n"
    fi
  fi

  if grep -E "z\.enum\(\[['\"]true['\"],\s*['\"]false['\"]\]\)" "$FILE_PATH" >/dev/null 2>&1 || \
     grep -E "z\.enum\(\[['\"]false['\"],\s*['\"]true['\"]\]\)" "$FILE_PATH" >/dev/null 2>&1 || \
     grep -E "z\.enum\(\[['\"]yes['\"],\s*['\"]no['\"]\]\)" "$FILE_PATH" >/dev/null 2>&1 || \
     grep -E "z\.enum\(\[['\"]no['\"],\s*['\"]yes['\"]\]\)" "$FILE_PATH" >/dev/null 2>&1; then
    VIOLATIONS="${VIOLATIONS}⚠️  Boolean enum detected → Use z.stringbool() for 'true'/'false' values\n"
  fi

  if grep -E "(firstName|lastName|username|fullName|name)[[:space:]]*:[[:space:]]*z\.string\(\)[[:space:]]*\.min\([^)]*\)" "$FILE_PATH" >/dev/null 2>&1; then
    if ! grep -E "(firstName|lastName|username|fullName|name)[[:space:]]*:[[:space:]]*z\.string\(\)[[:space:]]*\.trim\(\)" "$FILE_PATH" >/dev/null 2>&1; then
      VIOLATIONS="${VIOLATIONS}⚠️  Name field without .trim() → Add .trim() before validation\n"
      VIOLATIONS="${VIOLATIONS}   Example: z.string().trim().min(1) instead of z.string().min(1)\n"
    fi
  fi

  if grep -E "email[[:space:]]*:[[:space:]]*z\.(string\(\)\.)?email\(" "$FILE_PATH" >/dev/null 2>&1; then
    if ! grep -E "email[[:space:]]*:[[:space:]]*z\.string\(\)[[:space:]]*\.toLowerCase\(\)" "$FILE_PATH" >/dev/null 2>&1; then
      VIOLATIONS="${VIOLATIONS}⚠️  Email field without .toLowerCase() → Add .toLowerCase() before validation\n"
      VIOLATIONS="${VIOLATIONS}   Example: z.string().toLowerCase().email() or z.email().toLowerCase()\n"
    fi
  fi
fi

if [[ -n "$VIOLATIONS" ]]; then
  echo "⚠️  Zod v4 Compliance Issues Detected:"
  echo ""
  echo -e "$VIOLATIONS"
  echo ""
  echo "💡 See skills/VALIDATION-string-formats/ and skills/ERRORS-customization/ for guidance"
  exit 1
fi

exit 0

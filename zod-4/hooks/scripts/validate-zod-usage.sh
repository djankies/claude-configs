#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_UTILS="$(cd "${SCRIPT_DIR}/../../../marketplace-utils" && pwd)"

source "${MARKETPLACE_UTILS}/hook-lifecycle.sh"

init_hook "zod-4" "validate-zod-usage"

input=$(read_hook_input)

file_path=$(get_input_field "parameters.file_path")
file_ext="${file_path##*.}"

[[ "$file_ext" != "ts" && "$file_ext" != "tsx" && "$file_ext" != "js" && "$file_ext" != "jsx" && "$file_ext" != "json" ]] && echo "{}" && exit 0

violations=""

if [[ "$file_ext" == "json" && "$file_path" == *"package.json" ]]; then
  zod_version=$(grep -o '"zod"[[:space:]]*:[[:space:]]*"[^"]*"' "$file_path" 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)

  if [[ -n "$zod_version" ]]; then
    major_version=$(echo "$zod_version" | cut -d. -f1)
    if [[ "$major_version" -lt 4 ]]; then
      violations="${violations}❌ Zod version $zod_version detected. This plugin targets Zod v4.x\n"
      violations="${violations}   Upgrade: npm install zod@latest\n"
    fi
  fi
fi

if [[ "$file_ext" =~ ^(ts|tsx|js|jsx)$ ]]; then
  grep -q "from ['\"]zod['\"]" "$file_path" 2>/dev/null || grep -q "import zod" "$file_path" 2>/dev/null || echo "{}" && exit 0

  if grep -E "z\.string\(\)\.email\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}❌ Deprecated: z.string().email() → Use z.email()\n"
  fi

  if grep -E "z\.string\(\)\.uuid\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}❌ Deprecated: z.string().uuid() → Use z.uuid()\n"
  fi

  if grep -E "z\.string\(\)\.datetime\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}❌ Deprecated: z.string().datetime() → Use z.iso.datetime()\n"
  fi

  if grep -E "z\.string\(\)\.url\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}❌ Deprecated: z.string().url() → Use z.url()\n"
  fi

  if grep -E "z\.string\(\)\.cuid\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}❌ Deprecated: z.string().cuid() → Use z.cuid()\n"
  fi

  if grep -E "z\.string\(\)\.cuid2\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}❌ Deprecated: z.string().cuid2() → Use z.cuid2()\n"
  fi

  if grep -E "z\.string\(\)\.ulid\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}❌ Deprecated: z.string().ulid() → Use z.ulid()\n"
  fi

  if grep -E "z\.string\(\)\.jwt\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}❌ Deprecated: z.string().jwt() → Use z.jwt()\n"
  fi

  if grep -E "(message|errorMap|invalid_type_error|required_error)[[:space:]]*:" "$file_path" 2>/dev/null | grep -v "error[[:space:]]*:" >/dev/null 2>&1; then
    violations="${violations}⚠️  Deprecated error customization detected\n"
    violations="${violations}   Use { error: '...' } instead of { message, errorMap, invalid_type_error, required_error }\n"
  fi

  if grep -E "\.merge\(" "$file_path" >/dev/null 2>&1; then
    violations="${violations}⚠️  .merge() is deprecated → Use .extend()\n"
  fi

  if grep "\.parse(" "$file_path" >/dev/null 2>&1; then
    if grep -B5 -A5 "\.parse(" "$file_path" 2>/dev/null | grep -E "(try|catch)" >/dev/null 2>&1; then
      violations="${violations}⚠️  Anti-pattern: .parse() with try/catch → Use .safeParse() instead\n"
    fi
  fi

  if grep -E "z\.enum\(\[['\"]true['\"],\s*['\"]false['\"]\]\)" "$file_path" >/dev/null 2>&1 || \
     grep -E "z\.enum\(\[['\"]false['\"],\s*['\"]true['\"]\]\)" "$file_path" >/dev/null 2>&1 || \
     grep -E "z\.enum\(\[['\"]yes['\"],\s*['\"]no['\"]\]\)" "$file_path" >/dev/null 2>&1 || \
     grep -E "z\.enum\(\[['\"]no['\"],\s*['\"]yes['\"]\]\)" "$file_path" >/dev/null 2>&1; then
    violations="${violations}⚠️  Boolean enum detected → Use z.stringbool() for 'true'/'false' values\n"
  fi

  if grep -E "(firstName|lastName|username|fullName|name)[[:space:]]*:[[:space:]]*z\.string\(\)[[:space:]]*\.min\([^)]*\)" "$file_path" >/dev/null 2>&1; then
    if ! grep -E "(firstName|lastName|username|fullName|name)[[:space:]]*:[[:space:]]*z\.string\(\)[[:space:]]*\.trim\(\)" "$file_path" >/dev/null 2>&1; then
      violations="${violations}⚠️  Name field without .trim() → Add .trim() before validation\n"
      violations="${violations}   Example: z.string().trim().min(1) instead of z.string().min(1)\n"
    fi
  fi

  if grep -E "email[[:space:]]*:[[:space:]]*z\.(string\(\)\.)?email\(" "$file_path" >/dev/null 2>&1; then
    if ! grep -E "email[[:space:]]*:[[:space:]]*z\.string\(\)[[:space:]]*\.toLowerCase\(\)" "$file_path" >/dev/null 2>&1; then
      violations="${violations}⚠️  Email field without .toLowerCase() → Add .toLowerCase() before validation\n"
      violations="${violations}   Example: z.string().toLowerCase().email() or z.email().toLowerCase()\n"
    fi
  fi
fi

if [[ -n "$violations" ]]; then
  context="⚠️  Zod v4 Compliance Issues Detected:

${violations}
💡 See skills/VALIDATION-string-formats/ and skills/ERRORS-customization/ for guidance"

  log_warn "Zod v4 compliance issues detected in $file_path"
  posttooluse_respond "" "" "$context"
  exit 0
fi

echo "{}"

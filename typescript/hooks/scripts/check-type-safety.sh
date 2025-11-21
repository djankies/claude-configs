#!/bin/bash

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

if [[ -z "$FILE_PATH" || -z "$NEW_STRING" ]]; then
  exit 0
fi

FILE_EXT="${FILE_PATH##*.}"
if [[ "$FILE_EXT" != "ts" && "$FILE_EXT" != "tsx" ]]; then
  exit 0
fi

ISSUES=()

if echo "$NEW_STRING" | grep -q ': any\|<any>\|= any\| any\[\]'; then
  ISSUES+=("⚠️  Type Safety: Code contains 'any' type - consider using 'unknown' with type guards instead")
  ISSUES+=("   See: @typescript/TYPES-any-vs-unknown skill")
fi

if echo "$NEW_STRING" | grep -q ' as [A-Z]'; then
  if ! echo "$NEW_STRING" | grep -q 'as const'; then
    ISSUES+=("⚠️  Type Safety: Type assertion detected - ensure data is validated before assertion")
    ISSUES+=("   See: @typescript/VALIDATION-type-assertions skill")
  fi
fi

if echo "$NEW_STRING" | grep -Eq '<T\s*>|<T\s*=\s*any>'; then
  ISSUES+=("⚠️  Type Safety: Generic type without constraints - consider adding 'extends' constraint")
  ISSUES+=("   See: @typescript/TYPES-generics skill")
fi

if echo "$NEW_STRING" | grep -iq 'password.*=.*Buffer.*toString.*base64'; then
  echo "🚨 CRITICAL SECURITY VIOLATION: Base64 encoding detected on password field"
  echo "Base64 is NOT encryption. Use bcrypt or argon2 for password hashing."
  echo "See: @typescript/SECURITY-credentials skill"
  exit 2
fi

if echo "$NEW_STRING" | grep -iq 'paypalPassword\|googlePassword\|facebookPassword'; then
  echo "🚨 CRITICAL SECURITY VIOLATION: Accepting third-party credentials"
  echo "NEVER ask for passwords to other services. Use OAuth instead."
  echo "See: @typescript/SECURITY-credentials skill"
  exit 2
fi

if [[ ${#ISSUES[@]} -gt 0 ]]; then
  printf '%s\n' "${ISSUES[@]}"
fi

exit 0

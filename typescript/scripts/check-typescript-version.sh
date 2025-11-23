#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "typescript" "SessionStart"

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${SCRIPT_DIR}/..}"

if [[ ! -d "$PLUGIN_ROOT/node_modules" ]]; then
  log_info "Installing TypeScript compiler dependencies..."

  if ! command -v npm >/dev/null 2>&1; then
    log_warn "npm not found - skipping dependency installation"
  else
    if (cd "$PLUGIN_ROOT" && npm install --silent --no-audit --no-fund >/dev/null 2>&1); then
      if [[ -d "$PLUGIN_ROOT/node_modules" ]]; then
        log_info "Dependencies installed successfully"
      else
        log_error "npm install succeeded but node_modules not created"
      fi
    else
      log_error "npm install failed - TypeScript compiler validation will be disabled"
    fi
  fi
fi

read_hook_input > /dev/null
CWD=$(get_input_field "cwd")

if [[ -z "$CWD" || "$CWD" == "null" ]]; then
  CWD="."
fi

PACKAGE_JSON="$CWD/package.json"
TSCONFIG_JSON="$CWD/tsconfig.json"

CONTEXT_MESSAGE=""

if [[ ! -f "$PACKAGE_JSON" ]]; then
  log_warn "No package.json found"
  CONTEXT_MESSAGE="⚠️  No package.json found. TypeScript plugin activated but cannot verify TypeScript version."
  inject_context "$CONTEXT_MESSAGE"
  finish_hook 0
fi

TS_VERSION=$(grep -o '"typescript": *"[^"]*"' "$PACKAGE_JSON" 2>/dev/null | grep -o '[0-9][^"]*' | head -1 || echo "")

if [[ -z "$TS_VERSION" ]]; then
  DEV_TS_VERSION=$(grep -o '"@types/typescript": *"[^"]*"' "$PACKAGE_JSON" 2>/dev/null | grep -o '[0-9][^"]*' | head -1 || echo "")
  if [[ -n "$DEV_TS_VERSION" ]]; then
    TS_VERSION="$DEV_TS_VERSION"
  fi
fi

if [[ -z "$TS_VERSION" ]]; then
  log_warn "TypeScript not found in package.json"
  CONTEXT_MESSAGE="⚠️  TypeScript not found in package.json. TypeScript plugin activated.
   Install: npm install --save-dev typescript"
  inject_context "$CONTEXT_MESSAGE"
  finish_hook 0
fi

MAJOR_VERSION=$(echo "$TS_VERSION" | grep -o '^[0-9]*' | head -1)

if [[ "$MAJOR_VERSION" -lt 5 ]]; then
  log_warn "TypeScript version $TS_VERSION is older than TypeScript 5"
  CONTEXT_MESSAGE="⚠️  TypeScript version $TS_VERSION detected. Consider upgrading to TypeScript 5.x.
   Some features (const type parameters, satisfies) require TypeScript 4.9+
   Upgrade: npm install --save-dev typescript@latest"
elif [[ "$MAJOR_VERSION" -eq 5 ]]; then
  log_info "TypeScript 5 detected ($TS_VERSION)"
  CONTEXT_MESSAGE="✓ TypeScript $TS_VERSION detected. TypeScript plugin activated.
  Skills available: type-safety, security, best-practices, patterns
  Validation: Pattern detection + TypeScript compiler checks"
else
  log_info "TypeScript $TS_VERSION detected"
  CONTEXT_MESSAGE="✓ TypeScript $TS_VERSION detected. TypeScript plugin activated."
fi

if [[ -f "$TSCONFIG_JSON" ]]; then
  log_info "tsconfig.json found"

  STRICT_MODE=$(grep -o '"strict": *true' "$TSCONFIG_JSON" 2>/dev/null || echo "")
  if [[ -n "$STRICT_MODE" ]]; then
    CONTEXT_MESSAGE="${CONTEXT_MESSAGE}
  Strict mode: enabled ✓"
  else
    CONTEXT_MESSAGE="${CONTEXT_MESSAGE}
  Strict mode: disabled (consider enabling for better type safety)"
  fi
else
  CONTEXT_MESSAGE="${CONTEXT_MESSAGE}
  No tsconfig.json - consider adding for better type checking"
fi

inject_context "$CONTEXT_MESSAGE"
finish_hook 0

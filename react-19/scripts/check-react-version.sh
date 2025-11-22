#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "react-19" "SessionStart"

read_hook_input > /dev/null
CWD=$(get_input_field "cwd")

if [[ -z "$CWD" || "$CWD" == "null" ]]; then
  CWD="."
fi

PACKAGE_JSON="$CWD/package.json"

if [[ ! -f "$PACKAGE_JSON" ]]; then
  log_warn "No package.json found"
  inject_context "⚠️  No package.json found. React 19 plugin activated but cannot verify React version."
  finish_hook 0
fi

REACT_VERSION=$(grep -o '"react": *"[^"]*"' "$PACKAGE_JSON" | grep -o '[0-9][^"]*' | head -1)

if [[ -z "$REACT_VERSION" ]]; then
  log_warn "React not found in package.json"
  inject_context "⚠️  React not found in package.json. React 19 plugin activated."
  finish_hook 0
fi

MAJOR_VERSION=$(echo "$REACT_VERSION" | grep -o '^[0-9]*' | head -1)

CONTEXT_MESSAGE=""

if [[ "$MAJOR_VERSION" -lt 19 ]]; then
  log_warn "React version $REACT_VERSION is older than React 19"
  CONTEXT_MESSAGE="⚠️  React version $REACT_VERSION detected. This plugin is optimized for React 19.
   Some patterns (use hook, useActionState, ref-as-prop) require React 19.
   Consider upgrading: npm install react@19 react-dom@19"
elif [[ "$MAJOR_VERSION" -eq 19 ]]; then
  log_info "React 19 detected ($REACT_VERSION)"
  CONTEXT_MESSAGE="✓ React 19 detected ($REACT_VERSION). React 19 plugin activated.
  Skills available: hooks, components, forms, state, performance, testing
  Documentation: research/react-19-comprehensive.md"
else
  log_info "React $REACT_VERSION detected"
  CONTEXT_MESSAGE="✓ React $REACT_VERSION detected. React 19 plugin activated."
fi

if [[ -f ".react-19-plugin/validation-rules.json" ]]; then
  log_info "Validation rules loaded"
  CONTEXT_MESSAGE="${CONTEXT_MESSAGE}
  Validation rules loaded."
fi

inject_context "$CONTEXT_MESSAGE"
finish_hook 0

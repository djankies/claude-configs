# Hook Development Guide

This guide explains how to write hooks for Claude Code plugins using the `hook-lifecycle.sh` wrapper.

## Table of Contents

- [Hook Lifecycle Overview](#hook-lifecycle-overview)
- [Quick Start](#quick-start)
- [Using hook-lifecycle.sh](#using-hook-lifecyclesh)
- [Available Helper Functions](#available-helper-functions)
- [Hook Event Types](#hook-event-types)
- [Security Considerations](#security-considerations)
- [Best Practices](#best-practices)
- [Testing Hooks](#testing-hooks)
- [Debugging](#debugging)

## Hook Lifecycle Overview

Claude Code hooks are Bash scripts that respond to events in the Claude Code lifecycle:

1. **SessionStart**: Fired when a new Claude session begins
2. **PreToolUse**: Fired before a tool is executed (can block or modify)
3. **PostToolUse**: Fired after a tool executes (can inject context)
4. **Stop**: Fired when the session ends

Hooks receive JSON input via stdin and output JSON responses to stdout.

## Quick Start

Here's the simplest possible hook:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "my-plugin" "my-hook"

exit 0
```

This hook does nothing but initialize correctly. Let's build from here.

## Using hook-lifecycle.sh

The `hook-lifecycle.sh` wrapper provides all the infrastructure you need:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "my-plugin" "my-hook"

input=$(read_hook_input)

tool_name=$(get_input_field "tool_name")
log_info "Processing tool: $tool_name"

exit 0
```

**What `init_hook` does:**

- Validates the plugin name
- Checks for required dependencies (jq)
- Initializes session management
- Sets up logging and error reporting
- Exports environment variables:
  - `PLUGIN_NAME`: Your plugin name
  - `HOOK_NAME`: Your hook name
  - `HOOK_EVENT`: The event type triggering this hook
  - `SESSION_FILE`: Path to the session state file

## Available Helper Functions

### Input Handling

#### `read_hook_input()`

Reads JSON input from stdin and stores it in `HOOK_INPUT` environment variable:

```bash
input=$(read_hook_input)
```

#### `get_input_field(path)`

Extracts a field from the hook input using jq path syntax:

```bash
tool_name=$(get_input_field "tool_name")
file_path=$(get_input_field "tool_input.file_path")
content=$(get_input_field "tool_input.content")
```

### Response Helpers

#### `pretooluse_respond(decision, reason, updated_input)`

Generates a PreToolUse response:

```bash
pretooluse_respond "allow"
pretooluse_respond "block" "File is sensitive"
pretooluse_respond "allow" "" '{"tool_name":"Write","tool_input":{"file_path":"safe.ts"}}'
```

**Parameters:**
- `decision`: "allow" or "block"
- `reason`: Optional explanation (required for "block")
- `updated_input`: Optional JSON string with modified tool input

#### `posttooluse_respond(decision, reason, context)`

Generates a PostToolUse response:

```bash
posttooluse_respond "" "" "Skill recommendations available"
posttooluse_respond "block" "Validation failed" ""
```

**Parameters:**
- `decision`: Optional "block" to prevent further tool use
- `reason`: Explanation for decision
- `context`: Additional context to inject into conversation

#### `inject_context(context, hook_event)`

Injects context into the conversation:

```bash
inject_context "TypeScript file detected - React 19 skills available"
inject_context "Session initialized" "SessionStart"
```

#### `stop_respond(decision, reason)`

Generates a Stop hook response:

```bash
stop_respond ""
stop_respond "block" "Must save work first"
```

### Security Helpers

#### `validate_file_path(path)`

Validates a file path for security issues:

```bash
if validate_file_path "$file_path"; then
  log_info "Path is safe: $file_path"
fi
```

**Checks for:**
- Path traversal attempts (`..`)
- Suspicious characters

#### `is_sensitive_file(file)`

Checks if a file contains sensitive data:

```bash
if is_sensitive_file "$file_path"; then
  pretooluse_respond "block" "Cannot access sensitive file: $file_path"
  exit 0
fi
```

**Detects:**
- `.env` files
- SSH keys (`id_rsa`, `id_ed25519`)
- Git internals (`.git/*`)
- Credentials files (`credentials.json`, `*.pem`, `*.key`)
- Dependencies (`node_modules/*`, `vendor/*`, `.venv/*`)

### Session Management

#### `has_shown_recommendation(plugin, skill_name)`

Check if a skill recommendation has been shown:

```bash
if ! has_shown_recommendation "my-plugin" "typescript-linting"; then
  echo "TypeScript file detected - linting skills available"
  mark_recommendation_shown "my-plugin" "typescript-linting"
fi
```

#### `mark_recommendation_shown(plugin, skill_name)`

Mark a skill recommendation as shown.

#### `has_passed_validation(validation_name, file_path)`

Check if a validation has already passed:

```bash
if ! has_passed_validation "react-19-check" "$file_path"; then
  mark_validation_passed "react-19-check" "$file_path"
fi
```

#### `mark_validation_passed(validation_name, file_path)`

Mark a validation as passed for a specific file.

### Logging

#### `log_debug(message)`, `log_info(message)`, `log_warn(message)`, `log_error(message)`

Log messages at different levels:

```bash
log_debug "Processing file: $file_path"
log_info "Validation complete"
log_warn "Deprecated pattern detected"
log_error "Validation failed"
```

Set `CLAUDE_DEBUG_LEVEL` to control visibility:

```bash
export CLAUDE_DEBUG_LEVEL=DEBUG
export CLAUDE_DEBUG_LEVEL=INFO
export CLAUDE_DEBUG_LEVEL=WARN
export CLAUDE_DEBUG_LEVEL=ERROR
```

### Error Reporting

#### `fatal_error(code, message)`

Report a fatal error and exit:

```bash
if [[ ! -f "$config_file" ]]; then
  fatal_error "CONFIG_NOT_FOUND" "Configuration file missing: $config_file"
fi
```

## Hook Event Types

### SessionStart

Fired when a new Claude session begins. Use for initialization.

**Input:** Empty or minimal session metadata

**Example:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "my-plugin" "session-start"

log_info "Session starting for plugin: $PLUGIN_NAME"

inject_context "my-plugin initialized - TypeScript and React skills available"

exit 0
```

### PreToolUse

Fired before a tool executes. Can block or modify tool execution.

**Input:** Tool name and tool input parameters

**Use cases:**
- Validate file paths before reading/writing
- Block access to sensitive files
- Modify tool parameters
- Show contextual skill recommendations

**Example - Block Sensitive Files:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "security-plugin" "block-sensitive-files"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

if [[ "$tool_name" == "Read" || "$tool_name" == "Write" ]]; then
  file_path=$(get_input_field "tool_input.file_path")

  if [[ -z "$file_path" ]]; then
    pretooluse_respond "allow"
    exit 0
  fi

  validate_file_path "$file_path"

  if is_sensitive_file "$file_path"; then
    pretooluse_respond "block" "Access denied: $file_path contains sensitive data"
    exit 0
  fi
fi

pretooluse_respond "allow"
exit 0
```

**Example - Show Contextual Recommendations:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "typescript-plugin" "recommend-skills"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

if [[ "$tool_name" != "Read" && "$tool_name" != "Write" ]]; then
  exit 0
fi

file_path=$(get_input_field "tool_input.file_path")

if [[ -z "$file_path" ]]; then
  exit 0
fi

file_ext="${file_path##*.}"

case "$file_ext" in
  ts|tsx)
    if [[ "$file_path" == *"test"* || "$file_path" == *"spec"* ]]; then
      if ! has_shown_recommendation "$PLUGIN_NAME" "testing"; then
        echo "Test file detected: testing and TDD skills available"
        mark_recommendation_shown "$PLUGIN_NAME" "testing"
      fi
    else
      if ! has_shown_recommendation "$PLUGIN_NAME" "typescript"; then
        echo "TypeScript file: linting and refactoring skills available"
        mark_recommendation_shown "$PLUGIN_NAME" "typescript"
      fi
    fi
    ;;
esac

exit 0
```

### PostToolUse

Fired after a tool executes. Can inject context or perform validations.

**Input:** Tool name, tool input, tool output, and execution result

**Use cases:**
- Validate written code for anti-patterns
- Suggest improvements after file edits
- Track state for future recommendations
- Inject helpful context

**Example - Validate Code Patterns:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "react-plugin" "validate-react-19"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

if [[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]]; then
  exit 0
fi

file_path=$(get_input_field "tool_input.file_path")
content=$(get_input_field "tool_input.content")

if [[ -z "$file_path" || -z "$content" ]]; then
  exit 0
fi

file_ext="${file_path##*.}"

if [[ "$file_ext" != "tsx" && "$file_ext" != "jsx" ]]; then
  exit 0
fi

if has_passed_validation "react-19-patterns" "$file_path"; then
  exit 0
fi

if echo "$content" | grep -q "componentWillMount\|componentWillReceiveProps"; then
  posttooluse_respond "block" "Deprecated React lifecycle methods detected" \
    "The file uses deprecated lifecycle methods. Use functional components and hooks instead."
  exit 0
fi

if echo "$content" | grep -q "defaultProps"; then
  log_warn "defaultProps usage detected in $file_path"
  posttooluse_respond "" "" \
    "Note: defaultProps is deprecated in React 19. Consider using default parameters instead."
  exit 0
fi

mark_validation_passed "react-19-patterns" "$file_path"
exit 0
```

**Example - Track Statistics:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "stats-plugin" "track-edits"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

if [[ "$tool_name" == "Write" || "$tool_name" == "Edit" ]]; then
  file_path=$(get_input_field "tool_input.file_path")

  current_count=$(get_custom_data "edit_count" || echo "0")
  new_count=$((current_count + 1))

  set_custom_data "edit_count" "$new_count"

  log_info "Total edits this session: $new_count"
fi

exit 0
```

### Stop

Fired when the session ends. Use for cleanup or final validations.

**Input:** Minimal session metadata

**Use cases:**
- Remind user to commit changes
- Clean up temporary files
- Show session statistics
- Validate final state

**Example:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "git-plugin" "remind-commit"

if command -v git >/dev/null 2>&1; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
      echo ""
      echo "Uncommitted changes detected!"
      echo "Run 'git status' to review changes."
      echo ""

      stop_respond "block" "You have uncommitted changes. Commit or stash them first."
      exit 0
    fi
  fi
fi

stop_respond ""
exit 0
```

## Security Considerations

### Always Validate File Paths

```bash
file_path=$(get_input_field "tool_input.file_path")

if [[ -n "$file_path" ]]; then
  validate_file_path "$file_path"

  if is_sensitive_file "$file_path"; then
    pretooluse_respond "block" "Access denied to sensitive file"
    exit 0
  fi
fi
```

### Sanitize External Input

Never pass user input directly to shell commands:

```bash
file_path=$(get_input_field "tool_input.file_path")

if [[ "$file_path" =~ [^\;] ]]; then
  log_error "Invalid characters in file path"
  exit 1
fi
```

### Use jq for JSON

Always use `jq` to parse and generate JSON:

```bash
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

pretooluse_respond "allow"
```

Never construct JSON with string concatenation.

### Check Dependencies

```bash
if ! command -v jq >/dev/null 2>&1; then
  fatal_error "MISSING_DEPENDENCY" "jq is required but not installed"
fi
```

The `init_hook` function checks for `jq` automatically, but check for other dependencies manually.

## Best Practices

### 1. Exit Early for Irrelevant Events

```bash
tool_name=$(get_input_field "tool_name")

if [[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]]; then
  exit 0
fi
```

### 2. Use Session State to Avoid Repetition

```bash
if ! has_shown_recommendation "$PLUGIN_NAME" "react-skills"; then
  echo "React file detected - hooks and component skills available"
  mark_recommendation_shown "$PLUGIN_NAME" "react-skills"
fi
```

### 3. Log Debug Information

```bash
log_debug "Processing file: $file_path (type: $file_ext)"
log_debug "Tool: $tool_name"
log_debug "Session file: $SESSION_FILE"
```

### 4. Handle Missing Fields Gracefully

```bash
file_path=$(get_input_field "tool_input.file_path")

if [[ -z "$file_path" ]]; then
  log_debug "No file_path in input, skipping"
  exit 0
fi
```

### 5. Use Specific Error Codes

```bash
fatal_error "CONFIG_NOT_FOUND" "Missing config: $config_path"
fatal_error "INVALID_FILE_TYPE" "Expected .ts file, got: $file_ext"
fatal_error "VALIDATION_FAILED" "React 19 validation failed: deprecated patterns"
```

### 6. Keep Hooks Fast

Hooks run on every tool use. Optimize for speed:

```bash
if [[ "$file_ext" != "ts" ]]; then
  exit 0
fi

if has_passed_validation "typescript-check" "$file_path"; then
  exit 0
fi
```

### 7. Provide Helpful Messages

```bash
if is_sensitive_file "$file_path"; then
  pretooluse_respond "block" \
    "Cannot access $file_path - this file may contain secrets. Use .gitignore patterns."
  exit 0
fi
```

### 8. Document Your Hooks

Add a header comment explaining what the hook does:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hook-lifecycle.sh"

init_hook "typescript-plugin" "validate-imports"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

exit 0
```

## Testing Hooks

### Manual Testing

Create test input files and pipe them to your hook:

```bash
cat test-input.json | ./my-hook.sh
```

**test-input.json:**

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "src/test.ts",
    "content": "export const foo = () => {}"
  }
}
```

### Automated Testing

Use the test infrastructure in `marketplace-utils/tests/`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CLAUDE_SESSION_PID=$$
export CLAUDE_MARKETPLACE_ROOT="$SCRIPT_DIR/.."

cleanup() {
  rm -f "/tmp/claude-session-$$.json"
  rm -f "/tmp/claude-session-$$.log"
}
trap cleanup EXIT

test_my_hook() {
  local input='{"tool_name":"Write","tool_input":{"file_path":"test.ts"}}'

  local output
  output=$(echo "$input" | "${SCRIPT_DIR}/../hooks/my-hook.sh")

  if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' >/dev/null; then
    echo "PASS: Hook allows safe files"
    return 0
  else
    echo "FAIL: Hook should allow safe files"
    return 1
  fi
}

test_my_hook
```

### Test Multiple Scenarios

```bash
test_allows_safe_files() {
  local input='{"tool_name":"Write","tool_input":{"file_path":"src/safe.ts"}}'
  local output=$(echo "$input" | ./my-hook.sh)

  if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' >/dev/null; then
    echo "PASS"
    return 0
  fi
  echo "FAIL"
  return 1
}

test_blocks_env_files() {
  local input='{"tool_name":"Read","tool_input":{"file_path":".env"}}'
  local output=$(echo "$input" | ./my-hook.sh)

  if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "block"' >/dev/null; then
    echo "PASS"
    return 0
  fi
  echo "FAIL"
  return 1
}
```

## Debugging

### Enable Debug Logging

```bash
export CLAUDE_DEBUG_LEVEL=DEBUG
./my-hook.sh < test-input.json
```

### Check Log Files

```bash
tail -f /tmp/claude-session-$$.log
```

### Inspect Session State

```bash
cat /tmp/claude-session-$$.json | jq .
```

### Trace Hook Execution

Add trace output:

```bash
set -x
```

Or log each step:

```bash
log_debug "Reading input..."
input=$(read_hook_input)
log_debug "Input read: ${#input} bytes"

log_debug "Extracting tool_name..."
tool_name=$(get_input_field "tool_name")
log_debug "Tool name: $tool_name"
```

### Test JSON Output

Validate your output is valid JSON:

```bash
./my-hook.sh < test-input.json | jq .
```

### Common Issues

**"jq: command not found"**

Install jq:

```bash
brew install jq
apt-get install jq
```

**"Permission denied"**

Make your hook executable:

```bash
chmod +x my-hook.sh
```

**"HOOK_INPUT not set"**

You must call `read_hook_input()` before using `get_input_field()`:

```bash
input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")
```

**"Session file not found"**

Call `init_hook()` at the start of your script:

```bash
init_hook "my-plugin" "my-hook"
```

**"Invalid JSON output"**

Always use response helpers instead of `echo`:

```bash
pretooluse_respond "allow"
```

Not:

```bash
echo '{"decision":"allow"}'
```

## Advanced Patterns

### Conditional Context Injection

```bash
if [[ "$file_ext" == "tsx" ]]; then
  if echo "$content" | grep -q "useState"; then
    inject_context "React hooks detected - consider reviewing hook dependencies and memoization"
  fi
fi
```

### Multi-File Validation

```bash
declare -A validations

validate_file() {
  local file="$1"

  if [[ -n "${validations[$file]:-}" ]]; then
    return 0
  fi

  validations[$file]="validated"
}
```

### Progressive Recommendations

```bash
edit_count=$(get_custom_data "edit_count" || echo "0")

if [[ $edit_count -eq 5 ]] && ! has_shown_recommendation "$PLUGIN_NAME" "testing-reminder"; then
  echo "You've made 5 edits. Consider running tests."
  mark_recommendation_shown "$PLUGIN_NAME" "testing-reminder"
fi
```

### Plugin Coordination

```bash
typescript_active=$(get_plugin_value "typescript-plugin" "active")

if [[ "$typescript_active" == "true" ]]; then
  log_info "TypeScript plugin is active, skipping duplicate checks"
  exit 0
fi
```

## Summary

Key takeaways for writing hooks:

1. Always source `hook-lifecycle.sh` and call `init_hook()`
2. Use helper functions for input parsing and response generation
3. Exit early for irrelevant events
4. Use session state to avoid repetitive recommendations
5. Validate file paths and check for sensitive files
6. Log debug information generously
7. Test with multiple scenarios
8. Keep hooks fast and focused

For more examples, see:
- `marketplace-utils/hook-templates/`
- `marketplace-utils/tests/test-hook-lifecycle.sh`

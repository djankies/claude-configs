# Hooks Reference

Reference documentation for implementing hooks in Claude Code. See [Get started with Claude Code hooks](/en/hooks-guide) for quickstart guide with examples.

## Configuration

Configure hooks in [settings files](/en/settings):

- `~/.claude/settings.json` (user)
- `.claude/settings.json` (project)
- `.claude/settings.local.json` (local, not committed)
- Enterprise managed policy settings

### Structure

Hooks organized by event, each with matchers and hook arrays:

```json theme={null}
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command|prompt",
            "command": "bash-command" // for type: command
            "prompt": "LLM prompt"    // for type: prompt
            "timeout": 60             // optional, seconds
          }
        ]
      }
    ]
  }
}
```

**Matcher** (case-sensitive; omit for `UserPromptSubmit`, `Stop`, `SubagentStop`, `PreCompact`, `SessionStart`, `SessionEnd`):

- Simple string matches exactly: `Write`
- Regex patterns: `Edit|Write`, `Notebook.*`
- `*` matches all tools; empty string (`""`) equivalent

**Hooks**: `type` is `"command"` (bash) or `"prompt"` (LLM evaluation). For LLM prompts, use `$ARGUMENTS` placeholder for hook input JSON; if absent, input appended to prompt. Optional `timeout` (default 60s for commands, 30s for prompts) cancels individual hook.

**Project-specific scripts**: Reference scripts via `$CLAUDE_PROJECT_DIR` environment variable:

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-style.sh"
          }
        ]
      }
    ]
  }
}
```

### Plugin Hooks

Plugins define hooks in `hooks/hooks.json` or custom path. When enabled, plugin hooks merge with user/project hooks and run alongside them in parallel. Use `${CLAUDE_PLUGIN_ROOT}` for plugin files, `${CLAUDE_PROJECT_DIR}` for project root. Plugin hooks support optional `description` field. See [plugin components reference](/en/plugins-reference#hooks).

## Prompt-Based Hooks

Prompt-based hooks (`type: "prompt"`) use LLM (Haiku) for context-aware decisions. Supported for `Stop`, `SubagentStop`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`.

Process: (1) Send hook input and prompt to LLM; (2) LLM responds with JSON; (3) Claude Code processes decision.

**Response schema**:

```json theme={null}
{
  "decision": "approve"|"block",
  "reason": "Explanation",
  "continue": false,        // Optional: stops Claude entirely
  "stopReason": "Message",  // Optional: message shown to user
  "systemMessage": "Alert"  // Optional: shown to user
}
```

**Best practices**: Be specific; list decision criteria; test prompts; set appropriate timeouts; use for complex decisions (bash hooks better for deterministic rules).

**Example**:

```json theme={null}
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if Claude should stop. Context: $ARGUMENTS. Analyze: (1) tasks complete? (2) errors to fix? (3) follow-up needed? Respond: {\"decision\": \"approve\"|\"block\", \"reason\": \"explanation\"}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Comparison**:

| Feature           | Bash Commands       | Prompt-Based                   |
| ----------------- | ------------------- | ------------------------------ |
| Execution         | Runs bash script    | Queries LLM                    |
| Logic             | Code-implemented    | LLM evaluates context          |
| Setup             | Requires script     | Just configure prompt          |
| Context awareness | Limited             | Natural language understanding |
| Performance       | Fast (local)        | Slower (API call)              |
| Use case          | Deterministic rules | Context-aware decisions        |

## Hook Events

**PreToolUse**: After Claude creates tool parameters, before tool processing. Common matchers: `Task`, `Bash`, `Glob`, `Grep`, `Read`, `Edit`, `Write`, `WebFetch`, `WebSearch`. Use [PreToolUse decision control](#pretooluse-decision-control) to allow/deny/ask permission.

**PermissionRequest**: When user shown permission dialog. Same matchers as PreToolUse. Use [PermissionRequest decision control](#permissionrequest-decision-control).

**PostToolUse**: Immediately after tool succeeds. Same matchers as PreToolUse.

**Notification**: When Claude Code sends notifications. Common matchers: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`. Omit matcher to run for all notification types.

**UserPromptSubmit**: When user submits prompt, before processing. Allows context addition, validation, or blocking.

**Stop**: After main agent finishes (not if user interrupted).

**SubagentStop**: After subagent (Task tool) finishes.

**PreCompact**: Before compact operation. Matchers: `manual` (`/compact`), `auto` (context full).

**SessionStart**: When session starts or resumes. Matchers: `startup`, `resume` (`--resume`/`--continue`/`/resume`), `clear` (`/clear`), `compact`. Access `CLAUDE_ENV_FILE` to persist environment variables for subsequent commands:

```bash theme={null}
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
  # Or capture all environment changes:
  ENV_BEFORE=$(export -p | sort)
  source ~/.nvm/nvm.sh && nvm use 20
  ENV_AFTER=$(export -p | sort)
  comm -13 <(echo "$ENV_BEFORE") <(echo "$ENV_AFTER") >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

**SessionEnd**: When session ends. Reason field: `clear`, `logout`, `prompt_input_exit`, `other`.

## Hook Input

Hooks receive JSON via stdin with common fields (`session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`) plus event-specific data:

**PreToolUse**:

```json theme={null}
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": { "file_path": "/path/to/file.txt", "content": "..." },
  "tool_use_id": "toolu_01ABC123..."
}
```

**PostToolUse**: Same as PreToolUse plus `tool_response` field.

**Notification**:

```json theme={null}
{
  "...common fields...",
  "hook_event_name": "Notification",
  "message": "Claude needs your permission to use Bash",
  "notification_type": "permission_prompt"
}
```

**UserPromptSubmit**:

```json theme={null}
{
  "...common fields...",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "User's prompt text"
}
```

**Stop/SubagentStop**: Include `stop_hook_active` (true if already continuing from stop hook; check to prevent infinite loops).

**PreCompact**: Include `trigger` (`manual`/`auto`) and `custom_instructions`.

**SessionStart/SessionEnd**: Include `source`/`reason` respectively.

## Hook Output

Two mutually exclusive output methods:

### Exit Code (Simple)

- **0**: Success. stdout shown in verbose mode (ctrl+o), except UserPromptSubmit/SessionStart where stdout added as context. JSON in stdout parsed for structured control.
- **2**: Blocking error. Only stderr used as error message fed to Claude. JSON in stdout ignored.
- **Other**: Non-blocking error. stderr shown in verbose mode with format `Failed with non-blocking status code: {stderr}`.

**Exit Code 2 Behavior**:

| Event                              | Behavior                                            |
| ---------------------------------- | --------------------------------------------------- |
| PreToolUse                         | Blocks tool, shows stderr to Claude                 |
| PermissionRequest                  | Denies permission, shows stderr to Claude           |
| PostToolUse                        | Shows stderr to Claude                              |
| Notification                       | Shows stderr to user only                           |
| UserPromptSubmit                   | Blocks prompt, erases it, shows stderr to user only |
| Stop/SubagentStop                  | Blocks stoppage, shows stderr to Claude             |
| PreCompact/SessionStart/SessionEnd | Shows stderr to user only                           |

### JSON Output (Structured)

JSON processed only on exit code 0. Common optional fields:

```json theme={null}
{
  "continue": true, // Whether Claude continues (default: true)
  "stopReason": "string", // Message shown when continue=false
  "suppressOutput": false, // Hide stdout from transcript (default: false)
  "systemMessage": "string" // Warning shown to user (optional)
}
```

**PreToolUse Decision Control** (`"permissionDecision"` values):

- `"allow"`: Bypass permission system; `permissionDecisionReason` shown to user
- `"deny"`: Block tool; `permissionDecisionReason` shown to Claude
- `"ask"`: Ask user to confirm; `permissionDecisionReason` shown to user
- Use `updatedInput` to modify tool parameters before execution

```json theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Reason here",
    "updatedInput": { "field": "new_value" }
  }
}
```

**PermissionRequest Decision Control**:

```json theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow"|"deny",
      "updatedInput": {...},           // Optional for allow
      "message": "Why denied",         // Optional for deny
      "interrupt": false               // Optional for deny
    }
  }
}
```

**PostToolUse Decision Control**:

```json theme={null}
{
  "decision": "block"|undefined,
  "reason": "Explanation",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Additional info for Claude"
  }
}
```

**UserPromptSubmit Decision Control**:

- Add context via plain text stdout (simplest) or JSON `additionalContext`
- Block via `"decision": "block"` with `reason` shown to user

```json theme={null}
{
  "decision": "block"|undefined,
  "reason": "Why blocked",
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Additional context"
  }
}
```

**Stop/SubagentStop Decision Control**:

```json theme={null}
{
  "decision": "block"|undefined,
  "reason": "Must provide when blocking Claude from stopping"
}
```

**SessionStart Decision Control**:

```json theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Context to load"
  }
}
```

**Example: Bash Command Validation** (PreToolUse with exit code 2):

```python theme={null}
#!/usr/bin/env python3
import json, re, sys

RULES = [
    (r"\bgrep\b(?!.*\|)", "Use 'rg' instead of 'grep'"),
    (r"\bfind\s+\S+\s+-name\b", "Use 'rg --files | rg pattern' instead of 'find -name'"),
]

def validate(cmd: str) -> list[str]:
    return [msg for pattern, msg in RULES if re.search(pattern, cmd)]

input_data = json.load(sys.stdin)
if input_data.get("tool_name") != "Bash":
    sys.exit(1)

issues = validate(input_data.get("tool_input", {}).get("command", ""))
if issues:
    print("\n".join(f"• {msg}" for msg in issues), file=sys.stderr)
    sys.exit(2)
```

**Example: UserPromptSubmit with Validation and Context**:

```python theme={null}
#!/usr/bin/env python3
import json, re, sys, datetime

input_data = json.load(sys.stdin)
prompt = input_data.get("prompt", "")

# Block sensitive patterns
if re.search(r"(?i)\b(password|secret|key|token)\s*[:=]", prompt):
    print(json.dumps({"decision": "block", "reason": "Security: remove secrets"}))
    sys.exit(0)

# Add context
context = f"Current time: {datetime.datetime.now()}"
print(context)
sys.exit(0)
```

**Example: PreToolUse Auto-Approval**:

```python theme={null}
#!/usr/bin/env python3
import json, sys

input_data = json.load(sys.stdin)
if input_data.get("tool_name") == "Read":
    file_path = input_data.get("tool_input", {}).get("file_path", "")
    if file_path.endswith((".md", ".mdx", ".txt", ".json")):
        print(json.dumps({
            "decision": "approve",
            "reason": "Documentation auto-approved",
            "suppressOutput": True
        }))
        sys.exit(0)

sys.exit(0)
```

## Working with MCP Tools

MCP tools named `mcp__<server>__<tool>` (e.g., `mcp__memory__create_entities`, `mcp__filesystem__read_file`). Match specific tools or all from server:

```json theme={null}
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__memory__.*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Memory op' >> ~/mcp-ops.log"
          }
        ]
      },
      {
        "matcher": "mcp__.*__write.*",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/scripts/validate-write.py"
          }
        ]
      }
    ]
  }
}
```

## Security

**DISCLAIMER—USE AT YOUR OWN RISK**: Hooks execute arbitrary shell commands automatically. You are solely responsible. Hooks can modify/delete/access files your account can access. Malicious/poorly written hooks cause data loss/damage. Anthropic provides no warranty.

**Best practices**: (1) Validate/sanitize inputs; (2) Quote shell variables (`"$VAR"`, not `$VAR`); (3) Block path traversal (check for `..`); (4) Use absolute paths (use `$CLAUDE_PROJECT_DIR`); (5) Skip sensitive files (`.env`, `.git/`, keys).

**Configuration safety**: Hook snapshots captured at startup; edits don't take effect mid-session. Warnings issued if hooks modified externally. Changes require `/hooks` menu review to apply.

## Hook Execution Details

- **Timeout**: 60s default, configurable per command; timeouts for individual commands don't affect others
- **Parallelization**: All matching hooks run in parallel
- **Deduplication**: Identical hook commands deduplicated automatically
- **Environment**: Runs in current directory with Claude Code environment; `CLAUDE_PROJECT_DIR` available (project root); `CLAUDE_CODE_REMOTE` indicates web (`"true"`) vs local (empty/not set)
- **Input**: JSON via stdin
- **Output**: PreToolUse/PermissionRequest/PostToolUse/Stop/SubagentStop shown in verbose (ctrl+o); Notification/SessionEnd logged to debug only; UserPromptSubmit/SessionStart stdout added as context

## Debugging

**Troubleshooting**: (1) Run `/hooks` to verify registration; (2) Check JSON valid; (3) Test commands manually; (4) Verify script permissions; (5) Use `claude --debug` for details.

**Common issues**: Quotes not escaped (`\"` needed in JSON); matcher wrong (case-sensitive); command not found (use full paths).

**Advanced**: Use `claude --debug` for detailed execution. Example output:

```
[DEBUG] Executing hooks for PostToolUse:Write
[DEBUG] Getting matching hook commands for PostToolUse with query: Write
[DEBUG] Found 1 hook matchers in settings
[DEBUG] Matched 1 hooks for query "Write"
[DEBUG] Found 1 hook commands to execute
[DEBUG] Executing hook command: <cmd> with timeout 60000ms
[DEBUG] Hook command completed with status 0: <stdout>
```

Progress shown in verbose mode (ctrl+o): which hook running, command executed, success/failure, output/errors.

## Performance guidelines

Hook execution speed directly impacts developer workflow. Follow these guidelines:

**Execution targets:**
- **< 100ms ideal** - Provides instant feedback, imperceptible to users
- **< 500ms acceptable** - Minimal impact on workflow, standard target
- **> 1 second problematic** - Users may disable hooks, avoid at all costs

**Optimization strategies:**
- Use `grep`, `sed`, `awk` for pattern matching (not complex parsers)
- Early exit when conditions not met (check file extension first)
- Cache results when possible (store in /tmp)
- Avoid external API calls in synchronous hooks
- Use compiled tools for heavy work (not interpreted scripts)
- Limit file reads (don't read entire codebase)

**Testing performance:**
```bash
time /path/to/hook-script.sh < test-input.json
```

**Hook deduplication:** Claude Code automatically deduplicates identical hook commands across plugins, so multiple plugins can safely use the same validation script without performance penalty.

## Common hook patterns

Reusable patterns for typical hook use cases.

### Session state for once-per-session recommendations

**Problem:** Plugins need to recommend skills contextually without repeating the same recommendation multiple times per session, which causes context bloat.

**Solution:** Session state JSON file with boolean flags tracked per recommendation type.

**Pattern:**

**SessionStart hook** creates/resets state file:
```bash
#!/bin/bash

STATE_FILE="/tmp/claude-[plugin-name]-session.json"

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "recommendations_shown": {
    "context_type_1": false,
    "context_type_2": false,
    "context_type_3": false
  }
}
EOF

echo "[Plugin] session initialized"
```

**PreToolUse hook** checks/updates state:
```bash
#!/bin/bash

STATE_FILE="/tmp/claude-[plugin-name]-session.json"

[[ ! -f "$STATE_FILE" ]] && exit 0

FILE_PATH=$(echo "$1" | jq -r '.tool_input.file_path // empty')
FILE_EXT="${FILE_PATH##*.}"

RECOMMENDATION_TYPE=""
case "$FILE_EXT" in
  tsx|jsx)
    RECOMMENDATION_TYPE="react_context"
    MESSAGE="📚 React skills available: using-hooks, handling-forms"
    ;;
  *)
    exit 0
    ;;
esac

[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

exit 0
```

**Key benefits:**
- Once-per-session-per-type recommendations
- No context bloat from repetition
- Fast execution (< 1ms after first recommendation shown)
- No external dependencies (pure bash + sed/grep)
- Automatic cleanup on new session

**Variation for plugin-specific context:**
```bash
STATE_FILE="/tmp/claude-${PLUGIN_NAME}-session.json"
```

Use `${CLAUDE_PLUGIN_ROOT}` to get plugin-specific paths if needed.

### File pattern validation

**Problem:** Prevent deprecated patterns or anti-patterns in code.

**Solution:** Fast grep-based pattern detection with clear error messages.

**Pattern:**
```bash
#!/bin/bash

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && exit 0
[[ ! "$file_path" =~ \.(tsx|jsx|ts|js)$ ]] && exit 0

content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')

if echo "$content" | grep -q "forwardRef"; then
  echo "❌ Deprecated: forwardRef is deprecated in React 19" >&2
  echo "Use ref as regular prop instead" >&2
  exit 2
fi

exit 0
```

**Key features:**
- Early exit for non-relevant tools/files
- Clear error messages to stderr
- Exit code 2 blocks operation
- Fast pattern matching (< 50ms)

### Contextual skill loading

**Problem:** Load skill content only when specific file patterns detected.

**Solution:** PreToolUse hook with file pattern detection outputs skill reference.

**Pattern:**
```bash
#!/bin/bash

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [[ "$file_path" == *"/migrations/"* ]]; then
  echo "See {CLAUDE_PLUGIN_ROOT}/skills/handling-migrations/SKILL.md"
  exit 0
fi

exit 0
```

**Key benefits:**
- Skills load only when relevant
- Zero cost when pattern doesn't match
- Claude reads skill automatically from stdout

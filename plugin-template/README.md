# Claude Code Plugin Template

A comprehensive template for creating Claude Code plugins with correct, up-to-date patterns for all plugin features.

## Features

This template demonstrates:

- ✅ **Slash Commands** - User-invoked commands with argument handling
- ✅ **Specialized Agents** - Domain-specific AI assistants
- ✅ **Skills** - Model-invoked autonomous capabilities
- ✅ **Event Hooks** - Workflow automation via event handlers
- ✅ **MCP Servers** - External tool integrations via Model Context Protocol

## Quick Start

### 1. Copy This Template

```bash
cp -r plugin-template/ my-plugin/
cd my-plugin/
```

### 2. Customize Plugin Metadata

Edit `.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What your plugin does",
  "author": {
    "name": "Your Name",
    "email": "you@example.com"
  }
}
```

### 3. Add Your Features

Choose which features to implement:

- **Commands**: Edit `commands/example-command.md`
- **Agents**: Edit `agents/example-agent.md`
- **Skills**: Edit `skills/example-skill/SKILL.md`
- **Hooks**: Edit `hooks/hooks.json`
- **MCP**: Edit `.mcp.json`

### 4. Test Locally

```bash
cd /path/to/my-plugin
```

Then in Claude Code, test your features.

## File Structure

```tree
plugin-template/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata (REQUIRED)
├── knowledge/                   # Plugin-wide reference docs (REQUIRED)
│   └── plugin-name-comprehensive.md
├── commands/
│   └── example-command.md       # Slash command definition
├── agents/
│   └── example-agent.md         # Agent definition
├── skills/
│   └── example-skill/
│       ├── SKILL.md             # Skill definition (REQUIRED)
│       ├── references/          # Skill-specific docs (optional)
│       └── templates/           # Supporting files (optional)
│           └── example-template.txt
├── hooks/
│   ├── hooks.json               # Hook configuration
│   └── scripts/                 # Hook scripts (optional)
│       ├── lib/                 # Shared utilities (optional)
│       ├── init-session.sh
│       └── recommend-skills.sh
├── .mcp.json                    # MCP server configuration
├── LICENSE
└── README.md
```

## Component Details

### Commands (`commands/*.md`)

Slash commands that users invoke directly (e.g., `/example`).

**File Format:**
- Markdown file with optional YAML frontmatter
- Filename determines command name: `example.md` → `/example`
- Content becomes the instruction prompt sent to Claude

**Example:**

```markdown
---
description: What this command does
allowed-tools: Read, Write, Bash
model: sonnet
---

Instructions for Claude when user runs /example.

Use $1, $2 for arguments, or $ARGUMENTS for all arguments.
Use @file.ts to reference files.
Use !git status to run bash commands.
```

**Key Points:**
- Commands are auto-discovered from `commands/` directory
- No command definitions in `plugin.json`
- Simple Markdown content becomes the prompt

See [`commands/example-command.md`](./commands/example-command.md) for full template.

### Agents (`agents/*.md`)

Specialized AI assistants with domain expertise, invoked with `@agent-name`.

**File Format:**
- Markdown file with YAML frontmatter
- Frontmatter: `name`, `description` (required), `tools`, `model`, `permissionMode` (optional)
- Body content is the agent's system prompt

**Example:**

```markdown
---
name: code-reviewer
description: Use when reviewing code for bugs, performance, or best practices
tools: Read, Grep, Glob
model: sonnet
---

You are a specialized code reviewer. Your role is to...
```

**Key Points:**
- Agents are auto-discovered from `agents/` directory
- `description` field determines when Claude auto-invokes the agent
- No agent configuration in `plugin.json`
- Entire Markdown body becomes the agent's system prompt

See [`agents/example-agent.md`](./agents/example-agent.md) for full template.

### Skills (`skills/*/SKILL.md`)

Autonomous capabilities Claude invokes automatically based on context.

**Directory Structure:**
```tree
skills/
└── skill-name/
    ├── SKILL.md           # Required
    └── templates/         # Optional supporting files
```

**File Format:**
- Directory-based: `skills/skill-name/SKILL.md`
- Frontmatter: `name`, `description` (required), `allowed-tools` (optional)
- Body content contains instructions Claude follows when skill activates

**Example:**

```markdown
---
name: test-generator
description: Automatically generate test cases when working with untested code
allowed-tools: Read, Write, Glob
---

When you detect code without tests, generate comprehensive test cases...
```

**Key Points:**
- Skills are auto-discovered from `skills/` directory structure
- Claude invokes skills automatically (not user-triggered)
- `description` determines when skill activates
- No skill configuration in `plugin.json`
- Can include supporting files in skill directory

See [`skills/example-skill/SKILL.md`](./skills/example-skill/SKILL.md) for full template.

### Hooks (`hooks/hooks.json`)

Event handlers that trigger on specific actions.

**File Format:**
- JSON configuration at `hooks/hooks.json`
- Events: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `SessionStart`, etc.
- Hook types: `command` (shell script) or `prompt` (Claude evaluation)

**Example:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "./hooks/scripts/validate.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Verify the request is clear.",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

**Supported Events:**

**With matcher support:**
- `PreToolUse` - Before tool execution
- `PostToolUse` - After tool completion
- `PermissionRequest` - Permission handling
- `Notification` - System notifications

**Without matcher:**
- `UserPromptSubmit` - User submits prompt
- `SessionStart` - Session initialization
- `SessionEnd` - Session termination
- `Stop` - Main agent completes
- `SubagentStop` - Subagent completes
- `PreCompact` - Before context compaction

**Key Points:**
- Must be specified in `plugin.json` (not auto-discovered)
- Use `./` relative paths for portability
- Command hooks receive JSON via stdin
- Return JSON to stdout with exit code 0
- Exit code 2 blocks the action

See [`hooks/hooks.json`](./hooks/hooks.json) for full template.

### MCP Servers (`.mcp.json`)

External tool integrations via Model Context Protocol.

**File Format:**
- JSON configuration at `.mcp.json`
- Server types: `stdio`, `http`, `sse`

**Example:**

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "${CLAUDE_PLUGIN_ROOT}/server.js",
      "args": ["--verbose"],
      "env": {
        "API_KEY": "${MY_API_KEY}"
      }
    },
    "api-server": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${TOKEN}"
      }
    }
  }
}
```

**Server Types:**

| Type | Fields | Use Case |
|------|--------|----------|
| `stdio` | `command`, `args`, `env` | Local executables |
| `http` | `url`, `headers` | HTTP endpoints |
| `sse` | `url`, `headers` | Server-Sent Events |

**Key Points:**
- Tools are provided by the MCP server (not defined in this file)
- Use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths
- Environment variables: `${VAR}` or `${VAR:-default}`
- Must be specified in `plugin.json` (not auto-discovered)
- Restart Claude Code after changes

See [`.mcp.json`](./.mcp.json) for full template.

## Development Guide

### Component Auto-Discovery

Most components are **automatically discovered**:

- **Commands**: Any `.md` file in `commands/` → slash command
- **Agents**: Any `.md` file in `agents/` → agent
- **Skills**: Any `SKILL.md` in `skills/*/` → skill

**Not** auto-discovered (must specify in `plugin.json`):

- **Hooks**: Must reference `hooks.json` in `plugin.json`
- **MCP**: Must reference `.mcp.json` in `plugin.json`

### Plugin.json Configuration

**Required:**
- `name` - Plugin identifier (kebab-case)

**Optional metadata:**
- `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`

**Optional component paths:**
```json
{
  "commands": "./commands",
  "agents": "./agents",
  "skills": "./skills",
  "hooks": "./hooks/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

**Important:**
- Component paths are optional (auto-discovery works without them)
- Agent/skill/command definitions go in **Markdown files**, never in `plugin.json`
- Only `plugin.json` goes in `.claude-plugin/` directory
- Component directories go at plugin root

### Available Tools

When specifying `allowed-tools` or `tools` in frontmatter:

```
Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, WebFetch, WebSearch,
NotebookEdit, AskUserQuestion, Skill, SlashCommand
```

### Testing Your Plugin

1. **Validate structure:**
   ```bash
   ls -la .claude-plugin/plugin.json  # Must exist
   ls -la commands/ agents/ skills/   # Component directories
   ```

2. **Test commands:**
   ```bash
   # Check command appears
   /help

   # Test your command
   /example arg1 arg2
   ```

3. **Test agents:**
   ```
   @example-agent help me with a task
   ```

4. **Test skills:**
   Skills activate automatically based on context.

5. **Test hooks:**
   Perform actions that trigger your hooks and verify behavior.

## Common Mistakes to Avoid

❌ **Putting component definitions in plugin.json**
- Agents, skills, and commands are defined in Markdown files, not `plugin.json`

❌ **Wrong directory structure for skills**
- Must be `skills/skill-name/SKILL.md`, not `skills/skill-name.md`

❌ **Using incorrect hook event names**
- Use `PreToolUse`, not `onToolUse` or `tool:use`

❌ **Defining MCP tools in .mcp.json**
- Tools come from the MCP server itself, not the config file

❌ **Using ${CLAUDE_PROJECT_DIR} in plugins**
- Use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths

❌ **Placing components inside .claude-plugin/**
- Only `plugin.json` goes in `.claude-plugin/`
- Component directories go at plugin root

## Best Practices

### Naming
- Use kebab-case: `my-awesome-plugin`, not `myAwesomePlugin`
- Descriptive names: `/deploy-prod`, not `/dp`
- Clear agent names: `@code-reviewer`, not `@cr`

### Documentation
- Write clear descriptions in frontmatter (appears in `/help`)
- Include usage examples in README
- Document all parameters and options

### Security
- Never hardcode credentials
- Use environment variables: `${API_KEY}`
- Validate inputs in hooks
- Request minimum required permissions

### Performance
- Keep commands focused on single tasks
- Optimize hook scripts (low timeout values)
- Lazy-load supporting files in skills

## Examples by Use Case

### Command-Only Plugin

```bash
rm -rf agents/ skills/ hooks/
rm .mcp.json
```

Keep only `commands/` and `.claude-plugin/plugin.json`.

### Agent-Only Plugin

```bash
rm -rf commands/ skills/ hooks/
rm .mcp.json
```

Keep only `agents/` and `.claude-plugin/plugin.json`.

### Skill-Only Plugin

```bash
rm -rf commands/ agents/ hooks/
rm .mcp.json
```

Keep only `skills/` and `.claude-plugin/plugin.json`.

### MCP Integration Plugin

```bash
rm -rf commands/ agents/ skills/ hooks/
```

Keep only `.mcp.json` and `.claude-plugin/plugin.json`.

## Marketplace Utilities

The marketplace provides optional shared utilities to reduce code duplication:

- **Session Management**: `marketplace-utils/session-management.sh`
- **Frontmatter Parsing**: `marketplace-utils/frontmatter-parsing.sh`
- **File Detection**: `marketplace-utils/file-detection.sh`
- **JSON Utilities**: `marketplace-utils/json-utils.sh`
- **Skill Discovery**: `marketplace-utils/skill-discovery.sh`

**Usage:**

```bash
cp ../marketplace-utils/session-management.sh hooks/scripts/lib/
```

Or source directly (creates dependency):
```bash
source "$(dirname "$0")/../../../marketplace-utils/session-management.sh"
```

See [`marketplace-utils/README.md`](../marketplace-utils/README.md) for details.

## Knowledge Structure Standard

All plugins must follow the knowledge structure standard:

- **Required**: `/knowledge/{plugin-name}-comprehensive.md`
- **Optional**: `/skills/{skill-name}/references/` for skill-specific docs

Skills should reference knowledge documents instead of duplicating content.

See [`docs/KNOWLEDGE-STRUCTURE.md`](../docs/KNOWLEDGE-STRUCTURE.md) for the complete standard.

## Resources

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Plugin Development Guide](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugin Philosophy](../docs/PLUGIN-PHILOSOPHY.md)
- [Knowledge Structure Standard](../docs/KNOWLEDGE-STRUCTURE.md)
- [Marketplace Utilities](../marketplace-utils/README.md)

## License

MIT License - see [LICENSE](./LICENSE) for details.

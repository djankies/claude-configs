# Plugins reference

Complete technical reference: Claude Code plugin system schemas, CLI commands, component specifications.

<Tip>
  For tutorials and practical usage, see [Plugins](/en/plugins). For plugin management, see [Plugin marketplaces](/en/plugin-marketplaces).
</Tip>

## Plugin components reference

Plugins provide five component types:

### Commands

Custom slash commands integrated with Claude Code.

**Location**: `commands/` | **Format**: Markdown w/ frontmatter

See [Plugin commands](/en/slash-commands#plugin-commands) for structure, invocation patterns, and features.

### Agents

Specialized subagents Claude invokes automatically for specific tasks.

**Location**: `agents/` | **Format**: Markdown files

**Structure**:

```markdown theme={null}
---
description: Agent specialization
capabilities: ['task1', 'task2']
---

# Agent Name

Role, expertise, and invocation criteria. Appears in `/agents` interface; Claude invokes automatically or users invoke manually alongside built-in agents.
```

### Skills

Agent Skills extending Claude's capabilities; Claude autonomously decides when to use them.

**Location**: `skills/` | **Format**: Directories w/ `SKILL.md` files

**Example structure**:

```
skills/
├── pdf-processor/
│   ├── SKILL.md
│   ├── reference.md (optional)
│   └── scripts/ (optional)
└── code-reviewer/
    └── SKILL.md
```

Skills auto-discover on install; Claude invokes based on task context. See [Use Skills](/en/skills) and [Agent Skills overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview#skill-structure).

### Hooks

Event handlers responding to Claude Code events automatically.

**Location**: `hooks/hooks.json` or inline in `plugin.json` | **Format**: JSON config

**Example**:

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh" }]
      }
    ]
  }
}
```

**Events**: PreToolUse, PermissionRequest, PostToolUse, UserPromptSubmit, Notification, Stop, SubagentStop, SessionStart, SessionEnd, PreCompact

**Types**: command (shell/scripts), validation (file/project state), notification (alerts/status)

### MCP servers

Model Context Protocol servers connecting Claude Code with external tools/services.

**Location**: `.mcp.json` or inline in `plugin.json` | **Format**: Standard MCP configuration

**Example**:

```json theme={null}
{
  "mcpServers": {
    "plugin-database": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": { "DB_PATH": "${CLAUDE_PLUGIN_ROOT}/data" }
    },
    "plugin-api-client": {
      "command": "npx",
      "args": ["@company/mcp-server", "--plugin-mode"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}"
    }
  }
}
```

**Behavior**: Auto-start when enabled; appear as standard MCP tools; integrate seamlessly with existing tools; configure independently of user MCP servers.

---

## Plugin manifest schema

`plugin.json` defines metadata and configuration.

### Complete schema

```json theme={null}
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json"
}
```

### Required fields

| Field  | Type   | Description                    |
| :----- | :----- | :----------------------------- |
| `name` | string | Unique identifier (kebab-case) |

### Metadata fields

| Field         | Type   | Description        |
| :------------ | :----- | :----------------- |
| `version`     | string | Semantic version   |
| `description` | string | Plugin purpose     |
| `author`      | object | Author info        |
| `homepage`    | string | Documentation URL  |
| `repository`  | string | Source code URL    |
| `license`     | string | License identifier |
| `keywords`    | array  | Discovery tags     |

### Component path fields

| Field        | Type           | Description                |
| :----------- | :------------- | :------------------------- |
| `commands`   | string\|array  | Command files/directories  |
| `agents`     | string\|array  | Agent files                |
| `hooks`      | string\|object | Hook config path or inline |
| `mcpServers` | string\|object | MCP config path or inline  |

### Path behavior

Custom paths supplement (not replace) default directories. If `commands/` exists, it loads with custom paths. All paths relative to plugin root, starting with `./`. Multiple paths as arrays.

**Example**:

```json theme={null}
{
  "commands": ["./specialized/deploy.md", "./utilities/batch-process.md"],
  "agents": ["./custom-agents/reviewer.md", "./custom-agents/tester.md"]
}
```

### Environment variables

`${CLAUDE_PLUGIN_ROOT}`: Absolute path to plugin directory; use in hooks, MCP servers, scripts for location-independent paths.

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/process.sh" }]
      }
    ]
  }
}
```

---

## Plugin directory structure

### Standard layout

```
enterprise-plugin/
├── .claude-plugin/
│   └── plugin.json              # Required manifest
├── commands/                     # Default location
│   ├── status.md
│   └── logs.md
├── agents/                       # Default location
│   ├── security-reviewer.md
│   ├── performance-tester.md
│   └── compliance-checker.md
├── skills/                       # Agent Skills
│   ├── code-reviewer/
│   │   └── SKILL.md
│   └── pdf-processor/
│       ├── SKILL.md
│       └── scripts/
├── hooks/
│   ├── hooks.json
│   └── security-hooks.json
├── .mcp.json                     # MCP definitions
├── scripts/
│   ├── security-scan.sh
│   ├── format-code.py
│   └── deploy.js
├── LICENSE
└── CHANGELOG.md
```

<Warning>
  `.claude-plugin/` contains `plugin.json`. All other directories (commands/, agents/, skills/, hooks/) must be at plugin root, not inside `.claude-plugin/`.
</Warning>

### File locations

| Component   | Location                     | Purpose                 |
| :---------- | :--------------------------- | :---------------------- |
| Manifest    | `.claude-plugin/plugin.json` | Required metadata       |
| Commands    | `commands/`                  | Slash command markdown  |
| Agents      | `agents/`                    | Subagent markdown       |
| Skills      | `skills/`                    | Agent Skills (SKILL.md) |
| Hooks       | `hooks/hooks.json`           | Hook configuration      |
| MCP servers | `.mcp.json`                  | MCP definitions         |

---

## Debugging and development tools

### Debug output

`claude --debug` displays: plugin loading details, manifest errors, command/agent/hook registration, MCP server initialization.

### Common issues

| Issue                  | Cause                           | Solution                                             |
| :--------------------- | :------------------------------ | :--------------------------------------------------- |
| Plugin not loading     | Invalid `plugin.json`           | Validate JSON syntax                                 |
| Commands not appearing | Wrong directory structure       | Ensure `commands/` at root, not in `.claude-plugin/` |
| Hooks not firing       | Script not executable           | Run `chmod +x script.sh`                             |
| MCP server fails       | Missing `${CLAUDE_PLUGIN_ROOT}` | Use variable for all paths                           |
| Path errors            | Absolute paths used             | All paths relative, starting w/ `./`                 |

---

## See also

- [Plugins](/en/plugins) – Tutorials and usage
- [Plugin marketplaces](/en/plugin-marketplaces) – Marketplace creation and management
- [Slash commands](/en/slash-commands) – Command development
- [Subagents](/en/sub-agents) – Agent configuration
- [Agent Skills](/en/skills) – Capability extension
- [Hooks](/en/hooks) – Event handling
- [MCP](/en/mcp) – External tool integration
- [Settings](/en/settings) – Plugin configuration

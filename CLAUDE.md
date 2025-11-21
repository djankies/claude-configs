# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code Plugin Marketplace repository that serves as a centralized hub for discovering, sharing, and installing Claude Code plugins. It includes:

- A marketplace configuration system (marketplace.json)
- A comprehensive plugin template demonstrating all plugin features
- Validation tools for ensuring plugin quality and standards
- Documentation and contribution guidelines

## Commands

### Validation

```bash
npm install
npm run validate
```

Validates the marketplace structure, plugin configurations, JSON syntax, naming conventions, and version formats. The validation script checks:

- marketplace.json structure and schema compliance
- plugin.json files in all plugins
- hooks.json files
- .mcp.json MCP server configurations

### Testing

```bash
npm test
```

Runs the validation script (alias for `npm run validate`)

### Linting

```bash
npm run lint
```

Runs ESLint on the scripts directory

## Architecture

### Plugin Structure

All Claude Code plugins follow this structure:

```tree
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata (required)
├── commands/                # Custom slash commands (optional, auto-discovered)
│   └── *.md
├── agents/                  # Custom agents (optional, auto-discovered)
│   └── *.md
├── skills/                  # Autonomous skills (optional, auto-discovered)
│   └── skill-name/
│       └── SKILL.md
├── hooks/                   # Event handlers (optional, must be specified)
│   └── hooks.json
└── .mcp.json               # MCP server config (optional, must be specified)
```

### Component Auto-Discovery

Commands, agents, and skills are **auto-discovered** from their default directories even without explicit paths in plugin.json. However, hooks and MCP servers must be explicitly specified.

Component definitions live in Markdown files, NOT in plugin.json:

- Commands: defined in `commands/*.md`
- Agents: defined in `agents/*.md`
- Skills: defined in `skills/*/SKILL.md`
- Hooks: defined in `hooks/hooks.json`
- MCP servers: defined in `.mcp.json`

### Marketplace Configuration

The `.claude-plugin/marketplace.json` file defines the marketplace metadata:

- `name`: Marketplace identifier (kebab-case)
- `owner`: Owner name and email
- `metadata`: Description and version
- `plugins`: Array of plugin references (currently empty)

### Validation System

The validation script at `scripts/validate.js` uses:

- AJV for JSON schema validation
- Glob for finding plugin files
- Custom validators for naming conventions and version formats

Key schemas:

- `marketplaceSchema`: Validates marketplace.json structure
- `pluginSchema`: Validates plugin.json files

### Naming Conventions

- Plugin names: kebab-case (e.g., `my-plugin`)
- Versions: semantic versioning (e.g., `1.0.0`)
- Repository format: `owner/repo` for GitHub sources

## Plugin Development

When creating new plugins:

1. Use the `plugin-template/` as a starting point
2. Component paths in plugin.json are optional (auto-discovery works)
3. Place component directories at plugin root, NOT inside `.claude-plugin/`
4. Use relative paths starting with `./` when specifying paths
5. The plugin.json file must be at `.claude-plugin/plugin.json`

Common mistakes to avoid:

- Putting agent/skill/command definitions in plugin.json (they go in Markdown files)
- Using Node.js fields like 'main', 'engines', 'dependencies' (not used by Claude Code)
- Placing component directories inside .claude-plugin/ (they go at plugin root)
- Using absolute paths (always use relative paths)

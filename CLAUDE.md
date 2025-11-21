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
- Skills directory structure (SKILL.md files with frontmatter)
- Commands directory structure (.md files)
- Agents directory structure (.md files)
- Component directory placement (must be at plugin root)
- hooks.json files
- .mcp.json MCP server configurations

Use the `/validate` command within Claude Code for comprehensive validation with remediation.

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

### Available Claude Code Commands

- `/create-plugin <plugin-name>` - Create a new plugin from PLUGIN-DESIGN.md
- `/design-plugin <plugin-name>` - Generate comprehensive plugin design document
- `/validate` - Validate marketplace and all plugins with remediation
- `/review-plugin <plugin-name>` - Comprehensive plugin review and validation
- `/stress-test <technology>` - Stress test with realistic scenarios
- `/research-tool <tool@version>` - Research tool documentation and best practices

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
- Skills: defined in `skills/*/SKILL.md` (must be in subdirectories with SKILL.md file)
- Hooks: defined in `hooks/hooks.json`
- MCP servers: defined in `.mcp.json`

### Cross-Plugin Skill References

Plugins can reference skills from other plugins for review, validation, or security checks:

- **Review plugin:** Discovers review skills via `review: true` frontmatter
- **TypeScript plugin:** References security and validation skills from other plugins
- **Pattern:** Use `@{plugin-name}/skills/{skill-name}/SKILL.md` references in commands

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

Key validations:

- `marketplaceSchema`: Validates marketplace.json structure
- `pluginSchema`: Validates plugin.json files
- Skills validation: Checks SKILL.md files exist and have frontmatter (name, description)
- Commands validation: Checks .md files exist in commands/ directories
- Agents validation: Checks .md files exist in agents/ directories
- Directory placement: Ensures component directories are at plugin root, not inside .claude-plugin/
- Orphaned plugins: Detects plugins with plugin.json not listed in marketplace.json

### Naming Conventions

- Plugin names: kebab-case (e.g., `my-plugin`)
- Versions: semantic versioning (e.g., `1.0.0`)
- Repository format: `owner/repo` for GitHub sources

## Plugin Development

### Creating Plugins

Use the structured workflow:

1. **Research:** `/research-tool <tool@version>` - Research the tool/framework
2. **Stress Test:** `/stress-test <technology>` - Stress test with realistic scenarios
3. **Design:** `/design-plugin <plugin-name>` - Generate comprehensive design document
4. **Create:** `/create-plugin <plugin-name>` - Generate plugin from design
5. **Validate:** `/validate` - Validate structure and fix issues
6. **Review:** `/review-plugin <plugin-name>` - Comprehensive review

### Plugin Development Rules

1. Use the `plugin-template/` as a starting point
2. Component paths in plugin.json are optional (auto-discovery works)
3. Place component directories at plugin root, NOT inside `.claude-plugin/`
4. Use relative paths starting with `./` when specifying paths
5. The plugin.json file must be at `.claude-plugin/plugin.json`

### Review Skills

To make skills discoverable by the `review` plugin:

- Add `review: true` to skill frontmatter
- Name skills with gerund form: `reviewing-{concern}`
- Skills automatically discovered when `/review {concern}` is used

Example:

```markdown
---
name: reviewing-react-hooks
description: Review React hook usage for React 19 compliance
review: true
---
```

### Common Mistakes

- Putting agent/skill/command definitions in plugin.json (they go in Markdown files)
- Using Node.js fields like 'main', 'engines', 'dependencies' (not used by Claude Code)
- Placing component directories inside .claude-plugin/ (they go at plugin root)
- Using absolute paths (always use relative paths)
- Missing SKILL.md files in skills/ subdirectories
- Missing frontmatter in SKILL.md files

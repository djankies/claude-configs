# Claude Code Plugin Marketplace

A curated marketplace of Claude Code plugins for various technologies. This repository serves as a central hub for discovering, sharing, and installing Claude Code plugins that enhance development workflows.

## What is Claude Code?

Claude Code is an AI-powered coding assistant that can be extended through plugins. Plugins can add custom commands, specialized agents, autonomous skills, event hooks, and integrations with external tools via the Model Context Protocol (MCP).

## Features

- 🔌 **Plugin Marketplace**: Centralized catalog of plugins for various technologies
- 📦 **Easy Installation**: Simple commands to browse and install plugins
- 🛠️ **Plugin Template**: Comprehensive template demonstrating all plugin capabilities
- ✅ **Validation Tools**: Automated validation of plugin structure and configuration
- 📚 **Documentation**: Detailed guides for plugin development and contribution

## Quick Start

### Adding This Marketplace to Claude Code

```bash
/plugin marketplace add daniel/claude-configs
```

### Browsing Available Plugins

```bash
/plugin
```

This will open the plugin browser where you can see all available plugins from this marketplace.

### Installing a Plugin

```bash
/plugin install <plugin-name>@claude-configs
```

Replace `<plugin-name>` with the name of the plugin you want to install.

### Verifying Installation

```bash
/help
```

This will show all available commands, including those added by your installed plugins.

## Plugin Development

### Using the Plugin Template

This repository includes a comprehensive plugin template that demonstrates all available plugin features:

- **Commands**: Custom slash commands (`/example`)
- **Agents**: Specialized AI assistants (`@example-agent`)
- **Skills**: Autonomous capabilities that Claude uses automatically
- **Hooks**: Event handlers triggered by specific actions
- **MCP Servers**: External tool integrations

The template is located at [`plugin-template/`](./plugin-template/) and includes detailed documentation for each feature.

### Plugin Structure

A complete Claude Code plugin follows this structure:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata (required)
├── commands/                # Custom slash commands (optional)
│   └── example-command.md
├── agents/                  # Custom agents (optional)
│   └── example-agent.md
├── skills/                  # Autonomous skills (optional)
│   └── example-skill.md
├── hooks/                   # Event handlers (optional)
│   └── hooks.json
└── .mcp.json               # MCP server config (optional)
```

### Creating Your Own Plugin

1. **Fork or use the template** from [`plugin-template/`](./plugin-template/)
2. **Create a new repository** for your plugin
3. **Customize the plugin.json** with your plugin's metadata
4. **Add your features** (commands, agents, skills, hooks, MCP servers)
5. **Test locally** by adding your plugin repository to Claude Code
6. **Submit to this marketplace** by following the [Contributing Guide](./CONTRIBUTING.md)

### Local Development

To test your plugin locally before publishing:

```bash
# Add your local plugin directory
/plugin marketplace add ./path/to/your-plugin

# Install the plugin
/plugin install your-plugin-name

# Verify it works
/help
```

## Validation

This marketplace includes validation tools to ensure plugins meet quality standards.

### Running Validation

```bash
# Install dependencies
npm install

# Run validation
npm run validate
```

The validation script checks:
- ✅ marketplace.json structure and schema compliance
- ✅ Plugin references and metadata validity
- ✅ JSON syntax in all configuration files
- ✅ Naming conventions (kebab-case)
- ✅ Version format (semver)
- ✅ Required fields presence

## Available Plugins

Currently, this marketplace contains:

- **plugin-template**: A comprehensive template demonstrating all plugin features

More plugins will be added as the marketplace grows. Check back regularly or [contribute your own](#contributing)!

## Plugin Categories

Plugins are organized by technology and use case:

- **Development Tools**: Code analysis, testing, debugging
- **Language Support**: Technology-specific tools and integrations
- **Workflow Automation**: CI/CD, deployment, task automation
- **Documentation**: API docs, code comments, README generation
- **Database Tools**: Query builders, schema management
- **Cloud Services**: AWS, Azure, GCP integrations
- **AI/ML**: Model deployment, data science workflows

## Requirements

- Claude Code version 1.0.0 or higher
- Node.js 14+ (for validation scripts)
- Git (for installing plugins from repositories)

## Contributing

We welcome contributions! Please see our [Contributing Guide](./CONTRIBUTING.md) for details on:

- How to submit your plugin to the marketplace
- Plugin quality standards
- Code review process
- Security considerations

## Resources

### Official Documentation
- [Claude Code Plugins](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugin Marketplaces](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Model Context Protocol](https://modelcontextprotocol.io/)

### Community
- [Claude Code Plugin Directory](https://www.claudecodeplugin.com/)
- [GitHub Discussions](https://github.com/daniel/claude-configs/discussions)

## Security

Security is a top priority for this marketplace. All plugins should:

- ✅ Follow secure coding practices
- ✅ Not expose sensitive credentials
- ✅ Validate all user inputs
- ✅ Declare required permissions
- ✅ Use environment variables for secrets

If you discover a security vulnerability, please report it privately to the repository maintainers.

## License

This marketplace and the plugin template are licensed under the MIT License. See [LICENSE](./LICENSE) for details.

Individual plugins may have their own licenses - please check each plugin's repository for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/daniel/claude-configs/issues)
- **Discussions**: [GitHub Discussions](https://github.com/daniel/claude-configs/discussions)
- **Documentation**: Check the [plugin-template/](./plugin-template/) directory

## Roadmap

- [ ] Add more plugin examples for popular technologies
- [ ] Automated plugin testing and CI/CD
- [ ] Plugin versioning and update notifications
- [ ] Category browsing and search functionality
- [ ] Plugin rating and review system
- [ ] Integration with package managers (npm, pip, etc.)

## Acknowledgments

Thanks to the Claude Code team at Anthropic for creating an extensible AI coding assistant, and to all contributors who help build this ecosystem.

---

**Happy coding with Claude Code! 🚀**


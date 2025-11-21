# Contributing to Claude Code Plugin Marketplace

Thank you for your interest in contributing to this Claude Code plugin marketplace! This guide will help you submit high-quality plugins that benefit the entire community.

## Table of Contents

- [Getting Started](#getting-started)
- [Plugin Submission Process](#plugin-submission-process)
- [Plugin Requirements](#plugin-requirements)
- [Plugin Structure](#plugin-structure)
- [Best Practices](#best-practices)
- [Security Guidelines](#security-guidelines)
- [Code Review Process](#code-review-process)
- [Marketplace Guidelines](#marketplace-guidelines)

## Getting Started

### Prerequisites

Before contributing a plugin, ensure you have:

1. **Claude Code** installed and running (version 1.0.0+)
2. **Node.js** 14+ (for validation scripts)
3. **Git** for version control
4. A **GitHub account** to host your plugin repository

### Understanding Plugin Types

Claude Code plugins can include:

- **Commands**: Custom slash commands (e.g., `/deploy`, `/test`)
- **Agents**: Specialized AI assistants for specific domains
- **Skills**: Autonomous capabilities Claude uses automatically
- **Hooks**: Event handlers for workflow automation
- **MCP Servers**: External tool integrations via Model Context Protocol

## Plugin Submission Process

### 1. Create Your Plugin

#### Option A: Use the Template
```bash
# Copy the plugin template from this repository
cp -r plugin-template/ my-awesome-plugin/
cd my-awesome-plugin/

# Customize plugin.json with your metadata
# Add your commands, agents, skills, hooks, or MCP servers
```

#### Option B: Start from Scratch
```bash
# Create your plugin structure
mkdir -p my-awesome-plugin/.claude-plugin
mkdir -p my-awesome-plugin/commands
mkdir -p my-awesome-plugin/agents
mkdir -p my-awesome-plugin/skills
mkdir -p my-awesome-plugin/hooks

# Create plugin.json
# Add your plugin components
```

### 2. Test Your Plugin Locally

```bash
# Add your plugin locally
/plugin marketplace add ./path/to/my-awesome-plugin

# Install and test
/plugin install my-awesome-plugin

# Verify functionality
/help  # Check if your commands appear
```

### 3. Create a GitHub Repository

```bash
# Initialize git in your plugin directory
cd my-awesome-plugin/
git init
git add .
git commit -m "Initial commit: My Awesome Plugin"

# Create a repository on GitHub
# Push your plugin
git remote add origin https://github.com/yourusername/my-awesome-plugin.git
git push -u origin main
```

### 4. Submit to Marketplace

1. **Fork this repository** (daniel/claude-configs)
2. **Clone your fork**:
   ```bash
   git clone https://github.com/yourusername/claude-configs.git
   cd claude-configs
   ```
3. **Add your plugin reference** to `.claude-plugin/marketplace.json`:
   ```json
   {
     "plugins": [
       {
         "name": "my-awesome-plugin",
         "source": {
           "source": "github",
           "repo": "yourusername/my-awesome-plugin"
         }
       }
     ]
   }
   ```
4. **Validate your changes**:
   ```bash
   npm install
   npm run validate
   ```
5. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add my-awesome-plugin to marketplace"
   git push origin main
   ```
6. **Create a Pull Request** to the main repository

## Plugin Requirements

### Required Files

Every plugin MUST include:

- ✅ `.claude-plugin/plugin.json` - Plugin metadata
- ✅ `README.md` - Plugin documentation
- ✅ `LICENSE` - License file (MIT, Apache 2.0, or GPL recommended)

### Required Metadata (plugin.json)

```json
{
  "name": "plugin-name",           // Required: kebab-case
  "version": "1.0.0",              // Required: semver format
  "description": "Description",    // Required: clear description
  "author": {                      // Recommended
    "name": "Your Name",
    "email": "your@email.com"
  },
  "repository": {                  // Recommended
    "type": "git",
    "url": "https://github.com/..."
  },
  "license": "MIT"                 // Recommended
}
```

### Naming Conventions

- **Plugin names**: Must use kebab-case (lowercase with hyphens)
  - ✅ Good: `aws-deployer`, `test-generator`, `code-reviewer`
  - ❌ Bad: `AWS_Deployer`, `testGenerator`, `code.reviewer`
- **Versions**: Must follow semantic versioning (semver)
  - ✅ Good: `1.0.0`, `2.3.1`, `1.0.0-beta.1`
  - ❌ Bad: `v1`, `1.0`, `latest`

## Plugin Structure

### Complete Plugin Structure

```
my-awesome-plugin/
├── .claude-plugin/
│   └── plugin.json              # Required: Plugin metadata
├── commands/                    # Optional: Custom commands
│   ├── deploy.md               # Command: /deploy
│   └── test.md                 # Command: /test
├── agents/                      # Optional: Specialized agents
│   └── reviewer-agent.md       # Agent: @reviewer-agent
├── skills/                      # Optional: Autonomous skills
│   └── code-analysis.md        # Auto-invoked capability
├── hooks/                       # Optional: Event handlers
│   └── hooks.json              # Hook configuration
├── .mcp.json                   # Optional: MCP server config
├── README.md                   # Required: Documentation
├── LICENSE                     # Required: License
├── CHANGELOG.md               # Recommended: Version history
└── .gitignore                 # Recommended: Git ignore rules
```

### Command Files (commands/*.md)

Each command file should include:

```markdown
# Command Name

## Command Name
`/mycommand` or `/mc`

## Description
Clear description of what the command does

## Usage
\```
/mycommand [parameters] --flags
\```

## Parameters
- Required and optional parameters
- Parameter types and constraints

## Examples
Concrete usage examples

## Output
Expected output format
```

### Agent Files (agents/*.md)

```markdown
# Agent Name

## Agent Name
`my-agent`

## Purpose
What the agent specializes in

## Expertise Areas
- Domain knowledge
- Specialized capabilities

## Activation
How to invoke the agent (@my-agent)

## Example Interactions
Sample conversations
```

## Best Practices

### Documentation

- ✅ Write clear, comprehensive README
- ✅ Include usage examples for all features
- ✅ Document all parameters and options
- ✅ Provide troubleshooting section
- ✅ Keep CHANGELOG.md updated

### Code Quality

- ✅ Follow consistent code style
- ✅ Add helpful comments and explanations
- ✅ Handle errors gracefully
- ✅ Validate user inputs
- ✅ Provide meaningful error messages

### User Experience

- ✅ Make commands intuitive and discoverable
- ✅ Use clear, descriptive names
- ✅ Provide helpful command descriptions
- ✅ Support both long and short flags
- ✅ Show progress for long-running operations

### Performance

- ✅ Optimize for fast execution
- ✅ Lazy-load heavy dependencies
- ✅ Cache frequently accessed data
- ✅ Set reasonable timeouts
- ✅ Avoid blocking operations

## Security Guidelines

### Critical Security Requirements

1. **Never hardcode credentials**
   - ✅ Use environment variables
   - ✅ Document required env vars in README
   - ❌ Never commit API keys or tokens

2. **Validate all inputs**
   - ✅ Sanitize user inputs
   - ✅ Validate file paths
   - ✅ Check parameter types and ranges

3. **Request minimum permissions**
   - ✅ Declare required permissions in plugin.json
   - ✅ Explain why permissions are needed
   - ❌ Don't request unnecessary access

4. **Handle sensitive data carefully**
   - ✅ Use secure storage for credentials
   - ✅ Clear sensitive data after use
   - ❌ Never log passwords or tokens

5. **External dependencies**
   - ✅ Pin dependency versions
   - ✅ Audit dependencies regularly
   - ✅ Use reputable packages only

### Security Checklist

Before submitting, ensure:

- [ ] No hardcoded credentials or API keys
- [ ] All user inputs are validated and sanitized
- [ ] Sensitive data is handled securely
- [ ] Dependencies are up-to-date and secure
- [ ] HTTPS is used for all external requests
- [ ] Error messages don't expose sensitive information
- [ ] File operations are restricted to workspace
- [ ] Required permissions are documented

## Code Review Process

### What We Check

When reviewing plugin submissions, we verify:

1. **Functionality**
   - Plugin works as documented
   - All features function correctly
   - No breaking errors or bugs

2. **Security**
   - Follows security guidelines
   - No vulnerabilities or exploits
   - Safe handling of user data

3. **Quality**
   - Clean, readable code
   - Proper error handling
   - Good documentation

4. **Standards**
   - Follows naming conventions
   - Proper plugin structure
   - Valid JSON configurations

### Review Timeline

- Initial review: Within 3-5 business days
- Feedback provided via PR comments
- Revisions welcome and encouraged
- Approval once all requirements met

### Common Rejection Reasons

- ❌ Security vulnerabilities
- ❌ Poor documentation
- ❌ Broken functionality
- ❌ Malicious code
- ❌ Copyright violations
- ❌ Duplicate functionality without improvements

## Marketplace Guidelines

### Plugin Categories

Choose the most appropriate category for your plugin:

- **Development Tools**: Code analysis, testing, debugging
- **Language Support**: Python, JavaScript, Java, etc.
- **Workflow Automation**: CI/CD, deployment, scripts
- **Documentation**: Generators, formatters
- **Database**: Query builders, migrations
- **Cloud Services**: AWS, Azure, GCP
- **AI/ML**: Model training, data science
- **Utilities**: General-purpose tools

### Plugin Descriptions

Write clear, concise descriptions:

- ✅ Start with what the plugin does
- ✅ Mention key features
- ✅ Keep it under 160 characters for marketplace listing
- ❌ Avoid marketing speak or hype
- ❌ Don't make false claims

### Versioning

Follow semantic versioning (semver):

- **Major** (1.0.0 → 2.0.0): Breaking changes
- **Minor** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch** (1.0.0 → 1.0.1): Bug fixes

### Updates and Maintenance

- Keep your plugin updated with latest Claude Code versions
- Respond to issues and PRs promptly
- Update documentation when features change
- Maintain backward compatibility when possible

## Getting Help

### Questions?

- **GitHub Discussions**: Ask in our community forum
- **Issues**: Report bugs or request features
- **Documentation**: Check the [plugin-template](./plugin-template/)

### Resources

- [Claude Code Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Plugin Template](./plugin-template/)

## License

By contributing to this marketplace, you agree that:

- Your plugin has a compatible open-source license
- You have the rights to all code submitted
- You grant users the right to use your plugin per its license

---

Thank you for contributing to the Claude Code plugin ecosystem! 🎉


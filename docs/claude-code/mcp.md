# Connect Claude Code to tools via MCP

> Learn connecting Claude Code to your tools with the Model Context Protocol.

Claude Code connects to hundreds of external tools and data sources through the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction)—an open-source standard for AI-tool integrations. MCP servers grant Claude Code access to tools, databases, and APIs.

## What you can do with MCP

Ask Claude Code to:

- **Implement features from issue trackers**: "Add the feature described in JIRA issue ENG-4521 and create a PR on GitHub."
- **Analyze monitoring data**: "Check Sentry and Statsig for feature ENG-4521 usage."
- **Query databases**: "Find emails of 10 random users who used feature ENG-4521 from our Postgres database."
- **Integrate designs**: "Update our standard email template based on new Figma designs posted in Slack"
- **Automate workflows**: "Create Gmail drafts inviting 10 users to a feedback session."

## Popular MCP servers

<MCPServersTable platform="claudeCode" />

<Warning>
Use third-party MCP servers at your own risk—Anthropic hasn't verified all servers' correctness or security. Trust MCP servers before installing; exercise caution with servers fetching untrusted content (prompt injection risk).
</Warning>

<Note>
**Need a specific integration?** [Find hundreds more MCP servers on GitHub](https://github.com/modelcontextprotocol/servers) or build your own using the [MCP SDK](https://modelcontextprotocol.io/quickstart/server).
</Note>

## Installing MCP servers

Configure MCP servers three ways depending on needs:

### Option 1: Remote HTTP server

HTTP servers (recommended for remote/cloud services):

```bash theme={null}
# Basic syntax
claude mcp add --transport http <name> <url>

# Connect to Notion
claude mcp add --transport http notion https://mcp.notion.com/mcp

# With Bearer token
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"
```

### Option 2: Remote SSE server

<Warning>
SSE (Server-Sent Events) transport is deprecated; use HTTP servers instead.
</Warning>

```bash theme={null}
# Basic syntax
claude mcp add --transport sse <name> <url>

# Connect to Asana
claude mcp add --transport sse asana https://mcp.asana.com/sse

# With authentication header
claude mcp add --transport sse private-api https://api.company.com/sse \
  --header "X-API-Key: your-key-here"
```

### Option 3: Local stdio server

Stdio servers run as local processes; ideal for direct system access or custom scripts:

```bash theme={null}
# Basic syntax
claude mcp add --transport stdio <name> <command> [args...]

# Add Airtable server
claude mcp add --transport stdio airtable --env AIRTABLE_API_KEY=YOUR_KEY \
  -- npx -y airtable-mcp-server
```

**Understanding "--"**: The double dash separates Claude's CLI flags (before) from the server command and arguments (after). Example: `claude mcp add --transport stdio myserver --env KEY=value -- python server.py --port 8080` runs `python server.py --port 8080` with `KEY=value` in environment, preventing flag conflicts.

### Managing servers

```bash theme={null}
claude mcp list                    # List all configured servers
claude mcp get github              # Get details for specific server
claude mcp remove github           # Remove a server
/mcp                              # Within Claude Code: check server status
```

**Tips**:

- `--scope` flag specifies configuration storage: `local` (default; project-specific), `project` (shared via `.mcp.json`), `user` (all projects)
- Set environment variables: `--env KEY=value`
- Configure MCP startup timeout: `MCP_TIMEOUT=10000 claude` (milliseconds)
- Claude Code warns when MCP tool output exceeds 10,000 tokens; increase limit via `MAX_MCP_OUTPUT_TOKENS=50000` environment variable
- Use `/mcp` to authenticate with OAuth 2.0 remote servers

<Warning>
**Windows Users**: Local MCP servers using `npx` require `cmd /c` wrapper on native Windows (not WSL):
```bash theme={null}
claude mcp add --transport stdio my-server -- cmd /c npx -y @some/package
```
Without this, Windows cannot directly execute `npx`, causing "Connection closed" errors.
</Warning>

### Plugin-provided MCP servers

[Plugins](/en/plugins) can bundle MCP servers, automatically providing tools when enabled. Plugin MCP servers work identically to user-configured servers.

**How plugin MCP servers work**:

- Plugins define MCP servers in `.mcp.json` at plugin root or inline in `plugin.json`
- Servers start automatically when plugin enables; restart Claude Code to apply MCP server changes
- Plugin MCP tools appear alongside manually configured tools
- Plugin servers managed through plugin installation (not `/mcp` commands)

**Example configurations**:

In `.mcp.json`:

```json theme={null}
{
  "database-tools": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": { "DB_URL": "${DB_URL}" }
  }
}
```

Or inline in `plugin.json`:

```json theme={null}
{
  "name": "my-plugin",
  "mcpServers": {
    "plugin-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"]
    }
  }
}
```

**Features**: Automatic lifecycle (starts on plugin enable; restart Claude Code for changes); environment variables (use `${CLAUDE_PLUGIN_ROOT}` for plugin paths); user environment access; multiple transport types (stdio, SSE, HTTP—varies by server); view all MCP servers including plugins via `/mcp`.

**Benefits**: Bundled distribution (tools and servers packaged together); automatic setup (no manual configuration); team consistency (everyone gets same tools).

See [plugin components reference](/en/plugins-reference#mcp-servers) for bundling details.

## MCP installation scopes

MCP servers configure at three scope levels for managing server accessibility and sharing:

### Local scope (default)

Stored in project-specific user settings; private to you; accessible only within current project directory. Ideal for personal development servers, experimental configurations, or servers with sensitive credentials.

```bash theme={null}
claude mcp add --transport http stripe https://mcp.stripe.com
# Or explicitly:
claude mcp add --transport http stripe --scope local https://mcp.stripe.com
```

### Project scope

Stores configurations in `.mcp.json` at project root; designed for version control; ensures all team members access same MCP tools. Claude Code automatically creates/updates the file.

```bash theme={null}
claude mcp add --transport http paypal --scope project https://mcp.paypal.com/mcp
```

Resulting `.mcp.json` format:

```json theme={null}
{
  "mcpServers": {
    "shared-server": {
      "command": "/path/to/server",
      "args": [],
      "env": {}
    }
  }
}
```

Claude Code prompts for approval before using project-scoped servers from `.mcp.json` files. Reset approval choices via `claude mcp reset-project-choices`.

### User scope

Cross-project accessible; available across all projects on your machine; private to your user account. Works well for personal utility servers, development tools, or frequently-used services.

```bash theme={null}
claude mcp add --transport http hubspot --scope user https://mcp.hubspot.com/anthropic
```

### Choosing scope

- **Local**: Personal servers, experimental configurations, sensitive credentials (single project)
- **Project**: Team-shared servers, project-specific tools, collaboration services
- **User**: Personal utilities across projects, development tools, frequently-used services

### Scope hierarchy and precedence

Precedence (highest first): local → project → user. Personal configurations override shared ones when needed.

### Environment variable expansion in `.mcp.json`

Claude Code supports environment variable expansion in `.mcp.json`:

- `${VAR}` - Expands to environment variable `VAR`
- `${VAR:-default}` - Expands to `VAR` if set, otherwise `default`

Expansion locations: `command`, `args`, `env`, `url` (HTTP servers), `headers` (HTTP authentication).

```json theme={null}
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": { "Authorization": "Bearer ${API_KEY}" }
    }
  }
}
```

Missing required environment variables without defaults cause Claude Code to fail parsing.

## Practical examples

### Monitor errors with Sentry

```bash theme={null}
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
/mcp  # Authenticate with your Sentry account
```

Ask Claude: "What are the most common errors in the last 24 hours?" • "Show me the stack trace for error ID abc123" • "Which deployment introduced these new errors?"

### Connect to GitHub for code reviews

```bash theme={null}
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
/mcp  # Authenticate if needed
```

Ask Claude: "Review PR #456 and suggest improvements" • "Create a new issue for the bug we just found" • "Show me all open PRs assigned to me"

### Query PostgreSQL database

```bash theme={null}
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub \
  --dsn "postgresql://readonly:pass@prod.db.com:5432/analytics"
```

Ask Claude: "What's our total revenue this month?" • "Show me the schema for the orders table" • "Find customers who haven't made a purchase in 90 days"

## Authenticate with remote MCP servers

Many cloud-based MCP servers require authentication via OAuth 2.0:

1. Add the server requiring authentication: `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`
2. Use `/mcp` within Claude Code and follow browser login steps

**Tips**: Authentication tokens stored securely and refreshed automatically; use "Clear authentication" in `/mcp` menu to revoke access; if browser doesn't open automatically, copy the provided URL; OAuth works with HTTP servers.

## Add MCP servers from JSON configuration

```bash theme={null}
# Basic syntax
claude mcp add-json <name> '<json>'

# HTTP server example
claude mcp add-json weather-api '{"type":"http","url":"https://api.weather.com/mcp","headers":{"Authorization":"Bearer token"}}'

# Stdio server example
claude mcp add-json local-weather '{"type":"stdio","command":"/path/to/weather-cli","args":["--api-key","abc123"],"env":{"CACHE_DIR":"/tmp"}}'

# Verify server was added
claude mcp get weather-api
```

**Tips**: Ensure JSON is properly shell-escaped; must conform to MCP server configuration schema; use `--scope user` to add to user config instead of project config.

## Import MCP servers from Claude Desktop

```bash theme={null}
claude mcp add-from-claude-desktop  # Select servers to import interactively
claude mcp list                      # Verify servers were imported
```

**Tips**: Works on macOS and WSL only; reads Claude Desktop config from standard location; use `--scope user` to add to user configuration; imported servers retain same names; servers with duplicate names get numerical suffixes (e.g., `server_1`).

## Use Claude Code as an MCP server

```bash theme={null}
claude mcp serve  # Start Claude as stdio MCP server
```

Add to Claude Desktop `claude_desktop_config.json`:

```json theme={null}
{
  "mcpServers": {
    "claude-code": {
      "type": "stdio",
      "command": "claude",
      "args": ["mcp", "serve"],
      "env": {}
    }
  }
}
```

**Configuring executable path**: The `command` field must reference the Claude Code executable. If `claude` is not in system PATH, specify full path (find via `which claude`):

```json theme={null}
{
  "mcpServers": {
    "claude-code": {
      "type": "stdio",
      "command": "/full/path/to/claude",
      "args": ["mcp", "serve"],
      "env": {}
    }
  }
}
```

Without the correct path, you'll encounter errors like `spawn claude ENOENT`.

**Tips**: Server provides access to Claude's tools (View, Edit, LS, etc.); in Claude Desktop, ask Claude to read files, make edits, and more; client is responsible for implementing user confirmation for tool calls.

## MCP output limits and warnings

Claude Code manages token usage from large MCP outputs:

- **Warning threshold**: Displays warning when MCP tool output exceeds 10,000 tokens
- **Configurable limit**: Adjust via `MAX_MCP_OUTPUT_TOKENS` environment variable
- **Default limit**: 25,000 tokens

Increase limit for large-output tools:

```bash theme={null}
export MAX_MCP_OUTPUT_TOKENS=50000
claude
```

Useful when MCP servers query large datasets, generate detailed reports, or process extensive logs.

<Warning>
If frequently encountering warnings, consider increasing the limit or configuring the server to paginate/filter responses.
</Warning>

## Use MCP resources

MCP servers expose resources referenceable via @ mentions (like files).

### Reference MCP resources

1. Type `@` in prompt to see available resources from all connected MCP servers; resources appear in autocomplete alongside files
2. Reference specific resource using `@server:protocol://resource/path`: `@github:issue://123` or `@docs:file://api/authentication`
3. Reference multiple resources in single prompt: `@postgres:schema://users` and `@docs:file://database/user-model`

**Tips**: Resources automatically fetched and included as attachments; paths are fuzzy-searchable in @ autocomplete; Claude Code automatically provides tools to list/read MCP resources when servers support them; resources can contain any content type the MCP server provides (text, JSON, structured data, etc.).

## Use MCP prompts as slash commands

MCP servers expose prompts available as slash commands in Claude Code.

### Execute MCP prompts

1. Type `/` to see all available commands including those from MCP servers; MCP prompts use format `/mcp__servername__promptname`
2. Execute prompt without arguments: `/mcp__github__list_prs`
3. Execute prompt with arguments (space-separated): `/mcp__github__pr_review 456` or `/mcp__jira__create_issue "Bug in login flow" high`

**Tips**: MCP prompts dynamically discovered from connected servers; arguments parsed based on prompt's defined parameters; prompt results injected directly into conversation; server/prompt names normalized (spaces become underscores).

## Enterprise MCP configuration

For organizations needing centralized MCP control, Claude Code supports enterprise-managed configurations. IT administrators can:

- Control which MCP servers employees access (deploy standardized approved set)
- Prevent unauthorized MCP servers (optionally restrict users from adding their own)
- Disable MCP entirely if needed

### Setting up enterprise MCP configuration

System administrators deploy `managed-mcp.json` alongside managed settings file:

- **macOS**: `/Library/Application Support/ClaudeCode/managed-mcp.json`
- **Windows**: `C:\ProgramData\ClaudeCode\managed-mcp.json`
- **Linux**: `/etc/claude-code/managed-mcp.json`

Format (same as standard `.mcp.json`):

```json theme={null}
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp"
    },
    "company-internal": {
      "type": "stdio",
      "command": "/usr/local/bin/company-mcp-server",
      "args": ["--config", "/etc/company/mcp-config.json"],
      "env": { "COMPANY_API_URL": "https://internal.company.com" }
    }
  }
}
```

### Restricting MCP servers with allowlists and denylists

Administrators control allowed MCP servers via `allowedMcpServers` and `deniedMcpServers` in `managed-settings.json`:

- **macOS**: `/Library/Application Support/ClaudeCode/managed-settings.json`
- **Windows**: `C:\ProgramData\ClaudeCode\managed-settings.json`
- **Linux**: `/etc/claude-code/managed-settings.json`

```json theme={null}
{
  "allowedMcpServers": [
    { "serverName": "github" },
    { "serverName": "sentry" },
    { "serverName": "company-internal" }
  ],
  "deniedMcpServers": [{ "serverName": "filesystem" }]
}
```

**Allowlist behavior (`allowedMcpServers`)**:

- Undefined (default): No restrictions; users can configure any MCP server
- Empty array `[]`: Complete lockdown; users cannot configure any MCP servers
- List of server names: Users can only configure specified servers

**Denylist behavior (`deniedMcpServers`)**:

- Undefined (default): No servers blocked
- Empty array `[]`: No servers blocked
- List of server names: Specified servers explicitly blocked across all scopes

**Important notes**:

- Restrictions apply to all scopes (user, project, local, even enterprise servers from `managed-mcp.json`)
- Denylist takes absolute precedence: server appearing in both lists will be blocked

<Note>
**Enterprise configuration precedence**: Enterprise MCP configuration has highest precedence and cannot be overridden by user, local, or project configurations.
</Note>

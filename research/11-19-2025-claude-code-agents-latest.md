# Claude Code Agents Research

## Overview

- **Version**: Latest (as of January 2025)
- **Purpose in Project**: Creating and deploying specialized subagents in Claude Code for autonomous task handling
- **Official Documentation**:
  - [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents)
  - [Claude Agent SDK](https://platform.claude.com/docs/en/agent-sdk/overview)
  - [Agent Skills](https://code.claude.com/docs/en/skills)
  - [Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- **Last Updated**: 2025-01-19

## Core Concepts

### What Are Claude Code Agents?

Claude Code agents operate on a fundamental feedback loop: **gather context → take action → verify work → repeat**. The system provides three main extensibility mechanisms:

1. **Subagents**: Specialized AI assistants with dedicated context windows and custom configurations
2. **Agent Skills**: Modular capabilities that Claude autonomously invokes based on task requirements
3. **Hooks**: Event-driven automation that executes at specific workflow stages

### Key Design Principles

- **Isolated Context**: Each subagent operates in its own context window, preventing pollution of the main conversation
- **Progressive Disclosure**: Information is revealed layer-by-layer as needed, maximizing context efficiency
- **Model-Invoked**: Claude autonomously decides when to use skills and subagents based on descriptions
- **Low-level Customization**: Design agents around your specific workflow rather than adapting to predefined patterns

## Installation

### Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
```

### Claude Agent SDK

**TypeScript:**

```bash
npm install @anthropic-ai/claude-agent-sdk
```

**Python:**

```bash
pip install claude-agent-sdk
```

Requires Python 3.10+ or Node.js 18+.

## Authentication

The SDK supports three authentication methods:

1. **Direct API Key**

```bash
export ANTHROPIC_API_KEY=your-api-key
```

2. **Amazon Bedrock**

```bash
export CLAUDE_CODE_USE_BEDROCK=1
```

Configure AWS credentials via standard AWS methods.

3. **Google Vertex AI**

```bash
export CLAUDE_CODE_USE_VERTEX=1
```

Configure Google Cloud credentials.

## Subagents

### Creating Subagents

#### Quick Start Process

1. Run `/agents` command in Claude Code
2. Select "Create New Agent"
3. Define the subagent with detailed description and tool selection
4. Save and invoke automatically or explicitly

#### File Structure

Subagents use Markdown files with YAML frontmatter:

```markdown
---
name: agent-name
description: When/how to use this agent
tools: Tool1, Tool2, Tool3
model: sonnet
permissionMode: default
skills: skill1, skill2
---

System prompt describing the subagent's role and behavior.
```

### Configuration Fields

| Field            | Required | Type   | Purpose                                                 |
| ---------------- | -------- | ------ | ------------------------------------------------------- |
| `name`           | Yes      | string | Unique lowercase identifier with hyphens (max 64 chars) |
| `description`    | Yes      | string | Natural language purpose statement (max 1024 chars)     |
| `tools`          | No       | string | Comma-separated tools; omit to inherit all              |
| `model`          | No       | string | Model alias (sonnet/opus/haiku) or 'inherit'            |
| `permissionMode` | No       | string | Controls permission handling                            |
| `skills`         | No       | string | Auto-load skills on startup                             |

### Storage Locations

| Type    | Path                | Scope           | Priority |
| ------- | ------------------- | --------------- | -------- |
| Project | `.claude/agents/`   | Current project | Highest  |
| User    | `~/.claude/agents/` | All projects    | Lower    |
| Plugin  | `agents/` directory | Via plugin      | Varies   |

Project-level subagents override user-level when names conflict.

### Permission Modes

| Mode                | Description                                                | Use Case                                                           |
| ------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------ |
| `default`           | Standard permission behavior with normal checks            | Controlled execution requiring user approval                       |
| `acceptEdits`       | Auto-approves file modifications and filesystem operations | Rapid prototyping with isolated files                              |
| `bypassPermissions` | Bypasses all permission verification checks                | Controlled environments only (use with extreme caution)            |
| `plan`              | Planning mode - no execution                               | Present plan before running tools (not currently supported in SDK) |

### Tool Access

Subagents access Claude Code's built-in tools:

**Core Tools:**

- **Bash** - Execute shell commands with persistent sessions
- **Glob** - Fast file pattern matching
- **Grep** - Content search with regex support
- **Read** - Retrieve file content (supports text, images, PDFs, notebooks)
- **Edit** - Exact string replacements in files
- **Write** - Create or overwrite files
- **MultiEdit** - Multiple edits to a single file atomically

**Specialized Tools:**

- **Task** - Launch specialized sub-agents
- **WebFetch** - Extract information from web pages
- **WebSearch** - Query the web for current information
- **TodoWrite/TodoRead** - Task management and tracking
- **NotebookRead/NotebookEdit** - Jupyter notebook operations
- **SlashCommand** - Execute custom slash commands
- **ExitPlanMode** - Conclude planning phases

**Tool Configuration:**

- Omit `tools` field to inherit all tools from main thread (including MCP tools)
- Specify individual tools as comma-separated list for granular control
- Use `/agents` interface for easy tool permission management

### Using Subagents

#### Automatic Delegation

Claude Code proactively delegates tasks based on:

- The task description in your request
- The `description` field in subagent configurations
- Current context and available tools

**Pro Tip:** Include phrases like "use PROACTIVELY" in descriptions for more active delegation.

#### Explicit Invocation

```
> Use the code-reviewer subagent to check my recent changes
> Have the debugger subagent investigate this error
> Ask the data-scientist subagent to analyze this dataset
```

#### Chaining

Complex workflows can sequence multiple subagents for phased task completion.

### Example Subagents

#### Code Reviewer

```markdown
---
name: code-reviewer
description: Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards of code quality and security.

When invoked:

1. Run git diff to see recent changes
2. Focus on modified files
3. Check for:
   - Security vulnerabilities
   - Performance issues
   - Code style consistency
   - Best practices adherence
   - Missing tests or documentation
4. Provide specific, actionable feedback
```

#### Debugger

```markdown
---
name: debugger
description: Debugging specialist for errors, test failures, and unexpected behavior. Use proactively when encountering any issues.
tools: Read, Bash, Grep, Glob
model: sonnet
---

You are an expert debugger specializing in root cause analysis.

When invoked:

1. Understand the error or failure
2. Gather relevant logs and stack traces
3. Identify the root cause
4. Propose specific fixes
5. Verify the fix resolves the issue
```

#### Data Scientist

```markdown
---
name: data-scientist
description: Data analysis specialist for SQL, BigQuery, and analytics tasks. Use when working with databases or analyzing data.
tools: Bash, Read, Write
model: sonnet
---

You are a data scientist specializing in SQL and BigQuery analysis.

When invoked:

1. Understand the data analysis requirement
2. Write efficient SQL queries
3. Use BigQuery command line tools (bq) when appropriate
4. Analyze results and provide insights
5. Create visualizations when helpful
```

### Advanced Features

#### Resumable Subagents

Subagents can be resumed to continue previous conversations:

- Each execution receives unique `agentId`
- Transcripts stored as `agent-{agentId}.jsonl`
- Resume with `resume` parameter to maintain context
- Useful for long-running research or iterative tasks

#### CLI-Based Configuration

Define subagents dynamically using `--agents` JSON flag for testing, session-specific needs, or automation scripts.

## Agent Skills

### What Are Agent Skills?

Agent Skills are modular capability packages that extend Claude's functionality. They use **progressive disclosure** to load information layer-by-layer as needed, maximizing context efficiency.

### SKILL.md Format

Every Skill requires a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: skill-identifier
description: What it does and when to use it
allowed-tools: Tool1, Tool2, Tool3
---

# Skill Title

Instructions for Claude behavior.

## Examples

Usage demonstrations.

## Guidelines

Implementation constraints.
```

### Required Fields

| Field         | Type   | Purpose                               | Max Length |
| ------------- | ------ | ------------------------------------- | ---------- |
| `name`        | string | Lowercase, alphanumeric, hyphens only | 64 chars   |
| `description` | string | Context for Claude's discovery        | 1024 chars |

### Optional Fields

| Field           | Type   | Purpose                                                         |
| --------------- | ------ | --------------------------------------------------------------- |
| `allowed-tools` | string | Restricts Claude to specified tools without permission requests |

### File Structure & Progressive Disclosure

Skills support modular organization:

```tree
skill-name/
├── SKILL.md (required)
├── reference.md
├── examples.md
├── scripts/
│   └── extraction.py
└── templates/
    └── form.json
```

Claude reads files only when needed, implementing progressive disclosure:

1. **Metadata Level**: Skill names and descriptions pre-load into system prompt
2. **Core Level**: Complete `SKILL.md` loads when Claude determines relevance
3. **Detailed Level**: Supporting files retrieved on-demand

### Storage Locations

- **Personal**: `~/.claude/skills/` (individual workflows)
- **Project**: `.claude/skills/` (team-shared, git-tracked)
- **Plugin-bundled**: Automatically available via plugin installation

### Tool Access Control

The `allowed-tools` field restricts capabilities:

```yaml
---
name: safe-file-reader
description: Read files without making changes. Use when you need read-only file access.
allowed-tools: Read, Grep, Glob
---
```

This enables read-only Skills or limited-scope operations.

### Example Skills

#### PDF Processing Skill

```markdown
---
name: pdf-processor
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
allowed-tools: Bash, Read, Write
---

# PDF Processor

Extract text, fill forms, and manipulate PDF documents.

## Capabilities

- Text extraction
- Table extraction
- Form filling
- PDF merging and splitting

## Usage

When invoked:

1. Identify the PDF operation needed
2. Use Python scripts in /scripts for deterministic operations
3. Provide results in requested format

## Reference

See [reference.md](reference.md) for detailed API documentation.
```

#### Excel Analysis Skill

```markdown
---
name: excel-analyzer
description: Analyze Excel spreadsheets, create pivot tables, and generate charts. Use when working with Excel files, spreadsheets, or analyzing tabular data in .xlsx format.
allowed-tools: Bash, Read, Write
---

# Excel Analyzer

Analyze and manipulate Excel spreadsheets.

## Capabilities

- Data analysis
- Pivot table creation
- Chart generation
- Formula validation

## Scripts

Use scripts in /scripts for operations:

- `analyze.py` - Statistical analysis
- `pivot.py` - Pivot table generation
- `chart.py` - Chart creation
```

### Best Practices for Skills

1. **Focused scope**: Each Skill addresses one capability, not broad domains
2. **Specific descriptions**: Include trigger keywords users would mention
3. **Team validation**: Gather feedback from teammates before standardization
4. **Version documentation**: Track changes in SKILL.md
5. **Start with evaluation**: Identify capability gaps through testing before building
6. **Structure for scale**: Split unwieldy files, separate mutually exclusive contexts
7. **Think from Claude's perspective**: Monitor usage patterns; refine based on trigger behavior
8. **Iterate with Claude**: Collaborate with the model to discover context needs

### Security Considerations

Install skills only from trusted sources. Before use, audit bundled files for:

- Suspicious code dependencies
- External network connections
- Potential data exfiltration vectors

## Hooks

### What Are Hooks?

Hooks are event-driven automation that executes at specific workflow stages. They run automatically during the agent loop with your current environment's credentials.

### Hook Events

Claude Code supports 10 hook events:

| Event               | Timing                               | Can Block |
| ------------------- | ------------------------------------ | --------- |
| `PreToolUse`        | Before tool calls                    | Yes       |
| `PermissionRequest` | When permission dialogs appear       | Yes       |
| `PostToolUse`       | After tool calls complete            | No        |
| `UserPromptSubmit`  | Before Claude processes user input   | No        |
| `Notification`      | When Claude Code sends notifications | No        |
| `Stop`              | When Claude Code finishes responding | No        |
| `SubagentStop`      | When subagent tasks complete         | No        |
| `PreCompact`        | Before compact operations            | No        |
| `SessionStart`      | At session initiation or resumption  | No        |
| `SessionEnd`        | When a session terminates            | No        |

### Configuration Format

Hooks are stored in `~/.claude/settings.json` or `.claude/settings.json`:

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolName|ToolName",
        "hooks": [
          {
            "type": "command",
            "command": "shell command here"
          }
        ]
      }
    ]
  }
}
```

### Matcher Patterns

- **Specific tools**: `"Bash"`, `"Edit|Write"` (pipe-separated alternatives)
- **All tools**: `"*"` wildcard
- **Empty string**: Matches all occurrences

### Input Data Structure

Hooks receive JSON stdin:

```json
{
  "tool_input": {
    "command": "...",
    "description": "...",
    "file_path": "..."
  }
}
```

Access fields using `jq` for JSON parsing.

### Examples

#### Command Logging (PreToolUse)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"\\(.tool_input.command) - \\(.tool_input.description // \"No description\")\"' >> ~/.claude/bash-command-log.txt"
          }
        ]
      }
    ]
  }
}
```

#### Auto-Formatting (PostToolUse)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file_path; if echo \"$file_path\" | grep -q '\\.ts$'; then npx prettier --write \"$file_path\"; fi; }"
          }
        ]
      }
    ]
  }
}
```

#### File Protection (PreToolUse)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file_path; if [[ \"$file_path\" =~ \\.(env|lock)$ ]] || [[ \"$file_path\" =~ \\.git/ ]]; then exit 2; fi; }"
          }
        ]
      }
    ]
  }
}
```

**Control Flow:**

- Exit code 2 blocks operations
- Exit code 0 allows continuation

### Security Warning

Hooks run automatically with your current environment credentials. Malicious hooks can exfiltrate data. Only use hooks from trusted sources and audit all hook code before deployment.

## Slash Commands

### What Are Slash Commands?

Slash commands are custom prompts stored as Markdown files that you can trigger with `/command-name` syntax. They function as reusable prompt templates.

### File Organization

| Type     | Path                  | Scope                         |
| -------- | --------------------- | ----------------------------- |
| Project  | `.claude/commands/`   | Shared with team via Git      |
| Personal | `~/.claude/commands/` | Available across all projects |
| Plugin   | Plugin-provided       | Namespace support             |

### Basic Format

Each command is a Markdown file. The filename (minus `.md`) becomes the command name:

```markdown
Review the codebase for security vulnerabilities and provide a detailed report.
```

Save as `.claude/commands/security-audit.md`, invoke with `/security-audit`.

### Argument Interpolation

#### All Arguments (`$ARGUMENTS`)

```markdown
Create a new React component named $ARGUMENTS with TypeScript and tests.
```

Usage: `/new-component UserProfile`

#### Positional Parameters

```markdown
Create a $1 component named $2 with:

- TypeScript
- Unit tests
- Storybook story

Default type: ${1:-functional}
```

Usage: `/create-component class UserProfile`

### Frontmatter Options

```yaml
---
allowed-tools: Read, Grep, Glob
argument-hint: <component-name>
description: Create a new React component with tests
model: sonnet
disable-model-invocation: false
---
```

| Option                     | Purpose                              |
| -------------------------- | ------------------------------------ |
| `allowed-tools`            | Specifies permitted tools            |
| `argument-hint`            | Display hints during auto-completion |
| `description`              | Brief command summary                |
| `model`                    | Selects specific Claude model        |
| `disable-model-invocation` | Prevents SlashCommand tool execution |

### Advanced Features

#### Bash Integration

```yaml
---
allowed-tools: Bash
---

Run the following command:
!git status && git log -n 5 --oneline
```

#### File References

```markdown
Review the following file for issues:
@src/components/UserProfile.tsx
```

### Integration with Agents

**SlashCommand Tool**: Claude can programmatically execute custom commands during conversations when appropriate. This tool only supports user-defined commands with populated descriptions.

**Skills vs. Slash Commands**:

- Slash commands suit simple, frequently-used prompts
- Skills handle complex workflows requiring multiple files
- Both can coexist in projects

### Example Slash Commands

#### Code Review

`.claude/commands/review-pr.md`:

```markdown
---
description: Review a pull request for quality and security
argument-hint: <PR-number>
---

Review pull request #$ARGUMENTS:

1. Check code quality and style
2. Identify security vulnerabilities
3. Suggest performance improvements
4. Verify test coverage
5. Provide actionable feedback
```

#### Feature Creation

`.claude/commands/new-feature.md`:

```markdown
---
description: Scaffold a new feature with tests and documentation
argument-hint: <feature-name>
---

Create a new feature: $ARGUMENTS

Include:

- Feature implementation
- Unit tests
- Integration tests
- Documentation
- Usage examples
```

## Claude Agent SDK

### Python SDK

#### Basic Usage

```python
import anyio
from claude_agent_sdk import query

async def main():
    async for message in query(prompt="What is 2 + 2?"):
        print(message)

anyio.run(main)
```

#### Configuration

```python
from claude_agent_sdk import ClaudeAgentOptions

options = ClaudeAgentOptions(
    system_prompt="You are a helpful assistant",
    max_turns=1,
    allowed_tools=["Read", "Write", "Bash"],
    permission_mode='acceptEdits',
    cwd="/path/to/project"
)

async for message in query(prompt="Your task", options=options):
    pass
```

#### Interactive Client

```python
from claude_agent_sdk import ClaudeSDKClient

async with ClaudeSDKClient(options=options) as client:
    await client.query("Your prompt")
    async for msg in client.receive_response():
        print(msg)
```

#### Custom Tools (In-Process MCP Servers)

```python
from claude_agent_sdk import tool, create_sdk_mcp_server

@tool("greet", "Greet a user", {"name": str})
async def greet_user(args):
    return {
        "content": [
            {"type": "text", "text": f"Hello, {args['name']}!"}
        ]
    }

server = create_sdk_mcp_server(
    name="my-tools",
    version="1.0.0",
    tools=[greet_user]
)

options = ClaudeAgentOptions(
    mcp_servers={"tools": server},
    allowed_tools=["mcp__tools__greet"]
)
```

#### Permission Hooks

```python
from claude_agent_sdk import HookMatcher

async def check_bash_command(input_data, tool_use_id, context):
    if input_data["tool_name"] != "Bash":
        return {}
    command = input_data["tool_input"].get("command", "")
    if "dangerous_pattern" in command:
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": "Blocked pattern detected"
            }
        }
    return {}

options = ClaudeAgentOptions(
    hooks={
        "PreToolUse": [
            HookMatcher(matcher="Bash", hooks=[check_bash_command])
        ]
    }
)
```

#### Error Handling

```python
from claude_agent_sdk import (
    ClaudeSDKError,
    CLINotFoundError,
    CLIConnectionError,
    ProcessError,
    CLIJSONDecodeError
)

try:
    async for message in query(prompt="test"):
        pass
except CLINotFoundError:
    print("Install Claude Code CLI")
except ProcessError as e:
    print(f"Exit code: {e.exit_code}")
```

#### Configuration Options

| Option            | Purpose                        |
| ----------------- | ------------------------------ |
| `system_prompt`   | Custom instruction set         |
| `max_turns`       | Conversation turn limit        |
| `allowed_tools`   | Accessible tools list          |
| `permission_mode` | Auto-accept/deny behaviors     |
| `cwd`             | Working directory path         |
| `mcp_servers`     | Custom or external MCP servers |
| `hooks`           | Execution interceptors         |

### TypeScript SDK

```typescript
import { query, ClaudeAgentOptions } from '@anthropic-ai/claude-agent-sdk';

const options: ClaudeAgentOptions = {
  systemPrompt: 'You are a helpful assistant',
  maxTurns: 1,
  allowedTools: ['Read', 'Write', 'Bash'],
  permissionMode: 'acceptEdits',
  cwd: '/path/to/project',
};

for await (const message of query({ prompt: 'Your task', options })) {
  console.log(message);
}
```

## Model Context Protocol (MCP)

### What Is MCP?

The Model Context Protocol is an open standard for connecting AI agents to external systems. As of 2025, MCP has been adopted as the de-facto industry standard:

- **OpenAI** officially adopted MCP in March 2025
- **Google DeepMind** confirmed MCP support in Gemini models in April 2025
- Thousands of MCP servers built by the community

### Integration with Claude Code

Claude Code can connect to hundreds of external tools and data sources through MCP servers. MCP servers give Claude Code access to:

- Development tools: GitHub, Linear, Jira, Figma
- Communication: Slack, Intercom
- Payments: Stripe, Square, Plaid
- Databases and project management: Asana, Atlassian

### MCP in Subagents

Subagents automatically inherit MCP tools when the `tools` field is omitted:

```markdown
---
name: github-integration
description: Manage GitHub repositories, PRs, and issues
---

You have access to GitHub via MCP. Use it to:

- Create and manage issues
- Review pull requests
- Manage repository settings
```

### MCP Server Configuration

Configure MCP servers in `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your-token"
      }
    }
  }
}
```

### Code Execution with MCP

Code execution applies established patterns to agents, letting them use familiar programming constructs to interact with MCP servers more efficiently. This approach helps agents handle large numbers of tools while managing context token usage.

### Security (2025 Updates)

Claude Code (CLI and web) now includes:

- Filesystem sandboxing
- Network sandboxing
- Intelligent guardrails preventing accidental or malicious actions
- Reduced permission prompts while maintaining security

## CLAUDE.md Files

### What Are CLAUDE.md Files?

Special configuration files that Claude automatically incorporates into conversations. They serve as persistent context and instructions.

### Storage Locations

- Repository root: Project-specific instructions
- Parent/child directories: Hierarchical context
- Home folder (`~/.claude/CLAUDE.md`): Universal access across all projects

### What to Document

- Common bash commands and their purposes
- Core files, utility functions, and code style guidelines
- Testing and workflow instructions
- Repository conventions and developer environment requirements
- Project-specific quirks or unexpected behaviors

### Example CLAUDE.md

```markdown
# Project Context

## Architecture

This is a React application using TypeScript and Vite.

## Code Style

- Use functional components
- Prefer named exports
- Use TypeScript strict mode
- Follow Airbnb style guide

## Testing

- Run tests with: npm test
- Write tests for all new features
- Aim for 80% coverage

## Common Commands

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript compiler

## File Structure

- `/src/components` - React components
- `/src/hooks` - Custom hooks
- `/src/utils` - Utility functions
- `/src/types` - TypeScript types

## Quirks

- The API expects dates in ISO 8601 format
- Authentication tokens expire after 1 hour
- The build process requires Node 18+
```

### Best Practices

- Refine CLAUDE.md like you would production prompts through iterative testing
- Use the `#` key to have Claude automatically incorporate new instructions
- Run files through prompt improvement tools periodically
- Clear irrelevant context between tasks using `/clear` to maintain performance

## Plugins

### What Are Plugins?

Plugins are custom collections of:

- Slash commands
- Subagents
- MCP servers
- Hooks

They install with a single command and provide namespace support.

### Plugin Distribution

Recommended approach for sharing Skills and agents with teams. Alternatively, commit project Skills/agents to git for automatic team distribution.

## Best Practices

### Agent Design

1. **Start focused**: Create single-purpose agents initially
2. **Begin lightweight**: Minimal or no tools for maximum composability
3. **Use Claude-generated agents**: Let Claude help create initial agent definitions
4. **Write detailed prompts**: Clear, specific instructions improve performance
5. **Limit tool access**: Scope tools to necessary operations only

### Planning and Decomposition

1. **Research first**: Have Claude read files and understand context before coding
2. **Generate plans**: Request detailed plans before implementation
3. **Iterative implementation**: Implement and verify solutions step-by-step
4. **Use TodoWrite**: Break down complex tasks into trackable steps

### Context Management

1. **Use CLAUDE.md**: Document architecture, conventions, and patterns
2. **Progressive disclosure**: Load information as needed, not all at once
3. **Clear between tasks**: Use `/clear` to reset context for new work
4. **Optimize descriptions**: Craft skill/agent descriptions for accurate discovery

### Tool Management

1. **Scope tools per agent**: PM & Architect are read-heavy; Implementer gets Edit/Write/Bash
2. **Default inheritance**: Omit tools field to grant access to all available tools
3. **Explicit restrictions**: Use `allowed-tools` for read-only or limited agents
4. **Permission modes**: Start with `default`, switch to `acceptEdits` for trusted workflows

### Performance Optimization

1. **Engineer token efficiency**: Minimize tokens needed for agent initialization
2. **Use Haiku strategically**: Claude Haiku 4.5 delivers 90% of Sonnet performance at 2x speed, 3x cost savings
3. **Batch operations**: Run parallel tool calls when possible
4. **Compact context**: SDK automatically summarizes when approaching context limits

### Skills Development

1. **Start with evaluation**: Identify specific gaps before building
2. **Build incrementally**: Address shortcomings one at a time
3. **Structure for scale**: Split large files, separate exclusive contexts
4. **Monitor usage**: Refine based on actual trigger patterns
5. **Iterate with Claude**: Discover context needs through collaboration

### Multi-Agent Workflows

1. **Separate instances**: Run distinct Claude instances for writing and verification
2. **Use git worktrees**: Enable parallel independent tasks
3. **Fan-out patterns**: Generate task lists, process items concurrently
4. **Headless mode**: Chain operations via `-p` flag with JSON output

### Testing and Verification

1. **Independent verification**: Don't trust Claude's test reports without confirmation
2. **Run actual tests**: Execute test commands, verify outputs
3. **Check exit codes**: Scripts may report success despite failures
4. **Review carefully**: Tests can be flawed; validate before committing

## Common Anti-Patterns and Mistakes

### Starting Without Planning

Launching Claude straight into code without exploration leads to slow, chaotic progress with many iterations.

**Solution**: Allow Claude to explore the codebase, generate plans, use planning mode.

### Permission Sprawl

Granting excessive permissions creates unsafe autonomy.

**Solution**: Start with `default` mode, escalate to `acceptEdits` only for trusted operations.

### Ignoring Test Failures

Claude may add imports/parameters without using them, write failing tests, or report success when tests fail.

**Solution**: Independently verify all test results, review generated code carefully.

### Vague Descriptions

Poorly written skill/agent descriptions impair discovery.

**Solution**: Include specific trigger keywords users would mention, articulate both functionality and activation triggers.

### Missing Context

Extensive content without iteration on effectiveness.

**Solution**: Use CLAUDE.md to document patterns, iterate based on feedback, refine continuously.

### Assuming Knowledge

Believing you know how a tool works without consulting current documentation.

**Solution**: Always fetch current official documentation, verify version-specific behavior.

### Over-Mocking in Tests

Creating tests that validate mock behavior instead of actual functionality.

**Solution**: Test real implementations, use mocks sparingly and only when necessary.

## Advanced Patterns

### Subagent-Driven Development

Dispatch fresh subagent for each task with code review between tasks, enabling fast iteration with quality gates.

### Root Cause Tracing

Systematically trace bugs backward through call stack, adding instrumentation when needed, to identify source of invalid data or incorrect behavior.

### Defense in Depth

Validate data at every layer it passes through to make bugs structurally impossible.

### Condition-Based Waiting

Replace arbitrary timeouts with condition polling to wait for actual state changes, eliminating flaky tests.

### Verification Before Completion

Run verification commands and confirm output before making any success claims. Evidence before assertions always.

## Code Examples

### Complete Subagent Example

`.claude/agents/api-tester.md`:

```markdown
---
name: api-tester
description: Test REST APIs with comprehensive validation. Use proactively when working with API endpoints or HTTP requests.
tools: Bash, Read, Write
model: sonnet
permissionMode: default
---

You are an API testing specialist.

When invoked:

1. **Analyze the API**

   - Read API documentation
   - Identify endpoints to test
   - Note authentication requirements

2. **Generate Test Cases**

   - Happy path scenarios
   - Error cases
   - Edge cases
   - Authentication/authorization tests

3. **Execute Tests**

   - Use curl or HTTPie for requests
   - Validate response status codes
   - Verify response bodies
   - Check headers

4. **Report Results**

   - Summarize test outcomes
   - Highlight failures
   - Suggest improvements

5. **Generate Test Scripts**
   - Create reusable test scripts
   - Include assertions
   - Add documentation
```

### Complete Skill Example

`.claude/skills/dockerfile-builder/SKILL.md`:

```markdown
---
name: dockerfile-builder
description: Create optimized Dockerfiles for applications. Use when building containers or when the user mentions Docker, containers, or deployment.
allowed-tools: Read, Write, Bash
---

# Dockerfile Builder

Create production-ready, optimized Dockerfiles.

## Capabilities

- Multi-stage builds for minimal image size
- Security best practices
- Build caching optimization
- Health checks and metadata

## Process

1. **Analyze Application**

   - Identify language/framework
   - Determine dependencies
   - Check for build requirements

2. **Generate Dockerfile**

   - Use appropriate base image
   - Implement multi-stage build
   - Optimize layer caching
   - Add security measures

3. **Add Configuration**

   - .dockerignore file
   - Health checks
   - Labels and metadata
   - Build arguments

4. **Test Build**
   - Build image locally
   - Verify image size
   - Test runtime behavior

## Best Practices

- Use specific version tags, never :latest
- Run as non-root user
- Minimize layers
- Use .dockerignore
- Include health checks
- Add labels for metadata

## Examples

See [examples.md](examples.md) for language-specific templates.

## Reference

See [reference.md](reference.md) for detailed optimization techniques.
```

`.claude/skills/dockerfile-builder/examples.md`:

````markdown
# Dockerfile Examples

## Node.js Application

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
WORKDIR /app
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
USER nodejs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node healthcheck.js
CMD ["node", "dist/index.js"]
```
````

## Python Application

```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.11-slim
RUN useradd -m -u 1001 appuser
WORKDIR /app
COPY --from=builder /root/.local /home/appuser/.local
COPY . .
RUN chown -R appuser:appuser /app
USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD python healthcheck.py
CMD ["python", "main.py"]
```

````

### Hooks Configuration Example

`~/.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.command' | { read cmd; if echo \"$cmd\" | grep -q 'rm -rf /'; then exit 2; fi; }"
          },
          {
            "type": "command",
            "command": "jq -r '\"[BASH] \\(.tool_input.command)\"' >> ~/.claude/audit.log"
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file; if [[ \"$file\" =~ (package-lock.json|yarn.lock|\\.env)$ ]]; then exit 2; fi; }"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file; case \"$file\" in *.ts|*.tsx) npx prettier --write \"$file\" ;; *.py) black \"$file\" ;; esac; }"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"Session ended at $(date)\" >> ~/.claude/sessions.log"
          }
        ]
      }
    ]
  },
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/directory"]
    }
  }
}
````

### SDK Usage Example

```python
import anyio
from claude_agent_sdk import query, ClaudeAgentOptions, tool, create_sdk_mcp_server

@tool("search_codebase", "Search codebase for patterns", {"pattern": str, "file_type": str})
async def search_codebase(args):
    pattern = args["pattern"]
    file_type = args.get("file_type", "*")

    import subprocess
    result = subprocess.run(
        ["grep", "-r", pattern, f"*.{file_type}"],
        capture_output=True,
        text=True
    )

    return {
        "content": [
            {"type": "text", "text": result.stdout}
        ]
    }

@tool("run_tests", "Execute test suite", {"test_path": str})
async def run_tests(args):
    test_path = args["test_path"]

    import subprocess
    result = subprocess.run(
        ["pytest", test_path, "-v"],
        capture_output=True,
        text=True
    )

    return {
        "content": [
            {
                "type": "text",
                "text": f"Exit code: {result.returncode}\n\nOutput:\n{result.stdout}\n\nErrors:\n{result.stderr}"
            }
        ]
    }

async def main():
    server = create_sdk_mcp_server(
        name="custom-tools",
        version="1.0.0",
        tools=[search_codebase, run_tests]
    )

    options = ClaudeAgentOptions(
        system_prompt="You are a software engineering assistant with access to codebase search and testing tools.",
        max_turns=10,
        mcp_servers={"custom": server},
        allowed_tools=["mcp__custom__search_codebase", "mcp__custom__run_tests", "Read", "Edit", "Bash"],
        permission_mode="default",
        cwd="/path/to/project"
    )

    prompt = """
    Search the codebase for uses of the deprecated 'oldFunction' and:
    1. List all occurrences
    2. Suggest replacements with 'newFunction'
    3. Update the code
    4. Run tests to verify nothing broke
    """

    async for message in query(prompt=prompt, options=options):
        print(message)

anyio.run(main)
```

## Version-Specific Notes

### January 2025 Updates

- **MCP Adoption**: OpenAI and Google DeepMind officially adopted MCP
- **Security Enhancements**: Filesystem and network sandboxing in Claude Code
- **Claude Haiku 4.5**: 90% of Sonnet performance at 2x speed, 3x cost savings
- **Agent Skills**: Progressive disclosure architecture for context efficiency
- **Plugins System**: Install collections of commands, agents, MCP servers, and hooks

### Migration Notes

- Claude Code SDK renamed to Claude Agent SDK (reflects broader applicability)
- `plan` permission mode not yet supported in SDK
- Subagents cannot spawn other subagents (prevents infinite nesting)
- MCP servers are accessed via `mcp__server-name__tool-name` format

### Breaking Changes

None reported for current stable versions.

### Deprecations

None reported for current stable versions.

## References

### Official Documentation

- [Claude Code Documentation](https://code.claude.com/docs)
- [Claude Agent SDK Documentation](https://platform.claude.com/docs/en/agent-sdk/overview)
- [Agent Skills Guide](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp)

### GitHub Repositories

- [Claude Agent SDK - Python](https://github.com/anthropics/claude-agent-sdk-python)
- [Agent Skills Examples](https://github.com/anthropics/skills)
- [Awesome Claude Code Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)

### Community Resources

- [ClaudeLog](https://claudelog.com/) - Documentation, guides, tutorials
- [Claude Code Hooks Mastery](https://github.com/disler/claude-code-hooks-mastery)
- [Claude Command Suite](https://github.com/qdhenry/Claude-Command-Suite)

### Tools & Standards

- [Model Context Protocol](https://www.anthropic.com/news/model-context-protocol)
- [MCP Servers Directory](https://github.com/modelcontextprotocol/servers)

---

**Research Completed**: 2025-01-19
**Research Duration**: Comprehensive analysis of official documentation, SDK references, community resources, and best practices
**Sources Verified**: All code examples and configuration options verified against official Anthropic documentation as of January 2025

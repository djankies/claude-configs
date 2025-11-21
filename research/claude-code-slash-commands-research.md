# Claude Code Slash Commands Research

## Overview

- **Research Focus**: Writing effective Claude Code slash commands
- **Purpose in Project**: Guide development of reusable, maintainable slash commands for team workflows
- **Official Documentation**: https://code.claude.com/docs/en/slash-commands
- **Last Updated**: 2025-11-15

## Table of Contents

1. [What Are Slash Commands](#what-are-slash-commands)
2. [File Structure and Syntax](#file-structure-and-syntax)
3. [Frontmatter Configuration](#frontmatter-configuration)
4. [Dynamic Elements](#dynamic-elements)
5. [XML Tag Structuring](#xml-tag-structuring)
6. [Tool Integration](#tool-integration)
7. [Agent and Task System](#agent-and-task-system)
8. [TodoWrite Integration](#todowrite-integration)
9. [Extended Thinking](#extended-thinking)
10. [Best Practices](#best-practices)
11. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
12. [Command Design Patterns](#command-design-patterns)
13. [Validation and Testing](#validation-and-testing)
14. [Real-World Examples](#real-world-examples)

---

## What Are Slash Commands

Slash commands are **Markdown files containing prompt templates** that Claude Code executes when invoked. They transform complex, multi-line prompts into single, memorable commands that codify team knowledge and best practices.

### Key Characteristics

- **Reusable Prompts**: Store frequently-used instructions as executable templates
- **Team Sharing**: Check commands into git for team-wide availability
- **Context Injection**: Dynamically include repository state, file contents, and command outputs
- **Tool Access**: Control which tools (Bash, Edit, Task, etc.) the command can use

### Storage Locations

| Location              | Path                  | Scope                                   | Label in `/help` |
| --------------------- | --------------------- | --------------------------------------- | ---------------- |
| **Project commands**  | `.claude/commands/`   | Repository-specific, version-controlled | `(project)`      |
| **Personal commands** | `~/.claude/commands/` | User-specific, all projects             | `(user)`         |

### Invocation Syntax

```bash
/<command-name> [arguments]
```

Command names are derived from Markdown filenames (without `.md` extension).

---

## File Structure and Syntax

### Basic Structure

```markdown
---
[YAML frontmatter]
---

[Command content/prompt]
```

### Namespacing

Organize commands in subdirectories for categorization:

```
.claude/commands/
├── frontend/
│   └── component.md          # Invoked as /component (project:frontend)
├── backend/
│   └── api.md               # Invoked as /api (project:backend)
└── general-review.md        # Invoked as /general-review
```

Commands in subdirectories appear in `/help` with namespace prefix: `(project:frontend)`.

---

## Frontmatter Configuration

### Available Frontmatter Fields

| Field                      | Type    | Purpose                                                    | Default                    |
| -------------------------- | ------- | ---------------------------------------------------------- | -------------------------- |
| `allowed-tools`            | List    | Specifies permitted tools                                  | Inherits from conversation |
| `argument-hint`            | String  | Hints for command arguments                                | None                       |
| `description`              | String  | Brief command description (required for SlashCommand tool) | First line of prompt       |
| `model`                    | String  | Specific Claude model to use                               | Inherits from conversation |
| `disable-model-invocation` | Boolean | Prevents SlashCommand tool from invoking it                | `false`                    |

### Frontmatter Examples

**Simple command with tools:**

```yaml
---
description: Create a git commit
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
argument-hint: [message]
---
```

**Complex command with multiple tools:**

```yaml
---
description: Perform comprehensive code review with multi-dimensional analysis
argument-hint: @directory/or/file.tsx
allowed-tools: Task, Read, Glob, Grep, TodoWrite, Bash
---
```

**Model-specific command:**

```yaml
---
description: Quick syntax check
model: claude-3-5-haiku-20241022
allowed-tools: Bash, Read
---
```

### Tool Permission Syntax

The `allowed-tools` field uses specific patterns to control tool access:

| Pattern            | Meaning                    | Example             |
| ------------------ | -------------------------- | ------------------- |
| `ToolName`         | Permit every action        | `Bash`              |
| `ToolName(*)`      | Permit any argument        | `Edit(*)`           |
| `ToolName(filter)` | Permit matching calls only | `Bash(git add:*)`   |
| `ToolName(cmd:*)`  | Specific command pattern   | `Bash(pnpm test:*)` |

**Example: Git-only Bash access**

```yaml
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git log:*)
```

---

## Dynamic Elements

### Argument Placeholders

#### `$ARGUMENTS` - All Arguments

Captures everything passed to the command:

```markdown
---
description: Analyze code changes and create commits
argument-hint: <special instructions> (optional)
---

User provided context: $ARGUMENTS
```

**Invocation:** `/commit please include detailed commit messages`

**Result:** `$ARGUMENTS = "please include detailed commit messages"`

#### Positional Arguments

Access specific arguments individually:

```markdown
---
description: Review pull request
argument-hint: [pr-number] [priority] [assignee]
---

- PR Number: $1
- Priority: $2
- Assignee: $3
```

**Invocation:** `/review-pr 456 high alice`

**Result:**

- `$1 = "456"`
- `$2 = "high"`
- `$3 = "alice"`

### File References with `@`

Include file contents directly in the command context:

```markdown
<context>
Project configuration:
@package.json
@tsconfig.json

Current implementation:
@src/utils/helpers.ts
</context>
```

This injects the **actual file contents** into the prompt when the command runs.

### Bash Execution with `!`

Execute bash commands and include their output in the command context:

```markdown
<context>
Repository state:
- Branch: !`git branch --show-current`
- Status: !`git status --porcelain`
- Recent commits: !`git log --oneline -5`

Project info:

- Working directory: !`pwd`
- Node version: !`node --version`
  </context>
```

**Requirements:**

- Must include `Bash` in `allowed-tools`
- Output is captured at command execution time
- Failed commands show error messages in context

### Combined Example

```markdown
---
description: Debug test failures
allowed-tools: Bash, Read, Edit, Task
argument-hint: [test-file-pattern]
---

<role>
You are a Senior Test Engineer debugging failures in: $ARGUMENTS
</role>

<context>
Test environment:
@package.json
!`pnpm list vitest @testing-library/react`

Current test results:
!`pnpm test $ARGUMENTS 2>&1`

Git context:

- Branch: !`git branch --show-current`
- Recent changes: !`git diff --stat`
  </context>

<task>
Systematically debug and fix all test failures...
</task>
```

---

## XML Tag Structuring

Claude has been **fine-tuned to pay special attention to XML tags**, making them a powerful tool for structuring prompts. While modern Claude models understand structure without tags, they remain highly valuable for complex, multi-part commands.

### Core Benefits

1. **Clarity**: Isolates distinct prompt sections
2. **Accuracy**: Reduces misinterpretation errors
3. **Flexibility**: Easy to modify components without rewriting
4. **Parseability**: Enables post-processing of structured responses

### Recommended XML Tags

The documentation doesn't prescribe specific tags, but recommends meaningful names that match their content:

| Tag             | Purpose                                        | Example Usage                        |
| --------------- | ---------------------------------------------- | ------------------------------------ |
| `<role>`        | Define Claude's expertise and perspective      | Establish domain knowledge           |
| `<context>`     | Background information, file references, state | Project setup, requirements          |
| `<task>`        | Explicit instructions and steps                | What Claude should accomplish        |
| `<constraints>` | Rules, limitations, requirements               | What NOT to do                       |
| `<output>`      | Expected format and structure                  | How to present results               |
| `<examples>`    | Sample inputs/outputs                          | Guide behavior with concrete cases   |
| `<validation>`  | Verification commands and success criteria     | How to confirm correctness           |
| `<tool-usage>`  | When and how to use specific tools             | Guide tool selection                 |
| `<commentary>`  | Usage notes, tips, warnings                    | Help the user understand the command |

### Best Practices for XML Tags

**1. Consistency is Critical**

Use the same tag names throughout your command and reference them explicitly:

```markdown
<context>
Contract details are in @contracts/user-api.yaml
</context>

<task>
Using the contract in <context> tags, implement the API endpoints...
</task>
```

**2. Nesting for Hierarchical Information**

```markdown
<context>
  <project-state>
    - Branch: !`git branch --show-current`
    - Status: !`git status --porcelain`
  </project-state>

  <dependencies>
    @package.json
  </dependencies>
</context>
```

**3. Semantic Tag Names with Attributes**

XML tags support attributes for additional context:

```markdown
<file-to-analyze path="src/utils/auth.ts">
@src/utils/auth.ts
</file-to-analyze>

<expected-behavior>
Authentication should redirect to login on 401 errors
</expected-behavior>
```

**4. Combine with Other Techniques**

```markdown
<examples>
  <example id="good-commit">
```

feat(auth): add OAuth2 token refresh logic

- Implement automatic token refresh before expiration
- Add retry logic for failed refresh attempts
- Update tests for new refresh behavior

```
</example>

<example id="bad-commit">
```

update stuff

```
This is too vague and doesn't follow commit conventions.
</example>
</examples>
```

### Modern Perspective (2025)

While XML tags were once heavily recommended, latest guidance suggests:

- **Still valuable** for complex, structured tasks
- **Less critical** for simple commands
- **Most effective** when combined with clear headings, whitespace, and explicit language
- **Particularly useful** for chain-of-thought (`<thinking>`, `<answer>`) and multishot prompting (`<examples>`)

---

## Tool Integration

### Available Tools in Claude Code

| Tool         | Purpose                    | Permission Required | Common Use Cases                |
| ------------ | -------------------------- | ------------------- | ------------------------------- |
| `Bash`       | Execute shell commands     | Yes                 | Git operations, tests, builds   |
| `Edit`       | Targeted file edits        | Yes                 | Precise code modifications      |
| `MultiEdit`  | Multiple edits atomically  | Yes                 | Batch changes to single file    |
| `Write`      | Create/overwrite files     | Yes                 | New files, generated code       |
| `Read`       | Read file contents         | No                  | File inspection, analysis       |
| `Glob`       | Pattern-based file finding | No                  | Locate files by pattern         |
| `Grep`       | Search file contents       | No                  | Find code patterns              |
| `Task`       | Spawn sub-agents           | No                  | Parallel processing, delegation |
| `TodoWrite`  | Manage task lists          | No                  | Track progress, plan work       |
| `WebFetch`   | Fetch URL content          | Yes                 | Documentation, research         |
| `WebSearch`  | Web searches               | Yes                 | Latest information              |
| `BashKill`   | Kill bash processes        | Yes                 | Stop long-running commands      |
| `BashOutput` | Capture bash output        | No                  | Programmatic command results    |

### Tool Usage Guidance

**Specify tools explicitly in commands:**

```markdown
<tool-usage>
- **Bash**: Run tests, validation commands, gather project info
- **Read/Glob/Grep**: Investigate code files, search patterns, understand structure
- **Edit/MultiEdit**: Implement targeted fixes to specific files
- **Task**: Deploy specialized agents for complex debugging
- **TodoWrite**: Create and manage systematic investigation task lists
</tool-usage>
```

### Bash Tool Best Practices

**1. Always Specify allowed-tools**

```yaml
---
allowed-tools: Bash(git:*), Bash(pnpm:*), Read, Edit
---
```

**2. Use Specific Command Patterns**

```yaml
# Too permissive
allowed-tools: Bash

# Better - scoped to specific operations
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(pnpm test:*)
```

**3. Document Custom Tools in CLAUDE.md**

From Anthropic's best practices: "Tell Claude about custom tools by providing usage examples and encouraging it to run `--help` to see documentation. Document frequently used utilities in `CLAUDE.md`."

**4. Capture Output for Context**

```markdown
Current test failures:
!`pnpm test $ARGUMENTS 2>&1`
```

The `2>&1` redirects stderr to stdout, capturing all output.

---

## Agent and Task System

The **Task tool** enables Claude to delegate operations to sub-agents, dramatically improving efficiency for complex, multi-step workflows.

### Task Tool Overview

**Purpose**: Delegate operations to fresh Claude instances with isolated context windows.

**Key Benefits**:

- **Parallel Processing**: Up to 10 concurrent tasks with intelligent queuing
- **Context Preservation**: Main agent maintains focus while sub-agents handle details
- **Performance**: Reduces main agent overhead and latency
- **Modularity**: Each task has its own context window preventing pollution

### When to Use Task Agents

**Ideal for:**

- File analysis and code searching
- Basic read/write operations
- Bash operations and validation
- Research tasks
- Independent, parallelizable work

**Not ideal for:**

- Simple single-file operations
- Tasks requiring cross-task coordination
- Operations needing main agent's accumulated context

### Task Tool Patterns

#### Pattern 1: Parallel File Processing

```markdown
<task>
If multiple files have errors, spawn Task agents in parallel:

- One Task agent per file (strict 1:1 mapping)
- Each agent handles only its specified file
- No "rest of files" tasks - be explicit

Example Task invocation for 3 files:

1. Task agent for src/auth.ts
2. Task agent for src/api.ts
3. Task agent for src/utils.ts
   </task>
```

**From project's `/type-check` command:**

```markdown
2. **Parallel Processing Setup**
   - Create todo list with TodoWrite tool for tracking progress
   - If multiple files have errors, spawn Task agents in parallel (one per file)
   - Each Task agent must be strictly scoped to a single file
```

#### Pattern 2: Specialized Investigation Agents

**From project's `/fix` command:**

```markdown
**For Complex Issues**: Deploy specialized debugging agents using the Task tool:

- **Code Analysis Agent**: For tracing complex execution paths
- **Test Analysis Agent**: For test failures and debugging test issues
- **Integration Analysis Agent**: For multi-system interaction bugs
```

#### Pattern 3: Comprehensive Review with Task Delegation

**From project's `/general-review` command:**

````markdown
<task>
Use the Task tool to spawn a comprehensive code review agent with the following prompt:

<task-tool-prompt>
```plaintext
Perform a thorough code review of the provided files focusing on:

1. **Static Analysis & Automated Checks** (use Bash tool)

   - Lint specific files: `npx eslint [file_path] --cache`
   - Type check: `pnpm type-check 2>&1 | rg "[file_path]"`

2. **Security Vulnerabilities**
   - Input validation and sanitization issues
   - Authentication/authorization flaws

[... detailed instructions ...]
````

</task-tool-prompt>
</task>
```

### Best Practices for Task Agents

**1. Explicit Orchestration**

From research: "Claude utilizes sub-agents in a reserved manner primarily for operations like reading files, fetching web content, searching for specific text patterns, but maximizing their usage requires explicit delegation instructions."

**Example:**

```markdown
<task>
Execute in phases with explicit Task agent delegation:

**Phase 1: Discovery** (Main agent)

1. Identify all affected files
2. Classify issues by severity

**Phase 2: Resolution** (Task agents - parallel)
For each file with issues:

- Spawn Task agent with scope: [specific file]
- Agent applies fixes
- Agent verifies with validation commands

**Phase 3: Integration** (Main agent)

1. Collect results from all Task agents
2. Run final validation
3. Report summary
   </task>
```

**2. Balanced Grouping**

Don't create separate agents for every tiny operation. Group related tasks:

✅ **Good**: Task agent handles "analyze and fix all linting issues in auth.ts"

❌ **Bad**: Three separate tasks for "find issues", "fix issues", "verify fixes" in same file

**3. Parallel by Default**

Launch multiple Task agents simultaneously when work is independent:

```markdown
Launch the following Task agents in parallel:

1. Task: Fix type errors in src/components/Dialog.tsx
2. Task: Fix type errors in src/components/Modal.tsx
3. Task: Fix type errors in src/lib/utils.ts
```

**4. Context Optimization**

Provide agents with exactly what they need:

```markdown
Task agent context for src/auth.ts:

- Target file: @src/auth.ts
- Type definitions: @src/types/auth.ts
- Test file: @src/auth.test.ts
- Validation command: `pnpm type-check 2>&1 | grep "auth.ts"`
```

### Sub-agent Limitations (2025)

**Cannot spawn other sub-agents**: Task agents cannot spawn their own Task agents, preventing infinite nesting.

**No interactive thinking mode**: Sub-agents begin executing immediately without planning or showing intermediate thought process.

**Write operation conflicts**: Multiple agents modifying the same file simultaneously can conflict - coordinate carefully or make sequential.

---

## TodoWrite Integration

The **TodoWrite tool** provides structured task tracking that demonstrates thoroughness and maintains organization throughout complex workflows.

### When to Use TodoWrite

**Use TodoWrite for:**

- Complex multi-step tasks (3+ distinct steps)
- Non-trivial operations requiring careful planning
- Multiple user-provided tasks
- Workflows requiring progress visibility

**Skip TodoWrite for:**

- Single, straightforward tasks
- Trivial operations (<3 steps)
- Purely conversational interactions

### Task Structure

```typescript
{
  content: string; // Imperative form: "Run tests"
  activeForm: string; // Present continuous: "Running tests"
  status: 'pending' | 'in_progress' | 'completed';
}
```

### Task States and Best Practices

| State         | Meaning               | Best Practice                    |
| ------------- | --------------------- | -------------------------------- |
| `pending`     | Not yet started       | Default for queued tasks         |
| `in_progress` | Currently working on  | **Exactly ONE task** at a time   |
| `completed`   | Finished successfully | Mark IMMEDIATELY after finishing |

**Critical Rules:**

1. **Exactly one in_progress task**: Never less, never more
2. **Immediate completion**: Don't batch completions
3. **Only mark complete when FULLY accomplished**: If errors, blockers, or partial work, keep as in_progress
4. **Two forms required**: Always provide both `content` and `activeForm`

### TodoWrite in Slash Commands

#### Pattern 1: Investigation Task List

**From project's `/fix` command:**

```markdown
**Phase 1: Comprehensive Investigation & Root Cause Analysis**

1. **Create Investigation Todo List** - Use TodoWrite to create a systematic investigation plan
2. **Gather Evidence** - Document the exact problem
3. **Reproduce the Issue** - Verify consistent reproduction
4. **Trace the Data Flow** - Follow code execution paths
5. **Think Deeply About Root Causes** - Use extended thinking
6. **Isolate the Root Cause** - Ensure bug isn't introduced earlier
```

#### Pattern 2: Progress Tracking

**From project's `/type-check` command:**

```markdown
2. **Parallel Processing Setup**
   - Create todo list with TodoWrite tool for tracking progress
   - If multiple files have errors, spawn Task agents in parallel
   - Each Task agent must be strictly scoped to a single file
```

#### Pattern 3: Validation Gates

```markdown
<task>
Use TodoWrite to create a validation checklist:

- [ ] All type errors resolved
- [ ] Tests pass
- [ ] Linting clean
- [ ] Build succeeds
- [ ] Documentation updated

Mark each task complete ONLY after verification commands pass.
</task>
```

### Example TodoWrite Usage

````markdown
<task>
1. Use TodoWrite to create an implementation plan:

```json
{
  "todos": [
    {
      "content": "Analyze all TypeScript errors in src/auth.ts",
      "activeForm": "Analyzing TypeScript errors in src/auth.ts",
      "status": "in_progress"
    },
    {
      "content": "Fix type mismatches in authentication flow",
      "activeForm": "Fixing type mismatches in authentication flow",
      "status": "pending"
    },
    {
      "content": "Verify with type checking and tests",
      "activeForm": "Verifying with type checking and tests",
      "status": "pending"
    }
  ]
}
```
````

2. Work through each task systematically
3. Update status to completed IMMEDIATELY after each task finishes
4. If any task fails validation, keep as in_progress and create new task for fix
   </task>

````

### Completion Criteria

**Only mark tasks completed when:**

✅ Implementation is complete and correct
✅ All tests pass
✅ Validation commands succeed
✅ No errors or blockers remain

**Never mark completed if:**

❌ Tests are failing
❌ Implementation is partial
❌ Unresolved errors exist
❌ Files/dependencies are missing

---

## Extended Thinking

Extended thinking activates deeper reasoning for complex problems. Claude allocates progressively more computational budget based on specific trigger phrases.

### Trigger Phrases (from Anthropic Best Practices)

| Phrase | Thinking Depth | Use Case |
|--------|----------------|----------|
| `"think"` | Standard | Basic multi-step reasoning |
| `"think hard"` | Increased | Complex problem analysis |
| `"think harder"` | High | Deep technical evaluation |
| `"ultrathink"` | Maximum | Extremely complex decisions |
| `"think step-by-step"` | Structured | Methodical breakdown |
| `"think deeply"` | Thorough | Comprehensive analysis |

### When to Use Extended Thinking

**Ideal scenarios:**
- Complex debugging requiring root cause analysis
- Architectural decisions with multiple trade-offs
- Multi-step reasoning tasks
- Performance optimization planning
- Security vulnerability analysis
- Mathematical or logical problems
- When you want to see reasoning process

### Extended Thinking in Commands

**From project's `/type-check` command:**

```markdown
<task>
Think step-by-step to systematically resolve all TypeScript errors in the specified scope.

1. **Error Discovery & Classification**
   - Run comprehensive type checking to identify all errors
   - Classify errors by type
   - Prioritize errors by impact
````

**From project's `/fix` command:**

```markdown
**Phase 1: Comprehensive Investigation & Root Cause Analysis**

5. **Think Deeply About Root Causes** - Use extended thinking to analyze complex interactions
6. **Isolate the Root Cause** - Ensure the bug isn't introduced earlier in the execution chain
```

### Example Usage

```markdown
---
description: Analyze complex performance bottleneck
allowed-tools: Bash, Read, Grep, Task
---

<role>
You are a Performance Engineering Expert analyzing a critical production issue.
</role>

<context>
Performance metrics:
@metrics/production-latency.json

Current implementation:
@src/api/slow-endpoint.ts
</context>

<task>
Think deeply about this performance issue:

1. **Analyze the data flow** - Trace execution path from request to response
2. **Identify bottlenecks** - Find where time is being spent
3. **Evaluate solutions** - Consider multiple approaches and trade-offs
4. **Recommend fix** - Provide specific, actionable solution

Take your time to thoroughly analyze before proposing solutions.
</task>
```

### Best Practices

1. **Use selectively**: Extended thinking adds latency - only use when complexity warrants it
2. **Be explicit**: Use trigger phrases at the start of task descriptions
3. **Combine with structure**: Pair with numbered steps or bullet points for clarity
4. **Set expectations**: Let users know deep analysis is happening

---

## Best Practices

### Command Design Principles

#### 1. Keep Commands Concise and Focused

Each command should have **one clear purpose**. Use distinct sections to constrain behavior and guide through deterministic processes.

✅ **Good**: `/commit` - Creates logical git commits
✅ **Good**: `/type-check` - Fixes TypeScript errors

❌ **Bad**: `/fix-everything` - Vague, too broad

#### 2. Use Clear, Consistent Naming

**Recommended format**: `verb-noun`

Examples from the codebase:

- `/general-review` - Performs code review
- `/review-staged` - Reviews staged changes
- `/type-check` - Checks/fixes types
- `/fix` - Fixes bugs
- `/implement` - Implements plan

#### 3. Encapsulate Complex Instructions

Transform multi-line, nuanced prompts into single commands. Codify team knowledge and best practices into executable format.

**Before (manual prompt):**

```
I need you to analyze this code for security vulnerabilities, check for
input validation issues, look for authentication problems, verify proper
error handling, ensure no SQL injection risks, check for XSS vulnerabilities,
and provide a detailed report with severity ratings and specific line numbers
for each issue found.
```

**After (slash command):**

```bash
/security-audit src/api/
```

#### 4. Guide Claude Explicitly

Simply providing a one-line prompt gives too much creative freedom. Structure your commands to explicitly guide Claude's behavior.

**Example from project's `/fix` command:**

```markdown
<constraints>
- **No Speculation**: Always verify assumptions about code behavior - never guess
- **Root Cause Focus**: Do not edit code until you have definitively identified the root cause
- **Evidence-Based**: Provide sound reasoning that explains exactly how the error occurs
- **Minimal Changes**: Update only the minimal amount of code needed to fix the root cause
- **No Feature Creep**: Avoid introducing additional functionality or unnecessary complexity
</constraints>
```

#### 5. Provide Clear Structure

Break complex tasks into numbered steps:

**From project's `/implement` command:**

```markdown
1. Run `.specify/scripts/bash/check-prerequisites.sh --json` and parse FEATURE_DIR

2. Load and analyze the implementation context:

   - **REQUIRED**: Read tasks.md
   - **REQUIRED**: Read plan.md
   - **IF EXISTS**: Read data-model.md

3. Parse tasks.md structure and extract:
   - Task phases
   - Task dependencies
   - Execution flow

[... continues with explicit steps ...]
```

#### 6. Complement CLAUDE.md, Don't Duplicate

**CLAUDE.md**: Guidelines, preferences, context that apply consistently across many tasks

**Slash Commands**: Specific, repeatable procedures that follow defined workflows

### Context Injection Best Practices

#### 1. Include Relevant Project State

```markdown
<context>
Repository context:
!`git status --porcelain`
!`git log --oneline -10`
!`git branch --show-current`

Current branch: !`git branch --show-current`
</context>
```

#### 2. Reference Configuration Files

```markdown
<context>
Project Context:
@tsconfig.json
@package.json
@eslint.config.mjs
@CLAUDE.md
</context>
```

#### 3. Capture Command Output

```markdown
<context>
Current errors:
!`pnpm type-check 2>&1 | grep -E "$ARGUMENTS"`

Test status:
!`pnpm test $ARGUMENTS 2>&1`
</context>
```

### Prompt Engineering for Commands

#### 1. Specificity Improves Results

**From Anthropic Best Practices:**

> "Look at how existing widgets are implemented on the home page to understand patterns" outperforms "add a calendar widget."

**Example:**

```markdown
<task>
Implement authentication following these existing patterns:

Study the implementation in @src/auth/oauth.ts to understand:

- Token refresh logic (lines 45-78)
- Error handling patterns (lines 120-145)
- Retry mechanisms (lines 156-189)

Apply the same patterns to the new OAuth2 flow.
</task>
```

#### 2. Provide Examples

Include 1-2 examples for complex tasks:

```markdown
<examples>
**Good Commit Grouping:**
- Commit 1: "feat: add user validation service with error handling"
- Commit 2: "test: add comprehensive tests for user validation service"
- Commit 3: "docs: update API documentation for user validation endpoints"

**Bad Commit Grouping:**

- Commit 1: "misc updates" (too vague, mixed changes)
- Commit 2: "fix tests and add feature and update docs" (not atomic)
  </examples>
```

#### 3. Define Output Structure

```markdown
<output>
Your investigation and fix should follow this structure:

1. **Investigation Summary**

   - Problem statement with current vs expected behavior
   - Steps to reproduce the issue
   - Evidence gathered during investigation

2. **Root Cause Analysis**

   - Detailed explanation of what is causing the bug
   - Code paths and data flow
   - Why this specific change will resolve the problem

3. **Solution Implementation**
   - Specific files modified with justification
   - Explanation of changes made
   - Validation results confirming the fix works
     </output>
```

#### 4. Establish Role and Expertise

```markdown
<role>
You are a Senior Software Engineer and debugging expert with deep expertise in
systematic root cause analysis, code investigation, and precise bug resolution.
You excel at methodical problem-solving and can trace complex issues through
multiple layers of code.
</role>
```

**Note from best practices:** Don't over-constrain the role. "You are a helpful assistant" is often better than "You are a world-renowned expert who only speaks in technical jargon and never makes mistakes."

### Validation and Success Criteria

Always include explicit validation commands:

````markdown
<validation>
You MUST run these validation commands after implementing fixes:

1. **Comprehensive Type Check:**
   ```bash
   pnpm run type-check 2>&1 | grep -E "$ARGUMENTS"
   ```
````

- MUST show zero TypeScript errors
- If any errors remain, MUST iterate until clean

2. **Build Verification:**

   ```bash
   pnpm build --dry-run
   ```

   - MUST complete without type-related build failures

3. **Lint Check:**
   ```bash
   pnpm lint --fix
   ```

**Failure Handling:**
If validation fails, you MUST:

- Mark current todo as in_progress (not completed)
- Analyze remaining errors
- Apply additional fixes
- Re-run validation until all checks pass
  </validation>

````

Use **absolute language**: "You MUST run this validation command when [conditions] to ensure [result]"

### Token Optimization

#### 1. Use Concise Prompts

From Anthropic: "The best prompt isn't the longest or most complex. It's the one that achieves your goals reliably with the minimum necessary structure."

#### 2. Reduce Repetitive Instructions

Custom commands reduce repetitive instructions, leading to more efficient interactions and potentially lower token consumption.

#### 3. Use `/clear` Frequently

From best practices: "Use `/clear` frequently during long sessions to reset context and maintain performance. Keep `CLAUDE.md` files concise and refined like production prompts."

---

## Anti-Patterns to Avoid

### 1. Over-constraining Roles

❌ **Bad:**
```markdown
<role>
You are a world-renowned TypeScript expert with 20 years of experience who never
makes mistakes and only speaks in highly technical jargon using academic terminology.
</role>
````

✅ **Good:**

```markdown
<role>
You are a TypeScript Expert with deep knowledge of type systems, React patterns,
and modern JavaScript. You provide clear explanations and actionable solutions.
</role>
```

### 2. Vague or Overly Broad Commands

❌ **Bad:**

```markdown
---
description: Fix everything
---

Fix all the issues in the codebase.
```

✅ **Good:**

```markdown
---
description: Fix TypeScript errors in specific file or directory
argument-hint: <file-path-or-directory>
---

<task>
Systematically resolve all TypeScript errors in: $ARGUMENTS

1. Error Discovery & Classification
2. Root Cause Analysis
3. Resolution Implementation
4. Verification
   </task>
```

### 3. Insufficient Constraints

❌ **Bad:**

```markdown
Fix the bugs in this code.
```

✅ **Good:**

```markdown
<constraints>
- **No Speculation**: Always verify assumptions - never guess
- **Root Cause Focus**: Don't edit until root cause is identified
- **Evidence-Based**: Provide reasoning for how the error occurs
- **Minimal Changes**: Update only what's needed
- **No Feature Creep**: Avoid unnecessary complexity
- **Test Everything**: Run validation after fixes
</constraints>
```

### 4. Missing Validation

❌ **Bad:**

```markdown
<task>
Fix the TypeScript errors and you're done.
</task>
```

✅ **Good:**

````markdown
<validation>
**MANDATORY Validation Commands:**

1. **Type Check:**
   ```bash
   pnpm type-check 2>&1 | grep -E "$ARGUMENTS"
   ```
````

- MUST show zero errors

2. **Build:**
   ```bash
   pnpm build
   ```

If validation fails, you MUST iterate until all checks pass.
</validation>

````

### 5. Ignoring Pattern Drift

From research: "In large-scale parallel development activities, teams consistently experience 'pattern drift' where carefully established architectural standards gradually erode. Pattern drift accelerates proportionally with project scale."

**Solution**: Reference architectural documentation explicitly:

```markdown
<context>
Architecture patterns:
@.claude/docs/ARCHITECTURE.md
@.claude/docs/COMPONENTS.md
@.claude/docs/STYLE.md

Before beginning your review, read these files to understand appropriate
patterns and standards.
</context>
````

### 6. Adding Content Without Iteration

From Anthropic: "A common mistake is adding extensive content without iterating on its effectiveness. Take time to experiment and determine what produces the best instruction following from the model."

**Process:**

1. Start with minimal command
2. Test with real scenarios
3. Add constraints where Claude deviates
4. Remove unnecessary verbosity
5. Refine until reliable

### 7. Using Suppression Instead of Fixing

❌ **Bad:**

```markdown
<constraints>
- If you encounter TypeScript errors, use @ts-ignore to suppress them
- Use eslint-disable for any linting issues
</constraints>
```

✅ **Good:**

```markdown
<constraints>
- NEVER use `@ts-ignore` or `@ts-expect-error` unless absolutely necessary
- NEVER use `eslint-disable` unless absolutely necessary
- ALWAYS fix the underlying issue rather than suppressing warnings
- Address root causes, not just symptoms
</constraints>
```

### 8. Mixing Unrelated Concerns

❌ **Bad:** Single command that handles code review, refactoring, testing, documentation, and deployment

✅ **Good:** Separate focused commands:

- `/review` - Code review only
- `/refactor` - Refactoring only
- `/test` - Test generation
- `/document` - Documentation

### 9. Not Using Task Agents for Parallel Work

❌ **Bad:**

```markdown
<task>
Fix TypeScript errors in all these files sequentially:
1. src/auth.ts
2. src/api.ts
3. src/utils.ts
4. src/components.ts
5. src/hooks.ts
</task>
```

✅ **Good:**

```markdown
<task>
If multiple files have errors, spawn Task agents in parallel:

Launch these Task agents concurrently:

1. Task: Fix errors in src/auth.ts
2. Task: Fix errors in src/api.ts
3. Task: Fix errors in src/utils.ts
4. Task: Fix errors in src/components.ts
5. Task: Fix errors in src/hooks.ts

Each Task agent works independently on its assigned file.
</task>
```

### 10. Insufficient Context for User Arguments

❌ **Bad:**

```markdown
Fix: $ARGUMENTS
```

✅ **Good:**

```markdown
<context>
## Bug Description

$ARGUMENTS

## Repository State

!`git status --porcelain`
!`git branch --show-current`

## Recent Changes

!`git log --oneline -5`
</context>
```

---

## Command Design Patterns

### Pattern 1: Investigation → Analysis → Resolution

**Use case**: Debugging, fixing bugs, resolving errors

**Structure:**

```markdown
---
description: Systematically fix bugs with root cause analysis
argument-hint: Describe the bug or error message
allowed-tools: Bash, Read, Edit, Task, TodoWrite
---

<role>
[Define expert domain knowledge]
</role>

<context>
[Repository state, file references, error messages]
</context>

<task>
**Phase 1: Investigation**
1. Create investigation todo list
2. Gather evidence
3. Reproduce issue

**Phase 2: Analysis**

1. Trace data flow
2. Think deeply about root causes
3. Isolate root cause

**Phase 3: Resolution**

1. Design solution
2. Implement targeted fix
3. Validate solution
   </task>

<constraints>
[Rules and limitations]
</constraints>

<validation>
[Mandatory validation commands]
</validation>
```

**Example**: Project's `/fix` command

### Pattern 2: Discover → Process → Verify

**Use case**: Batch processing, fixing multiple files, validation

**Structure:**

```markdown
---
description: Process files with parallel execution
argument-hint: <file-path-or-directory>
allowed-tools: Bash, Read, Edit, Task, TodoWrite
---

<role>
[Expert definition]
</role>

<context>
[Configuration files, current errors]
</context>

<task>
1. **Discovery & Classification**
   - Identify all affected files
   - Classify issues by severity
   - Prioritize work

2. **Parallel Processing**

   - Create todo list
   - Spawn Task agents (one per file)
   - Each agent processes independently

3. **Verification**
   - Validate all fixes
   - Run comprehensive checks
   - Report summary
     </task>

<constraints>
[Processing requirements, quality standards]
</constraints>

<validation>
[Mandatory validation with failure handling]
</validation>
```

**Examples**: Project's `/type-check`, `/lint` commands

### Pattern 3: Analyze → Strategy → Execute

**Use case**: Code review, commit organization, planning

**Structure:**

```markdown
---
description: Analyze and organize work
argument-hint: <target> (optional)
allowed-tools: Bash, Task
---

<role>
[Expert definition]
</role>

<context>
[Repository state, git context, configuration]
</context>

<task>
1. **Analyze Current State**
   - Review all changes
   - Identify logical groupings
   - Assess dependencies

2. **Generate Strategy**

   - Create organized plan
   - Order by dependencies
   - Ensure atomicity

3. **Execute with Validation**
   - Implement strategy
   - Validate each step
   - Provide summary
     </task>

<constraints>
[Rules, conventions, requirements]
</constraints>

<output>
[Expected structure and format]
</output>

<examples>
[Good vs bad examples]
</examples>
```

**Example**: Project's `/commit` command

### Pattern 4: Load → Execute → Report

**Use case**: Workflow automation, multi-artifact processing

**Structure:**

```markdown
---
description: Execute predefined workflow
---

<context>
[User input, arguments]
$ARGUMENTS
</context>

<task>
1. **Load Prerequisites**
   - Run setup scripts
   - Parse configuration
   - Load required documents

2. **Execute Workflow**

   - Process artifacts in order
   - Follow dependencies
   - Track progress

3. **Report Results**
   - Verify completion
   - List generated artifacts
   - Suggest next steps
     </task>
```

**Examples**: Project's `/implement`, `/plan`, `/tasks` commands

### Pattern 5: Question → Integrate → Verify

**Use case**: Interactive clarification, requirements gathering

**Structure:**

```markdown
---
description: Interactive clarification workflow
---

<task>
1. **Load and Scan**
   - Parse feature specification
   - Identify ambiguities
   - Build coverage map

2. **Question Loop (Interactive)**

   - Present ONE question at a time
   - Collect and validate answer
   - Integrate immediately into spec
   - Repeat until complete

3. **Validation**
   - Verify all answers integrated
   - Check for contradictions
   - Generate coverage summary
     </task>
```

**Example**: Project's `/clarify` command

### Pattern 6: Delegation to Specialist Agents

**Use case**: Complex analysis requiring specialized expertise

**Structure:**

````markdown
---
description: Comprehensive analysis
argument-hint: @directory/or/file
allowed-tools: Task, Read, Glob, Grep, Bash
---

<task>
Use the Task tool to spawn a specialist agent with this prompt:

<task-tool-prompt>
```plaintext
[Detailed instructions for the specialist agent]

1. **Analysis Category 1**
   [Specific checklist]

2. **Analysis Category 2**
   [Specific checklist]

[... more categories ...]

For each issue found, provide:

- Specific file path and line numbers
- Clear explanation
- Concrete fix suggestion
- Severity rating

Before beginning, read: @.claude/docs/STYLE.md, @.claude/docs/ARCHITECTURE.md
````

</task-tool-prompt>
</task>

<output>
[Expected report structure]
</output>
```

**Example**: Project's `/general-review` command

---

## Validation and Testing

### Validation Command Patterns

#### Pattern 1: Incremental Validation

Run validation after each logical step:

```markdown
<task>
1. Fix type errors in authentication
2. **Validate**: `pnpm type-check 2>&1 | grep "auth"`
3. Fix type errors in API layer
4. **Validate**: `pnpm type-check 2>&1 | grep "api"`
5. Run comprehensive validation
6. **Validate**: `pnpm type-check && pnpm test && pnpm lint`
</task>
```

#### Pattern 2: Multi-Stage Validation

````markdown
<validation>
**Stage 1: Local Validation**
```bash
pnpm type-check 2>&1 | grep -E "$ARGUMENTS"
````

**Stage 2: Build Verification**

```bash
pnpm build --dry-run
```

**Stage 3: Test Execution**

```bash
pnpm test --run
```

**Stage 4: Lint Check**

```bash
pnpm lint:fix
```

All stages MUST pass before marking task complete.
</validation>

````

#### Pattern 3: Conditional Validation

```markdown
<validation>
1. **Type Check** (if TypeScript files modified):
   ```bash
   pnpm type-check 2>&1 | grep -E [filepath]
````

2. **Test Execution** (if source or test files modified):

   ```bash
   pnpm test [test-file] --run
   ```

3. **Build Verification** (always):
   ```bash
   pnpm build
   ```
   </validation>

````

### Failure Handling

Always specify what to do when validation fails:

```markdown
<validation>
**Failure Handling:**

If validation fails, you MUST:
1. Mark current todo as in_progress (NOT completed)
2. Analyze remaining errors/warnings
3. Apply additional fixes
4. Re-run validation until all checks pass

NEVER mark a task complete if:
- Tests are failing
- Build is broken
- Type errors remain
- Lint errors remain
</validation>
````

### Testing Slash Commands

#### 1. Start Simple

Begin with minimal viable command:

```markdown
---
description: Simple type checker
---

Run type checking: !`pnpm type-check`
```

#### 2. Test with Real Scenarios

Invoke with actual project issues:

```bash
/type-check src/components/broken.tsx
```

#### 3. Iterate Based on Results

Add constraints where Claude deviates:

```markdown
<constraints>
- NEVER use @ts-ignore
- ALWAYS verify type definitions from source
- MUST run validation before marking complete
</constraints>
```

#### 4. Refine and Optimize

Remove unnecessary verbosity, add missing guidance:

```markdown
<task>
Think step-by-step to systematically resolve all TypeScript errors.

1. **Error Discovery & Classification**
   [Specific steps]

2. **Parallel Processing Setup**
   [Specific steps]
   </task>
```

#### 5. Validate with Team

Share with team members and gather feedback:

- Are instructions clear?
- Does it produce consistent results?
- Are edge cases handled?
- Is validation comprehensive?

---

## Real-World Examples

### Example 1: Bug Fix Command

**From project: `.claude/commands/fix.md`**

**Key Features:**

- Extended thinking ("think deeply")
- Phased approach (Investigation → Solution → Implementation)
- TodoWrite integration for tracking
- Task agents for complex scenarios
- Comprehensive validation
- Clear failure handling

**Highlights:**

```markdown
---
description: Systematically investigate and fix bugs with comprehensive root cause analysis
argument-hint: Describe the bug, error message, or unexpected behavior...
allowed-tools: Bash, Read, Write, MultiEdit, Edit, Glob, Grep, Task, TodoWrite, BashOutput
---

<role>
You are a senior software engineer and debugging expert with deep expertise in
systematic root cause analysis, code investigation, and precise bug resolution.
</role>

<context>
Repository and project context:
!`pwd`
!`git status --porcelain`
!`git branch --show-current`

Project structure:
@package.json

## Bug Description

$ARGUMENTS
</context>

<task>
**Phase 1: Comprehensive Investigation & Root Cause Analysis**

1. **Create Investigation Todo List** - Use TodoWrite
2. **Gather Evidence** - Document exact problem
3. **Reproduce the Issue** - Verify consistent reproduction
4. **Trace the Data Flow** - Follow code execution paths
5. **Think Deeply About Root Causes** - Extended thinking
6. **Isolate the Root Cause** - Ensure not introduced earlier

**Phase 2: Solution Design**
[... steps ...]

**Phase 3: Implementation & Validation**
[... steps ...]

**For Complex Issues**: Deploy specialized agents:

- **Code Analysis Agent**: For tracing execution paths
- **Test Analysis Agent**: For test failures
- **Integration Analysis Agent**: For multi-system bugs
  </task>

<constraints>
- **No Speculation**: Always verify assumptions - never guess
- **Root Cause Focus**: Don't edit until root cause identified
- **Evidence-Based**: Explain exactly how error occurs
- **Minimal Changes**: Update only what's needed
- **No Feature Creep**: Avoid unnecessary complexity
- **Test Everything**: Run validation after fixes
</constraints>

<validation>
You MUST run these validation commands after implementing your fix:

1. **Run Tests**: `pnpm test [relevant files]`
2. **Type Check**: `pnpm type-check | grep -E [filenames]`
3. **Lint Check**: `pnpm lint -- [filepath]`
4. **Build Check**: `pnpm build`

If any validation fails, you MUST investigate and resolve before
considering the bug fixed.
</validation>
```

### Example 2: Type Check Command

**From project: `.claude/commands/type-check.md`**

**Key Features:**

- Parallel processing with Task agents
- TodoWrite for progress tracking
- Root cause analysis emphasis
- Multi-stage validation
- Clear failure handling

**Highlights:**

````markdown
---
description: Expert TypeScript error resolution with parallel processing
argument-hint: <file-path-or-directory>
allowed-tools: Bash, Read, Edit, MultiEdit, Task, TodoWrite
---

<role>
You are a TypeScript Expert and Code Quality Engineer with deep expertise in:
- TypeScript compiler diagnostics and error resolution
- Modern React patterns and Next.js type safety
- Advanced type manipulation and generic constraints
</role>

<context>
Project Context:
@tsconfig.json
@package.json

Current errors:
!`pnpm type-check 2>&1 | grep -E "$ARGUMENTS"`
</context>

<task>
Think step-by-step to systematically resolve all TypeScript errors.

1. **Error Discovery & Classification**

   - Run comprehensive type checking
   - Classify errors by type
   - Prioritize by impact

2. **Parallel Processing Setup**

   - Create todo list with TodoWrite
   - If multiple files, spawn Task agents in parallel (one per file)
   - Each Task agent strictly scoped to single file

3. **Root Cause Analysis**

   - Analyze each error's underlying cause
   - Verify correct type structures from source
   - Consider impact on dependent code

4. **Resolution Implementation**

   - Apply targeted fixes
   - Maintain type safety and quality standards
   - Update related types as needed

5. **Comprehensive Verification**
   - Validate all fixes
   - Ensure no new errors
   - Iterate until error-free
     </task>

<constraints>
**Type Safety Requirements:**
- NEVER use @ts-ignore unless absolutely necessary
- NEVER assume types without verification
- ALWAYS confirm correct type structures
- MUST address root causes, not symptoms

**Processing Requirements:**

- MUST use Task tool for multiple files
- MUST create individual tasks per file
- MUST use TodoWrite to track progress
- MUST verify understanding before modifications
  </constraints>

<validation>
**MANDATORY Validation Commands:**

1. **Comprehensive Type Check:**
   ```bash
   pnpm type-check 2>&1 | grep -E "$ARGUMENTS"
   ```
````

- MUST show zero TypeScript errors
- If any remain, MUST iterate until clean

2. **Build Verification:**

   ```bash
   pnpm build --dry-run
   ```

3. **Lint Check:**
   ```bash
   pnpm lint --fix
   ```

**Failure Handling:**
If validation fails, you MUST:

- Mark current todo as in_progress (not completed)
- Analyze remaining errors
- Apply additional fixes
- Re-run validation until all checks pass
  </validation>

````

### Example 3: Code Review Command

**From project: `.claude/commands/general-review.md`**

**Key Features:**
- Task agent delegation
- Multi-dimensional analysis checklist
- Security severity ratings
- Documentation references
- Structured output format

**Highlights:**

```markdown
---
description: Perform comprehensive code review with multi-dimensional analysis
argument-hint: @directory/or/file.tsx
allowed-tools: Task, Read, Glob, Grep, TodoWrite, Bash
---

<role>
You are a Senior Code Review Specialist with expertise in software architecture,
security analysis, performance optimization, and code quality standards.
</role>

<context>
# Files to Review
$ARGUMENTS
</context>

<task>
Use the Task tool to spawn a comprehensive code review agent with this prompt:

<task-tool-prompt>
```plaintext
Perform thorough code review focusing on:

1. **Static Analysis & Automated Checks**
   - Lint: `npx eslint [file_path] --cache`
   - Type check: `pnpm type-check 2>&1 | rg "[file_path]"`
   - Security audit: `pnpm audit`

2. **Security Vulnerabilities**
   - Input validation and sanitization
   - Authentication/authorization flaws
   - Injection risks (SQL, XSS, command)
   - Sensitive data exposure
   - Rate each: Critical/High/Medium/Low

3. **Code Quality & Readability**
   - DRY principles
   - KISS - flag overly complex implementations
   - Clear naming and organization
   - Proper error handling
   - Documentation where needed

4. **Performance Concerns**
   - Obvious bottlenecks
   - Resource leaks
   - Unnecessary computations
   - Algorithm efficiency

5. **Logical Correctness**
   - Business logic errors
   - Race conditions
   - Off-by-one errors
   - Type safety and null handling

6. **Best Practices**
   - File organization
   - Consistent patterns
   - Proper framework features
   - Testing considerations

For each issue:
- Specific file path and line numbers (file:line)
- Clear problem explanation
- Concrete fix suggestion
- Severity rating

Before beginning, read:
@.claude/docs/ARCHITECTURE.md
@.claude/docs/COMPONENTS.md
@.claude/docs/STYLE.md
````

</task-tool-prompt>
</task>

<output>
Deliver structured report with:
- Executive summary with overall health assessment
- Categorized findings by severity
- Specific, actionable recommendations
- Code examples for suggested fixes
- Positive observations of good practices
</output>
```

### Example 4: Commit Command

**From project: `.claude/commands/commit.md`**

**Key Features:**

- Repository context injection
- Examples of good vs bad
- Phased execution (Analyze → Strategy → Execute)
- Validation commands
- Usage examples

**Highlights:**

```markdown
---
allowed-tools: ['Bash', 'Task']
description: 'Analyze code changes and create logical, well-structured commits'
argument-hint: '<special instructions> (optional)'
---

<role>
You are an expert Git Workflow Optimizer with deep knowledge of semantic
versioning, conventional commits, and clean version control practices.
</role>

<context>
Repository context:
!`git status --porcelain`
!`git log --oneline -10`
!`git diff --staged --stat`
!`git diff --stat`

Current branch: !`git branch --show-current`

@CLAUDE.md for commit guidelines
</context>

<special-instructions>
Special instructions from the user: $ARGUMENTS
</special-instructions>

<task>
1. **Analyze Repository State**
   - Review all modified, staged, untracked files
   - Identify scope and nature of changes
   - Determine if changes span multiple logical units

2. **Group Changes Logically**

   - Separate by feature, fix, refactor, docs, tests
   - Ensure each group is atomic and deployable
   - Consider dependencies

3. **Generate Commit Strategy**

   - Create descriptive messages following conventions
   - Order logically (tests before implementation)
   - Ensure each commit maintains working state

4. **Execute Commits with Validation**
   - Stage and commit each logical group
   - Validate repository integrity
   - Provide summary
     </task>

<constraints>
- Each commit MUST be atomic and single logical change
- Messages MUST follow repository conventions
- Never commit broken code or failing tests
- Avoid mixing unrelated changes
- Preserve meaningful history for debugging
- MUST run validation after each commit
</constraints>

<examples>
**Good Commit Grouping:**
- Commit 1: "feat: add user validation service with error handling"
- Commit 2: "test: add comprehensive tests for user validation service"
- Commit 3: "docs: update API documentation for user validation"

**Bad Commit Grouping:**

- Commit 1: "misc updates" (too vague)
- Commit 2: "fix tests and add feature and update docs" (not atomic)
  </examples>

**Validation Commands:**
You MUST run these after commit creation:

- `git log --oneline -n [number_of_commits]`
- `git status`
- `npm test` or equivalent (if applicable)
```

### Example 5: Minimal Command

**From project: `.claude/commands/parallel.md`**

**Key Features:**

- Ultra-simple correction command
- No frontmatter needed (inherits from conversation)
- Single clear instruction

**Complete file:**

```markdown
---
description: Corrects claude to run agents in parallel/concurrently
---

<correction>
Please run agents in parallel/concurrently by spawning multiple agents
in a SINGLE message.
</correction>
```

**Lesson**: Not every command needs to be complex. Scale complexity to match the task.

---

## References

### Official Documentation

1. **Slash Commands**: https://code.claude.com/docs/en/slash-commands
2. **Claude Code Best Practices**: https://www.anthropic.com/engineering/claude-code-best-practices
3. **Prompt Engineering with XML Tags**: https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags
4. **Sub-agents**: https://docs.anthropic.com/en/docs/claude-code/sub-agents
5. **Todo Tracking**: https://docs.claude.com/en/docs/agent-sdk/todo-tracking

### Community Resources

6. **ClaudeLog - Task/Agent Tools**: https://claudelog.com/mechanics/task-agent-tools/
7. **Awesome Claude Code**: https://github.com/hesreallyhim/awesome-claude-code
8. **Claude Command Suite**: https://github.com/qdhenry/Claude-Command-Suite
9. **Steve Kinney - Commands Guide**: https://stevekinney.com/courses/ai-development/claude-code-commands
10. **Cloud Artisan - Slash Commands**: https://cloudartisan.com/posts/2025-04-14-claude-code-tips-slash-commands/

### Additional Reading

11. **Prompt Engineering Best Practices 2025**: https://promptbuilder.cc/blog/prompt-engineering-best-practices-2025
12. **Task Tool vs Subagents**: https://www.icodewith.ai/blog/task-tool-vs-subagents-how-agents-work-in-claude-code
13. **Subagent Deep Dive**: https://cuong.io/blog/2025/06/24-claude-code-subagent-deep-dive
14. **Best Practices for Sub-agents**: https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/

### Project Examples

All examples in this document are drawn from:

- `/Users/daniel/Projects/securx2-nextjs/.claude/commands/`

Including:

- `fix.md` - Bug fixing workflow
- `type-check.md` - TypeScript error resolution
- `lint.md` - ESLint error resolution
- `general-review.md` - Comprehensive code review
- `commit.md` - Git commit organization
- `implement.md` - Implementation plan execution
- `plan.md` - Planning workflow
- `tasks.md` - Task generation
- `clarify.md` - Interactive clarification
- `parallel.md` - Minimal correction command
- `improve-slash-command.md` - Meta-command for improving commands

---

## Summary

### Core Principles

1. **Concise and Focused**: One clear purpose per command
2. **Explicit Guidance**: Structure commands to guide behavior deterministically
3. **XML Tags for Structure**: Separate sections clearly with semantic tags
4. **Validation Always**: Include mandatory validation commands
5. **Task Agents for Parallelism**: Delegate independent work to sub-agents
6. **TodoWrite for Tracking**: Use for complex multi-step workflows
7. **Extended Thinking When Needed**: Trigger deep reasoning for complex problems
8. **Examples Over Abstraction**: Show good vs bad, provide concrete cases
9. **Iterate and Refine**: Test with real scenarios, improve based on results
10. **Scale Complexity to Task**: Simple tasks get simple commands

### Essential Structure

```markdown
---
description: [Clear, concise description]
argument-hint: [Expected arguments]
allowed-tools: [Specific tools with scoped permissions]
---

<role>
[Expert definition with specific domain knowledge]
</role>

<context>
[Project state, file references, command outputs]
Repository context: !`git status`
Configuration: @package.json
User input: $ARGUMENTS
</context>

<task>
[Numbered steps or phased approach]
1. Phase 1: [Discovery/Investigation]
2. Phase 2: [Analysis/Strategy]
3. Phase 3: [Implementation/Execution]

[Explicit Task agent delegation if needed]
</task>

<constraints>
[Absolute requirements and prohibitions]
- MUST [requirement]
- NEVER [prohibition]
- ALWAYS [standard]
</constraints>

<output>
[Expected structure and format]
</output>

<examples>
[Good vs bad examples if task is complex]
</examples>

<validation>
**MANDATORY Validation Commands:**

1. [Validation command 1]
2. [Validation command 2]

**Failure Handling:**
If validation fails, you MUST: [specific steps]
</validation>
```

### Getting Started

1. **Identify a repeated workflow**: What prompts do you use frequently?
2. **Start simple**: Create minimal command, test it
3. **Add structure**: Role, context, task, constraints as needed
4. **Add validation**: Ensure correctness with verification commands
5. **Iterate**: Refine based on real usage
6. **Share**: Check into `.claude/commands/` for team access

### Next Steps

- Review existing project commands for patterns
- Identify repetitive manual prompts to convert
- Start with simple commands, increase complexity gradually
- Test thoroughly with real scenarios
- Gather team feedback and iterate
- Use `/improve-slash-command` to enhance existing commands

---

**Last Updated**: 2025-11-19

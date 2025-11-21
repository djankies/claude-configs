---
description: Brief description of what this command does (appears in /help)
argument-hint: <file-or-directory> [options]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, WebFetch, WebSearch, NotebookEdit, AskUserQuestion, Skill, SlashCommand
model: sonnet
---

# Command Template for Effective Slash Commands

This template demonstrates best practices for creating powerful, maintainable slash commands. Replace sections below with your actual command logic.

---

## Template Instructions

### 1. Frontmatter Configuration

The YAML frontmatter above controls command behavior:

- **description**: (required) Brief description shown in `/help`
- **argument-hint**: Shows expected arguments (e.g., `<file> [options]`)
- **allowed-tools**: Comma-separated list of permitted tools
  - Use specific patterns: `Bash(git:*)` instead of broad `Bash`
  - Common tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite
- **model**: Optional model override (sonnet, opus, haiku)

### 2. Command Structure

Use XML tags to structure complex commands clearly:

```markdown
<role>
You are a [expert type] with expertise in [domain knowledge].
</role>

<context>
[Project state, file references, command outputs]
Repository: !`git status --porcelain`
Config: @package.json
User input: $ARGUMENTS
</context>

<task>
[Numbered steps or phased approach]
1. Phase 1: [Discovery/Investigation]
2. Phase 2: [Analysis/Implementation]
3. Phase 3: [Validation/Reporting]
</task>

<constraints>
[Absolute requirements]
- MUST [requirement]
- NEVER [prohibition]
- ALWAYS [standard]
</constraints>

<validation>
[Mandatory validation commands]
</validation>
```

### 3. Dynamic Elements

Access user input and context dynamically:

**Arguments:**

- `$ARGUMENTS` - All arguments as single string
- `$1`, `$2`, `$3` - Individual positional arguments

**File References:**

- `@package.json` - Include file contents
- `@src/main.ts` - Reference any project file
- `@$1` - Use argument as file path

**Bash Execution:**

- `!git status` - Execute and include output
- `!pnpm test $ARGUMENTS` - Use arguments in commands
- `!pwd` - Capture command output

### 4. Best Practices

**Keep Commands Focused:**

- One clear purpose per command
- Use verb-noun naming: `/type-check`, `/review-code`

**Guide Explicitly:**

- Don't give Claude too much freedom
- Use constraints to prevent unwanted behavior
- Specify exact validation steps

**Use Task Agents for Parallel Work:**

```markdown
<task>
If multiple files need processing:

1. Create todo list with TodoWrite
2. Spawn Task agents in parallel (one per file)
3. Each agent works independently
   </task>
```

**Always Include Validation:**

```markdown
<validation>
**MANDATORY Validation:**

1. Run: `pnpm test $ARGUMENTS`
2. Check: `pnpm type-check`

If validation fails, MUST iterate until passing.
</validation>
```

---

## Example Command Template

Replace the sections below with your actual command:

---

<role>
You are a [Senior Engineer/Expert/Specialist] with deep expertise in [specific domain].
You excel at [key capabilities] and provide [type of assistance].
</role>

<context>
## User Request

$ARGUMENTS

## Project Context

Repository state:
!`git status --porcelain`
!`git branch --show-current`

Project configuration:
@package.json
@tsconfig.json

[Include relevant project files or command outputs]
</context>

<task>
Think step-by-step to [accomplish the command's goal].

**Phase 1: [Discovery/Analysis]**

1. [Specific step with clear action]
2. [Analyze/Gather/Identify specific information]
3. [Classify or prioritize based on criteria]

**Phase 2: [Implementation/Processing]**

1. [Create plan or strategy]
2. [For multiple items, spawn Task agents in parallel]
   - One Task agent per [file/component/module]
   - Each agent handles [specific scope]
3. [Use TodoWrite to track progress]

**Phase 3: [Validation/Reporting]**

1. [Run validation commands]
2. [Verify success criteria]
3. [Provide summary or report]

**Task Agent Delegation** (if applicable):
For complex processing, use Task tool to spawn specialized agents:

- Each agent receives: [specific context]
- Each agent produces: [specific output]
- Agents run in parallel when possible
  </task>

<constraints>
**Quality Requirements:**

- MUST [critical requirement]
- NEVER [prohibited action]
- ALWAYS [required practice]

**Processing Requirements:**

- MUST verify [assumption/condition] before proceeding
- NEVER use [anti-pattern] unless absolutely necessary
- ALWAYS [best practice or standard]

**Task Management:**

- MUST use TodoWrite for tracking if 3+ steps
- MUST mark tasks complete only when fully done
- NEVER mark complete if validation fails
  </constraints>

<output>
Your response should include:

1. **[Section 1 Name]**

   - [Specific information to include]
   - [Format or structure requirement]

2. **[Section 2 Name]**

   - [What to report]
   - [How to present it]

3. **[Section 3 Name]**
   - [Final deliverable]
   - [Summary or next steps]
     </output>

<examples>
**Good [Example Type]:**

- Example 1: [Description]
- Example 2: [Description]

**Bad [Example Type]:**

- Anti-example 1: [What NOT to do]
- Anti-example 2: [Why this approach fails]
  </examples>

<validation>
**MANDATORY Validation Commands:**

You MUST run these commands after implementation:

1. **[Validation Type]:**

   ```bash
   [command to validate]
   ```

   - MUST [success criteria]
   - If fails, [specific action]

2. **[Second Validation]:**

   ```bash
   [second validation command]
   ```

   - MUST [success criteria]

3. **[Final Check]:**
   ```bash
   [comprehensive validation]
   ```

**Failure Handling:**

If ANY validation fails, you MUST:

1. Keep current todo as `in_progress` (NOT completed)
2. Analyze the failure
3. Apply fixes
4. Re-run validation until ALL checks pass

NEVER mark work complete with failing validation.
</validation>

---

## Minimal Command Example

Not every command needs full structure. For simple commands:

```markdown
---
description: Quick task description
allowed-tools: Bash, Read
---

<task>
Run [specific command] and [do something with output].

Validation: `[verify command]`
</task>
```

---

## Pattern Examples

### Pattern 1: Investigation → Analysis → Resolution

For debugging, bug fixing, error resolution:

```markdown
<task>
**Phase 1: Investigation**

1. Gather evidence
2. Reproduce issue
3. Trace execution

**Phase 2: Analysis**

1. Identify root cause
2. Think deeply about solution
3. Design fix

**Phase 3: Resolution**

1. Implement fix
2. Validate solution
3. Report results
   </task>
```

### Pattern 2: Discover → Process → Verify

For batch processing, fixing multiple files:

```markdown
<task>
**Phase 1: Discovery**

1. Identify all affected files
2. Classify by severity
3. Create todo list

**Phase 2: Parallel Processing**

1. Spawn Task agents (one per file)
2. Each agent processes independently
3. Track progress with TodoWrite

**Phase 3: Verification**

1. Run comprehensive validation
2. Ensure all checks pass
3. Provide summary
   </task>
```

### Pattern 3: Analyze → Strategy → Execute

For code review, commit organization, planning:

```markdown
<task>
**Phase 1: Analyze**

1. Review current state
2. Identify patterns
3. Assess quality

**Phase 2: Strategy**

1. Create organized plan
2. Order by dependencies
3. Ensure completeness

**Phase 3: Execute**

1. Implement strategy
2. Validate each step
3. Report results
   </task>
```

---

## Key Reminders

- **Start simple, iterate**: Begin minimal, add complexity as needed
- **Test with real scenarios**: Use actual project issues to refine
- **Be explicit**: Don't assume Claude knows what you want
- **Validate always**: Include mandatory verification steps
- **Use parallel agents**: Leverage Task tool for independent work
- **Track progress**: Use TodoWrite for complex multi-step workflows
- **Scale complexity**: Match command complexity to task complexity

---

## Command Checklist

Before finalizing your command, verify:

- [ ] Clear, focused purpose (one main task)
- [ ] Frontmatter includes description and allowed-tools
- [ ] User arguments captured with `$ARGUMENTS` or `$1`, `$2`, etc.
- [ ] Relevant context included (files, command outputs)
- [ ] Task broken into clear phases or steps
- [ ] Constraints specify what to do AND what NOT to do
- [ ] Validation commands are mandatory and comprehensive
- [ ] Failure handling is explicit
- [ ] Examples provided if task is complex
- [ ] XML tags used appropriately for structure
- [ ] Command tested with real scenarios

---

**Remember:** The best command is the one that achieves your goals reliably with minimum necessary structure. Don't over-engineer simple tasks.

---
name: example-agent
description: Brief description of when to use this agent (triggers auto-invocation when relevant to user's task)
tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, WebFetch, WebSearch, NotebookEdit, AskUserQuestion, Skill, SlashCommand
model: sonnet
permissionMode: default
---

# Agent Description Template

## ⚠️ Important: When NOT to Use Agents

**Before creating an agent, read this carefully.**

According to the Claude Code plugin philosophy, **agents should be rare**. Most use cases are better served by skills.

### Use a Skill Instead If:

- You're providing domain knowledge or expertise (React patterns, API design, security practices)
- The task uses the same tools as the parent Claude
- The task uses the same permissions as the parent Claude
- The task uses the same model as the parent Claude
- The work happens in the main conversation
- You're teaching how to do something correctly

**Skills provide progressive disclosure and are more efficient than agents in 95% of cases.**

### Only Use an Agent If:

You answer **YES** to at least one of these questions:

1. **Different Permissions**: Does this task require different permissions than the parent?

   - Example: Read-only investigation without making changes
   - Example: Accept edits without asking for permission each time

2. **Different Model**: Does this task benefit from a different model for cost/speed?

   - Example: Using Haiku for rapid iteration on large traces
   - Example: Using Opus for complex architectural decisions

3. **Isolated Context**: Does this task need to run separately to avoid polluting the main conversation?
   - Example: Analyzing large stack traces without cluttering main chat
   - Example: Generating reports that shouldn't be in the main flow

If you answered **NO** to all three questions, **create a skill instead**, not an agent.

---

## How to Write an Agent Description (If Justified)

Only proceed if you've confirmed an agent is necessary. Write a comprehensive paragraph describing your agent. Include these elements:

### 1. WHEN to Use This Agent (CRITICAL)

Start with: "Use this agent when [specific task requiring isolation/different capabilities]."

Be explicit about:

- The specific task requiring agent-level isolation
- Why the parent Claude can't handle this (permissions, model, context)
- What makes this different from normal requests
- Trigger keywords for auto-invocation

### 2. What Makes This Agent Different

**Specify exactly ONE of these differentiators:**

- **Permission Mode**: `read-only` (investigation only), `acceptEdits` (auto-apply changes), `bypassPermissions`
- **Model**: `haiku` (fast/cheap iteration), `opus` (complex reasoning), or `inherit`
- **Isolated Context**: Needs to work separately from main conversation (traces, reports, investigations)

### 3. Approach & Methodology

How should the agent approach tasks? What process should it follow?

### 4. Output & Return Format

What should the agent return to the parent? Be specific about format and content.

### 5. Constraints

What should the agent NOT do? When should it fail fast or ask for clarification?

---

## Example Agent Descriptions

### Example 1: Read-Only Code Investigation Agent

```text
Use this agent when investigating bugs or analyzing code without making any changes. Activate when users mention "investigate", "analyze without changes", "find the cause", "trace the issue", or "debug read-only". This agent operates in READ-ONLY mode with no ability to edit files, ensuring safe investigation of production issues or unfamiliar codebases. The agent should systematically trace issues by reading relevant files, examining logs, checking git history, and analyzing dependencies. When investigating, start with the error message or symptom, identify related files using grep/glob, read through code paths, trace data flow, and document findings. The agent should produce a detailed investigation report including: root cause analysis, affected components, reproduction steps, and recommended fixes (but not implement them). The agent defers all code changes to the parent Claude and focuses purely on analysis. Return findings as a structured markdown report with evidence and recommendations.
```

**Why This Needs an Agent:**

- ✅ Different permissions: `permissionMode: default` with read-only tools (Read, Grep, Glob, Bash for read-only commands)
- ✅ Isolated context: Investigation traces don't clutter main conversation
- ✅ Clear input/output: Takes bug description, returns investigation report

**Why Not a Skill:**

- ❌ Skills can't restrict permissions
- ❌ Investigation traces would pollute main chat
- ❌ Can't prevent accidental changes during investigation

### Example 2: Fast Iteration Test Generator (Haiku Model)

```text
Use this agent when rapidly generating multiple test variations or test suites for the same code. Activate when users mention "generate tests quickly", "mass test generation", "test all cases", or "quick test coverage". This agent uses the Haiku model for fast, cost-effective iteration when creating comprehensive test suites. The agent should analyze the target code, identify edge cases and scenarios, generate test cases covering happy paths, error conditions, edge cases, and boundary conditions. For each code unit, create multiple test variations efficiently. The agent should prioritize speed and coverage over deep analysis. Generate tests following the project's existing test patterns and framework (Jest, Vitest, etc.). Return a complete test file with multiple test cases, organized by scenario. The agent defers complex test architecture decisions to the parent Claude and focuses on rapid test case generation.
```

**Why This Needs an Agent:**

- ✅ Different model: Uses Haiku for speed and cost efficiency
- ✅ Isolated context: Bulk generation doesn't clutter main flow
- ✅ Clear input/output: Takes code, returns complete test suite

**Why Not a Skill:**

- ❌ Skills can't change the model
- ❌ Multiple rapid iterations would clutter main conversation
- ❌ Cost optimization requires model switching

### Example 3: Performance Trace Analyzer (Isolated Context)

```text
Use this agent when analyzing large performance traces, profiler outputs, or stack traces that would clutter the main conversation. Activate when users mention "analyze trace", "profile analysis", "performance bottleneck", "stack trace analysis", or "debug performance". This agent works in isolated context to process large diagnostic outputs without overwhelming the main chat. The agent should parse and analyze traces, identify bottlenecks, correlate timing data, detect patterns (N+1 queries, excessive re-renders, memory leaks), and summarize findings. When analyzing, examine the trace structure, identify hot paths, measure time distributions, detect anomalies, and correlate with code. The agent should filter noise and focus on actionable insights. Return a concise summary report with: top bottlenecks ranked by impact, specific code locations, performance metrics, and optimization recommendations. The detailed trace analysis stays in the agent context. The agent defers optimization implementation to the parent Claude and focuses on trace interpretation.
```

**Why This Needs an Agent:**

- ✅ Isolated context: Large traces don't pollute main conversation
- ✅ Different approach: Focused solely on trace analysis
- ✅ Clear input/output: Takes trace file, returns summary report

**Why Not a Skill:**

- ❌ Skills load into main context (would clutter with large traces)
- ❌ Analysis requires separate workspace
- ❌ Can't isolate trace processing from main flow

---

## Anti-Pattern: The Domain Expert Agent

**DON'T write agents like this:**

```text
❌ Use this agent when working with React code. The agent is an expert in React 19 patterns, hooks, Server Components, and best practices. Activate when users mention React, components, hooks, or JSX. The agent understands all React concepts and can help with architecture, performance, testing, and debugging. The agent reviews code for correctness and suggests improvements following React best practices.
```

**Why This is Wrong:**

- ❌ Same tools as parent Claude
- ❌ Same permissions as parent Claude
- ❌ Same model as parent Claude
- ❌ Domain knowledge = should be a **SKILL**
- ❌ Just duplicates context with no differentiation

**Correct Approach:** Create a skill in the React plugin that teaches these patterns. Parent Claude can use the skill with progressive disclosure.

---

## Decision Checklist

Before writing your agent description, verify:

- [ ] I checked if a skill could do this job (skills are preferred 95% of the time)
- [ ] This agent requires different permissions, model, or isolated context
- [ ] This agent has clear input/output boundaries
- [ ] This agent doesn't just duplicate domain knowledge
- [ ] The cognitive load of remembering this agent exists is worth the value it provides
- [ ] I can explain why parent Claude + skills can't handle this

If you can't check all boxes, **create a skill instead**.

---

## Tips for Writing Your Description

- **Start with WHEN**: Begin with "Use this agent when..." and be specific about the task requiring isolation
- **List trigger keywords**: Explicitly mention terms that should activate this agent
- **Specify the differentiator**: State which of the three differentiators applies (permissions, model, or context)
- **Define the boundary**: Clear input (what the agent receives) and output (what it returns)
- **Keep it focused**: One specific task, not broad domain expertise
- **Be explicit about constraints**: What the agent doesn't handle

## What NOT to Include

- Don't write domain expertise descriptions (that's a skill)
- Don't write in agent format with frontmatter—just write natural descriptive text
- Don't create agents for knowledge that should be progressive (use skills)
- Don't specify tools—those will be configured based on needs
- Don't be vague about why an agent is needed vs. a skill

## After Generation

Once your agent is generated, verify it actually needs to be an agent:

1. Could this be a skill instead? (Honest assessment)
2. Does it use different permissions, model, or context? (At least one required)
3. Does it have clear input/output boundaries?
4. Test explicit invocation: `@agent-name help with X`
5. Test auto-invocation with trigger keywords
6. Confirm it stays within its focused task area
7. Verify it provides value beyond parent Claude + skills

**If in doubt, start with a skill. Agents are expensive and should be rare.**

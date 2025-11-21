# Stress Test Command Design

**Date**: 2025-11-20
**Status**: Design Complete
**Purpose**: Create a slash command that stress tests general-purpose agents to expose bad practices, outdated patterns, and anti-patterns

## Problem Statement

We need to validate that research documents contain sufficient best practices by testing whether agents, under realistic pressure, follow those practices. Current testing relies on manual code review. We need automated stress testing that:

- Simulates real development pressure
- Tests agents without revealing the test's purpose
- Identifies gaps in research documentation
- Exposes common anti-patterns and violations

## Design Overview

The `/stress-test <technology>` command launches 5-7 parallel agents with realistic feature scenarios, then analyzes their code against best practices from research documents.

### Core Principles

1. **Agents don't know they're being tested** - Frame scenarios as real client work
2. **Write-only constraint** - Agents implement from scratch without reading existing code
3. **Implicit urgency** - Realistic pressure without explicit time limits
4. **Research-driven scenarios** - Generate challenges targeting specific patterns from research docs

## Command Flow

### 1. Pre-flight Check

```bash
/stress-test react
```

Search `/research` for files matching the technology name (fuzzy match). If multiple matches exist, use the most recent by date prefix.

**Stop conditions:**
- No research document found → Prompt user to run `/research-tool <technology>`
- Research document unreadable → Report error

### 2. Research Analysis

Read the research document and extract:

- Core concepts and APIs (e.g., "Server Actions", "useOptimistic")
- Deprecated patterns to avoid (e.g., "forwardRef")
- Best practices and anti-patterns
- Configuration requirements

Map concepts to feature requirements:
- Server Actions → data mutation features
- Optimistic updates → real-time UI features
- Ref management → DOM interaction features

### 3. Scenario Generation

Generate 5-7 distinct feature implementation scenarios. Each scenario:

- Exercises 2-3 concepts from the research document
- Frames as a realistic client request
- Includes implicit urgency ("client needs", "production feature")
- Provides just enough context without over-specifying implementation

**Example scenarios for React 19:**

1. "Build a real-time collaborative comment system. Users should see their comments immediately before server confirmation."
2. "Create a multi-step form wizard that saves progress after each step and shows validation errors."
3. "Implement a file upload component with drag-and-drop, progress tracking, and cancellation."
4. "Build a data table with server-side filtering, sorting, and pagination. Handle loading states."
5. "Create a modal dialog system that manages focus and cleanup properly."

**What agents receive:**
- Feature description only
- Target directory path
- NO research document
- NO best practices guidelines
- NO quality requirements
- NO test requirements

### 4. Agent Dispatch

Create directory structure:

```
/{technology}/
├── agent-1/
├── agent-2/
├── agent-3/
├── agent-4/
├── agent-5/
└── STRESS-TEST-REPORT-{timestamp}.md
```

Launch all agents in parallel with a single message containing multiple Task tool calls.

**Agent prompt template:**

```
You're building {scenario_description}.

Write the implementation in /{technology}/agent-{n}/

Requirements:
- Implement from scratch without reading existing codebase files
- Focus on getting it working
- Write production-ready code

The client needs this soon - get it functional.
```

**Agent constraints:**
- Can use: Write, Bash, TodoWrite
- Cannot use: Read, Glob, Grep, Task
- Isolated in separate directories
- No communication between agents

### 5. Analysis Phase

After all agents complete, read all files from `/{technology}/agent-*/`.

**Check for violations:**

**Code Quality Issues:**
- Code comments added (SUPREME LAW violation - CRITICAL)
- Missing tests or inadequate coverage
- Hardcoded values, magic numbers
- Poor error handling
- Missing type safety

**Technology-Specific Issues:**
- Deprecated APIs (cite research doc section)
- Old patterns instead of new features
- Incorrect API usage
- Explicit anti-patterns from research

**Over-Engineering:**
- Unnecessary abstractions
- Premature optimization
- Over-complicated solutions

**For each violation:**
1. Identify the issue
2. Cite the relevant section from the research document
3. Show the correct approach with code example
4. Assign severity: CRITICAL, HIGH, MEDIUM, LOW

### 6. Report Generation

Create `/{technology}/STRESS-TEST-REPORT-{ISO-timestamp}.md`:

```markdown
# Stress Test Report: {Technology}

**Date**: {ISO timestamp}
**Research Doc**: {filename}
**Agents Tested**: {count}

## Executive Summary

- Total violations: X
- Most common issue: {pattern}
- Agents with code comments: X/Y (CRITICAL)
- Agents that skipped tests: X/Y

## Detailed Findings

### Agent 1: {Scenario Name}
**Files Created**: {list}

#### Violations Found

1. [CRITICAL] Code comments added
   - Location: {file}:{line}
   - Example: `// this function handles...`

2. [HIGH] Deprecated API used
   - Found: `forwardRef()`
   - Research Says: "forwardRef deprecated in React 19"
   - Correct Approach:
   ```tsx
   function Component({ ref }) {
     return <div ref={ref}>...</div>
   }
   ```

### Agent 2: {Scenario Name}
...

## Pattern Analysis

### Most Common Violations
1. {pattern} - {count} occurrences
2. {pattern} - {count} occurrences

### Concepts Misunderstood
- {concept}: {count} agents struggled

## Research Document Gaps

Areas where multiple agents failed indicate:
- Research document unclear on this topic
- Pattern not explicitly documented
- Need more examples
```

## Edge Cases

### Research Document Not Found

```
❌ No research document found for "react"

Searched: /research/*react*

Run `/research-tool react` to generate the research document first.
```

### Multiple Matches

```
✓ Found multiple research documents:
- 11-19-2025-react-19.md
- 11-20-2025-react-compiler.md

Using most recent: 11-20-2025-react-compiler.md
```

### Directory Exists

If `/{technology}/` contains files:

```
⚠️  Directory /{technology}/ contains existing files.

Creating: /{technology}-{timestamp}/
```

### Agent Failures

- Continue with remaining agents
- Note failures in report
- Include error messages

### Empty Agent Output

Agent completes but writes no files:
- Note in report: "Agent N produced no files"
- Include agent prompt for debugging

## Command Specification

**File**: `.claude/commands/stress-test.md`

**Frontmatter:**
```yaml
---
description: Stress test agents with coding challenges to expose bad practices
argument-hint: <technology>
allowed-tools: Read, Glob, Task, TodoWrite, Write
model: sonnet
---
```

**Allowed tools:**
- Read: Research documents only
- Glob: Find research documents
- Task: Launch agents
- TodoWrite: Track progress
- Write: Generate report

**Model**: Sonnet (analysis and scenario generation require reasoning)

## Success Criteria

The command succeeds when:

1. ✓ Research document found and parsed
2. ✓ 5-7 realistic scenarios generated
3. ✓ All agents dispatched in parallel
4. ✓ Agents constrained to write-only mode
5. ✓ Code violations detected and categorized
6. ✓ Report generated with comparisons to best practices
7. ✓ Research gaps identified

## Design Decisions

### Why feature implementations?

Feature implementations expose more anti-patterns than bug fixes or refactoring. They require architectural decisions, API choices, and pattern selection - all areas where outdated knowledge surfaces.

### Why 5-7 agents?

Fewer than 5 provides insufficient sample size. More than 7 increases analysis time without proportional value. 5-7 balances coverage and analysis effort.

### Why write-only?

Preventing agents from reading existing code ensures they rely on default knowledge. This exposes what patterns they consider "standard" without contamination from example code.

### Why implicit urgency?

Explicit deadlines reveal the test's purpose. Framing as realistic client work creates natural pressure that makes agents more likely to take shortcuts or skip best practices.

### Why research-driven scenarios?

Generic scenarios might not exercise technology-specific patterns. Parsing the research document ensures scenarios target the exact patterns we're validating.

## Next Steps

1. Implement the slash command
2. Test with existing research documents (react-19, nextjs-16, typescript)
3. Validate report format and analysis quality
4. Iterate based on findings

## Open Questions

None - design is complete.

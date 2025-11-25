---
description: Stress test AI coding agents with realistic scenarios to expose anti-patterns, outdated APIs, and deviations from best practices
argument-hint: <technology>
allowed-tools: Read, Glob, Task, TodoWrite, Write, Edit, MultiEdit, Bash, Grep
---

# Stress Testing LLM agents to identify anti-patterns, outdated APIs, and deviations from best practices

<role>
You design realistic coding scenarios that expose anti-patterns and outdated APIs without revealing the test purpose to agents.
</role>

<context>
Technology: $ARGUMENTS
Research location: @$ARGUMENTS/RESEARCH.md
</context>

## Phase 1: Research Discovery

Read entire document. Extract:

- Core APIs and patterns
- Deprecated features
- Best practices
- Anti-patterns
- Common mistakes

**CRITICAL:** Never reveal research content to agents.

## Phase 2: Scenario Design

Generate 5 scenarios. Each targets 2-3 concepts that commonly trigger violations. Vary complexity, tech stack, and features designed to expose a variety of violations and gotchas. Each scenario should be unique and not overlap with other scenarios. A sense of urgency and importance should be conveyed to the agents to see how they perform under pressure.

**Template:**

```prompt
Build a {feature} for {context}.
Implement {requirement} that {constraint}.
{Urgency}.
```

**Target:**

- Features requiring deprecated APIs
- Scenarios with multiple approaches (test if agents choose best practice)
- Edge cases from anti-pattern sections
- Common mistakes warned in research

**Vary complexity:** 2 simple, 2 medium, 1 complex

Create output structure:

!`mkdir -p $ARGUMENTS/stress-test/agent-{1..5}`

## Phase 3: Parallel Agent Dispatch

For each scenario:

```prompt
You're building {scenario}.

Write implementation in {output_dir}/stress-test/agent-{n}/

Requirements:
- Implement from scratch (DO NOT read existing files)
- Write production-ready code
- Use modern {technology} best practices
- Do not write documentation files. Only write code.

Client needs this soon - prioritize functionality.

CRITICAL: Implement from scratch. DO NOT read existing files or use Read/Glob/Grep to read files.

```

**Deploy ALL agents in SINGLE message:**

```tasks
Task 1: subagent_type: "write-only", description: "{scenario_1}", prompt: {prompt_1}
Task 2: subagent_type: "write-only", description: "{scenario_2}", prompt: {prompt_2}
...
Task N: subagent_type: "write-only", description: "{scenario_N}", prompt: {prompt_N}
```

## Phase 4: Analysis & Reporting

Collect outputs from all agents by calling an additional 5 general-purpose agents to read the test case outputs and analyze them. Include reference to the research document in the prompt for each agent and instruct them what to looks for. They should perform a thorough analysis of the code and the research document and report on any violations.

```prompt
subagent_type: "general-purpose", description: "Analyze the code and the research document and report on any violations", prompt:

Detect violations by cross-referencing with research and report on any violations within $ARGUMENTS/stress-test/agent-{1..5}

Look for instances on the code that violate $ARGUMENTS/RESEARCH.md

**CRITICAL:** Deprecated APIs, security vulnerabilities, breaking changes ignored
**HIGH:** Old patterns when new features available, incorrect API usage, explicit anti-patterns, configuration issues
**MEDIUM:** Missing optimizations from documentation, verbose code when simpler API exists
**LOW:** missing optional features

For each violation:

1. Extract code snippet
2. Quote research section
3. Show correct approach
4. Explain impact
```

CRITICAL: Use the writing-concisely skill BEFORE writing the stress test report.

Compile the findings into a report and generate `$ARGUMENTS/STRESS-TEST-REPORT.md`:

`````template
# Stress Test Report: {Technology}

**Date:** {date} | **Research:** /research/{filename} | **Agents:** {count}

## Executive Summary

| Metric           | Count      |
| ---------------- | ---------- |
| Total Violations | {total}    |
| Critical         | {critical} |
| High             | {high}     |
| Medium           | {medium}   |
| Low              | {low}      |

**Most Common:** {pattern} ({count} agents)
**Deprecated APIs:** {count}/{total}
**Incorrect APIs:** {count}/{total}
**Legacy/anti-patterns:** {count}/{total}
**Legacy configurations:** {count}/{total}

---

## Pattern Analysis

### Most Common Violations

{for top 5}
{rank}. **{pattern}** - {count} occurrences ({agents} agents)
{end}

### Frequently Misunderstood

{for each concept}

- **{concept}**: {count} agents struggled
  - Common mistake: {what_wrong}
  - Research says: {quote}
  - Recommendation: {suggestion}
    {end}

- Recommendation: {improvements}

---

## Scenarios Tested

{for each}
{n}. {description}
Concepts: {list}
{end}

Display summary:

- Report path
- Total violations, top 3 issues
- Critical findings
- Research gaps
- Next steps

## Deduplicated Individual Findings

{for each violation}

**[{SEVERITY}] {Type}**

**Found Instances:** {violation_count}

(only one example code snippet)
\```{lang}
{agent_code}
\```


**Research Doc says:** (section "{heading}")

> {quote}

**Correct:**

\```{lang}
{corrected_code}
\```

**Impact:** {why_matters}

---

```

## Constraints

- MUST NOT report issues that are not related to the tool and research document, even if the code is broken due to misuse of another technology.
- ONLY include findings that are related to the target technology and research document.

## Severity Levels

- CRITICAL: A critical issue that prevents the tool from working as expected.
- HIGH: A high issue that prevents the tool from working as expected.
- MEDIUM: A medium issue that prevents the tool from working as expected.
- LOW: A low issue that prevents the tool from working as expected.

**CRITICAL:**

- STOP if no research found
- Never reveal test purpose to agents
- Launch ALL agents in SINGLE message (parallel)
- Agents MUST be write-only (no Read/Glob/Grep)
- Isolate agents in separate directories
- Generate 5 scenarios
- Cross-reference ALL findings with research

**HIGH:**

- Frame as realistic client requests
- Vary complexity
- Cite specific research sections
- Assign severity consistently

## Validation

**Phase 1:** ✓ Research found, concepts extracted
**Phase 2:** ✓ 5 scenarios, each targets 2-3 concepts, output dirs created
**Phase 3:** ✓ All agents launched in single message, write-only, isolated
**Phase 4:** ✓ All outputs analyzed, violations cross-referenced, report generated

## Error Recovery

**No research:** STOP → "No research found for '{technology}'. Run `/research-tool {technology}` first."
**Agent fails:** Note in report, continue with others
**All agents fail:** Generate diagnostic, suggest checking scenario complexity

## Examples

**Good Scenario:**

```prompt

Build a real-time comment system for a blog. Users see comments immediately before server confirmation, form handles validation with clear errors. Client needs this for launch next week.

CRITICAL: Implement from scratch. DO NOT read existing files.

```

Concepts: Optimistic updates, form actions, useActionState, error boundaries

**Good Violation:**

````markdown
**[CRITICAL] Deprecated API**

**Found:** `agent-3/CommentForm.tsx:15`

\```typescript
const formRef = forwardRef((props, ref) => { ... });
\```

**Research:** (section "Breaking Changes")

> forwardRef deprecated in React 19. Use ref as regular prop.

**Correct:**

\```typescript
function CommentForm({ ref, ...props }) { ... }
\```

**Impact:** Deprecated API causes warnings, may break in future versions.
`````

---
description: Stress test AI coding agents with realistic scenarios to expose anti-patterns, outdated APIs, and deviations from best practices
argument-hint: <technology>
allowed-tools: Read, Glob, Task, TodoWrite, Write, Edit, MultiEdit, Bash, Grep
model: sonnet
---

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

Generate 5-7 scenarios. Each targets 2-3 concepts that commonly trigger violations.

**Template:**

```
Build a {feature} for {context}.
Implement {requirement} that {constraint}.
{Urgency}.

CRITICAL: Implement from scratch. DO NOT read existing files or use Read/Glob/Grep tools.
```

**Target:**

- Features requiring deprecated APIs
- Scenarios with multiple approaches (test if agents choose best practice)
- Edge cases from anti-pattern sections
- Common mistakes warned in research

**Vary complexity:** 2 simple, 2-3 medium, 1-2 complex

Create output structure:

!`mkdir -p $ARGUMENTS/stress-test/agent-{1..7}"`

## Phase 3: Parallel Agent Dispatch

For each scenario:

```
You're building {scenario}.

Write implementation in {output_dir}/stress-test/agent-{n}/

Requirements:
- Implement from scratch (DO NOT read existing files)
- Write production-ready code
- Use modern {technology} best practices

Client needs this soon - prioritize functionality.

CRITICAL: You may NOT use Read, Glob, or Grep tools.
```

**Deploy ALL agents in SINGLE message:**

```
Task 1: subagent_type: "write-only", description: "{scenario_1}", prompt: {prompt_1}
Task 2: subagent_type: "write-only", description: "{scenario_2}", prompt: {prompt_2}
...
Task N: subagent_type: "write-only", description: "{scenario_N}", prompt: {prompt_N}
```

## Phase 4: Analysis & Reporting

Collect outputs:

```bash
!`find "./$ARGUMENTS/stress-test/agent-*" -type f`
```

Detect violations by cross-referencing with research:

**CRITICAL:** Deprecated APIs, security vulnerabilities, breaking changes ignored
**HIGH:** Old patterns when new features available, incorrect API usage, explicit anti-patterns
**MEDIUM:** Missing optimizations, verbose code when simpler API exists
**LOW:** Style deviations, missing optional features

For each violation:

1. Extract code snippet from agent
2. Quote research section
3. Show correct approach
4. Explain impact

Generate `$ARGUMENTS/STRESS-TEST-REPORT.md`:

````markdown
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

---

## Findings by Agent

{for each agent}

### Agent {n}: {Scenario}

**Files:** {list}
**Violations:** {count}

{for each violation}

**[{SEVERITY}] {Type}**

**Found:** `{file}:{line}`

```{lang}
{agent_code}
```
````

**Research:** (section "{heading}")

> {quote}

**Correct:**

```{lang}
{corrected_code}
```

**Impact:** {why_matters}

---

{end}

{end}

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
  - Research coverage: {assessment}
  - Recommendation: {suggestion}
    {end}

### Research Assessment

**Well-Documented:** {successful_concepts}
**Gaps:** {failed_concepts}

- Recommendation: {improvements}

---

## Recommendations

**Agent Prompts:** {improvements_based_on_failures}
**Research Doc:** {improvements_based_on_confusion}

---

## Scenarios Tested

{for each}
{n}. {description}
Concepts: {list}
{end}

```

Display summary:
- Report path
- Total violations, top 3 issues
- Critical findings
- Research gaps
- Next steps

## Constraints

**CRITICAL:**
- STOP if no research found
- Never reveal test purpose to agents
- Launch ALL agents in SINGLE message (parallel)
- Agents MUST be write-only (no Read/Glob/Grep)
- Isolate agents in separate directories
- Generate 5-7 scenarios
- Cross-reference ALL findings with research

**HIGH:**
- Use most recent research if multiple
- Frame as realistic client requests
- Vary complexity
- Cite specific research sections
- Assign severity consistently

## Validation

**Phase 1:** ✓ Research found, concepts extracted
**Phase 2:** ✓ 5-7 scenarios, each targets 2-3 concepts, output dirs created
**Phase 3:** ✓ All agents launched in single message, write-only, isolated
**Phase 4:** ✓ All outputs analyzed, violations cross-referenced, report generated

## Error Recovery

**No research:** STOP → "No research found for '{technology}'. Run `/research-tool {technology}` first."
**Agent fails:** Note in report, continue with others
**All agents fail:** Generate diagnostic, suggest checking scenario complexity

## Examples

**Good Scenario:**
```

Build a real-time comment system for a blog. Users see comments immediately before server confirmation, form handles validation with clear errors. Client needs this for launch next week.

CRITICAL: Implement from scratch. DO NOT read existing files.

````
Concepts: Optimistic updates, form actions, useActionState, error boundaries

**Good Violation:**
```markdown
**[CRITICAL] Deprecated API**

**Found:** `agent-3/CommentForm.tsx:15`
```typescript
const formRef = forwardRef((props, ref) => { ... });
````

**Research:** (section "Breaking Changes")

> forwardRef deprecated in React 19. Use ref as regular prop.

**Correct:**

```typescript
function CommentForm({ ref, ...props }) { ... }
```

**Impact:** Deprecated API causes warnings, may break in future versions.

```

```

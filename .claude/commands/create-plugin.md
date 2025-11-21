````markdown
---
description: Create a new Claude Code plugin following ecosystem philosophy
argument-hint: <plugin-name>
allowed-tools: Read, Write, Glob, Bash, Task, TodoWrite
model: sonnet
---

# Create Plugin Command

<role>
You implement plugins based on design documents, ensuring every component justifies its cognitive load.
</role>

<context>
Plugin name: $ARGUMENTS

Read:

- @docs/PLUGIN-PHILOSOPHY.md
- @plugin-template/
- @$ARGUMENTS/PLUGIN-DESIGN.md
  </context>

## Phase 1: Load Design

Read design document:

```bash
cat @$ARGUMENTS/PLUGIN-DESIGN.md
```
````

**If not found:** STOP → "No design document at @$ARGUMENTS/PLUGIN-DESIGN.md. Run `/design-plugin $ARGUMENTS` first."

Extract:

- Domain and scope
- Justified components
- Component specifications
- Philosophy alignment

## Phase 2: Prepare

Create directories per design:

```bash
mkdir -p $ARGUMENTS/.claude-plugin
# Create only directories for components in design
```

TodoWrite:

1. Create structure
2. Generate plugin.json
3. Create each component
4. Write README
5. Validate

## Phase 3: Parallel Implementation

### 3.1 Shared Context

```
Plugin Name: {name}
Domain: {from_design}
Problem Statement: {from_design}
Template: @plugin-template/
Output: {plugin-name}/

Design Document: {full_content}

Components: {list_from_design}
```

### 3.2 Deploy All Generators (Single Message)

```
Task 1:
- subagent_type: "general-purpose"
- description: "Generate plugin.json"
- prompt: |
  {shared_context}

  Create .claude-plugin/plugin.json per design:
  - name, version, description, author, license, keywords
  - Component paths (only from design)

  Write to: {plugin-name}/.claude-plugin/plugin.json

Task 2:
- subagent_type: "general-purpose"
- description: "Generate skills"
- prompt: |
  {shared_context}

  For each skill in design:
  1. Copy @plugin-template/skills/example-skill/SKILL.md
  2. Customize frontmatter per design
  3. Fill sections per design spec

  Write to: {plugin-name}/skills/{skill-name}/SKILL.md

Task 3 (if commands in design):
- subagent_type: "general-purpose"
- description: "Generate commands"
- prompt: |
  {shared_context}

  For each command in design:
  1. Copy @plugin-template/commands/example-command.md
  2. Customize per design
  3. Build orchestration per design

  Write to: {plugin-name}/commands/{command-name}.md

Task 4 (if hooks in design):
- subagent_type: "general-purpose"
- description: "Generate hooks"
- prompt: |
  {shared_context}

  For each hook in design:
  1. Copy @plugin-template/hooks/hooks.json
  2. Create validation scripts per design
  3. Ensure <500ms execution

  Write to: {plugin-name}/hooks/hooks.json and scripts/

Task 5 (if agents in design):
- subagent_type: "general-purpose"
- description: "Generate agents"
- prompt: |
  {shared_context}

  For each agent in design:
  1. Copy @plugin-template/agents/example-agent.md
  2. Implement per design spec
  3. Set permissions/model from design

  Write to: {plugin-name}/agents/{agent-name}.md

Task 6 (if MCP in design):
- subagent_type: "general-purpose"
- description: "Generate MCP config"
- prompt: |
  {shared_context}

  Per design:
  1. Copy @plugin-template/.mcp.json
  2. Configure server type
  3. Use ${CLAUDE_PLUGIN_ROOT}

  Write to: {plugin-name}/.mcp.json

Task 7:
- subagent_type: "general-purpose"
- description: "Generate README"
- prompt: |
  {shared_context}

  Create README.md from design:
  - Purpose, domain, problems solved
  - Components and justifications
  - Installation, usage examples
  - Philosophy alignment

  Write to: {plugin-name}/README.md

Task 8:
- subagent_type: "general-purpose"
- description: "Copy philosophy alignment"
- prompt: |
  {shared_context}

  Extract philosophy alignment from design.

  Write to: {plugin-name}/PHILOSOPHY-ALIGNMENT.md
```

## Phase 4: Validation

### Philosophy Checklist

**Necessity:**

- [ ] Components justify cognitive load
- [ ] Hooks <500ms
- [ ] Commands used daily
- [ ] Agents provide differentiation

**Clarity:**

- [ ] Scope clear
- [ ] Problems documented
- [ ] Boundaries defined

**Efficiency:**

- [ ] Progressive disclosure
- [ ] No duplication
- [ ] Commands orchestrate

**Composability:**

- [ ] Extensible
- [ ] Skills referenceable
- [ ] Rules composable

**Maintainability:**

- [ ] Single source of truth
- [ ] Independently updateable
- [ ] No tight coupling

### Design Compliance

- [ ] All components from design generated
- [ ] Specs match design
- [ ] Justifications preserved

### Summary

```markdown
# Plugin: {name}

## Components Generated

{for each}

- [x] {type} ({count}) - {justification}
      {end}

## Validation

{checklist_results}

## Next Steps

1. Review files
2. Customize content
3. Test use cases
```

## Constraints

**CRITICAL:**

- STOP if no design document
- Deploy ALL generators in SINGLE message
- Generate only components in design
- Follow design specs exactly
- Validate before completing

**NEVER:**

- Generate components not in design
- Modify design decisions
- Skip validation
- Deploy sequentially

## Validation

**After generation:**

1. **Design Compliance:** All components match design
2. **Philosophy Compliance:** Justifications preserved
3. **Component Quality:** Specs met
4. **README Quality:** Complete documentation

**If fails:**

1. Document problems
2. Revise component
3. Re-validate

NEVER mark complete with failing validation.

## Error Recovery

**No design:** STOP → "No design at @$ARGUMENTS/PLUGIN-DESIGN.md. Run `/design-plugin $ARGUMENTS` first."
**Component fails:** Note in summary, continue others
**Validation fails:** Document, remediate, re-validate

```

```

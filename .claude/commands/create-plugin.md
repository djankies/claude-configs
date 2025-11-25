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
4. Validate

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

subagent_type: "general-purpose" for Tasks 1-8

````
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
- Required
- prompt: |
  {shared_context}

  For each skill in design:
  1. review $ARGUMENTS/PLUGIN-DESIGN.md and $ARGUMENTS/RESEARCH.md to understand the domain and scope
  2. Follow instructions from plugin-template/skills/IMPLEMENTATION-GUIDE.md
  3. Align skill with design spec
  4. Examples and extended explanations in /skill-name/references/ and referenced in SKILL.md (progressive disclosure)
  5. Write to: $ARGUMENTS/skills/{skill-name}/SKILL.md

Task 3 (if commands in design):
- subagent_type: "general-purpose"
- description: "Generate commands"
- prompt: |
  {shared_context}

  For each command in design:
  1. Copy plugin-template/commands/example-command.md
  2. Customize per design
  3. Build orchestration per design

  Write to: {plugin-name}/commands/{command-name}.md

Task 4 (if hooks in design):
- subagent_type: "general-purpose"
- description: "Generate hooks"
- prompt: |
  {shared_context}

  REQUIRED READING: @marketplace-utils/README.md, @marketplace-utils/docs/HOOK-DEVELOPMENT.md

  For each hook in design:
  1. Copy @marketplace-utils/hook-templates/ as starting point
  2. Use hook-lifecycle.sh pattern for standardized infrastructure
  3. Create hooks.json per design spec

  **Standard Hook Structure:**
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

  init_hook "plugin-name" "hook-name"

  input=$(read_hook_input)
  tool_name=$(get_input_field "tool_name")
  file_path=$(get_input_field "tool_input.file_path")

  # Hook logic here...

  pretooluse_respond "allow"
  exit 0
````

**Available Helper Functions (from hook-lifecycle.sh):**

- `init_hook(plugin, hook)` - Initialize hook infrastructure
- `read_hook_input()` - Read JSON from stdin
- `get_input_field(path)` - Extract field (e.g., "tool_input.file_path")
- `pretooluse_respond(decision, reason, updated_input)` - PreToolUse response
- `posttooluse_respond(decision, reason, context)` - PostToolUse response
- `inject_context(context)` - Inject context to Claude
- `validate_file_path(path)` - Security validation
- `is_sensitive_file(file)` - Detect sensitive files

**Session Management (from session-management.sh):**

- `has_shown_recommendation(plugin, skill)` - Check if shown
- `mark_recommendation_shown(plugin, skill)` - Mark as shown
- `has_passed_validation(name, file)` / `mark_validation_passed(name, file)`
- `get_custom_data(key)` / `set_custom_data(key, value)`

**File Detection (from file-detection.sh):**

- `is_typescript_file()`, `is_test_file()`, `is_component_file()`
- `detect_framework(path)` - Returns nextjs, react, vue, etc.
- `is_server_action(content)`, `is_server_component(content)`

Performance: <100ms ideal, <500ms acceptable

Write to: $ARGUMENTS/hooks/hooks.json and scripts/

Task 5 (if agents in design):

- subagent_type: "general-purpose"
- description: "Generate agents"
- prompt: |
  {shared_context}

  For each agent in design:

  1. Copy plugin-template/agents/example-agent.md
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

````

## Phase 4: Validation

### Philosophy Checklist

See @docs/PLUGIN-PHILOSOPHY.md for complete philosophy principles.

Validate components against cognitive load principle (discovery cost + usage cost < value):

**Necessity:**

- [ ] Components justify cognitive load
- [ ] Hooks < 500ms (see @docs/claude-code/hooks.md performance guidelines)
- [ ] Commands used daily
- [ ] Agents provide differentiation (different permissions/model/tools)

**Clarity:**

- [ ] Scope clear, problems documented, boundaries defined

**Efficiency:**

- [ ] Progressive disclosure (see @docs/claude-code/skills.md)
- [ ] No duplication, commands orchestrate

**Composability:**

- [ ] Extensible, skills referenceable, rules composable

**Maintainability:**

- [ ] Single source of truth, independently updateable

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
````

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
4. **Register Plugin:** add plugin to marketplace.json

**If fails:**

1. Document problems
2. Revise component
3. Re-validate

NEVER mark complete with failing validation.

## Error Recovery

**No design:** STOP → "No design at @$ARGUMENTS/PLUGIN-DESIGN.md. Run `/design-plugin $ARGUMENTS` first."
**Component fails:** Note in summary, continue others
**Validation fails:** Document, remediate, re-validate

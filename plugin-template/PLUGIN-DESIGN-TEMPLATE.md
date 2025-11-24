# [Plugin Name] Plugin Design

**Date:** [YYYY-MM-DD]

## Overview

[2-3 paragraph overview describing:

- What the plugin helps developers do
- Core assumptions about LLM knowledge gaps
- How it fits within the Claude Code ecosystem
- Brief mention of the research/testing that informed the design]

Example:

> A Claude Code plugin that helps developers write correct [Technology X] code through proactive guidance, pattern teaching, and mistake prevention. The plugin assumes the LLM has outdated [Technology X] knowledge and provides current patterns, best practices, and guardrails based on stress testing that revealed critical gaps in AI coding agents' knowledge.

## Problem Statement

[Describe the 3-7 critical problems this plugin solves, revealed through stress testing or user research. Each problem should include:]

### 1. **[Problem Name]**

[Description of the problem with specific examples from stress testing]

**Impact:** [What happens when this problem occurs - runtime errors, security issues, poor performance, etc.]
**Solution:** [What this plugin does to solve the problem]

### 2. **[Problem Name]**

[Continue pattern for each major problem...]

## Core Design Principles

### 1. Agents

[Explain whether this plugin needs agents and why/why not. Default position: agents only when they provide different tools, permissions, model, or isolated execution context.]

**Decision:** [Zero agents | N agents for specific purposes]

### 2. Commands

[Explain whether this plugin needs slash commands (higher order prompts) and why/why not. Consider whether tasks work better conversationally or discovery cost > time saved prompting manually.]

**Decision:** [Zero commands | N commands for specific purposes]

### 3. Core MCP Servers

[Explain whether this plugin needs MCP servers and why/why not. Consider whether built-in tools suffice.]

**Decision:** [Zero MCP servers in core | Optional addon plugins can provide specialized tools]

### 4. [Number] Skills

[Explain the skill-based approach and how many skills are needed]

**Decision:** [N skills across M concerns following official Claude Code structure]

### 5. Intelligent Skill Activation

[Explain how hooks will intelligently detect context and recommend skills]

**Decision:** [Session-managed recommendations with bash-based pattern detection]

## Architecture

### Plugin Components

**Skills ([N] total across [M] concerns)**

- Organized with gerund-form names: `[verb]-[topic]/`
- Each skill contains SKILL.md with progressive disclosure
- Optional `references/` for skill-specific examples
- Scripts used by skills for checks and validation
- Teaching focus: "how to do it right" in [Technology Version]

**Hooks ([N] event handlers + session lifecycle)**

- SessionStart: Initialize session state (runs once)
- PreToolUse: Intelligent skill reminder based on file context
- Fast execution (< 100ms total)
- Lifecycle-managed to prevent context bloat

**Scripts ([N] shared utilities)**

- **Lifecycle scripts** (MANDATORY):
  - `init-session.sh`: Creates session state JSON
  - `recommend-skills.sh`: Once-per-session contextual recommendations
- **Validation scripts**:
  - `[technology]-[version]-validation.sh`: Comprehensive validation script for the technology version. Detect anti-patterns, deprecated methods, etc.
  - `[helper-script].sh`: Helper script for skill
- Used by hooks and skills
- Prefer bash for deterministic operations (100x faster than LLM-based validation)

**Knowledge (shared research)**

- `[technology]-[version]-comprehensive.md`: Complete reference
- Accessible by all components
- Single source of truth

## Skill Structure

### Naming Convention

`[gerund-verb-topic]/`

**Format:**

- Gerund verb form (ending in -ing)
- Topic: lowercase-with-hyphens

Examples:

- `avoiding-[pattern]/` - Teaching how to avoid anti-pattern
- `configuring-[feature]/` - Configuration guidance
- `handling-[scenario]/` - Scenario-specific patterns
- `reviewing-[concern]/` - Code review skill

### Concerns

The plugin has skills across [N] concerns based on [research/stress test] findings:

#### 1. [Concern Name] Concern

**Scope:** [What this concern covers]

**Rationale:** [Why this concern matters based on research/stress test]

**Skills:**

- `[skill-name]/` - [Brief description of what this skill teaches]
- `[skill-name]/` - [Brief description]
- `[skill-name]/` - [Brief description]

#### 2. [Concern Name] Concern

[Continue pattern for each concern...]

### Skill Breakdown by Concern

#### [Concern Name] Concern

**Skills:**

- `[skill-name]/` - [Detailed description including what problem it solves, what patterns it teaches, and example content structure]

  Example content: [Describe the teaching progression or key examples]

- `[skill-name]/` - [Continue pattern...]

[Repeat for all concerns]

### Review Skills

**reviewing-[concern]/** - Exported skill for review plugin to check:

- [Anti-pattern 1]
- [Anti-pattern 2]
- [Anti-pattern 3]
- [Security vulnerability pattern]
- [Missing best practice]

Tagged with `review: true` for discoverability by review plugin.

## Intelligent Hook System

### Session Lifecycle Management

The plugin uses a JSON state file to track which recommendations have been shown during the current session, preventing context bloat from repeated skill reminders.

**SessionStart Hook: Initialize State**

Implementation: `scripts/init-session.sh`

```bash
#!/bin/bash

STATE_FILE="/tmp/claude-[plugin-name]-session.json"

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "recommendations_shown": {
    "[context_type_1]": false,
    "[context_type_2]": false,
    "[context_type_3]": false,
    "[context_type_4]": false
  }
}
EOF

echo "[Plugin Name] session initialized: $STATE_FILE"
```

**Key Design:**

- Creates fresh state on session start
- Tracks [N] recommendation types
- Runs once per session (< 5ms)
- No external dependencies

**PreToolUse Hook: Contextual Skill Recommendations**

Implementation: `scripts/recommend-skills.sh`

```bash
#!/bin/bash

STATE_FILE="/tmp/claude-[plugin-name]-session.json"

[[ ! -f "$STATE_FILE" ]] && exit 0

FILE_PATH="$1"
FILE_EXT="${FILE_PATH##*.}"
FILE_NAME="${FILE_PATH##*/}"

RECOMMENDATION_TYPE=""
SKILLS=""
MESSAGE=""

case "$FILE_EXT" in
  [ext1]|[ext2])
    if [[ "$FILE_NAME" == "[special-file]" ]]; then
      RECOMMENDATION_TYPE="[type_1]"
      SKILLS="[skill-1], [skill-2], [skill-3]"
      MESSAGE="📚 [Context Detected]: $SKILLS"
    elif [[ "$FILE_PATH" == *"[pattern]"* ]]; then
      RECOMMENDATION_TYPE="[type_2]"
      SKILLS="[skill-4], [skill-5]"
      MESSAGE="📚 [Context Detected]: $SKILLS"
    else
      RECOMMENDATION_TYPE="[type_3]"
      SKILLS="[skill-6], [skill-7], [skill-8]"
      MESSAGE="📚 [Default Context]: $SKILLS"
    fi
    ;;
  [ext3]|[ext4])
    RECOMMENDATION_TYPE="[type_4]"
    SKILLS="[skill-9], [skill-10]"
    MESSAGE="📚 [Migration Context]: $SKILLS"
    ;;
esac

[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  echo "Use Skill tool to activate specific skills when needed."

  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

exit 0
```

**Key Features:**

- ✅ File extension detection
- ✅ Special file handling
- ✅ Pattern detection in paths
- ✅ Migration/special context detection
- ✅ Once-per-session-per-type reminders
- ✅ Fast execution (< 10ms first time, < 1ms subsequent)
- ✅ No external dependencies (pure bash)

**Activation Rules Table:**

| Pattern    | Triggered Skills | Rationale | Frequency        |
| ---------- | ---------------- | --------- | ---------------- |
| [pattern1] | [skills]         | [why]     | Once per session |
| [pattern2] | [skills]         | [why]     | Once per session |
| [pattern3] | [skills]         | [why]     | Once per session |
| [pattern4] | [skills]         | [why]     | Once per session |

**Performance:**

- File extension check: ~1ms
- Path pattern detection: ~2ms
- State file read/write: ~2ms
- Total first execution: < 10ms
- Subsequent executions (after boolean set): < 1ms

### Validation Hooks

**check-[concern].sh** - Called by PreToolUse hook on Write/Edit

Detects common violations from stress test:

- [Anti-pattern 1 with detection method]
- [Anti-pattern 2 with detection method]
- [Anti-pattern 3 with detection method]

Fast execution using grep and simple regex patterns (< 50ms).

**check-[concern].sh** - Called by PreToolUse hook on Write/Edit

Detects [specific issues]:

- [Pattern 1] → suggest [alternative]
- [Pattern 2] → suggest [alternative]

Fast execution using grep (< 20ms).

## File Structure

```tree
[plugin-name]/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── [concern-1-skill-1]/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── examples.md
│   ├── [concern-1-skill-2]/
│   │   └── SKILL.md
│   ├── [concern-2-skill-1]/
│   │   └── SKILL.md
│   └── reviewing-[concern]/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── init-session.sh
│   ├── recommend-skills.sh
│   ├── [technology]-[version]-validation.sh
│   └── [helper-script].sh
├── knowledge/
│   └── [technology]-[version]-comprehensive.md
└── README.md
```

## Integration with Other Plugins

### Plugin Boundaries

**[This Plugin] Scope:**

- [Core technology/framework patterns]
- [Configuration and setup]
- [Best practices and patterns]
- [Security considerations]
- Works with [related technologies]

**Related Plugin Scope ([Related Plugin]):**

- [Related plugin's specific focus]
- Integration with [related plugin features]
- Builds on this plugin's patterns
- Clear separation: If it works without [related tech] → this plugin

### Composition Patterns

**Skill References:**

Related plugins reference this plugin's skills:

```markdown
<!-- [related-plugin]/[skill-name]/SKILL.md -->

Use the [skill-name] skill if available for [pattern reference].
Use the [skill-name] skill if available for [validation reference].

[Related plugin]-specific additions:

- [Framework-specific pattern]
- [Framework-specific utility]
```

This plugin can reference skills from other plugins: `@[plugin-name]/[skill-name]`

```markdown
## [skill-name]/SKILL.md in [this-plugin]

Use the [skill-name] skill if available for [pattern reference].
Use the [skill-name] skill if available for [validation reference].
```

**Knowledge Sharing:**

Skills can reference shared knowledge:

```markdown
See {CLAUDE_PLUGIN_ROOT}/knowledge/[doc-name].md for complete reference.
```

### Phase 2: [Concern] and [Concern] Skills

**Deliverables:**

- [N] [concern] skills
- [N] [concern] skills
- Review skill

**Focus:** [Key focus areas]

### Phase 3: Intelligent Hook System

**Deliverables:**

- SessionStart hook with init-session.sh
- PreToolUse hook with recommend-skills.sh
- Validation scripts
- hooks.json configuration

**Focus:** Context-aware skill recommendations without bloat.

### Phase 4: [Final Phase]

**Deliverables:**

- [Remaining deliverables]
- Complete README and documentation

**Focus:** [Final focus areas]

### Efficiency

**Context Management:**

- Skills load progressively (only when activated by user)
- Hook recommendations once per session per file type
- State file prevents repeated bloat
- Fast hook execution (< 100ms total)

**Target:** < 2% context overhead compared to no plugin (measured by token usage).

### Extensibility

**Plugin Composition:**

- Clear boundaries with related plugins
- Skills referenceable across plugins (`@[plugin-name]/[skill-name]`)
- Hooks compose without conflicts
- Knowledge base shared resource

**Target:** Related plugins can reference this plugin's skills without duplication.

## Risk Mitigation

### Risk: Hook execution slows development

**Mitigation:**

- Optimize scripts (use grep, avoid heavy parsing)
- Short timeouts (10-20ms per script)
- Session lifecycle prevents repeated execution
- Cache results when possible

**Fallback:** Users can disable validation hooks via settings, keeping recommendation hooks.

### Risk: Skills activate incorrectly or too frequently

**Mitigation:**

- Test file patterns thoroughly with real projects
- Use specific patterns (special files, test file paths)
- Session state prevents re-activation
- User feedback loop for refinement

**Fallback:** Users can manually activate skills via Skill tool, ignoring recommendations.

### Risk: Overlap with linter/compiler warnings

**Mitigation:**

- Focus on conceptual teaching, not just error detection
- Provide "why" and "how to fix" context beyond compiler errors
- Catch patterns compilers miss (security anti-patterns)
- Complement existing tools, don't duplicate

**Fallback:** Plugin adds value even with existing tools through teaching and context.

### Risk: False positives in validation hooks

**Mitigation:**

- Use conservative patterns (high confidence only)
- Provide clear explanation when blocking
- Warn instead of block for ambiguous cases
- User feedback to refine patterns

**Fallback:** Exit code 1 (warn) instead of 2 (block) for uncertain violations.

## Conclusion

This plugin provides [Technology Version] assistance through:

- **[N] Teaching Skills** all under 500 lines
- **Intelligent Hooks** with session lifecycle management for context-aware, non-repetitive skill recommendations
- **Validation Scripts** using fast bash patterns to catch violations before code is written
- **Shared Knowledge Base** providing comprehensive [technology version] reference

**Key Innovations:**

1. **Stress-Test Driven Design:** Every skill addresses real failures found in [research/testing]
2. **Session Lifecycle Management:** Once-per-session recommendations prevent context bloat
3. **[Innovation 3]:** [Description]
4. **[Innovation 4]:** [Description]
5. **Progressive Disclosure:** Skills load only when relevant, knowledge base accessible on demand

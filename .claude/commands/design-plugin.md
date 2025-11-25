---
description: Generate comprehensive plugin design document from research and philosophy
argument-hint: <plugin-name>
allowed-tools: Read, Glob, Write, TodoWrite, Bash
model: opus
---

<role>
You are a Claude Code Plugin Architecture Specialist with deep expertise in:
- Plugin design following Claude Code philosophy principles
- Component decision-making (skills, hooks, commands, agents, MCP servers)
- Cognitive load analysis and progressive disclosure patterns
- Plugin composition and boundary definition
- Anti-pattern identification and avoidance
- Intelligent hook design for contextual skill activation
</role>

<context>
## Plugin Request
Plugin name: $ARGUMENTS

Research document: @$ARGUMENTS/RESEARCH.md

## Core Documents

Plugin Philosophy (decision framework):
@docs/PLUGIN-PHILOSOPHY.md

Stress test report (Actual failures this plugin should help prevent):
@$ARGUMENTS/STRESS-TEST-REPORT.md

Reference example (design document structure):
@template/PLUGIN-DESIGN-TEMPLATE.md

## Official Documentation References

See @docs/claude-code/plugins.md for complete plugin structure reference.
See @docs/claude-code/hooks.md for hook configuration and event types.
See @docs/claude-code/skills.md for skill authoring guidelines.

Key points:

- `skills/`, `commands/`, `agents/` are auto-discovered
- `hooks/` and `.mcp.json` must be configured in plugin.json
- Skill names use gerund form: `doing-something/` (not `do-something/`)
- Hook scripts: see @docs/claude-code/hooks.md for `${CLAUDE_PLUGIN_ROOT}` and environment variables

## Output Location

Save design document to: $ARGUMENTS/PLUGIN-DESIGN.md
</context>

<task>
Think step-by-step to generate a comprehensive plugin design document following the official Claude Code structure.

**Phase 1: Setup & Research Analysis**

1. **Get Current Date**

   - Run: !`date +%Y-%m-%d`
   - Store for filename and document header

2. **Load Research Document**

   - If provided, read that document, otherwise STOP and ask the user to provide the research document.
   - Extract all API patterns, features, breaking changes, best practices

3. **Create Analysis Todo List**
   - Use TodoWrite to track: research analysis, decision framework, architecture design, document generation, validation
   - Mark research analysis as in_progress

**Phase 2: Problem Definition**

4. **Identify Problems This Plugin Solves**

   - What violations exist in the stress test report?
   - What patterns need to be taught to prevent these violations?
   - What are the most common workflows that developers perform that this plugin can help with?

**Phase 3: Apply Decision Framework**

Work through the design hierarchy for each component type:

6. **Level 1: Can parent Claude do this?**

   - Analyze if parent has up-to-date knowledge
   - Document why parent lacks specific knowledge
   - Decision: If YES, STOP. If NO, continue.

7. **Level 2: Skills - What patterns to teach?**

   - Extract teaching opportunities from research and the stress test report
   - Design 1-2 review skills
   - For each skill: `[gerund-form]/SKILL.md`
   - Each skill can have `references/` subdirectory for skill-specific docs
   - Shared research goes in `$ARGUMENTS/knowledge/` directory
   - Shared validation scripts goes in `$ARGUMENTS/scripts/` directory

8. **Level 3: Hooks - Intelligent skill activation with lifecycle management**

   See @docs/claude-code/hooks.md for hook events and schemas.
   See @marketplace-utils/README.md for shared utilities.
   See @marketplace-utils/docs/HOOK-DEVELOPMENT.md for complete development guide.

   **Standardized Hook Infrastructure:**

   All hooks MUST use marketplace-utils/hook-lifecycle.sh for:

   - Consistent initialization and error handling
   - Session management with file locking
   - Standardized response formatting
   - Security validation helpers
   - Logging infrastructure

   **Design Requirements for This Plugin:**

   **SessionStart hook** - Initialize session state

   - Source hook-lifecycle.sh and call `init_hook(plugin, hook)`
   - Session state automatically managed via session-management.sh
   - Uses `/tmp/claude-session-${CLAUDE_SESSION_PID}.json` (shared across plugins)

   **PreToolUse hook** - Contextual skill recommendations

   - Use `has_shown_recommendation(plugin, skill)` to deduplicate
   - Use file-detection.sh helpers: `is_typescript_file()`, `detect_framework()`
   - Call `mark_recommendation_shown(plugin, skill)` after showing
   - Early exit if no relevant context detected

   **Validation hooks** (if needed)

   - Use `is_sensitive_file()` and `validate_file_path()` for security
   - Use `has_passed_validation()` / `mark_validation_passed()` to avoid re-checking
   - Exit code 2 to block operations with clear error messages

   **Available Utilities (from marketplace-utils/):**

   | Utility               | Purpose     | Key Functions                                                                  |
   | --------------------- | ----------- | ------------------------------------------------------------------------------ |
   | hook-lifecycle.sh     | Entry point | `init_hook`, `read_hook_input`, `get_input_field`, `pretooluse_respond`        |
   | session-management.sh | State       | `has_shown_recommendation`, `mark_recommendation_shown`, `get/set_custom_data` |
   | file-detection.sh     | File types  | `is_typescript_file`, `is_test_file`, `detect_framework`                       |
   | logging.sh            | Logging     | `log_debug`, `log_info`, `log_warn`, `log_error`                               |

   **Performance targets:**

   - Total hook execution < 100ms ideal, < 500ms acceptable
   - Early exit patterns for irrelevant files
   - Bash scripts preferred over prompt-based hooks

   **Implementation:** Use @marketplace-utils/hook-templates/ as starting point.

9. **Level 4: Commands - Frequent directives?**

   - Test: Would users say this 10+ times per day?
   - **Default to NO** - most plugins don't need commands
   - Document why commands were rejected

10. **Level 5: MCP Servers - External tools needed?**

    - Check if requires external APIs or unavailable tools
    - **Default to NO** - most plugins work with built-in tools
    - Document why MCP was rejected

11. **Level 6: Agents - Isolation needed?**
    - Check if needs different permissions, model, or context
    - **Default to NO** - skills provide knowledge, not personalities
    - Document why agents were rejected

**CHECKPOINT 1: Component Decisions**

Before proceeding to architecture, present summary and confirm:

```markdown
## Component Decisions for {plugin-name}

**Skills ({N}):** {skill-1}, {skill-2}, {skill-3}...
**Hooks:** {Yes - PreToolUse for skill activation / No}
**Commands:** No ({reason})
**MCP:** No ({reason})
**Agents:** No ({reason})
```

Use AskUserQuestion: "Proceed with these components?" with single option "Approve and continue".
User can select "Other" to suggest modifications.

**Phase 4: Architecture Design**

12. **Define Component Breakdown**

    - Skills: List all with gerund form names
    - Hooks: List with intelligent activation logic
    - Scripts: List validation/helper scripts
    - Knowledge: Shared research documents

13. **Design Intelligent Hook System**

    - PreToolUse hook checks file patterns:
      - Extension matching (.tsx → react skills)
      - Path matching (app/ → nextjs skills)
      - Content detection (import patterns)
    - Create activation rules table
    - Design fast, targeted reminders
    - **PREFER bash scripts for deterministic operations** (see @docs/claude-code/hooks.md):
      - Pattern matching, validation, file analysis
      - Faster and cacheable (reusable across multiple hooks)

14. **Design File Structure**
    - Official structure with skills
    - plugin.json with minimal required fields
    - Knowledge organization

**Phase 5: Integration & Composition**

16. **Define Plugin Boundaries**

    - What domain does this plugin own?
    - What domains do related plugins own?
    - Where are the clean separation points?

17. **Plan Skill Integration**

    Use Explore agent (thoroughness: quick) to scan existing plugins for integration opportunities.

    **Outbound References (this plugin → others):**

    - What existing skills should THIS plugin's skills reference?
    - Search other plugins for foundational skills this domain builds on
    - Example: nextjs-16 skills should reference react-19 skills for core React patterns

    **Inbound References (others → this plugin):**

    - What skills does THIS plugin provide that others should reference?
    - Identify related plugins that discuss this domain
    - Document expected references for cross-plugin consistency

    **Review Skill Integration:**

    - Does this plugin include review skills (`review: true` frontmatter)?
    - How will `/review {domain}` discover these skills?
    - What review concerns does this plugin uniquely address?

    **Duplication Prevention:**

    - What knowledge exists in other plugins that should NOT be duplicated?
    - Document "reference instead of duplicate" decisions

    **Integration Planning Table:**
    | Direction | Other Plugin | Skill | Integration Type |
    |-----------|--------------|-------|------------------|
    | Outbound | react-19 | using-use-hook | Reference in async patterns |
    | Inbound | nextjs-16 | using-form-actions | Should reference this plugin |
    | Review | review | reviewing-\* | Auto-discovery via frontmatter |

18. **Map Composition Patterns**
    - Identify related plugins
    - Document cross-references using `@plugin-name/skills/skill-name`
    - Show how plugins layer (e.g., react-19 + nextjs-16 + tailwind-4)

**CHECKPOINT 2: Architecture & Integration**

Before generating document, present summary and confirm:

```markdown
## Architecture for {plugin-name}

**Skills:** {N} total ({teaching} teaching, {review} review)
**Hook Triggers:** {file-patterns} → recommends {skills}
**Integration:** {N} outbound refs, {N} inbound refs expected
**Boundaries:** Owns {domain}, delegates {concern} to {other-plugin}
```

Use AskUserQuestion: "Generate design document?" with single option "Approve and generate".
User can select "Other" to request revisions.

**Phase 6: Implementation Planning**

19. **Create Phased Implementation Plan**

    - Phase 1: Core skills
    - Phase 2: Intelligent hooks
    - Phase 3: Integration and testing
    - Phase 4: Refinement

20. **Define Success Metrics**

    - Effectiveness: What does success look like?
    - Efficiency: Performance targets
    - Extensibility: Composition goals

21. **Identify Risks and Mitigation**
    - List potential risks (3-5)
    - For each: mitigation strategy and fallback

**Phase 7: Document Generation**

22. **Generate Design Document**

    Create `$ARGUMENTS/PLUGIN-DESIGN.md` with structure:

    ````markdown
    # [Plugin Name] Plugin Design

    **Date:** [current date]
    **Status:** Draft Design
    **Author:** Design Session with Claude Code

    ## Overview

    [2-3 paragraph summary of plugin purpose and approach]

    ## Problem Statement

    [3-5 specific problems this plugin solves]
    [Why these problems matter]
    [Context about the domain]

    ## Core Design Principles

    ### 1. No Agents [or: Why We Use/Don't Use Agents]

    [Decision and rationale]

    ### 2. No Commands [or: Command Strategy]

    [Decision and rationale]

    ### 3. No Core MCP Servers [or: MCP Strategy]

    [Decision and rationale]

    ### 5. Intelligent Skill Activation

    [How hooks intelligently remind parent of available skills based on context]

    ## Architecture

    ### Plugin Components

    **Skills ([N] total)**

    - Structure and authoring: see @docs/claude-code/skills.md
    - Progressive disclosure strategy for plugin architecture

    **Hooks ([N] event handlers)**

    - SessionStart: Initialize session state (runs once)
    - PreToolUse: Intelligent skill reminder based on file patterns
    - Additional validation hooks if needed
    - Fast execution (< 100ms)
    - Lifecycle-managed with JSON state tracking

    **Scripts ([N] shared utilities)**

    All hooks should source @marketplace-utils/hook-lifecycle.sh for standardized infrastructure.

    - **Use marketplace-utils/ for common operations:**
      - hook-lifecycle.sh: Hook initialization, input parsing, responses
      - session-management.sh: Session state, recommendation deduplication
      - file-detection.sh: File type detection, framework detection
      - logging.sh: Structured logging with levels
    - **Plugin-specific scripts** (as needed):
      - Domain-specific anti-pattern detection
      - Custom validation rules
    - Fast, focused, single-purpose
    - **STRONGLY PREFER bash scripts with marketplace-utils helpers**:
      - Validation, pattern matching, file analysis
      - Faster than LLM-based validation
      - Reusable across all plugin components

    **Knowledge (shared research)**

    - Comprehensive domain documentation
    - Accessible by all components
    - Single source of truth

    ## Skill Structure

    See @docs/claude-code/skills.md for complete skill authoring guidelines including:

    - Naming conventions (gerund form, kebab-case)
    - SKILL.md file format and frontmatter requirements
    - Supporting files and references/ subdirectory structure
    - Best practices for descriptions and tool restrictions

    ## Intelligent Hook System

    ### Session Lifecycle Management

    See @docs/claude-code/hooks.md for hook events and schemas.
    See @marketplace-utils/docs/HOOK-DEVELOPMENT.md for complete development guide.

    **Standardized Hook Infrastructure:**

    All hooks MUST use marketplace-utils/hook-lifecycle.sh:

    ```bash
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

    init_hook "plugin-name" "hook-name"

    input=$(read_hook_input)
    tool_name=$(get_input_field "tool_name")
    file_path=$(get_input_field "tool_input.file_path")

    # Hook logic using marketplace-utils helpers...

    pretooluse_respond "allow"
    exit 0
    ```

    **For this plugin's design document, include:**

    **Activation Rules Table:**

    | Pattern    | Triggered Skills | Rationale | Frequency        |
    | ---------- | ---------------- | --------- | ---------------- |
    | [pattern1] | [skills]         | [why]     | Once per session |
    | [pattern2] | [skills]         | [why]     | Once per session |
    | [pattern3] | [skills]         | [why]     | Once per session |

    **Hook Scripts:**

    - `scripts/init-session.sh` - SessionStart hook (sources hook-lifecycle.sh)
    - `scripts/recommend-skills.sh` - PreToolUse hook (uses session-management.sh)
    - `scripts/validate-[concern].sh` - PostToolUse validation hooks (uses file-detection.sh)

    **Implementation:** Use @marketplace-utils/hook-templates/ as starting point.

    ### Additional Hooks

    [List any PostToolUse or other hooks if needed beyond session lifecycle]

    ## File Structure

    See @docs/claude-code/plugins.md for official plugin directory structure.

    Design-specific additions for this plugin:

    ```tree
    [plugin-name]/
    ├── scripts/
    │   ├── init-session.sh          # MANDATORY: SessionStart - initialize state JSON
    │   ├── recommend-skills.sh      # MANDATORY: PreToolUse - once-per-session recommendations
    │   └── validate-[aspect].sh     # Additional validation scripts as needed
    └── knowledge/
        └── [domain]-comprehensive.md # Shared research accessible to all components
    ```

    Standard auto-discovered directories (skills/, commands/, agents/) and configured components (hooks/, .mcp.json) follow official structure.

    ## Integration with Other Plugins

    ### Plugin Boundaries

    [Define what's in scope vs out of scope]

    **This plugin provides:**

    - [Responsibility 1]
    - [Responsibility 2]

    **Related plugins provide:**

    - `@[plugin-1]`: [What it provides]
    - `@[plugin-2]`: [What it provides]

    ### Composition Patterns

    **Skill References:**
    Other plugins can reference skills: `@$1/[topic]`

    **Knowledge Sharing:**
    Skills can reference: `@$1/knowledge/[document]`

    **Hook Layering:**
    Multiple plugins can have PreToolUse hooks - they compose additively

    ## Plugin Metadata

    See @docs/claude-code/plugins.md for complete plugin.json schema.

    Minimum required fields:

    ```json
    {
      "name": "$1",
      "version": "1.0.0",
      "description": "[description]"
    }
    ```

    Note: Component paths (skills/, commands/, agents/) are auto-discovered. Only hooks and MCP servers need explicit configuration.

    ## Implementation Strategy

    ### Phase 1: Core Skills

    - Write [N] skill files following @docs/claude-code/skills.md authoring guidelines
    - Create SKILL.md for each with proper frontmatter
    - Add skill-specific references as needed

    ### Phase 2: Intelligent Hooks

    - Design activation rules based on file patterns
    - Implement PreToolUse hook with pattern matching
    - Create validation scripts in scripts/
    - Test hook performance (< 100ms)

    ### Phase 3: Knowledge Base

    - Consolidate research into knowledge/
    - Ensure comprehensive coverage
    - Link from skills using references

    ### Phase 4: Integration & Testing

    - Test skill activation with real files
    - Verify hook triggering logic
    - Test composition with related plugins
    - Performance tuning

    ### Phase 5: Refinement

    - Gather feedback on activation accuracy
    - Refine skill descriptions
    - Optimize hook patterns
    - Documentation polish

    ## Success Metrics

    **Effectiveness:**

    - Skills activate appropriately based on file context
    - Parent Claude reminded of relevant skills at right time
    - Mistakes prevented before code is written

    **Efficiency:**

    - Hook execution < 100ms
    - Skills load progressively (not all at once)
    - No context bloat from over-activation

    **Extensibility:**

    - Clear boundaries with other plugins
    - Skill references work across plugins
    - Hooks compose without conflicts

    ## Risk Mitigation

    **Risk: Hook pattern matching too broad**

    - Mitigation: Use specific patterns, test with real files
    - Fallback: Allow users to configure activation rules

    **Risk: Too many skills activated at once**

    - Mitigation: Use precise file patterns, group related skills
    - Fallback: Summarize available skills instead of listing all

    **Risk: Hook execution too slow**

    - Mitigation: Use fast pattern matching (grep, case statements)
    - Fallback: Cache results, reduce pattern complexity

    **Risk: Skills overlap with other plugins**

    - Mitigation: Clear domain boundaries in design
    - Fallback: Document intended composition patterns

    [Add 1-2 more risks specific to plugin domain]

    ## Conclusion

    This plugin follows official Claude Code structure for organization. The intelligent hook system ensures skills are surfaced at the right time based on file context, reducing cognitive load while maximizing relevance.

    **Key innovations:**

    - Intelligent PreToolUse hook for contextual activation
    - Knowledge/ for shared research
    - Scripts/ for reusable validation logic

    **Implementation ready:** All components defined, phased approach clear, success metrics established.

    ```

    ```
    ````

23. **Verify Completeness**
    - [ ] All sections present
    - [ ] Intelligent hook design included
    - [ ] File structure follows official docs
    - [ ] Knowledge/ and scripts/ directories defined
    - [ ] File saved to $ARGUMENTS/PLUGIN-DESIGN.md

**Phase 8: Final Validation**

24. **Run Quality Checks**

    - Document has 10+ major sections
    - PreToolUse hook has activation rules
    - Plugin boundaries clear
    - Integration planning table complete
    - Implementation plan realistic

25. **Generate Summary**
    Output:

    ```text
    Plugin: $1
    Design document: $ARGUMENTS/PLUGIN-DESIGN.md

    Structure: Official Claude Code (skills/, hooks/, knowledge/, scripts/)

    Components:
    - [N] Teaching Skills
    - [N] Review Skills
    - 1 Intelligent PreToolUse Hook
    - [N] Additional Hooks (if needed)
    - [N] Scripts
    - Shared knowledge base

    Status: Ready for review and implementation
    ```

<constraints>
**Document Format Requirements:**
- MUST save to $ARGUMENTS/PLUGIN-DESIGN.md
- MUST follow structure from docs/plans/2025-11-19-react-19-plugin-design.md
- MUST include all required sections

**Structure Requirements:**

- MUST use official directories: skills/, commands/, agents/, hooks/
- MUST include knowledge/ for shared research
- MUST include scripts/ for shared validation/helper scripts
- NEVER use custom directories like forms/, state/, etc.
- NEVER require exports field (use auto-discovery)

**Skill Organization:**

- Follow naming conventions from @docs/claude-code/skills.md (gerund form, kebab-case)
- MUST limit to 6-10 teaching skills + 1-2 review skills
- EACH skill can have optional `references/` subdirectory (see @docs/claude-code/skills.md)
- SHARED knowledge goes in `knowledge/` directory at root

**Hook Design Requirements:**

- MUST design intelligent PreToolUse hook
- MUST use marketplace-utils/hook-lifecycle.sh for standardized infrastructure
- MUST include hooks that source hook-lifecycle.sh:

  **SessionStart hook** (`scripts/init-session.sh`):

  - Sources hook-lifecycle.sh and calls `init_hook(plugin, hook)`
  - Session state automatically managed via session-management.sh
  - Location: `/tmp/claude-session-${CLAUDE_SESSION_PID}.json` (shared across plugins)

  **PreToolUse hook** (`scripts/recommend-skills.sh`):

  - Uses `has_shown_recommendation(plugin, skill)` to check state
  - Uses file-detection.sh helpers for file type detection
  - Calls `mark_recommendation_shown(plugin, skill)` after showing
  - Prevents context bloat from repeated recommendations

- MUST use file-detection.sh: `is_typescript_file()`, `detect_framework()`
- MUST keep total execution < 100ms
- MUST create activation rules table with "Frequency" column showing "Once per session"
- SCRIPTS go in `scripts/` directory, source marketplace-utils utilities
- STRONGLY PREFER bash scripts with marketplace-utils helpers:
  - hook-lifecycle.sh for input/output handling
  - session-management.sh for state tracking
  - file-detection.sh for file type detection

**Decision Framework Requirements:**

- MUST work through design hierarchy in order
- MUST justify every inclusion AND exclusion
- MUST define clear plugin boundaries
- MUST document composition with other plugins

**Implementation Requirements:**

- MUST provide phased approach
- MUST define success metrics
- MUST identify risks with mitigation
- MUST be actionable and realistic
  </constraints>

<validation>
After generating the design document, you MUST verify:

1. **File Location Check:**

   ```bash
   ls -la $ARGUMENTS/PLUGIN-DESIGN.md
   ```

   File exists in $ARGUMENTS/

2. **Structure Compliance:**

   - [ ] Uses official directories (skills/, hooks/, knowledge/, scripts/)
   - [ ] No custom directories like forms/, state/, etc.
   - [ ] No exports field in plugin.json
   - [ ] Intelligent PreToolUse hook designed

3. **Completeness Check:**

   ```bash
   grep -c "^## " $ARGUMENTS/PLUGIN-DESIGN.md
   ```

   Should have 10+ major sections

4. **Content Check:**
   - [ ] Activation rules table present
   - [ ] File structure tree matches official docs
   - [ ] Knowledge/ directory included
   - [ ] Scripts/ directory included
   - [ ] Skill naming uses gerund form verb
   - [ ] Hook execution time < 100ms
   - [ ] Hooks reference marketplace-utils/hook-lifecycle.sh

**Failure Handling:**
If validation fails, you MUST:

- Mark current todo as in_progress
- Identify missing sections or incorrect structure
- Fix issues
- Re-run validation until complete
  </validation>

<output>

**CRITICAL: Use the `writing-concisely` skill tool BEFORE writing the design document.**

Save design document to: **$ARGUMENTS/PLUGIN-DESIGN.md**

The document provides:

1. **Clear Problem Definition**

   - What problems this plugin solves
   - Context and target users

2. **Official Structure Compliance**

   - Uses skills/, hooks/, knowledge/, scripts/
   - Auto-discovery (no exports needed)

3. **Intelligent Hook Design**

   - File extension detection
   - Path pattern matching
   - Activation rules table
   - Performance targets

4. **Detailed Architecture**

   - All skills
   - Hook activation logic
   - Knowledge organization
   - Script purposes

5. **Integration Plan**

   - Plugin boundaries
   - Composition with other plugins
   - Cross-plugin references

6. **Implementation Roadmap**
   - Phased approach
   - Success metrics
   - Risk mitigation

Inform user: "Design document created at $ARGUMENTS/PLUGIN-DESIGN.md following official Claude Code structure with intelligent hook system."
</output>

<examples>
**Good Hook Activation Rule:**

```markdown
| Pattern                        | Triggered Skills               | Rationale              |
| ------------------------------ | ------------------------------ | ---------------------- |
| _.tsx, _.jsx                   | react skills                   | React component file   |
| app/page.tsx                   | react skills + Next.js context | Next.js page component |
| \*Form.tsx                     | form related skills            | Form component pattern |
| file contains `useActionState` | using-use-action-state skill   | Server Action pattern  |
```

**Good File Structure Example:**

See @docs/claude-code/plugins.md for complete structure reference.

```tree
react-19/
├── .claude-plugin/
│   └── plugin.json              # Required manifest
├── skills/                       # Auto-discovered
│   ├── using-the-use-hook/
│   │   └── SKILL.md
│   └── validating-type-assertions/
│       └── SKILL.md
├── hooks/                        # Must configure in plugin.json
│   └── hooks.json
├── scripts/                      # Design-specific: lifecycle management
│   ├── init-session.sh
│   └── recommend-skills.sh
└── knowledge/                    # Design-specific: shared research
    └── react-19-comprehensive.md
```

</examples>

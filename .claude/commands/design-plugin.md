---
description: Generate comprehensive plugin design document from research and philosophy
argument-hint: <plugin-name>
allowed-tools: Read, Glob, Write, TodoWrite, Bash
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

   See @docs/claude-code/hooks.md for:

   - Complete hook event reference (SessionStart, PreToolUse, PostToolUse, etc.)
   - Hook input/output schemas and exit codes
   - Performance guidelines (< 100ms ideal, < 500ms acceptable)
   - Common hook patterns (session state, file validation, contextual loading)

   **Design Requirements for This Plugin:**

   **SessionStart hook** - Initialize session state

   - Use session state JSON pattern from hooks.md
   - Track recommendation types for this plugin's contexts
   - Create `/tmp/claude-[plugin]-session.json` with boolean flags

   **PreToolUse hook** - Contextual skill recommendations

   - Use session state pattern to recommend skills once per session per context type
   - Detect context from file extension, path patterns, or content
   - Early exit if no relevant context detected
   - Update session state after first recommendation shown

   **Validation hooks** (if needed)

   - Use file pattern validation pattern from hooks.md
   - Detect anti-patterns specific to this plugin's domain
   - Exit code 2 to block operations with clear error messages

   **Performance targets** (see @docs/claude-code/hooks.md performance guidelines):

   - Total hook execution < 100ms ideal
   - Individual scripts < 50ms
   - Early exit patterns for irrelevant files
   - Bash scripts preferred over prompt-based hooks for speed

   **Implementation:** Complete bash examples will be in PLUGIN-DESIGN-TEMPLATE.md for copy-paste.

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

17. **Map Composition with Other Plugins**
    - Identify related plugins
    - Document cross-references using `@plugin-name/[plugin-name]`
    - Show how plugins layer (e.g., react-19 + nextjs-15)

**Phase 6: Implementation Planning**

18. **Create Phased Implementation Plan**

    - Phase 1: Core skills
    - Phase 2: Intelligent hooks
    - Phase 3: Integration and testing
    - Phase 4: Refinement

19. **Define Success Metrics**

    - Effectiveness: What does success look like?
    - Efficiency: Performance targets
    - Extensibility: Composition goals

20. **Identify Risks and Mitigation**
    - List potential risks (3-5)
    - For each: mitigation strategy and fallback

**Phase 7: Document Generation**

21. **Generate Design Document**

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

    - **Lifecycle scripts** (MANDATORY):
      - `init-session.sh`: SessionStart - creates/resets state JSON
      - `recommend-skills.sh`: PreToolUse - once-per-session recommendations
    - **Validation scripts** (as needed):
      - Pattern matching, file analysis, code validation
    - Used by hooks for validation
    - Used by skills for checks
    - Used by commands for operations
    - Fast, focused, single-purpose
    - **STRONGLY PREFER bash scripts for deterministic operations** (see @docs/claude-code/hooks.md):
      - Validation, pattern matching, file analysis
      - Faster than LLM-based validation
      - Cacheable and optimizable by Claude Code
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

    See @docs/claude-code/hooks.md for:

    - Complete hook event documentation (SessionStart, PreToolUse, etc.)
    - Session state JSON pattern with complete bash examples
    - File pattern validation patterns
    - Performance optimization strategies

    **For this plugin's design document, include:**

    **Activation Rules Table:**
    | Pattern | Triggered Skills | Rationale | Frequency |
    |---------|------------------|-----------|-----------|
    | [pattern1] | [skills] | [why] | Once per session |
    | [pattern2] | [skills] | [why] | Once per session |
    | [pattern3] | [skills] | [why] | Once per session |

    **Hook Scripts:**

    - `scripts/init-session.sh` - SessionStart hook (see hooks.md pattern)
    - `scripts/recommend-skills.sh` - PreToolUse hook (see hooks.md pattern)
    - `scripts/validate-[concern].sh` - Validation hooks as needed

    **Implementation:** Complete bash examples are in:

    1. @docs/claude-code/hooks.md (patterns section)
    2. PLUGIN-DESIGN-TEMPLATE.md (copy-paste templates)

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

22. **Verify Completeness**
    - [ ] All sections present
    - [ ] Intelligent hook design included
    - [ ] File structure follows official docs
    - [ ] Knowledge/ and scripts/ directories defined
    - [ ] File saved to $ARGUMENTS/PLUGIN-DESIGN.md

**Phase 8: Final Validation**

23. **Run Quality Checks**

    - Document has 10+ major sections
    - PreToolUse hook has activation rules
    - Plugin boundaries clear
    - Implementation plan realistic

24. **Generate Summary**
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
- MUST include session lifecycle scripts:

  **SessionStart hook** (`scripts/init-session.sh`):

  - Creates/resets session state JSON file
  - Location: `/tmp/claude-[plugin]-session.json`
  - Structure: `{"recommendations_shown": {"[type]": false, ...}}`
  - Runs once at session start

  **PreToolUse hook** (`scripts/recommend-skills.sh`):

  - Reads session state JSON programmatically
  - Checks relevant boolean for current file context
  - If false: shows recommendation, updates boolean to true
  - If true: exits silently (< 1ms)
  - Uses sed/grep for JSON manipulation (no external dependencies)
  - Prevents context bloat from repeated recommendations

- MUST check file extension (.tsx, .jsx, etc.)
- MUST check file path patterns (app/, components/, etc.)
- MUST keep total execution < 100ms
- MUST create activation rules table with "Frequency" column showing "Once per session"
- SCRIPTS go in `scripts/` directory, used by hooks
- STRONGLY PREFER bash scripts over prompt-based hooks (see @docs/claude-code/hooks.md):
  - Use for deterministic operations: pattern matching, validation, file analysis
  - Faster and cacheable

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

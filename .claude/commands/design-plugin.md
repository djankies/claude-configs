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
@typescript/PLUGIN-DESIGN.md

## Official Plugin Structure

Per Claude Code documentation:

- `skills/` - Auto-discovered, organize with concern prefixes (e.g., `HOOKS-use-hook/`)
- `commands/` - Auto-discovered slash commands
- `agents/` - Auto-discovered agent definitions
- `hooks/` - Must specify in hooks.json
- `knowledge/` - Shared research accessible to all components
- `scripts/` - Shared validation scripts used by hooks/skills

## Naming Convention

- Concern prefix: ALL CAPS (HOOKS, FORMS, STATE, etc.)
- Topic: lowercase-with-hyphens
- Format: `[CONCERN]-[topic]/`
- Examples: `HOOKS-use-hook/`, `FORMS-server-actions/`, `STATE-context-api/`

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
   - Identify distinct conceptual areas (these become concern prefixes)

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
   - Identify concerns (4-8 typical: HOOKS, FORMS, STATE, TESTING, etc.)
   - Design 6-10 teaching skills with concern prefixes
   - Design 1-2 review skills (prefix: `REVIEW-`)
   - For each skill: `[CONCERN]-[topic]/SKILL.md`
   - Each skill can have `references/` subdirectory for skill-specific docs
   - Shared research goes in `$ARGUMENTS/knowledge/` directory

8. **Level 3: Hooks - Intelligent skill activation with lifecycle management**

   - Design PreToolUse hook that intelligently reminds which skills are available
   - Based on file extension (.tsx, .jsx → react skills)
   - Based on file path patterns (app/page.tsx → nextjs skills)
   - Based on file content patterns (detected via grep/analysis)
   - Keep checks fast (< 100ms total)
   - Early exit with no output if trigger condition is not met, ideally condition is placed within hooks.json to prevent the script from being called at all if the condition is not met.
   - Design 1-3 additional validation hooks if needed
   - Hooks use scripts from `scripts/` directory

   - **MANDATORY: Session lifecycle management**:

     **SessionStart hook** (`scripts/init-session.sh`):

     - Creates/resets session state JSON file
     - Location: `/tmp/claude-[plugin]-session.json`
     - Structure: `{"recommendations_shown": {"[type]": false, ...}}`
     - Runs once at session start
     - Fast: < 5ms (simple JSON write)
     - should handle scenarios where file already exists from another session or plugin. all plugins should be able to share the same session state file.

     **PreToolUse hook** (`scripts/recommend-skills.sh`):

     - Reads session state JSON programmatically
     - Checks relevant boolean for current file context
     - If false: shows recommendation, updates boolean to true
     - If true: exits silently (< 1ms)
     - Uses `jq` or simple grep/sed for JSON manipulation
     - Prevents context bloat from repeated recommendations

   - **STRONGLY ENCOURAGE bash scripts over prompt-based hooks**:

     - Deterministic: Same input = same output
     - Optimizable: Can be cached, parallelized
     - Fast: No LLM inference overhead
     - Reusable: Share scripts across hooks/skills/commands
     - Example: File pattern detection, validation checks, code analysis

     Best practices:

     - Keep output as minimal as possible.
     - ONLY output bare minimum and nothing else
     - Keep scripts simple and focused on a single purpose.
     - handle errors and edge cases gracefully -> output message "SHARE WITH USER: [script-filepath] failed to run"

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

    - Skills: List all with concern-prefixed names
    - Hooks: List with intelligent activation logic
    - Scripts: List validation/helper scripts
    - Knowledge: Shared research documents

13. **Organize Skills by Concern**

    - Group related skills (4-8 concerns)
    - Use naming: `[CONCERN]-[topic]/`
    - Examples:
      - `HOOKS-use-hook/`
      - `HOOKS-action-state/`
      - `FORMS-server-actions/`
      - `STATE-context-api/`
      - `REVIEW-patterns/`

14. **Design Intelligent Hook System**

    - PreToolUse hook checks file patterns:
      - Extension matching (.tsx → react skills)
      - Path matching (app/ → nextjs skills)
      - Content detection (import patterns)
    - Create activation rules table
    - Design fast, targeted reminders
    - **PREFER bash scripts for all deterministic operations**:
      - Pattern matching, validation, file analysis
      - Faster and more cacheable than LLM prompts
      - Reusable across multiple hooks

15. **Design File Structure**
    - Official structure with concern-prefixed skills
    - plugin.json with minimal required fields
    - Knowledge organization

**Phase 5: Integration & Composition**

16. **Define Plugin Boundaries**

    - What domain does this plugin own?
    - What domains do related plugins own?
    - Where are the clean separation points?

17. **Map Composition with Other Plugins**
    - Identify related plugins
    - Document cross-references using `@plugin-name/[concern]-[topic]`
    - Show how plugins layer (e.g., react-19 + nextjs-15)

**Phase 6: Implementation Planning**

18. **Create Phased Implementation Plan**

    - Phase 1: Core skills (time estimate)
    - Phase 2: Intelligent hooks (time estimate)
    - Phase 3: Integration and testing (time estimate)
    - Phase 4: Refinement (time estimate)

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

    ### 4. Concern-Prefix Organization

    [How concern prefixes organize skills while following official structure]

    ### 5. Intelligent Skill Activation

    [How hooks intelligently remind parent of available skills based on context]

    ## Architecture

    ### Plugin Components

    **Skills ([N] total across [M] concerns)**

    - Organized with concern prefixes: `[CONCERN]-[topic]/`
    - Each skill contains SKILL.md
    - Optional `references/` for skill-specific docs
    - Progressive disclosure strategy

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
    - **STRONGLY PREFER bash scripts for deterministic operations**:
      - Validation, pattern matching, file analysis
      - 100x faster than LLM-based validation
      - Cacheable and optimizable by Claude Code
      - Reusable across all plugin components
      - Examples: grep patterns, AST parsing, regex checks, JSON state management

    **Knowledge (shared research)**

    - Comprehensive domain documentation
    - Accessible by all components
    - Single source of truth

    ## Skill Structure

    ### Naming Convention

    `[CONCERN]-[topic]/`

    **Format:**

    - Concern prefix: ALL CAPS (HOOKS, FORMS, STATE, TESTING, etc.)
    - Topic: lowercase-with-hyphens
    - Separator: single hyphen

    Examples:

    - `HOOKS-use-hook/` - Teaching use() API
    - `FORMS-server-actions/` - Server Actions patterns
    - `STATE-context-api/` - Context patterns
    - `REVIEW-patterns/` - Code review skill

    ### Concerns

    [List 4-8 concerns with rationale]

    ### Skill Breakdown by Concern

    #### Concern: [CONCERN NAME]

    **Skills:**

    - `[CONCERN]-[topic-1]/` - [description]
    - `[CONCERN]-[topic-2]/` - [description]

    [Repeat for each concern]

    ## Intelligent Hook System

    ### Session Lifecycle Management

    The plugin uses a JSON state file to track which recommendations have been shown during the current session.

    **SessionStart Hook: Initialize State**

    Implementation: `scripts/init-session.sh`

    ```bash
    #!/bin/bash
    # scripts/init-session.sh
    # Creates/resets session state on session start

    STATE_FILE="/tmp/claude-[plugin-name]-session.json"

    # Create JSON state file with all booleans set to false
    cat > "$STATE_FILE" <<EOF
    {
      "session_id": "$$-$(date +%s)",
      "recommendations_shown": {
        "react_skills": false,
        "nextjs_skills": false,
        "form_skills": false,
        "state_skills": false
      }
    }
    EOF

    echo "Session initialized: $STATE_FILE"
    ```

    **PreToolUse Hook: Contextual Skill Recommendations**

    Implementation: `scripts/recommend-skills.sh`

    ```bash
    #!/bin/bash
    # scripts/recommend-skills.sh
    # Recommends skills once per session based on file context

    STATE_FILE="/tmp/claude-[plugin-name]-session.json"

    # Exit if state file doesn't exist (session not initialized)
    [[ ! -f "$STATE_FILE" ]] && exit 0

    # Get file info from hook input
    FILE_PATH="$1"
    FILE_EXT="${FILE_PATH##*.}"

    # Determine recommendation type based on file pattern
    RECOMMENDATION_TYPE=""
    case "$FILE_EXT" in
      tsx|jsx)
        RECOMMENDATION_TYPE="react_skills"
        SKILLS="HOOKS-*, FORMS-*, STATE-*"
        MESSAGE="📚 React Skills available: $SKILLS"
        ;;
      ts|js)
        if [[ "$FILE_PATH" == *"/app/"* ]]; then
          RECOMMENDATION_TYPE="nextjs_skills"
          SKILLS="All React skills + Next.js patterns"
          MESSAGE="📚 Next.js detected: $SKILLS"
        fi
        ;;
    esac

    # Exit if no recommendation needed for this file type
    [[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

    # Check if this recommendation was already shown
    SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

    if [[ -z "$SHOWN" ]]; then
      # Show recommendation
      echo "$MESSAGE"
      echo "Use Skill tool to activate when needed."

      # Update state file: set boolean to true
      sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
    fi

    # Exit silently if already shown (< 1ms)
    exit 0
    ```

    **Key Design Patterns:**

    - ✅ **Centralized state**: Single JSON file tracks all recommendation types
    - ✅ **Session lifecycle**: SessionStart hook creates/resets state
    - ✅ **Programmatic updates**: sed/grep for fast JSON manipulation (no jq dependency)
    - ✅ **Type-specific tracking**: Different booleans for different recommendation types
    - ✅ **Fast**: < 1ms after recommendation shown, < 5ms for first show
    - ✅ **Non-intrusive**: Silent after first recommendation per type
    - ✅ **Automatic reset**: New session = new state file

    **File Extension Detection:**

    ```bash
    case "$FILE_EXT" in
      .tsx|.jsx)
        echo "Available skills: [list relevant skills]"
        ;;
      .ts|.js)
        echo "Available skills: [list relevant skills]"
        ;;
    esac
    ```

    **Path Pattern Detection:**

    ```bash
    if [[ "$FILE_PATH" == *"/app/"* ]]; then
      # Next.js App Router context
    elif [[ "$FILE_PATH" == *"/components/"* ]]; then
      # Component development context
    fi
    ```

    **Activation Rules Table:**
    | Pattern | Triggered Skills | Rationale | Frequency |
    |---------|------------------|-----------|-----------|
    | _.tsx, _.jsx | HOOKS-_, FORMS-_, STATE-* | React file editing | Once per session |
    | app/page.tsx | Next.js related | Next.js routing | Once per session |
    | *Form*.tsx | FORMS-*, STATE-\* | Form components | Once per session |

    **Performance:**

    - File extension check: ~1ms
    - Path pattern check: ~5ms
    - State file check: ~1ms
    - Total hook execution: < 10ms
    - Subsequent calls (after state file exists): < 1ms

    ### Additional Hooks

    [List any PostToolUse or other hooks if needed]

    ## File Structure

    ```tree
    [plugin-name]/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── skills/
    │   ├── [CONCERN-1]-[topic-1]/
    │   │   ├── SKILL.md
    │   │   └── references/          # Optional: skill-specific docs
    │   │       └── examples.md
    │   ├── [CONCERN-1]-[topic-2]/
    │   ├── [CONCERN-2]-[topic-1]/
    │   └── REVIEW-[domain]/
    ├── commands/                     # If commands needed
    │   └── [command].md
    ├── agents/                       # If agents needed
    │   └── [agent].md
    ├── hooks/
    │   └── hooks.json
    ├── scripts/
    │   ├── init-session.sh          # MANDATORY: SessionStart - initialize state JSON
    │   ├── recommend-skills.sh      # MANDATORY: PreToolUse - once-per-session recommendations
    │   ├── check-file-patterns.sh
    │   └── validate-[aspect].sh
    ├── knowledge/
    │   └── [domain]-comprehensive.md
    └── README.md
    ```

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
    Other plugins can reference skills: `@$1/[CONCERN]-[topic]`

    **Knowledge Sharing:**
    Skills can reference: `@$1/knowledge/[document]`

    **Hook Layering:**
    Multiple plugins can have PreToolUse hooks - they compose additively

    ## Plugin Metadata

    ```json
    {
      "name": "$1",
      "version": "1.0.0",
      "description": "[description]",
      "author": {
        "name": "Plugin Author",
        "email": "author@example.com"
      },
      "keywords": ["[keyword1]", "[keyword2]"],
      "engines": {
        "claude-code": ">=1.0.0"
      }
    }
    ```

    Note: No `exports` field needed - uses standard auto-discovery

    ## Implementation Strategy

    ### Phase 1: Core Skills ([time estimate])

    - Write [N] skill files with concern prefixes
    - Organize by domain ([M] concerns)
    - Create SKILL.md for each
    - Add skill-specific references as needed

    ### Phase 2: Intelligent Hooks ([time estimate])

    - Design activation rules based on file patterns
    - Implement PreToolUse hook with pattern matching
    - Create validation scripts in scripts/
    - Test hook performance (< 100ms)

    ### Phase 3: Knowledge Base ([time estimate])

    - Consolidate research into knowledge/
    - Ensure comprehensive coverage
    - Link from skills using references

    ### Phase 4: Integration & Testing ([time estimate])

    - Test skill activation with real files
    - Verify hook triggering logic
    - Test composition with related plugins
    - Performance tuning

    ### Phase 5: Refinement ([time estimate])

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

    This plugin follows official Claude Code structure while using concern prefixes for organization. The intelligent hook system ensures skills are surfaced at the right time based on file context, reducing cognitive load while maximizing relevance.

    **Key innovations:**

    - Concern-prefix naming for clarity
    - Intelligent PreToolUse hook for contextual activation
    - Knowledge/ for shared research
    - Scripts/ for reusable validation logic

    **Implementation ready:** All components defined, phased approach clear, success metrics established.

    ```

    ```
    ````

22. **Verify Completeness**
    - [ ] All sections present
    - [ ] All skills with concern prefixes
    - [ ] Intelligent hook design included
    - [ ] File structure follows official docs
    - [ ] Knowledge/ and scripts/ directories defined
    - [ ] File saved to $ARGUMENTS/PLUGIN-DESIGN.md

**Phase 8: Final Validation**

23. **Run Quality Checks**

    - Document has 10+ major sections
    - All skills use concern-prefix naming
    - PreToolUse hook has activation rules
    - Plugin boundaries clear
    - Implementation plan realistic

24. **Generate Summary**
    Output:

    ````
    Plugin: $1
    Design document: $ARGUMENTS/PLUGIN-DESIGN.md

        Structure: Official Claude Code (skills/, hooks/, knowledge/, scripts/)
        Organization: Concern-prefix naming

        Components:
        - [N] Teaching Skills (organized by [M] concern prefixes)
        - [N] Review Skills
        - 1 Intelligent PreToolUse Hook
        - [N] Additional Hooks (if needed)
        - [N] Scripts
        - Shared knowledge base

        Implementation estimate: [total time]
        Status: Ready for review and implementation
        ```

    </task>
    ````

<constraints>
**Document Format Requirements:**
- MUST save to $ARGUMENTS/PLUGIN-DESIGN.md
- MUST follow structure from docs/plans/2025-11-19-react-19-plugin-design.md
- MUST include all required sections

**Structure Requirements:**

- MUST use official directories: skills/, commands/, agents/, hooks/
- MUST organize skills with concern prefixes: `[CONCERN]-[topic]/`
- MUST include knowledge/ for shared research
- MUST include scripts/ for shared validation/helper scripts
- NEVER use custom directories like concerns/
- NEVER require exports field (use auto-discovery)

**Skill Organization:**

- MUST use concern-prefix naming with ALL CAPS concern: `HOOKS-use-hook/`, `FORMS-server-actions/`
- Concern prefix: ALL CAPS (HOOKS, FORMS, STATE, TESTING, etc.)
- Topic: lowercase-with-hyphens
- MUST limit to 6-10 teaching skills + 1-2 review skills
- MUST organize by 4-8 concern areas
- EACH skill can have optional `references/` subdirectory
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
- STRONGLY PREFER bash scripts over prompt-based hooks for:
  - Pattern matching and validation (deterministic)
  - File analysis and checks (cacheable)
  - Any operation that doesn't require LLM reasoning

**Decision Framework Requirements:**

- MUST work through design hierarchy in order
- MUST justify every inclusion AND exclusion
- MUST define clear plugin boundaries
- MUST document composition with other plugins

**Implementation Requirements:**

- MUST provide phased approach
- MUST include time estimates
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
   - [ ] Skills use concern-prefix naming
   - [ ] No custom directories like concerns/
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
   - [ ] Skill naming uses concern prefixes
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
   - Concern-prefix organization
   - Auto-discovery (no exports needed)

3. **Intelligent Hook Design**

   - File extension detection
   - Path pattern matching
   - Activation rules table
   - Performance targets

4. **Detailed Architecture**

   - All skills with concern prefixes
   - Hook activation logic
   - Knowledge organization
   - Script purposes

5. **Integration Plan**

   - Plugin boundaries
   - Composition with other plugins
   - Cross-plugin references

6. **Implementation Roadmap**
   - Phased approach
   - Time estimates
   - Success metrics
   - Risk mitigation

Inform user: "Design document created at $ARGUMENTS/PLUGIN-DESIGN.md following official Claude Code structure with intelligent hook system."
</output>

<examples>
**Good Skill Naming:**
```
skills/
├── HOOKS-use-hook/
├── HOOKS-action-state/
├── FORMS-server-actions/
├── STATE-context-api/
└── REVIEW-patterns/
```

**Bad Skill Naming:**

```
skills/
├── use-hook/              # Missing concern prefix
├── hooks-use-hook/        # Concern not uppercase
├── HOOKS/                 # Directory, not skill
└── FORMS-server-actions-skill/  # Redundant "skill" suffix
```

**Good Hook Activation Rule:**

```markdown
| Pattern      | Triggered Skills             | Rationale              |
| ------------ | ---------------------------- | ---------------------- |
| _.tsx, _.jsx | HOOKS-_, FORMS-_, STATE-\*   | React component file   |
| app/page.tsx | All skills + Next.js context | Next.js page component |
| \*Form.tsx   | FORMS-_, STATE-_             | Form component pattern |
```

**Good File Structure:**

```tree
react-19/
├── skills/
│   ├── HOOKS-use-hook/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── examples.md
│   └── FORMS-server-actions/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── init-session.sh            # MANDATORY: SessionStart lifecycle
│   ├── recommend-skills.sh        # MANDATORY: Once-per-session recommendations
│   └── check-react-patterns.sh
└── knowledge/
    └── react-19-comprehensive.md
```

</examples>

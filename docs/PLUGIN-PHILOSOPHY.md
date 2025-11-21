# Claude Code Plugin System Philosophy

**Version:** 1.0
**Date:** 2025-11-19
**Purpose:** North star for all plugin development decisions

## Table of Contents

- [Core Philosophy](#core-philosophy)
- [Component Decision Framework](#component-decision-framework)
- [Decision Logic Diagrams](#decision-logic-diagrams)
- [Integration Principles](#integration-principles)
- [Anti-Patterns](#anti-patterns)
- [Examples](#examples)

---

## Core Philosophy

### The Prime Directive: Minimal Cognitive Load

**Every component must justify its existence by reducing cognitive load more than it adds.**

Users face two cognitive loads:

1. **Remembering the component exists** (discovery cost)
2. **Remembering how to use it** (usage cost)

If discovery cost + usage cost > value provided, the component fails.

### The Five Truths

#### 1. The Parent Claude Is Already Capable

Parent Claude with skills loaded can do almost anything. Adding components (agents, commands, MCP servers) creates overhead.

**Implication:** Only add components when they provide clear differentiation from parent capabilities.

#### 2. Progressive Disclosure Beats Preloading

Loading everything upfront wastes context. Loading layer-by-layer as needed maximizes efficiency.

**Implication:** Prefer skills (progressive disclosure) over agents (full context load).

#### 3. Context Is Expensive, Events Are Cheap

Context consumes tokens. Event hooks consume none until triggered.

**Implication:** Prefer hooks (event-driven) over agents (context-driven) for validation.

#### 4. Conversation Beats Commands for Complexity

Natural language handles nuance and context. Commands force users into rigid syntax.

**Implication:** Commands should be rare shortcuts for frequent, simple directives.

#### 5. Composition Over Duplication

Multiple plugins should compose cleanly without duplicating knowledge or functionality.

**Implication:** Clear boundaries, explicit extension points, shared primitives.

### Design Hierarchy

When solving a problem, evaluate solutions in this order:

1. **Can parent Claude do this with existing tools?** → Don't add anything
2. **Can a skill teach this pattern?** → Add skill
3. **Can a hook prevent this mistake?** → Add hook
4. **Is this a frequent user directive?** → Maybe add command
5. **Does this need external tools?** → Maybe add MCP server
6. **Does this need isolation + different permissions/model?** → Maybe add agent

Stop at the first "yes". Lower on the hierarchy = higher cost.

---

## Component Decision Framework

### Skills: Teaching Patterns

**Purpose:** Teach parent Claude how to do something correctly.

**Use When:**

- Teaching a pattern or best practice
- Providing domain knowledge
- Showing examples and anti-patterns
- Context loads only when relevant
- Up-to-date knowledge is important

**Don't Use When:**

- Knowledge is trivial (one sentence)
- Pattern rarely applies
- Better as inline documentation
- Global knowledge should always be available

**Key Properties:**

- Progressive disclosure (metadata → core → details)
- Can restrict tools via `allowed-tools`
- Triggered by description match
- Content is markdown with examples

**Example:** `using-react-19-hooks.md` - Teaches when/how to use new React 19 hooks

### Hooks: Preventing Mistakes

**Purpose:** Proactively catch and prevent errors before they happen.

**Use When:**

- Validating code against known rules
- Preventing security vulnerabilities
- Enforcing code standards
- Blocking deprecated patterns
- Context triggered prompt injection

**Don't Use When:**

- Validation is subjective (architectural preferences)
- Error is harmless (style preferences)
- False positives are likely
- Validation is expensive (> 1 second)

**Key Properties:**

- Event-driven (no context cost)
- Exit code 2 blocks operations
- Receives JSON stdin with tool context
- Should be fast (< 500ms ideal)

**Example:** Block `forwardRef` usage, suggest ref-as-prop alternative

### Commands: User Directives

**Purpose:** Shortcut for frequent, specific user requests.

**Use When:**

- User makes this request multiple times per day
- Request is simple and unambiguous
- Clearer than natural language explanation
- Orchestrates existing skills/tools

**Don't Use When:**

- Request needs context or explanation
- Parent can handle conversationally
- Syntax is complex to remember
- Used less than weekly

**Key Properties:**

- Orchestrates existing capabilities
- Argument interpolation for flexibility
- Should be self-documenting
- One clear purpose

**Example:** `/review review` - Orchestrates skills to review react code

### Agents: Isolated Execution

**Purpose:** Execute tasks in isolated context with different capabilities than parent.

**Use When:**

- Need different permission mode (read-only, acceptEdits)
- Need different model (haiku for speed/cost)
- Need isolated context (debugging traces, review reports)
- Task has clear input/output boundary

**Don't Use When:**

- Same tools as parent
- Same permissions as parent
- Same model as parent
- Work happens in main conversation
- Domain knowledge can be a skill

**Key Properties:**

- Separate execution context
- Can set permission mode
- Can set model
- Receives task from parent, returns result

**Example:** Debugger agent (read-only, isolated investigation)

**Critical Rule:** If an agent would just duplicate parent's context with no differentiation, it's overhead. Use a skill instead.

### MCP Servers: External Tools

**Purpose:** Provide tools parent Claude doesn't have built-in.

**Use When:**

- Need external API access (GitHub, databases)
- Need specialized parsing (AST, SQL)
- Need tool-specific functionality
- Shared across multiple plugins

**Don't Use When:**

- Built-in tools (Read, Write, Bash) suffice
- Adds startup cost for little value
- Creates external dependencies
- Could be a bash script instead

**Key Properties:**

- Process-based isolation
- Standard tool protocol
- Reusable across plugins
- Optional dependencies

**Example:** GitHub MCP server for PR operations

---

## Decision Logic Diagrams

### Diagram 1: Primary Component Selection

```
START: I want to help with X

┌─────────────────────────────────────────┐
│ Can parent Claude do X with existing   │
│ tools + natural language request?      │
└─────────────┬───────────────────────────┘
              │
        ┌─────┴─────┐
        │    YES    │ → STOP: Don't add anything
        └───────────┘
              │ NO
              ↓
┌─────────────────────────────────────────┐
│ Is X about teaching a pattern or       │
│ providing domain knowledge?             │
└─────────────┬───────────────────────────┘
              │
        ┌─────┴─────┐
        │    YES    │ → Add SKILL
        └───────────┘   - Progressive disclosure
              │ NO      - Activates when relevant
              ↓         - Teaches how to do X
┌─────────────────────────────────────────┐
│ Is X about preventing a specific error │
│ or enforcing a rule proactively?        │
└─────────────┬───────────────────────────┘
              │
        ┌─────┴─────┐
        │    YES    │ → Add HOOK
        └───────────┘   - Event-driven validation
              │ NO      - Fast execution
              ↓         - Can block operations
┌─────────────────────────────────────────┐
│ Is X a frequent user directive that    │
│ users say multiple times per day?      │
└─────────────┬───────────────────────────┘
              │
        ┌─────┴─────┐
        │    YES    │ → Add COMMAND
        └───────────┘   - Orchestrates skills
              │ NO      - Clear single purpose
              ↓         - Self-documenting
┌─────────────────────────────────────────┐
│ Does X need external tools or APIs     │
│ that Claude doesn't have built-in?     │
└─────────────┬───────────────────────────┘
              │
        ┌─────┴─────┐
        │    YES    │ → Add MCP SERVER
        └───────────┘   - External integration
              │ NO      - Optional dependency
              ↓         - Shared across plugins
┌─────────────────────────────────────────┐
│ Does X need isolated execution with    │
│ different permissions/model/context?    │
└─────────────┬───────────────────────────┘
              │
        ┌─────┴─────┐
        │    YES    │ → Add AGENT
        └───────────┘   - Isolated context
              │ NO      - Different capabilities
              ↓         - Clear input/output
┌─────────────────────────────────────────┐
│          STOP: Reconsider              │
│    X might not need a component        │
└─────────────────────────────────────────┘
```

### Diagram 2: Agent vs Skill Decision

```
START: I want to add domain expertise about Y

┌──────────────────────────────────────────┐
│ Does Y need to execute in isolation     │
│ (separate from main conversation)?      │
└──────────────┬───────────────────────────┘
               │
         ┌─────┴─────┐
    NO ←─┤           │─→ YES
         └───────────┘
            │              │
            ↓              ↓
    ┌────────────┐   ┌──────────────────────┐
    │            │   │ Does Y need different│
    │   SKILL    │   │ permissions than     │
    │            │   │ parent?              │
    └────────────┘   └──────┬───────────────┘
                            │
                      ┌─────┴─────┐
                 NO ←─┤           │─→ YES
                      └───────────┘
                         │              │
                         ↓              ↓
                 ┌────────────┐   ┌──────────┐
                 │            │   │          │
                 │   SKILL    │   │  AGENT   │
                 │            │   │          │
                 └────────────┘   └──────────┘
                         ↑              ↑
                         │              │
                 Does Y need different  │
                 model (haiku) for cost?│
                         │              │
                    NO ──┘              └── YES
```

**Key Insight:** If domain expertise has no execution requirements different from parent, it's a skill.

### Diagram 3: Command vs Conversational Request

```
START: I want users to be able to request X

┌──────────────────────────────────────────┐
│ How often will users request X?         │
└──────────────┬───────────────────────────┘
               │
         ┌─────┴─────┐
    < Weekly         > Daily
         │              │
         ↓              ↓
┌────────────────┐  ┌──────────────────────┐
│ Conversational │  │ Is X simple enough   │
│    Request     │  │ to express as        │
│                │  │ /command [args]?     │
└────────────────┘  └──────┬───────────────┘
                           │
                     ┌─────┴─────┐
                NO ←─┤           │─→ YES
                     └───────────┘
                        │              │
                        ↓              ↓
                ┌────────────────┐  ┌──────────┐
                │ Conversational │  │ COMMAND  │
                │    Request     │  │          │
                └────────────────┘  └──────────┘

Examples:
- "Review this component" (daily, simple) → COMMAND
- "Refactor this using better patterns" (weekly, needs context) → Conversational
- "Add a form with validation" (weekly, complex requirements) → Conversational
- "Check my hook dependencies" (daily, simple) → Could be command, but overlaps with linting
```

### Diagram 4: Core Plugin vs Addon Decision

```
START: Feature F for Plugin P

┌──────────────────────────────────────────┐
│ Does F work without external            │
│ dependencies or tools?                   │
└──────────────┬───────────────────────────┘
               │
         ┌─────┴─────┐
    NO ←─┤           │─→ YES
         └───────────┘
            │              │
            ↓              ↓
    ┌────────────┐   ┌──────────────────────┐
    │   ADDON    │   │ Is F used by >50% of │
    │   PLUGIN   │   │ P users?             │
    └────────────┘   └──────┬───────────────┘
                            │
                      ┌─────┴─────┐
                 NO ←─┤           │─→ YES
                      └───────────┘
                         │              │
                         ↓              ↓
                 ┌────────────┐   ┌──────────┐
                 │   ADDON    │   │   CORE   │
                 │   PLUGIN   │   │          │
                 └────────────┘   └──────────┘

Examples:
- React testing patterns (needs test runner) → ADDON
- React hook patterns (built-in tools) → CORE
- React migration codemods (one-time use) → ADDON
- React review command (daily use) → CORE
```

---

## Integration Principles

### 1. Plugin Boundaries

**Rule:** A plugin owns a domain, not a technology stack.

**Good Boundaries:**

- `react-19` - React library patterns (works in Vite, CRA, Next.js, Remix)
- `nextjs-15` - Next.js framework features (App Router, Route Handlers)
- `testing-tools` - Testing patterns (works across all frameworks)

**Bad Boundaries:**

- `react-nextjs-combo` - Mixes library and framework concerns
- `frontend-everything` - Too broad, no clear domain
- `my-project-specific` - Not reusable

**Test:** If feature F works without framework X, it doesn't belong in X's plugin.

### 2. Skill Composition

Skills should reference, not duplicate.

**Good:**

```markdown
<!-- nextjs-15/skills/server-actions-in-routes.md -->

See @react-19/forms/server-actions for base Server Action pattern.

Next.js additions:

- revalidatePath() after mutations
- redirect() for navigation
- cookies() and headers() access
```

**Bad:**

```markdown
<!-- nextjs-15/skills/server-actions-in-routes.md -->

Server Actions are async functions marked with 'use server'...
[duplicates entire React Server Actions explanation]
```

**Mechanism:** Use skill references like `@plugin-name/concern/skill-name`.

### 3. Hook Composition

Hooks should be additive, not conflicting.

**Good:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "command": "react-validation.sh" },
          { "command": "nextjs-routing-validation.sh" },
          { "command": "typescript-validation.sh" }
        ]
      }
    ]
  }
}
```

All hooks run in parallel. Each validates its domain.

**Bad:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [{ "command": "react-validates-everything.sh" }]
      },
      {
        "matcher": "Write",
        "hooks": [{ "command": "nextjs-also-validates-everything.sh" }]
      }
    ]
  }
}
```

Overlapping validation = wasted work and conflicts.

### 4. Command Namespacing

Commands should be namespaced appropriately based on plugin type.

**Tool Plugin Commands (domain-specific actions):**

Format: `/<plugin-short-name> <verb> [args]`

- `/next deploy` - Next.js plugin specific action
- `/db migrate` - Database plugin specific action
- `/git sync` - Git plugin specific action

**Cross-Cutting Plugin Commands (work across domains):**

Format: `/<verb> [concerns...]`

- `/review [react] [typescript] [security]` - Review plugin
- `/migrate [react-18-to-19] [typescript-5]` - Migration plugin
- `/test [unit] [integration]` - Testing plugin

**Bad:**

- `/r` - Too cryptic
- `/react-review-code-for-issues` - Too verbose
- `/react review` when review works across multiple plugins - Should be cross-cutting

**Key Rule:** If a command orchestrates functionality across multiple tool plugins, it belongs in a cross-cutting plugin, not in individual tool plugins.

### 5. Validation Rule Composition

Validation rules should be concern-specific and composable.

**File Structure:**

```tree
react-19/concerns/forms/validation/rules.json
nextjs-15/concerns/routing/validation/rules.json
typescript/concerns/types/validation/rules.json
```

Each plugin owns validation for its concerns. Hooks load relevant rules based on file type and context.

### 6. Cross-Cutting Plugin Pattern

Some functionality applies across multiple domains. These should be separate plugins that orchestrate skills from tool plugins.

**Plugin Types:**

1. **Tool Plugins** (domain-specific)

   - Provide domain knowledge (React, TypeScript, Next.js, security, etc.)
   - Export review skills tagged with `review: true`
   - Zero commands for cross-cutting concerns
   - Focus on teaching patterns and preventing domain-specific mistakes

2. **Cross-Cutting Plugins** (orchestration)
   - Provide commands that work across domains
   - Consume skills from tool plugins
   - Examples: review, migration, testing, documentation

**Good:**

```tree
plugins/
├── react-19/                        ← Tool plugin
│   └── concerns/hooks/skills/
│       ├── using-use-hook.md
│       └── review-hook-patterns.md  ← Exported with review: true
├── typescript/                      ← Tool plugin
│   └── concerns/types/skills/
│       └── review-type-safety.md    ← Exported with review: true
└── review/                          ← Cross-cutting plugin
    └── commands/
        └── review.md                ← /review [concerns...]
```

**Usage:**

```bash
/review react typescript    # Loads skills from both plugins
/review security           # Loads security review skills
/review                    # Loads all available review skills
```

**Bad:**

```tree
plugins/
├── react-19/
│   └── commands/
│       └── react-review.md          ✗ Duplicates orchestration
├── typescript/
│   └── commands/
│       └── typescript-review.md     ✗ Duplicates orchestration
└── nextjs-15/
    └── commands/
        └── nextjs-review.md         ✗ Duplicates orchestration
```

**Why This Pattern:**

- Single `/review` command instead of `/react review`, `/next review`, etc.
- Composable: `/review react typescript security`
- No duplication of orchestration logic
- Clear separation: tool plugins = knowledge, cross-cutting plugins = orchestration
- Tool plugins stay focused on domain expertise

**Skill Discovery:**

Cross-cutting plugins discover skills via:

1. Frontmatter tag: `review: true`
2. Naming convention: `review-[concern].md`
3. Plugin metadata exports

**Example Review Skill:**

```markdown
---
name: review-react-hook-patterns
description: Review React hook usage for React 19 compliance
review: true
---

# Review: React Hook Patterns

Check for:

## New React 19 Hooks

- Using `use()` for Promises and conditional context
- Using `useActionState` for form state

## Deprecated Patterns

- ❌ `forwardRef` usage → suggest ref-as-prop
```

---

## Anti-Patterns

### 1. The God Agent

**Anti-Pattern:** Creating one agent that handles everything.

```markdown
---
name: full-stack-expert
description: Expert in React, Next.js, TypeScript, testing, deployment, everything
---
```

**Why Bad:**

- Duplicates parent context
- No differentiation
- Can't use progressive disclosure
- High context cost

**Solution:** Use skills for domain knowledge, let parent Claude integrate.

### 2. The Redundant Command

**Anti-Pattern:** Creating commands for things users say naturally.

```markdown
/react create-component MyComponent
```

vs

```text
Create a React component called MyComponent
```

**Why Bad:**

- Users must remember command syntax
- Natural language is clearer
- Parent Claude already understands the request

**Solution:** Only create commands for frequent, simple directives that save typing.

### 3. The Duplicate Skill

**Anti-Pattern:** Multiple plugins teaching the same pattern.

```tree
react-19/skills/using-context.md
nextjs-15/skills/using-context-in-nextjs.md  ← Duplicates React content
```

**Why Bad:**

- Maintenance burden (update both)
- Wastes context (loads similar content twice)
- Causes confusion (which is right?)

**Solution:** Base plugin teaches pattern, framework plugin adds specifics and references base.

### 4. The Over-Engineered Hook

**Anti-Pattern:** Hooks that do complex analysis.

```bash
# validate-everything.sh
# 1. Parse AST
# 2. Run type checker
# 3. Run linter
# 4. Run tests
# 5. Check coverage
# Takes 30 seconds per file...
```

**Why Bad:**

- Slows down development
- Users disable hooks
- Overlaps with existing tools (ESLint, TypeScript)

**Solution:** Hooks should be fast validators (< 500ms), not full analysis tools.

### 5. The Unclear Boundary

**Anti-Pattern:** Plugin that doesn't know what it owns.

```tree
react-toolkit/
  - React patterns
  - Next.js routing
  - Vite config
  - ESLit rules
  - Testing patterns
```

**Why Bad:**

- Unclear what's included
- Overlaps with other plugins
- Hard to maintain
- Users install unwanted features

**Solution:** One domain per plugin. Clear scope in README.

### 6. The Chatty Hook

**Anti-Pattern:** Hooks that log everything.

```bash
echo "Checking file: $file"
echo "Running validation 1..."
echo "Running validation 2..."
echo "All checks passed!"
```

**Why Bad:**

- Clutters output
- Slows down workflows
- Users ignore messages

**Solution:** Hooks should be silent on success, specific on failure.

### 7. The Kitchen Sink MCP

**Anti-Pattern:** MCP server that does everything.

```tree
mega-mcp-server
  - File operations
  - Git operations
  - Database queries
  - API calls
  - Email sending
  - ...
```

**Why Bad:**

- High startup cost
- Most features unused
- Hard to maintain
- Unclear dependencies

**Solution:** Focused MCP servers for specific integrations. Users install what they need.

---

## Examples

### Example 1: Adding Form Validation Support

**Request:** "Help users validate forms"

**Decision Process:**

1. Can parent Claude do this? → **YES**, if they ask naturally
   **But:** Might not know best patterns

2. Can a skill teach this? → **YES**
   **Create:** `forms/skills/form-validation.md`

   - Teaches client + server validation
   - Shows zod/yup patterns
   - Progressive disclosure

3. Can a hook prevent mistakes? → **YES**
   **Create:** Hook to check Server Actions have validation

4. Is this a frequent directive? → **NO**
   Users say "add validation" naturally, no command needed

**Result:**

- ✅ Skill teaches patterns
- ✅ Hook prevents missing validation
- ❌ No command needed
- ❌ No agent needed
- ❌ No MCP needed (validation libraries are npm packages)

### Example 2: GitHub PR Integration

**Request:** "Help users create and review PRs"

**Decision Process:**

1. Can parent Claude do this? → **NO**, needs GitHub API access

2. Can a skill teach this? → **NO**, needs external tool

3. Can a hook prevent mistakes? → **NO**, not about validation

4. Is this a frequent directive? → **MAYBE**
   Could be `/github create-pr`, but `gh` CLI exists

5. Does this need external tools? → **YES**
   **Create:** MCP server for GitHub API

**Result:**

- ❌ No skill needed (MCP provides capability)
- ❌ No hook needed (not validation)
- ❌ No command needed (use `gh` CLI or natural language)
- ❌ No agent needed (same permissions as parent)
- ✅ MCP server for GitHub integration

### Example 3: Code Review

**Request:** "Review code for quality and security"

**Decision Process:**

1. Can parent Claude do this? → **YES**, if asked

2. Can a skill teach review criteria? → **YES**
   **Create:** Review skills in tool plugins (React, TypeScript, security)

3. Can a hook run automatic checks? → **YES**
   **Create:** PostToolUse hook to check for common issues

4. Is this a frequent directive? → **YES**
   But should each tool plugin have its own `/react review`, `/typescript review`, etc.?
   **NO** - This is cross-cutting functionality

5. Should this be a cross-cutting plugin? → **YES**
   - Applies across multiple domains (React, TypeScript, Next.js, security)
   - Same orchestration logic regardless of domain
   - Users want to compose: `/review react typescript security`
   - **Decision:** Separate review plugin

**Result:**

**Tool Plugins (React, TypeScript, etc.):**

- ✅ Skills teach domain-specific review criteria
- ✅ Hooks run automatic checks for that domain
- ✅ Export review skills with `review: true` tag
- ❌ No `/react review` command (cross-cutting concern)
- ❌ No agent (no differentiation)

**Review Plugin (cross-cutting):**

- ✅ Command `/review [concerns...]` orchestrates skills
- ✅ Discovers review skills from all installed tool plugins
- ✅ Composes multiple domains: `/review react typescript security`
- ❌ No domain knowledge (consumes from tool plugins)
- ❌ No agent (no differentiation)
- ❌ No MCP (built-in tools suffice)

**Key Insight:** Cross-cutting plugins prevent command proliferation. Single `/review` command instead of N commands across N tool plugins.

### Example 4: Debugging Assistance

**Request:** "Help users debug errors"

**Decision Process:**

1. Can parent Claude do this? → **YES**, if they share the error

2. Can a skill teach debugging techniques? → **YES**
   **Create:** `debugging/skills/systematic-debugging.md`

3. Can a hook prevent bugs? → **SOMETIMES**
   **Create:** Hooks for common mistake patterns

4. Is this a frequent directive? → **NO**
   Debugging is contextual, needs conversation

5. Should this be an agent? → **MAYBE**
   - Different tools? → **YES** (read-only to prevent changes during investigation)
   - Different model? → **YES** (haiku for faster iteration)
   - Needs isolation? → **YES** (debugging traces shouldn't pollute main conversation)
   - **Decision:** Could be an agent

**Result:**

- ✅ Skill teaches debugging methodology
- ✅ Hooks prevent common bugs
- ❌ No command (too contextual)
- ✅ Maybe agent for isolated investigation (read-only, haiku)
- ❌ No MCP needed

### Example 5: Database Query Builder

**Request:** "Help users write SQL queries"

**Decision Process:**

1. Can parent Claude do this? → **YES**, if database schema is known

2. Can a skill teach SQL patterns? → **YES**
   **Create:** `database/skills/sql-patterns.md`

3. Does this need external tools? → **MAYBE**

   - Query database schema? → MCP server
   - Execute queries? → MCP server
   - Analyze query plans? → MCP server

4. Should this be an agent? → **NO**
   - Same permissions as parent
   - Work happens in main conversation
   - Schema info can be in skills

**Result:**

- ✅ Skill teaches SQL patterns
- ❌ No hook (SQL is too diverse to validate generically)
- ❌ No command (queries are contextual)
- ❌ No agent (no differentiation)
- ✅ Optional MCP server for database introspection

---

## Plugin Quality Checklist

Before publishing a plugin, verify:

### Necessity

- [ ] Every component justifies its cognitive load
- [ ] Skills couldn't do the job better
- [ ] Hooks are fast (< 500ms)
- [ ] Commands are used daily
- [ ] Agents provide clear differentiation
- [ ] MCP servers provide essential tools

### Clarity

- [ ] Plugin scope is clear and focused
- [ ] README explains what problems it solves
- [ ] Boundaries with other plugins are documented
- [ ] Component descriptions are specific

### Efficiency

- [ ] Skills use progressive disclosure
- [ ] No duplicated knowledge across components
- [ ] Hooks don't overlap with existing tools
- [ ] Commands orchestrate, don't duplicate logic

### Composability

- [ ] Other plugins can extend this one
- [ ] Skills can be referenced by other plugins
- [ ] Hooks are additive, not conflicting
- [ ] Validation rules are composable

### Maintainability

- [ ] Single source of truth for domain knowledge
- [ ] Components are independently updateable
- [ ] No tight coupling between plugins
- [ ] Changes don't cascade to dependents

---

## Conclusion

**The North Star:** Reduce cognitive load while increasing capability.

Every component must:

1. Solve a real problem parent Claude can't handle alone
2. Be discoverable when needed
3. Be simple to use
4. Compose cleanly with other plugins
5. Justify its maintenance burden

When in doubt, start with less. It's easier to add components later than to remove ones users depend on.

**Remember:**

- Skills teach (progressive disclosure)
- Hooks prevent (event-driven)
- Commands orchestrate (frequent directives)
- Agents isolate (different capabilities)
- MCP servers integrate (external tools)

Choose the simplest component that solves the problem. Stop there.

# React 19 Plugin Philosophy Alignment

**Date:** 2025-11-19
**Plugin:** react-19
**Status:** Design Complete

## Overview

This document explains how the React 19 plugin aligns with the Claude Code Plugin System Philosophy and justifies every architectural decision made during plugin development.

## Core Design Decisions

### 1. Skills Only, Zero Agents

**Decision:** Use 24 skills across 6 concerns. Zero agents.

**Philosophy Alignment:**

From the Plugin Philosophy:

> **Truth 1: The Parent Claude Is Already Capable**
>
> Parent Claude with skills loaded can do almost anything. Adding components (agents, commands, MCP servers) creates overhead.

**Why This Applies:**

An agent would duplicate the parent's context without offering:
- Different tool access (skills can use allowed-tools to restrict tools)
- Different permission mode (not needed for React teaching)
- Different model (not needed for React patterns)
- Isolated execution context (React work happens in main conversation)

**Cognitive Load Analysis:**

- **Agent approach:** Users must remember an agent exists, when to invoke it, and how to switch between agent and parent
- **Skill approach:** Skills activate automatically when relevant. Zero discovery cost after installation.

Skills provide the same React 19 knowledge through progressive disclosure (metadata → core → details) without the overhead of context switching.

**Result:** Skills teach patterns efficiently. Parent Claude becomes React-aware without duplication.

---

### 2. Zero Commands in Core Plugin

**Decision:** No commands in the core plugin. Review skills exported for use by cross-cutting review plugin.

**Philosophy Alignment:**

From the Plugin Philosophy:

> **Truth 4: Conversation Beats Commands for Complexity**
>
> Natural language handles nuance and context. Commands force users into rigid syntax.

**Command Evaluation:**

Potential commands considered and rejected:

- `/react review` - Cross-cutting concern, belongs in separate review plugin
- `/react migrate` - One-time use, not daily, better as conversation
- `/react create-component` - Natural language is clearer: "Create a React component called X"
- `/react refactor` - Needs context and explanation, too complex for command syntax

**Cross-Cutting Plugin Pattern:**

From the Plugin Philosophy:

> **Cross-Cutting Plugins** (orchestration)
> - Provide commands that work across domains
> - Consume skills from tool plugins
> - Examples: review, migration, testing, documentation

The review plugin orchestrates review skills from multiple tool plugins (React, TypeScript, security). Single `/review` command instead of `/react review`, `/typescript review`, etc.

**Result:** Zero commands. Review skills exported with `review: true` frontmatter for discovery by review plugin.

---

### 3. Zero MCP Servers in Core

**Decision:** No MCP servers in the core plugin. Optional addon plugins can provide MCP as needed.

**Philosophy Alignment:**

From the Plugin Philosophy:

> **MCP Servers: External Tools**
>
> Use When:
> - Need external API access (GitHub, databases)
> - Need specialized parsing (AST, SQL)
>
> Don't Use When:
> - Built-in tools (Read, Write, Bash) suffice

**Why Built-in Tools Suffice:**

React development needs:
- Reading files: `Read` tool
- Editing files: `Edit` tool
- Writing files: `Write` tool
- Searching code: `Grep` tool
- Running scripts: `Bash` tool

All available as built-in tools. No external APIs needed.

**AST Parsing:**

Validation scripts use Node.js + Babel for AST parsing, executed via `Bash` tool. No dedicated MCP server needed.

**Result:** Zero MCP servers. Core plugin has zero external dependencies.

---

### 4. Concern-Based Organization (Not Feature-Type)

**Decision:** Organize by React domain (hooks, components, forms, state, performance, testing) not by feature type (validators, generators).

**Philosophy Alignment:**

From the Plugin Philosophy:

> **Clarity**
> - Plugin scope is clear and focused
> - README explains what problems it solves
> - Boundaries with other plugins are documented

**Developer Mental Model:**

Developers think in React concerns:
- "I need to add a form with Server Actions" → `concerns/forms/skills/`
- "How do I optimize performance?" → `concerns/performance/skills/`
- "What's the right hook pattern?" → `concerns/hooks/skills/`

Not in feature types:
- "Where's the validator for this?" → Unclear
- "Is this a generator or a helper?" → Confusing

**Structure:**

```tree
concerns/
├── hooks/skills/          # Hook patterns and anti-patterns
├── components/skills/     # Component composition and architecture
├── forms/skills/          # Server Actions and form handling
├── state/skills/          # State management strategies
├── performance/skills/    # Optimization techniques
└── testing/skills/        # Testing patterns
```

Each concern is self-contained with skills and validation rules.

**Result:** Developers navigate by concern, matching their mental model.

---

### 5. Progressive Disclosure via Skills

**Decision:** Skills load in layers: metadata → core examples → comprehensive reference.

**Philosophy Alignment:**

From the Plugin Philosophy:

> **Truth 2: Progressive Disclosure Beats Preloading**
>
> Loading everything upfront wastes context. Loading layer-by-layer as needed maximizes efficiency.

**Three-Layer Pattern:**

**Layer 1: Metadata (always loaded)**
```yaml
---
name: server-actions
description: Build secure Server Actions with 'use server' directive
allowed-tools: Read, Write, Edit
---
```

**Layer 2: Skill Content (loaded when activated)**
```markdown
# Server Actions

## Quick Example
'use server';
export async function createUser(formData) {
  const name = formData.get('name');
  await db.users.create({ name });
}
```

**Layer 3: Comprehensive Reference (referenced, not loaded)**
```markdown
## Reference
For complete security checklist, validation patterns, and edge cases:
research/react-19-comprehensive.md lines 450-680
```

**Context Efficiency:**

- Skill metadata: ~50 tokens each × 24 skills = 1,200 tokens always loaded
- Skill content: ~500 tokens, loaded only when relevant
- Comprehensive doc: ~30,000 tokens, referenced but not loaded unless needed

Without progressive disclosure: 30,000+ tokens loaded upfront for every conversation.

**Result:** Maximum efficiency. Context loads only what's needed, when it's needed.

---

### 6. Event-Driven Validation via Hooks

**Decision:** Use event hooks for validation instead of always-active context.

**Philosophy Alignment:**

From the Plugin Philosophy:

> **Truth 3: Context Is Expensive, Events Are Cheap**
>
> Context consumes tokens. Event hooks consume none until triggered.

**Hook Configuration:**

```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-react-patterns.sh",
          "timeout": 5000
        }
      ]
    }
  ]
}
```

**Cost Comparison:**

- **Always-active validation in context:** ~2,000 tokens loaded in every turn
- **Event hook:** 0 tokens until Write/Edit tool is used, then bash script runs (<100ms)

**Validation Scripts:**

1. `validate-react-patterns.sh` - Checks for deprecated patterns (forwardRef, propTypes)
2. `validate-compliance.sh` - Verifies React 19 compliance (use server, use client)
3. `check-react-version.sh` - Validates environment on session start

Scripts receive JSON stdin with tool context. Exit code 2 blocks operations.

**Result:** Zero context cost. Validation runs only when needed. Fast execution.

---

### 7. Single Source of Truth

**Decision:** One comprehensive reference document (`research/react-19-comprehensive.md`) as the single source of truth for React 19 knowledge.

**Philosophy Alignment:**

From the Plugin Philosophy:

> **Maintainability**
> - Single source of truth for domain knowledge
> - Components are independently updateable

**Structure:**

All 24 skills reference sections of the comprehensive document:

```markdown
## <!-- using-use-hook.md -->

Quick examples: [practical code here]

For complete API reference, edge cases, and TypeScript patterns:
research/react-19-comprehensive.md lines 230-450
```

**Benefits:**

1. **Updates:** Change React 19 knowledge in one place
2. **Consistency:** All skills reference the same truth
3. **Efficiency:** Comprehensive doc loaded only when user needs deep details
4. **Maintainability:** No duplicated knowledge across 24 skills

**Result:** Easy to maintain. Knowledge never contradicts itself. One file to update when React 19 evolves.

---

### 8. Component-by-Component Cognitive Load

**Decision:** Each component (skill, hook, script) justified individually against cognitive load.

**Philosophy Alignment:**

From the Plugin Philosophy:

> **The Prime Directive: Minimal Cognitive Load**
>
> Every component must justify its existence by reducing cognitive load more than it adds.

**Skill-by-Skill Justification:**

Example: `using-use-hook.md`

**Discovery cost:** Zero (auto-activates when user writes Promise or Context code)
**Usage cost:** Zero (user doesn't need to remember syntax, skill teaches it)
**Value provided:** Prevents using deprecated patterns, teaches new `use()` API

**Value > Cost** → Skill justified

Example: `/react create-component` command (rejected)

**Discovery cost:** High (user must remember command exists and syntax)
**Usage cost:** Medium (must remember argument format)
**Value provided:** Low (natural language "create a React component" works fine)

**Cost > Value** → Command rejected

**Hook-by-Hook Justification:**

Example: `validate-react-patterns.sh`

**Discovery cost:** Zero (runs automatically on Write/Edit)
**Usage cost:** Zero (user doesn't interact with it)
**Value provided:** High (blocks deprecated patterns before they're written)

**Value > Cost** → Hook justified

**Result:** Every component in the plugin passes the cognitive load test.

---

### 9. Composability with Framework Plugins

**Decision:** React plugin provides generic patterns. Framework plugins (Next.js, Remix) add framework-specific features.

**Philosophy Alignment:**

From the Plugin Philosophy:

> **Truth 5: Composition Over Duplication**
>
> Multiple plugins should compose cleanly without duplicating knowledge or functionality.

**Plugin Boundaries:**

**React 19 Plugin Scope:**
- Generic React patterns that work in any framework
- Hooks, components, forms, state, performance, testing
- Works with Vite, Create React App, Remix, Next.js, etc.

**Next.js 15 Plugin Scope:**
- Framework-specific features (App Router, Route Handlers, revalidation)
- Builds on React plugin patterns
- References React skills, doesn't duplicate them

**Skill Composition Example:**

```markdown
## <!-- nextjs-15/skills/server-actions-in-routes.md -->

## Base Pattern

See @react-19/forms/skills/server-actions.md for Server Action fundamentals.

## Next.js Additions

Next.js provides framework-specific helpers:

- revalidatePath() - Revalidate cached data after mutations
- redirect() - Navigate after form submission
- cookies() - Access request cookies
- headers() - Access request headers
```

**Result:** Clear boundaries. No duplication. Framework plugins extend, don't replace.

---

## Success Metrics

**Effectiveness:**
- ✅ Blocks deprecated patterns before they're written (PreToolUse hooks)
- ✅ Suggests correct React 19 patterns proactively (skill auto-activation)
- ✅ Reduces architecture mistakes (component composition skills)

**Efficiency:**
- ✅ Skills load only when relevant (progressive disclosure)
- ✅ No context duplication (skills vs agents)
- ✅ Fast execution (bash scripts <100ms, no heavy dependencies)

**Extensibility:**
- ✅ Clear boundaries for framework plugins (React generic, Next.js specific)
- ✅ Skill composition works smoothly (reference via @plugin-name/path)
- ✅ No conflicts with other plugins (hooks are additive)

---

## Alignment Summary

| Philosophy Principle | React 19 Plugin Decision | Alignment |
|---------------------|-------------------------|-----------|
| Parent Claude Is Already Capable | Zero agents | ✅ Perfect |
| Progressive Disclosure Beats Preloading | Three-layer skill structure | ✅ Perfect |
| Context Is Expensive, Events Are Cheap | Event-driven hooks | ✅ Perfect |
| Conversation Beats Commands | Zero commands in core | ✅ Perfect |
| Composition Over Duplication | Single source of truth + skill references | ✅ Perfect |
| Minimal Cognitive Load | Every component justified | ✅ Perfect |

**Conclusion:**

The React 19 plugin is a reference implementation of the Plugin System Philosophy. Every decision reduces cognitive load while increasing capability. Skills teach patterns efficiently. Hooks prevent mistakes proactively. No overhead from unnecessary agents, commands, or MCP servers.

Simple. Efficient. Extensible.

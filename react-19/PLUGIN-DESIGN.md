# React 19 Plugin Design

**Date:** 2025-11-19
**Status:** Final Design
**Author:** Design Session with Claude Code

## Overview

A Claude Code plugin that helps developers write correct React 19 code through proactive guidance, pattern teaching, and mistake prevention. The plugin assumes the LLM has outdated React knowledge and provides current React 19 patterns, best practices, and guardrails.

## Problem Statement

When helping users write React code, LLMs face three critical problems:

1. **Outdated patterns** - Suggests `forwardRef`, `propTypes`, `useCallback` everywhere, doesn't know `use()`, `useActionState`, etc.
2. **Missing best practices** - Doesn't understand Server Actions, async transitions, or React 19 form patterns
3. **Architecture mistakes** - Creates god components, prop drilling, wrong abstraction levels, improper state management

The plugin must work within a multi-plugin ecosystem where React is one of many frameworks (Next.js, Remix, etc.).

## Core Design Principles

### 1. No Agents

Agents provide value only when they offer:

- Different tool access than parent
- Different permission mode than parent
- Different model (haiku for speed/cost)
- Isolated execution context

A "React expert agent" duplicates the parent's context with no differentiation. Skills provide the same knowledge more efficiently through progressive disclosure.

**Decision: Zero agents. Skills teach patterns.**

### 2. No Commands

Commands are shortcuts for frequent user directives. Most tasks (refactoring, building, debugging) work better as conversational requests because users can explain context.

Cross-cutting concerns (review, testing, migration) should be separate plugins that orchestrate skills from tool plugins.

**Decision: Zero commands. Review skills exported for use by review plugin.**

### 3. No Core MCP Servers

Built-in tools (Read, Write, Edit, Grep, Glob, Bash) suffice for React work. MCP servers add dependencies and startup cost.

**Decision: Zero MCP servers in core. Optional addon plugins provide MCP as needed.**

### 4. Concern-Based Organization

Organize by React domain (hooks, components, forms, state, performance, testing) not by feature type (validators, generators). This matches how developers think.

**Decision: Six concerns, each with skills and validation rules.**

## Architecture

### Plugin Components

**Skills (25 total across 6 concerns)**

- Progressive disclosure - load only when relevant
- Teach "how to do it right" in React 19
- Activate based on code context
- Tool restrictions via `allowed-tools` field

**Hooks (3 event handlers)**

- Validate code as written (PreToolUse, PostToolUse)
- Proactive mistake prevention
- Event-driven, not context-heavy
- Exit code 2 blocks operations

**Review Skills (exported for review plugin)**

- Skills tagged with `review: true` for discoverability
- Used by separate review plugin via `/review react`
- Teach what to check during code review

**Scripts (3 bash validators)**

- Run by hooks for validation
- AST parsing via Node.js/Babel
- Check patterns, security, anti-patterns

**Research (React 19 knowledge base)**

- Comprehensive React 19 documentation
- Loaded by skills as needed
- Single source of truth

## Concern Structure

Each concern is self-contained with skills and validation rules:

### 1. Hooks Concern

**Scope:** React hook usage and patterns

**Skills:**

- `using-use-hook.md` - When/how to use `use()` with Promises and Context
- `action-state-patterns.md` - `useActionState` for form state
- `optimistic-updates.md` - `useOptimistic` for immediate UI updates
- `migrating-from-forwardref.md` - Convert `forwardRef` to ref-as-prop

**Validation:** Hook rules, dependencies, deprecated pattern detection

### 2. Components Concern

**Scope:** Component architecture and composition

**Skills:**

- `server-vs-client-boundaries.md` - When to use Server/Client Components
- `component-composition.md` - Children, compound components, render props
- `custom-elements-support.md` - Web Components in React 19

**Validation:** Component size, `'use client'` necessity, architecture patterns

### 3. Forms Concern

**Scope:** Form handling with Server Actions

**Skills:**

- `server-actions.md` - Creating and securing Server Actions
- `form-status-tracking.md` - `useFormStatus` in submit buttons
- `form-validation.md` - Client + server validation patterns

**Validation:** Server Action security, input validation, progressive enhancement

### 4. State Concern

**Scope:** State management patterns

**Skills:**

- `local-vs-global-state.md` - When to lift state vs use Context
- `context-api-patterns.md` - Using `use()` for conditional context
- `reducer-patterns.md` - When `useReducer` vs `useState`

**Validation:** State immutability, prop drilling depth, context overuse

### 5. Performance Concern

**Scope:** Optimization patterns

**Skills:**

- `react-compiler-aware.md` - What React Compiler handles automatically
- `code-splitting.md` - `lazy()` and `Suspense` patterns
- `resource-preloading.md` - `preload`, `preinit`, `prefetchDNS`

**Validation:** Array index keys, unnecessary re-renders, missing optimizations

### 6. Testing Concern

**Scope:** Component testing patterns

**Skills:**

- `testing-components.md` - React Testing Library patterns
- `testing-hooks.md` - `renderHook` for custom hooks
- `testing-server-actions.md` - Testing Server Actions in isolation

**Validation:** Implementation detail tests, missing coverage

## Hook Configuration

Hooks run bash scripts that validate code against React 19 patterns.

**`.claude/settings.json`:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/react-19/scripts/validate-react-patterns.sh\"",
            "timeout": 30
          },
          {
            "type": "prompt",
            "prompt": "Check if this React code uses deprecated patterns (forwardRef, propTypes, defaultProps). Code: $ARGUMENTS. If violations found, explain the React 19 alternative.",
            "timeout": 20
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/react-19/scripts/check-react-security.sh\"",
            "timeout": 15
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/react-19/scripts/load-react-context.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Review all React code changes made in this turn. Check for: 1) Deprecated patterns 2) Missing dependencies in hooks 3) Security issues 4) Anti-patterns. Summary: $ARGUMENTS",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/react-19/scripts/setup-react-env.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Validation Scripts:**

1. **`validate-react-patterns.sh`** - Checks code against React 19 patterns (exit 2 blocks)
2. **`check-react-security.sh`** - Validates security (XSS, unsafe HTML, Server Action validation)
3. **`load-react-context.sh`** - Loads React 19 docs when user mentions React
4. **`setup-react-env.sh`** - Validates React 19 + TypeScript on session start

Scripts receive JSON stdin with `tool_name`, `tool_input`, `cwd`. They parse code using AST (Babel) and return exit codes: 0 = pass, 2 = block, other = warn.

## Review Skills Definition

Review skills are exported for use by the separate review plugin. They teach what to check during code review.

**Naming Convention:** `review-[concern].md`

**Example: `concerns/hooks/skills/review-hook-patterns.md`:**

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
- Using `useOptimistic` for optimistic updates
- Using `useFormStatus` in form children

## Deprecated Patterns
- ❌ `forwardRef` usage → suggest ref-as-prop
- ❌ Missing `initialValue` in `useRef` (TypeScript)

## Hook Rules
- All dependencies included in arrays
- No conditional hook calls
- Hooks only at top level

## Common Mistakes
- Array index as key
- Direct state mutation
- Missing cleanup in useEffect
```

**Other Review Skills:**

- `concerns/components/skills/review-component-architecture.md` - Component size, composition
- `concerns/forms/skills/review-server-actions.md` - Server Action security, validation
- `concerns/state/skills/review-state-management.md` - Context usage, immutability
- `concerns/performance/skills/review-performance-patterns.md` - Re-renders, code splitting
- `concerns/testing/skills/review-test-quality.md` - Test patterns, coverage

Review plugin discovers these via `review: true` frontmatter tag or file naming convention.

## File Structure

```tree
react-19/
├── .claude-plugin/
│   └── plugin.json
├── concerns/
│   ├── hooks/
│   │   ├── skills/
│   │   │   ├── using-use-hook.md
│   │   │   ├── action-state-patterns.md
│   │   │   ├── optimistic-updates.md
│   │   │   ├── migrating-from-forwardref.md
│   │   │   └── review-hook-patterns.md          ← exported for review plugin
│   │   └── validation/
│   │       └── rules.json
│   ├── components/
│   │   ├── skills/
│   │   │   ├── server-vs-client-boundaries.md
│   │   │   ├── component-composition.md
│   │   │   ├── custom-elements-support.md
│   │   │   └── review-component-architecture.md  ← exported for review plugin
│   │   └── validation/
│   │       └── rules.json
│   ├── forms/
│   │   ├── skills/
│   │   │   ├── server-actions.md
│   │   │   ├── form-status-tracking.md
│   │   │   ├── form-validation.md
│   │   │   └── review-server-actions.md          ← exported for review plugin
│   │   └── validation/
│   │       └── rules.json
│   ├── state/
│   │   ├── skills/
│   │   │   ├── local-vs-global-state.md
│   │   │   ├── context-api-patterns.md
│   │   │   ├── reducer-patterns.md
│   │   │   └── review-state-management.md        ← exported for review plugin
│   │   └── validation/
│   │       └── rules.json
│   ├── performance/
│   │   ├── skills/
│   │   │   ├── react-compiler-aware.md
│   │   │   ├── code-splitting.md
│   │   │   ├── resource-preloading.md
│   │   │   └── review-performance-patterns.md    ← exported for review plugin
│   │   └── validation/
│   │       └── rules.json
│   └── testing/
│       ├── skills/
│       │   ├── testing-components.md
│       │   ├── testing-hooks.md
│       │   ├── testing-server-actions.md
│       │   └── review-test-quality.md            ← exported for review plugin
│       └── validation/
│           └── rules.json
├── scripts/
│   ├── validate-react-patterns.sh
│   ├── check-react-security.sh
│   ├── load-react-context.sh
│   └── setup-react-env.sh
├── research/
│   └── react-19-comprehensive.md
└── README.md
```

## Integration with Future Plugins

### Plugin Boundaries

**React Plugin Scope:**

- Generic React patterns that work in any framework
- Hooks, components, forms, state, performance, testing
- Works with Vite, Create React App, Remix, Next.js, etc.

**Framework Plugin Scope (Next.js, Remix, etc.):**

- Framework-specific features (routing, data loading, deployment)
- Builds on React plugin patterns
- Clear separation: If it works without the framework → React plugin

### Extension Mechanisms

**1. Concern Composition**

Next.js plugin adds framework-specific concerns:

```tree
nextjs-15/concerns/
├── routing/        # App Router patterns
├── rendering/      # SSR, SSG, ISR
└── api-routes/     # Route handlers
```

**2. Skill Imports**

Framework plugins reference React skills:

```markdown
## <!-- nextjs-15/skills/server-components-with-routing.md -->

name: nextjs-server-components
description: Next.js App Router with React 19 Server Components

---

# Next.js App Router

## Base Pattern

Use the server-vs-client-boundaries skill from the react-19 plugin for Server Component basics.

## Next.js Specific

- File-based routing conventions
- Layout and page patterns
- revalidatePath() and revalidateTag()
```

**3. Hook Augmentation**

Plugins add hooks without conflicts:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write|Edit", "hooks": ["react-validation"] },
      { "matcher": "Write|Edit", "hooks": ["nextjs-routing-validation"] }
    ]
  }
}
```

**4. Shared Validation**

Validation rules compose:

```javascript
// React provides base rules
concerns / forms / validation / rules.json;

// Next.js adds framework rules
concerns / routing / validation / nextjs - rules.json;
```

## Plugin Metadata

**`.claude-plugin/plugin.json`:**

```json
{
  "name": "react-19",
  "version": "1.0.0",
  "description": "React 19 patterns, hooks, and best practices for modern React applications",
  "author": {
    "name": "Plugin Author",
    "email": "author@example.com"
  },
  "keywords": ["react", "react-19", "hooks", "server-actions", "server-components"],
  "engines": {
    "claude-code": ">=1.0.0"
  },
  "exports": {
    "concerns": "./concerns",
    "skills": "./concerns/*/skills",
    "validation": "./concerns/*/validation"
  },
  "peerPlugins": {
    "nextjs-15": "optional",
    "remix-2": "optional",
    "testing-tools": "optional",
    "migration-tools": "optional"
  }
}
```

## Implementation Strategy

### Phase 1: Core Skills (Week 1)

- Write 18 skill files across 6 concerns
- Base content on comprehensive React 19 research
- Focus on progressive disclosure (keep files focused)
- Test skill activation with sample React code

### Phase 2: Hook Scripts (Week 2)

- Write 4 bash validation scripts
- Implement AST parsing with Babel
- Test exit codes and blocking behavior
- Validate against common React patterns

### Phase 3: Command & Integration (Week 3)

- Create `/react review` command
- Test orchestration of skills
- Write plugin README and documentation
- Create example projects for testing

### Phase 4: Testing & Refinement (Week 4)

- Test with real React codebases
- Refine skill descriptions for better activation
- Optimize hook performance
- Gather feedback and iterate

## Success Metrics

**Effectiveness:**

- Blocks deprecated patterns before they're written (forwardRef, propTypes)
- Suggests correct React 19 patterns proactively (useActionState, Server Actions)
- Reduces architecture mistakes (component size, prop drilling)

**Efficiency:**

- Skills load only when relevant (progressive disclosure)
- No context duplication (skills vs agents)
- Fast execution (bash scripts, no heavy dependencies)

**Extensibility:**

- Clear boundaries for framework plugins
- Skill composition works smoothly
- No conflicts with other plugins

## Risk Mitigation

**Risk: Hook scripts slow down development**

- Mitigation: Optimize scripts, use caching, short timeouts
- Fallback: Make hooks optional via settings

**Risk: Skills activate incorrectly**

- Mitigation: Test descriptions thoroughly, refine based on usage
- Fallback: Users can disable specific skills

**Risk: Overlap with framework plugins**

- Mitigation: Clear documentation of boundaries
- Fallback: Framework plugins can override React patterns

**Risk: React 19 evolves, plugin becomes outdated**

- Mitigation: Research file is single source of truth, easy to update
- Fallback: Users can edit skills directly

## Conclusion

This plugin provides React 19 assistance through:

- **Skills** that teach patterns (progressive disclosure, efficient)
- **Hooks** that prevent mistakes (event-driven, proactive)
- **Commands** that orchestrate (lightweight directives)
- **Scripts** that validate (fast, deterministic)

Zero agents, zero MCP servers, one command. The parent Claude becomes React-aware through skills. Simple, efficient, extensible.

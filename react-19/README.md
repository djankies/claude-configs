# React 19 Plugin for Claude Code

A comprehensive Claude Code plugin providing specialized skills, hooks, and validation for React 19 development. This plugin teaches Claude modern React patterns including the new `use()` hook, `useActionState`, Server Components, Server Actions, and migrating away from deprecated APIs.

## Philosophy

This plugin follows Claude Code's philosophy of **progressive disclosure** and **minimal cognitive load**:

- **Skills over agents**: Teaches patterns through focused, reusable skills instead of creating separate agent personalities
- **Just-in-time learning**: Skills activate when needed, teaching specific patterns in context
- **Validation at boundaries**: Hooks catch deprecated patterns and security issues before they reach your codebase
- **Reference over duplication**: Skills provide practical examples with references to comprehensive documentation

### Component Justification

Each plugin component is justified by the cognitive load equation: **Discovery Cost + Usage Cost < Value Delivered**

**Skills (25 total):**
- Discovery cost: Low (skill search finds relevant patterns)
- Usage cost: Medium (reading skill content, understanding examples)
- Value delivered: High (correct React 19 patterns, avoids deprecated APIs)
- Result: Net positive value

**Hooks (3 total):**
- Discovery cost: Zero (automatic execution)
- Usage cost: Zero (transparent validation)
- Value delivered: Very high (prevents critical errors before they occur)
- Result: Maximum value with zero cognitive overhead

**Commands (0 total):**
- Discovery cost: Medium (must learn command syntax)
- Usage cost: Medium (must remember when to invoke)
- Value delivered: Low (infrequent tasks better handled conversationally)
- Result: Cognitive overhead exceeds value

**Agents (0 total):**
- Discovery cost: High (understanding agent capabilities)
- Usage cost: High (context duplication with parent agent)
- Value delivered: Negative (creates confusion, duplicate knowledge)
- Result: Actively harmful to user experience

See [PHILOSOPHY-ALIGNMENT.md](./PHILOSOPHY-ALIGNMENT.md) for detailed design decisions.

## Installation

```bash
# Clone the plugin to your Claude Code plugins directory
cd ~/.claude/plugins
git clone <repository-url> react-19

# Or install via Claude Code CLI
claude plugins install react-19
```

## Features

### 25 Skills Across 6 Concerns

#### Hooks (5 skills)
- **using-use-hook**: Master the new `use()` API for Promises and Context
- **managing-action-state**: Build forms with `useActionState` and form state management
- **implementing-optimistic-updates**: Implement instant UI feedback with `useOptimistic`
- **migrating-from-forwardref**: Migrate from deprecated `forwardRef` to ref-as-prop pattern
- **review-hook-patterns**: Review checklist for React 19 hook compliance

#### Components (4 skills)
- **choosing-component-boundaries**: Decide when to use Server vs Client Components
- **composing-components**: Master children props, compound components, render props
- **using-custom-elements**: Use Web Components with React 19's full Custom Elements support
- **review-component-architecture**: Review checklist for component organization

#### Forms (4 skills)
- **implementing-server-actions**: Build secure Server Actions with `'use server'` directive
- **tracking-form-status**: Track form submission state with `useFormStatus`
- **validating-forms**: Implement client and server validation with zod
- **review-server-actions**: Security checklist for Server Actions

#### State (4 skills)
- **choosing-state-location**: Choose between useState, Context, and external state
- **using-context-api**: Use Context API with React 19's `use()` hook
- **using-reducers**: Manage complex state logic with `useReducer`
- **review-state-management**: Review checklist for state patterns

#### Performance (4 skills)
- **writing-compiler-aware-code**: Write code that works with React Compiler's automatic optimization
- **implementing-code-splitting**: Implement lazy loading with `lazy()` and `Suspense`
- **preloading-resources**: Optimize loading with `prefetchDNS`, `preconnect`, `preload`, `preinit`
- **review-performance-patterns**: Review checklist for performance optimization

#### Testing (4 skills)
- **testing-components**: Test React 19 components with React Testing Library
- **testing-hooks**: Test custom hooks with `renderHook`
- **testing-server-actions**: Test Server Actions in isolation
- **review-test-quality**: Review checklist for test coverage and quality

### 3 Validation Hooks

Automatic validation that runs during development:

1. **PreToolUse**: Warns about deprecated patterns before you edit files
   - Catches `forwardRef`, `propTypes`, `defaultProps`, class components
   - Validates Server Action security (input validation, auth checks)
   - Script: `validate-react-patterns.sh`

2. **PostToolUse**: Validates React 19 compliance after edits
   - Confirms no new deprecated API usage
   - Checks `'use server'` and `'use client'` directives
   - Verifies form patterns use `useActionState`
   - Script: `validate-compliance.sh`

3. **SessionStart**: Checks environment on session start
   - Verifies React version (warns if <19)
   - Displays available skills and documentation
   - Script: `check-react-version.sh`

## How Skills Work

Skills activate automatically based on your work:

```javascript
// When you write this, the "server-actions" skill activates
'use server';
export async function createUser(formData) {
  // Skill teaches: validation, authentication, error handling
}
```

```javascript
// When you use this hook, "action-state-patterns" activates
const [state, formAction, isPending] = useActionState(submitForm, null);
```

You can also invoke skills explicitly:

```bash
/skill using-use-hook
/skill migrating-from-forwardref
```

Review skills can be invoked to check code quality:

```bash
/skill review-hook-patterns
/skill review-server-actions
/skill review-performance-patterns
```

## Validation Scripts

Four bash scripts validate React 19 patterns:

- `scripts/validate-react-patterns.sh` - Pre-execution pattern validation
- `scripts/validate-compliance.sh` - Post-execution compliance checking
- `scripts/review-suggestions.sh` - Review agent suggestions
- `scripts/check-react-version.sh` - Verify React version on session start

## Documentation

### Comprehensive Research

The plugin includes a 2300+ line comprehensive React 19 reference document:

```
research/react-19-comprehensive.md
```

This document covers:
- Complete API reference for all React 19 features
- Migration guides from React 18 and deprecated patterns
- Advanced patterns and edge cases
- Security considerations
- Performance optimization techniques

**All skills reference this document** using progressive disclosure - they provide practical examples inline and point to comprehensive documentation for deeper understanding.

### Skill Structure

Each skill follows this structure:

```markdown
---
name: skill-name
description: What the skill teaches
allowed-tools: Read, Write, Edit
version: 1.0.0
---

# Skill Title

## Practical Examples
[Concise, copy-paste ready code]

## When to Use
[Clear decision criteria]

## Anti-Patterns
[What to avoid]

## Reference
For comprehensive details, see: research/react-19-comprehensive.md lines X-Y
```

## Requirements

- React 19.0.0 or higher
- Claude Code 1.0.0 or higher
- For Server Components/Actions: Next.js 15+ or compatible framework

## Plugin Structure

```tree
react-19/
├── .claude-plugin/
│   └── plugin.json                    # Plugin metadata and exports
├── concerns/                          # Organized by React concern
│   ├── hooks/skills/                  # Hook-related skills
│   ├── components/skills/             # Component patterns
│   ├── forms/skills/                  # Form and Server Action patterns
│   ├── state/skills/                  # State management patterns
│   ├── performance/skills/            # Performance optimization
│   └── testing/skills/                # Testing patterns
├── hooks/
│   └── hooks.json                     # Event hook configuration
├── scripts/                           # Validation scripts
│   ├── validate-react-patterns.sh
│   ├── validate-compliance.sh
│   ├── review-suggestions.sh
│   └── check-react-version.sh
├── research/
│   └── react-19-comprehensive.md      # 2300+ line reference doc
├── README.md                          # This file
└── PHILOSOPHY-ALIGNMENT.md            # Design decisions and justifications
```

## Exported Review Skills

Six review skills are exported for use by cross-cutting review plugins:

- `review-hook-patterns`
- `review-component-architecture`
- `review-server-actions`
- `review-state-management`
- `review-performance-patterns`
- `review-test-quality`

These can be used by a general code review plugin to perform React 19-specific reviews.

## Peer Plugin

This plugin declares a peer dependency on a general review plugin that orchestrates cross-cutting reviews. The review plugin will invoke the exported review skills during code review sessions.

## Contributing

When contributing new skills:

1. Follow the progressive disclosure pattern
2. Provide practical, copy-paste ready examples
3. Reference comprehensive documentation for details
4. Add validation rules to hooks if applicable
5. Test skills activate in appropriate contexts

## License

MIT

## Version

1.0.0

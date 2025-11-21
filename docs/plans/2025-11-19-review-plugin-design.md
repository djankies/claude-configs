# Review Plugin Design

**Date:** 2025-11-19
**Status:** Final Design
**Type:** Cross-Cutting Plugin
**Author:** Design Session with Claude Code

## Overview

A Claude Code cross-cutting plugin that orchestrates code review across multiple tool plugins. Instead of each tool plugin (React, TypeScript, Next.js, security) implementing its own review command, this plugin provides a single `/review` command that composes review skills from all installed tool plugins.

## Problem Statement

Without the cross-cutting pattern, every tool plugin would implement its own review command:

- `/react review` - React plugin
- `/typescript review` - TypeScript plugin
- `/nextjs review` - Next.js plugin
- `/security review` - Security plugin

This creates:

1. **Command proliferation** - Users must remember N commands
2. **No composition** - Can't review multiple concerns together
3. **Duplicated orchestration** - Same review logic in N plugins
4. **Maintenance burden** - Update review logic in N places

The review plugin solves this with a single composable command.

## Core Design Principles

### 1. Zero Domain Knowledge

The review plugin has no React, TypeScript, or framework knowledge. It only knows how to:

- Discover review skills from installed plugins
- Load skills based on user arguments
- Orchestrate the review process
- Report findings

**All domain expertise comes from tool plugins.**

### 2. Skill Discovery

The plugin discovers review skills through:

1. **Frontmatter tag:** Skills marked with `review: true`
2. **Naming convention:** Skills matching `review-*.md`
3. **Plugin metadata:** Plugins exporting review skills

Tool plugins make skills discoverable without explicit registration.

### 3. Composable Arguments

Users can review multiple concerns in one command:

```bash
/review react typescript        # React + TypeScript review
/review security                # Security only
/review                         # All available concerns
```

Arguments map to skill names or concern categories.

## Architecture

### Plugin Components

**Commands (1 total)**

- `/review [concerns...]` - Orchestrates review across specified concerns

**Skills (0 total)**

- Zero - all skills come from tool plugins

**Hooks (0 total)**

- Zero - tool plugins provide their own validation hooks

**Agents (0 total)**

- Zero - reviews happen in main conversation

**MCP Servers (0 total)**

- Zero - built-in tools suffice

### Review Flow

1. **User invokes:** `/review react typescript security`

2. **Plugin discovers skills:**
   - Scans installed plugins for `review: true` skills
   - Filters by user arguments (react, typescript, security)
   - Loads matching skills

3. **Parent Claude reviews:**
   - Uses loaded skills as review checklist
   - Examines code against criteria
   - Reports findings with specific locations

4. **User responds:**
   - Accepts findings
   - Asks questions
   - Requests fixes

## Skill Discovery Implementation

### Tool Plugin Structure

Tool plugins export review skills:

```tree
react-19/
└── concerns/
    ├── hooks/skills/
    │   └── review-hook-patterns.md       ← review: true
    ├── components/skills/
    │   └── review-component-architecture.md
    ├── forms/skills/
    │   └── review-server-actions.md
    └── state/skills/
        └── review-state-management.md
```

### Plugin Metadata

Tool plugins declare review skills in `plugin.json`:

```json
{
  "name": "react-19",
  "exports": {
    "skills": "./concerns/*/skills",
    "review-skills": "./concerns/*/skills/review-*.md"
  }
}
```

### Discovery Algorithm

```javascript
function discoverReviewSkills(concerns) {
  const allPlugins = getInstalledPlugins()
  const reviewSkills = []

  for (const plugin of allPlugins) {
    const skills = plugin.exports['review-skills']

    for (const skill of skills) {
      const metadata = parseSkillFrontmatter(skill)

      if (metadata.review === true) {
        const concernMatch = concerns.length === 0 ||
          concerns.some(c => skill.includes(c))

        if (concernMatch) {
          reviewSkills.push(skill)
        }
      }
    }
  }

  return reviewSkills
}
```

## Command Implementation

### File: `commands/review.md`

```markdown
---
name: review
description: Review code for quality, security, and best practices across specified concerns
---

# Review Code

Review code against best practices from installed tool plugins.

## Usage

/review [concerns...]

## Arguments

- concerns (optional): Space-separated list of concerns to review
  - Examples: react, typescript, nextjs, security, performance
  - If omitted, reviews all available concerns

## Process

1. Discover review skills from installed plugins matching concerns
2. Load skills as review checklist
3. Examine code files changed in recent commits or current branch
4. Report findings with:
   - Issue description
   - File path and line number
   - Severity (error, warning, suggestion)
   - Recommended fix

## Example

User: /review react typescript

Claude Code:
1. Discovers review-hook-patterns.md, review-component-architecture.md from react-19
2. Discovers review-type-safety.md, review-strict-mode.md from typescript
3. Loads all 4 skills
4. Reviews code against combined checklist
5. Reports findings
```

## Integration with Tool Plugins

### Tool Plugin Responsibilities

Tool plugins must:

1. **Create review skills** - Document what to check during review
2. **Tag with frontmatter** - Mark skills with `review: true`
3. **Export in metadata** - Declare review skills in plugin.json
4. **Focus on domain** - Only review domain-specific concerns

**Example review skill from React plugin:**

```markdown
---
name: review-react-hook-patterns
description: Review React hook usage for React 19 compliance
review: true
---

# Review: React Hook Patterns

## New React 19 Hooks

✅ Check for:

- Using `use()` for Promises and conditional context
- Using `useActionState` for form state
- Using `useOptimistic` for optimistic updates
- Using `useFormStatus` in form children

## Deprecated Patterns

❌ Flag:

- `forwardRef` usage → suggest ref-as-prop
- Missing `initialValue` in `useRef` (TypeScript)

## Hook Rules

- All dependencies included in arrays
- No conditional hook calls
- Hooks only at top level

## Common Mistakes

- Array index as key
- Direct state mutation
- Missing cleanup in useEffect
```

### Review Plugin Responsibilities

The review plugin must:

1. **Discover skills** - Find review skills from all plugins
2. **Load dynamically** - Load only requested concerns
3. **Orchestrate** - Coordinate review process
4. **Report clearly** - Format findings for user

**The review plugin has zero domain knowledge.**

## File Structure

```tree
review/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── review.md
└── README.md
```

That's it. No skills, hooks, agents, or MCP servers.

## Plugin Metadata

**`.claude-plugin/plugin.json`:**

```json
{
  "name": "review",
  "version": "1.0.0",
  "description": "Cross-cutting code review plugin that orchestrates review skills from tool plugins",
  "author": {
    "name": "Plugin Author",
    "email": "author@example.com"
  },
  "keywords": ["review", "code-quality", "orchestration", "cross-cutting"],
  "engines": {
    "claude-code": ">=1.0.0"
  },
  "peerPlugins": {
    "react-19": "optional",
    "typescript": "optional",
    "nextjs-15": "optional",
    "security": "optional"
  },
  "consumes": {
    "review-skills": "*/concerns/*/skills/review-*.md"
  }
}
```

**Key field:** `consumes` declares what this plugin expects from tool plugins.

## Usage Examples

### Review Everything

```bash
/review
```

Loads all review skills from all installed tool plugins.

### Review Specific Concerns

```bash
/review react typescript
```

Loads only React and TypeScript review skills.

### Review Single Concern

```bash
/review security
```

Loads only security review skills.

### Review with Context

```bash
User: I just refactored the authentication system. Can you review it?

Claude: I'll use the /review command to check your authentication refactor.

[Uses /review command internally]

[Loads security, typescript, and react review skills]

[Reviews code against checklist]

Findings:

1. src/auth/login.ts:45 - ❌ ERROR
   - Using innerHTML with user input
   - Security risk: XSS vulnerability
   - Fix: Use textContent or sanitize input

2. src/auth/hooks.ts:12 - ⚠️ WARNING
   - useEffect missing dependency: userId
   - May cause stale closures
   - Fix: Add userId to dependency array

3. src/auth/form.tsx:8 - 💡 SUGGESTION
   - Could use useActionState for form state
   - React 19 best practice
   - Current approach works but consider upgrading
```

## Benefits of Cross-Cutting Pattern

### For Users

1. **Single command** - `/review` instead of `/react review`, `/typescript review`, etc.
2. **Composable** - Review multiple concerns together
3. **Consistent** - Same review experience across all tool plugins
4. **Discoverable** - Automatically finds new review skills as plugins are installed

### For Plugin Authors

1. **No orchestration code** - Just write review skills
2. **No command logic** - Review plugin handles it
3. **Focus on domain** - Teach what to review, not how
4. **Automatic integration** - Tag with `review: true` and done

### For Ecosystem

1. **No duplication** - Review orchestration written once
2. **Extensible** - New tool plugins work automatically
3. **Maintainable** - Update review logic in one place
4. **Composable** - Plugins combine cleanly

## Comparison: Before vs After

### Before (Each Tool Plugin Has Command)

```tree
plugins/
├── react-19/
│   ├── commands/
│   │   └── react-review.md          ← Duplicated orchestration
│   └── skills/
│       └── review-hooks.md
├── typescript/
│   ├── commands/
│   │   └── typescript-review.md     ← Duplicated orchestration
│   └── skills/
│       └── review-types.md
└── nextjs-15/
    ├── commands/
    │   └── nextjs-review.md         ← Duplicated orchestration
    └── skills/
        └── review-routing.md
```

**Problems:**

- 3 commands for users to remember
- Can't compose: Want React + TypeScript? Run both commands
- Orchestration logic duplicated 3 times
- Update review format? Change 3 files

### After (Cross-Cutting Plugin)

```tree
plugins/
├── react-19/
│   └── concerns/*/skills/
│       └── review-*.md              ← Just the knowledge
├── typescript/
│   └── concerns/*/skills/
│       └── review-*.md              ← Just the knowledge
├── nextjs-15/
│   └── concerns/*/skills/
│       └── review-*.md              ← Just the knowledge
└── review/
    └── commands/
        └── review.md                ← Single orchestration
```

**Benefits:**

- 1 command: `/review [concerns...]`
- Composable: `/review react typescript nextjs`
- Orchestration logic in one place
- Update review format? Change 1 file
- Tool plugins focus on domain knowledge

## Other Cross-Cutting Plugin Examples

This pattern works for any cross-cutting concern:

### Migration Plugin

**Tool plugins export migration skills:**

- `react-19/skills/migrate-from-18.md`
- `typescript/skills/migrate-to-5.md`
- `nextjs-15/skills/migrate-from-14.md`

**Migration plugin provides:**

- `/migrate [from-to...]` command
- Discovers migration skills
- Orchestrates multi-step migrations

**Usage:**

```bash
/migrate react-18-to-19 typescript-4-to-5
```

### Testing Plugin

**Tool plugins export testing skills:**

- `react-19/skills/test-components.md`
- `react-19/skills/test-hooks.md`
- `nextjs-15/skills/test-server-actions.md`

**Testing plugin provides:**

- `/test [types...]` command
- Discovers testing skills
- Runs tests and reports

**Usage:**

```bash
/test unit integration
```

### Documentation Plugin

**Tool plugins export doc skills:**

- `react-19/skills/document-components.md`
- `typescript/skills/document-types.md`
- `api/skills/document-endpoints.md`

**Documentation plugin provides:**

- `/docs [types...]` command
- Discovers documentation skills
- Generates documentation

**Usage:**

```bash
/docs api components
```

## Implementation Checklist

### Phase 1: Core Command

- [ ] Create plugin structure
- [ ] Write `/review` command markdown
- [ ] Implement skill discovery logic
- [ ] Test with mock skills

### Phase 2: Integration

- [ ] Test with react-19 plugin
- [ ] Test with typescript plugin
- [ ] Test with multiple plugins
- [ ] Test concern filtering

### Phase 3: Polish

- [ ] Write README with examples
- [ ] Document skill format for tool plugins
- [ ] Add error handling (no plugins installed, no matching skills)
- [ ] Test edge cases

### Phase 4: Validation

- [ ] Review with real codebases
- [ ] Gather feedback from users
- [ ] Refine discovery algorithm
- [ ] Optimize performance

## Success Metrics

**Effectiveness:**

- Single command handles all review concerns
- Users can compose multiple concerns
- Tool plugins integrate automatically

**Simplicity:**

- Review plugin < 100 lines of orchestration code
- Tool plugins just tag skills with `review: true`
- No explicit registration required

**Extensibility:**

- New tool plugins work without changes to review plugin
- Review format changes in one place
- Multiple cross-cutting plugins coexist

## Conclusion

The review plugin demonstrates the cross-cutting plugin pattern:

- **Tool plugins** provide domain knowledge (review skills)
- **Cross-cutting plugins** provide orchestration (review command)
- **Zero duplication** - each concern implemented once
- **Maximum composition** - skills combine freely

This pattern prevents command proliferation while enabling rich multi-domain functionality. The review plugin has no React, TypeScript, or security knowledge - yet it can review all three together because it orchestrates skills from tool plugins.

**Key insight:** Separate "what to check" (tool plugins) from "how to orchestrate checking" (cross-cutting plugins).
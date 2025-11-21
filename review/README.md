# Review Plugin

**Type:** Cross-Cutting Plugin
**Version:** 1.0.0
**Status:** Production Ready

A Claude Code cross-cutting plugin that orchestrates code review across multiple tool plugins. Instead of each tool plugin implementing its own review command, this plugin provides a single `/review` command that composes review skills from all installed tool plugins.

## Problem Statement

Without the cross-cutting pattern, every tool plugin would need its own review command:

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

## Philosophy Alignment

### Core Principle: Zero Domain Knowledge

This plugin has **ZERO React, TypeScript, or framework knowledge**. It only knows how to:

- Discover review skills from installed plugins
- Load skills based on user arguments
- Orchestrate the review process
- Report findings

**All domain expertise comes from tool plugins.**

### Design Hierarchy Compliance

Following the plugin philosophy design hierarchy:

1. ❌ **Can parent Claude do this?** No - needs skill discovery and orchestration
2. ❌ **Can a skill teach this?** No - skills can't discover other skills dynamically
3. ❌ **Can a hook prevent this?** No - not about validation
4. ✅ **Is this a frequent directive?** **YES** - users review code daily
5. **Stopped here** - Command is the right level

### Cognitive Load Analysis

**Discovery Cost:** Low
- Single command to remember: `/review`
- Intuitive arguments: concern names

**Usage Cost:** Low
- Natural syntax: `/review react typescript`
- Auto-discovery of skills from tool plugins
- No configuration required

**Value Provided:** High
- Composable reviews across multiple domains
- Consistent review experience
- Automatic integration with new tool plugins
- Single point of orchestration

**Net Impact:** ✅ Strongly Positive

## Components

### Commands (1)

- **`/review [concerns...]`** - Orchestrates review across specified concerns
  - **Justification:** Daily user directive for code review
  - **Why not conversational:** Provides consistent orchestration pattern
  - **Why not in parent:** Requires dynamic skill discovery

### Skills (0)

- **None** - All review skills come from tool plugins
  - **Why zero skills:** This is pure orchestration, no domain knowledge

### Hooks (0)

- **None** - Tool plugins provide their own validation hooks
  - **Why zero hooks:** Not about preventing mistakes, about orchestrating review

### Agents (0)

- **None** - Reviews happen in main conversation
  - **Why zero agents:** Same permissions, same model, same context as parent

### MCP Servers (0)

- **None** - Built-in tools suffice
  - **Why zero MCP:** Read, Glob, Grep handle all needs

## How It Works

### 1. Skill Discovery

**Auto-Discovery Mechanism**

The plugin automatically discovers review skills on command invocation:

1. **Runs discovery script:** Executes `discover-review-skills.sh` when `/review` is called
2. **Scans all plugins:** Searches all installed plugins for skills with `review: true` frontmatter
3. **Builds dynamic mapping:** Creates a mapping of concerns → skills for fast lookup
4. **No configuration needed:** New plugins work immediately after installation

**Skill Tagging Convention**

Tool plugins tag review skills for auto-discovery:

- **Frontmatter:** Skills marked with `review: true` in YAML frontmatter
- **Naming convention:** Skill names use gerund form: `reviewing-{concern}`
  - Example: `reviewing-nextjs-16-patterns`
  - Example: `reviewing-react-hooks`
  - Example: `reviewing-typescript-types`
- **Location:** Skills can be anywhere in plugin directory structure

**Automatic Integration**

Once a plugin is installed:

- Review skills automatically available via `/review`
- Users invoke: `/review {concern}` where concern matches plugin domain
- Multiple concerns composable: `/review react typescript nextjs-16`
- Discovery runs fresh on each invocation to catch new plugins

**Backward Compatibility**

The system supports both:

- Auto-discovered skills (preferred, dynamic)
- Hardcoded skill references (legacy, static)

New plugins should use auto-discovery for zero-configuration integration.

### 2. Tool Plugin Structure

Tool plugins export review skills:

```tree
react-19/
└── concerns/
    ├── hooks/skills/
    │   └── review-hook-patterns.md       ← review: true
    ├── components/skills/
    │   └── review-component-architecture.md
    └── forms/skills/
        └── review-server-actions.md
```

### 3. Review Flow

```
User invokes: /review react typescript security
      ↓
Plugin discovers skills:
  - Scans plugins for review: true skills
  - Filters by concerns (react, typescript, security)
  - Loads matching skills
      ↓
Parent Claude reviews:
  - Uses skills as review checklist
  - Examines code against criteria
  - Reports findings with locations
      ↓
User responds:
  - Accepts findings
  - Asks questions
  - Requests fixes
```

## Installation

```bash
claude plugin install review
```

## Usage

### Review Everything

```bash
/review
```

Shows all available concerns from auto-discovery, then loads all review skills from all installed tool plugins.

### Review Specific Concerns

```bash
/review react typescript
```

Loads only React and TypeScript review skills (auto-discovered from installed plugins).

### Review Single Concern

```bash
/review nextjs-16
```

Uses auto-discovered Next.js 16 review skill from the nextjs-16 plugin.

### Compose Multiple Auto-Discovered Skills

```bash
/review react typescript nextjs-16
```

Composes multiple auto-discovered skills together for comprehensive review across React, TypeScript, and Next.js 16 concerns.

### Conversational Review

```
User: I just refactored the authentication system. Can you review it?

Claude Code: I'll review your authentication refactor.

[Uses /review internally]
[Loads security, typescript, and react review skills]
[Reviews code against combined checklist]

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

## Integration with Tool Plugins

### Tool Plugin Responsibilities

Tool plugins must:

1. **Create review skills** - Document what to check during review
2. **Tag with frontmatter** - Mark skills with `review: true`
3. **Export in metadata** - Declare review skills in plugin.json
4. **Focus on domain** - Only review domain-specific concerns

**Example review skill:**

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

## Deprecated Patterns

❌ Flag:
- `forwardRef` usage → suggest ref-as-prop
- Missing `initialValue` in `useRef` (TypeScript)

## Hook Rules

- All dependencies included in arrays
- No conditional hook calls
- Hooks only at top level
```

### Review Plugin Responsibilities

The review plugin:

1. **Discovers skills** - Finds review skills from all plugins
2. **Loads dynamically** - Loads only requested concerns
3. **Orchestrates** - Coordinates review process
4. **Reports clearly** - Formats findings for user

## Benefits

### For Users

1. **Single command** - `/review` instead of N commands
2. **Composable** - Review multiple concerns together
3. **Consistent** - Same experience across all tool plugins
4. **Discoverable** - Auto-finds new review skills

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

## Cross-Cutting Pattern

This plugin demonstrates the cross-cutting plugin pattern:

- **Tool plugins** provide domain knowledge (review skills)
- **Cross-cutting plugins** provide orchestration (review command)
- **Zero duplication** - each concern implemented once
- **Maximum composition** - skills combine freely

Other cross-cutting plugins following this pattern:

- **migration** - `/migrate [from-to...]` - Orchestrates migration skills
- **testing** - `/test [types...]` - Orchestrates testing skills
- **docs** - `/docs [types...]` - Orchestrates documentation skills

## Dependencies

### Peer Plugins (Optional)

- `react-19` - React review skills
- `typescript` - TypeScript review skills
- `nextjs-15` - Next.js review skills
- `security` - Security review skills

Works with ANY tool plugin that exports review skills.

### Consumes

- `review-skills: */concerns/*/skills/review-*.md`

Tool plugins make skills discoverable via this pattern.

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

## Philosophy Validation

### Necessity ✅

- [x] Command justifies cognitive load (daily directive)
- [x] Skills couldn't do this (requires dynamic discovery)
- [x] Provides clear orchestration value
- [x] Reduces N commands to 1 command

### Clarity ✅

- [x] Plugin scope clear: orchestration only, zero domain knowledge
- [x] README explains problem solved
- [x] Boundaries documented: consumes review skills from tool plugins
- [x] Command description specific

### Efficiency ✅

- [x] Zero duplicated knowledge (tool plugins own domain expertise)
- [x] Command orchestrates, doesn't duplicate logic
- [x] Progressive skill loading (only requested concerns)
- [x] Minimal file structure

### Composability ✅

- [x] Tool plugins extend by adding review skills
- [x] Skills discoverable via convention
- [x] Multiple concerns composable in single command
- [x] No tight coupling

### Maintainability ✅

- [x] Single source of truth: tool plugins for domain, review plugin for orchestration
- [x] Components independently updateable
- [x] No coupling between tool plugins
- [x] Review logic centralized

## License

MIT

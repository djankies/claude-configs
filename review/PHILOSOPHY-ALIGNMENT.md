# Philosophy Alignment Document

**Plugin:** review
**Type:** Cross-Cutting Plugin
**Date:** 2025-11-20
**Status:** Production Ready

## Component Justifications

### Command: `/review [concerns...]`

#### 1. Why this component type?

**Why a command and not:**

- ❌ **Conversational request:** While users could say "review my code," a command provides:
  - Consistent orchestration behavior
  - Explicit concern filtering (`/review react typescript`)
  - Predictable skill discovery pattern
  - Clear integration point for tool plugins

- ❌ **Skill:** Skills teach patterns; they can't dynamically discover and load other skills

- ❌ **Hook:** Hooks prevent mistakes; review is about analyzing existing code, not blocking operations

- ❌ **Agent:** Same permissions, same model, same context as parent - no differentiation

- ❌ **MCP:** Built-in tools (Read, Glob, Grep) handle all needs

**Why this is the right level:**

Commands are for **frequent, specific user directives that orchestrate existing capabilities**. Code review is:
- Daily activity for developers
- Requires skill composition from multiple plugins
- Benefits from consistent orchestration
- Clear input (concerns) and output (findings)

#### 2. What cognitive load does it reduce?

**Discovery Cost:** Low
- Single command: `/review`
- Intuitive arguments: concern names
- Auto-completes in UI

**Usage Cost:** Low
- Natural syntax: `/review react typescript`
- No configuration needed
- Self-documenting via `/help`

**Value Provided:**

**Without review plugin:**
- Remember `/react review`, `/typescript review`, `/nextjs review`, `/security review`
- Run 4 separate commands to review React+TypeScript+Next.js+security
- Can't compose concerns
- Duplicate orchestration logic in 4 plugins

**With review plugin:**
- Remember 1 command: `/review`
- Run 1 command: `/review react typescript nextjs security`
- Automatic composition
- Single orchestration point

**Net Cognitive Load:** Strongly Positive
- Reduces N commands → 1 command
- Reduces N orchestration implementations → 1 implementation
- Enables composition impossible before

#### 3. Why can't parent Claude + existing tools do this?

**Parent Claude limitations:**

1. **No skill discovery mechanism:** Parent can't dynamically discover which plugins have review skills
2. **No standardized orchestration:** Each conversational review would vary in process
3. **No concern filtering:** Can't easily load only React skills, skip TypeScript skills
4. **No composition pattern:** Difficult to compose multiple domain reviews consistently

**What the command adds:**

- Standardized skill discovery protocol (`review: true` tag)
- Concern-based filtering of skills
- Consistent orchestration across all reviews
- Clear extension point for tool plugins

#### 4. How does this compose with other plugins?

**With tool plugins:**

Tool plugins expose review skills via:
```json
{
  "name": "react-19",
  "exports": {
    "review-skills": "./concerns/*/skills/review-*.md"
  }
}
```

Skills tagged with `review: true`:
```markdown
---
name: review-hook-patterns
description: Review React hook usage for React 19 compliance
review: true
---
```

**Composition:**
- Tool plugins provide domain knowledge (skills)
- Review plugin provides orchestration (command)
- No coupling - tool plugins don't know about review plugin
- No duplication - each concern implemented once

**With other cross-cutting plugins:**

Following the same pattern:
- `/migrate` - Orchestrates migration skills
- `/test` - Orchestrates testing skills
- `/docs` - Orchestrates documentation skills

**Shared primitives:**
- Skill discovery via frontmatter tags
- Concern-based filtering
- Plugin metadata exports

**No conflicts:**
- Each plugin owns its orchestration domain
- No overlapping commands
- Composable workflows (review → test → migrate)

## Design Hierarchy Analysis

### Level 1: Can parent Claude do this?

❌ **No**

Parent Claude cannot:
- Dynamically discover review skills from installed plugins
- Filter skills by concern without explicit loading
- Provide consistent orchestration across tool plugins
- Know which plugins have review capabilities

### Level 2: Can a skill teach this?

❌ **No**

Skills are for teaching patterns, not orchestrating other skills. A skill cannot:
- Discover other skills from different plugins
- Load skills conditionally based on arguments
- Coordinate multi-plugin workflows

### Level 3: Can a hook prevent this?

❌ **No**

Hooks are for validation and error prevention. Review is:
- Analytical (examining code)
- Not preventive (not blocking operations)
- Post-hoc (code already written)
- Conversational (requires user interaction)

### Level 4: Is this a frequent directive?

✅ **YES**

Code review is:
- Daily developer activity
- Repeated multiple times per session
- Benefits from consistent process
- Clear, specific intent

**Command justified at this level.**

### Why we stopped here:

- MCP not needed (built-in tools suffice)
- Agent not needed (no permission/model/context differentiation)

## Minimal Cognitive Load Proof

### The Prime Directive

**Every component must justify its existence by reducing cognitive load more than it adds.**

**Discovery cost:** Low
- 1 command to remember: `/review`
- Natural arguments: concern names
- Listed in `/help`

**Usage cost:** Low
- Syntax is intuitive: `/review [what to review]`
- No configuration required
- Works immediately after install

**Value provided:**

**Scenario 1: Review React code**

Before:
```
User: Remember /react review command exists
User: Run /react review
```

After:
```
User: Remember /review command exists
User: Run /review react
```

**Same cost, but...**

**Scenario 2: Review React + TypeScript + Security**

Before:
```
User: Remember 3 commands exist
User: Run /react review
User: Run /typescript review
User: Run /security review
User: Mentally combine 3 separate outputs
```

After:
```
User: Remember 1 command exists
User: Run /review react typescript security
User: Receive unified output
```

**Massive cost reduction**

### Calculation

**Without review plugin:**
- Discovery: N commands (N = number of tool plugins)
- Usage: Run N commands separately
- Mental overhead: Combine N outputs
- Maintenance: Update N orchestration implementations

**With review plugin:**
- Discovery: 1 command
- Usage: Run 1 command with N concerns
- Mental overhead: Unified output
- Maintenance: Update 1 orchestration

**Net impact:** Reduces cognitive load by factor of N

## The Five Truths Compliance

### 1. The Parent Claude Is Already Capable

**Truth:** Parent Claude with skills loaded can do almost anything.

**Compliance:** ✅
- Plugin doesn't duplicate parent capabilities
- Plugin adds skill discovery and orchestration
- Parent still does the actual review (using discovered skills)
- Plugin is infrastructure, not intelligence

### 2. Progressive Disclosure Beats Preloading

**Truth:** Loading everything upfront wastes context.

**Compliance:** ✅
- Command loads only when invoked
- Skills loaded only for requested concerns
- `/review react` loads only React skills, not TypeScript
- `/review` without args can load all, but that's explicit user choice

### 3. Context Is Expensive, Events Are Cheap

**Truth:** Context consumes tokens. Event hooks consume none until triggered.

**Compliance:** ✅
- No hooks (no event cost)
- Command context loaded only on invocation
- Skills loaded progressively based on concerns
- No persistent context overhead

### 4. Conversation Beats Commands for Complexity

**Truth:** Natural language handles nuance and context.

**Compliance:** ✅
- Command handles simple case: "review these concerns"
- Complex cases still conversational:
  - "Review my auth refactor" → conversational
  - "Review this specific function" → conversational
  - "Review for security issues in login flow" → conversational
- Command is shortcut for frequent simple case
- Doesn't prevent conversational usage

### 5. Composition Over Duplication

**Truth:** Multiple plugins should compose cleanly.

**Compliance:** ✅
- Zero domain knowledge duplication
- Clear boundary: tool plugins = knowledge, review plugin = orchestration
- Explicit extension points (exports.review-skills)
- Shared primitives (frontmatter tags, concern names)
- No tight coupling

## Anti-Pattern Avoidance

### ❌ The God Agent

**Anti-pattern:** One agent that handles everything.

**Avoided:** ✅
- Zero agents
- Zero domain knowledge
- Pure orchestration
- Delegates to tool plugin skills

### ❌ The Redundant Command

**Anti-pattern:** Commands for things users say naturally.

**Addressed:** ⚠️ Partial
- Users COULD say "review my React code" naturally
- Command provides value through:
  - Consistent orchestration
  - Explicit concern filtering
  - Composable syntax
  - Clear extension point for plugins

**Justification:** Command isn't replacing natural language, it's providing composition that's awkward conversationally:
- Natural: "Review my code" ✅
- Awkward: "Review my code for React, TypeScript, Next.js, and security concerns using review skills from all installed plugins" ❌
- Command: `/review react typescript nextjs security` ✅

### ❌ The Duplicate Skill

**Anti-pattern:** Multiple plugins teaching same pattern.

**Avoided:** ✅
- Zero skills in review plugin
- All knowledge in tool plugins
- Single source of truth per concern
- References via discovery, not duplication

### ❌ The Over-Engineered Hook

**Anti-pattern:** Hooks that do complex analysis.

**Avoided:** ✅
- Zero hooks
- Review is analytical, not preventive
- Hooks would be wrong component type

### ❌ The Unclear Boundary

**Anti-pattern:** Plugin that doesn't know what it owns.

**Avoided:** ✅
- Crystal clear: orchestration only
- Explicitly documented: zero domain knowledge
- Clear dependencies: consumes review-skills from tool plugins
- Single responsibility: coordinate review

### ❌ The Chatty Hook

**Anti-pattern:** Hooks that log everything.

**Avoided:** ✅
- Zero hooks

### ❌ The Kitchen Sink MCP

**Anti-pattern:** MCP server that does everything.

**Avoided:** ✅
- Zero MCP servers
- Built-in tools sufficient

## Success Criteria

### Effectiveness ✅

- [x] Single command handles all review concerns
- [x] Users can compose multiple concerns
- [x] Tool plugins integrate automatically
- [x] Works with zero to N tool plugins

### Simplicity ✅

- [x] Review plugin < 100 lines of orchestration code (command is ~200 lines markdown, mostly docs)
- [x] Tool plugins just tag skills with `review: true`
- [x] No explicit registration required
- [x] Zero configuration

### Extensibility ✅

- [x] New tool plugins work without changes to review plugin
- [x] Review format changes in one place (commands/review.md)
- [x] Multiple cross-cutting plugins coexist
- [x] Pattern documented for replication (/migrate, /test, /docs)

## Comparison with Alternatives

### Alternative 1: No Review Plugin (Each Tool Plugin Has Command)

**Structure:**
```
plugins/
├── react-19/commands/react-review.md
├── typescript/commands/typescript-review.md
└── nextjs-15/commands/nextjs-review.md
```

**Problems:**
- 3 commands to remember
- Can't compose: want React+TypeScript? Run both
- Orchestration duplicated 3 times
- Update review format? Change 3 files

**Cognitive load:** High (3 commands × 3 tool plugins = 9 mental items)

### Alternative 2: Review Plugin with Bundled Knowledge

**Structure:**
```
review/
├── skills/review-react.md
├── skills/review-typescript.md
└── skills/review-nextjs.md
```

**Problems:**
- Duplicates tool plugin knowledge
- Must update review plugin when React/TypeScript/Next.js change
- Tight coupling
- Violates composition over duplication

**Cognitive load:** Medium, but maintenance nightmare

### Alternative 3: Skill-Based Review (No Command)

**Structure:**
```
review/
└── skills/orchestrating-reviews.md
```

**Problems:**
- Skills can't dynamically discover other skills
- No programmatic skill loading
- Inconsistent execution
- Can't filter by concerns

**Cognitive load:** Low discovery, high usage (must explain process each time)

### Chosen Solution: Cross-Cutting Command

**Structure:**
```
review/
└── commands/review.md
```

**Benefits:**
- 1 command regardless of tool plugin count
- Composable concerns
- Single orchestration point
- Zero duplication
- Clean boundaries

**Cognitive load:** Minimal (1 command, intuitive syntax, automatic integration)

## Conclusion

The review plugin is **perfectly aligned** with the Claude Code plugin philosophy:

1. **Minimal Cognitive Load:** Reduces N commands → 1 command
2. **Design Hierarchy:** Stopped at right level (command for frequent directive)
3. **Progressive Disclosure:** Loads only requested concerns
4. **Context Efficient:** No persistent overhead
5. **Single Responsibility:** Pure orchestration, zero domain knowledge
6. **Composition:** Clean boundaries with tool plugins
7. **Five Truths:** Compliant with all

**The review plugin demonstrates the cross-cutting pattern that enables rich ecosystem composition without command proliferation or knowledge duplication.**

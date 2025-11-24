# Claude Code Plugin System Philosophy

**Version:** 1.0 | **Date:** 2025-11-19 | **Purpose:** North star for plugin development decisions

---

## Core Philosophy

### The Prime Directive

Every component must reduce cognitive load (discovery cost + usage cost) more than it adds. If users forget the component exists or how to use it, the value doesn't justify the overhead.

### The Five Truths

1. **Parent Claude Is Capable**: Adding components creates overhead; only add when providing clear differentiation
2. **Progressive Disclosure > Preloading**: Layer capabilities as needed; prefer skills (progressive) over agents (full context)
3. **Context Is Expensive, Events Are Cheap**: Hooks consume no tokens until triggered; prefer event-driven over context-driven
4. **Conversation > Commands for Complexity**: Natural language handles nuance; commands are rare shortcuts for frequent, simple directives
5. **Composition Over Duplication**: Multiple plugins compose cleanly with clear boundaries and shared primitives

### Design Hierarchy

Evaluate solutions in order; stop at first "yes":

1. Can parent Claude do this with existing skills? → Don't add anything
2. Can a skill teach this? → Add skill (progressive disclosure)
3. Can a hook prevent this? → Add hook (event-driven)
4. Is this a frequent user directive? → Maybe add command
5. Does this need external tools? → Maybe add MCP server
6. Does this need isolation + different permissions/model? → Maybe add agent

---

## Component Decision Framework

| **Component**   | **Purpose**        | **Use When**                                                                                                                | **Don't Use When**                                                                                  | **Key Properties**                                                                                   |
| --------------- | ------------------ | --------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Skills**      | Teach patterns     | Teaching best practices; providing domain knowledge; examples/anti-patterns matter; up-to-date knowledge important          | Knowledge is trivial; pattern rarely applies; better as inline docs; always-on knowledge            | Progressive disclosure; `allowed-tools` restrictions; triggers on description match; markdown format |
| **Hooks**       | Prevent mistakes   | Validating rules; preventing security vulnerabilities; blocking deprecated patterns; stopping prompt injection              | Validation is subjective; errors harmless; false positives likely; slow (>1s)                       | Event-driven; exit code 2 blocks; receives JSON stdin; fast (<500ms ideal)                           |
| **Commands**    | User directives    | Multiple daily requests; simple/unambiguous; clearer than natural language; orchestrates existing skills                    | Needs context/explanation; parent handles conversationally; complex syntax; used <weekly            | Orchestrates capabilities; argument interpolation; self-documenting; single purpose                  |
| **Agents**      | Isolated execution | Different permission mode (read-only, acceptEdits); different model (haiku); isolated context; clear input/output           | Same tools/permissions/model as parent; work in main conversation; domain knowledge better as skill | Separate context; permission mode configurable; model configurable; clear boundaries                 |
| **MCP Servers** | External tools     | External API access (GitHub, databases); specialized parsing (AST, SQL); tool-specific functionality; shared across plugins | Built-in tools sufficient; high startup cost; external dependencies; could be bash script           | Process-based isolation; standard tool protocol; reusable; optional dependencies                     |

**Critical Rule:** If an agent just duplicates parent context with no differentiation, use a skill instead.

---

## Decision Logic

**Primary Selection:**

```
Can parent do X? → YES: Stop, don't add
                → NO: Is X pattern/domain knowledge? → YES: Add Skill
                       → NO: Is X validation/error prevention? → YES: Add Hook
                              → NO: Is X frequent directive? → YES: Add Command
                                     → NO: External tools needed? → YES: Add MCP
                                            → NO: Needs isolation? → YES: Add Agent
                                                   → STOP: Reconsider
```

**Agent vs Skill:** Does Y need isolation? → YES: Different permissions? → YES: Agent; NO: Skill. NO: Skill.

**Command vs Conversational:** Used >daily AND simple to express? → YES: Command; NO: Conversational.

**Core vs Addon:** Works without external deps? → YES: Used by >50% of users? → YES: Core; NO: Addon. NO: Addon.

---

## Integration Principles

### 1. Plugin Boundaries: Domain, Not Stack

**Good:** `react-19` (works in Vite, CRA, Next.js, Remix); `nextjs-15` (framework features); `testing-tools` (all frameworks)

**Bad:** `react-nextjs-combo` (mixes concerns); `frontend-everything` (too broad); project-specific (non-reusable)

**Test:** Does feature F work without framework X? If yes, exclude from X's plugin.

### 2. Skill Composition: Reference, Don't Duplicate

Reference base skills via `Use the [skill-name] skill to...`. Framework plugins add specifics only.

### 3. Hook Composition: Additive, Not Conflicting

All hooks run in parallel, each validating its domain. No overlapping validation.

### 4. Command Namespacing

**Tool Plugins:** `/<plugin> <verb> [args]` (e.g., `/next deploy`, `/db migrate`)

**Cross-Cutting Plugins:** `/<verb> [concerns...]` (e.g., `/review react typescript security`, `/migrate react-18-to-19`)

**Rule:** Multi-domain commands belong in cross-cutting plugins, not individual tool plugins.

### 5. Validation Rule Composition

Each plugin owns validation for its domain:

```text
react-19/scripts/validate-react-patterns.sh
nextjs-15/scripts/validate-nextjs-patterns.sh
typescript/scripts/validate-typescript-patterns.sh
```

### 6. Cross-Cutting Plugin Pattern

Some functionality applies across domains; separate plugins orchestrate skills from tool plugins.

**Architecture:**

- **Tool Plugins** (React, TypeScript, Next.js, security): Provide domain knowledge via skills tagged `review: true`; zero commands for cross-cutting concerns; focus on patterns + validation
- **Cross-Cutting Plugins** (review, migration, testing): Provide commands working across domains; consume skills from tool plugins

**Example:**

```tree
plugins/
├── react-19/skills/reviewing-state-management/SKILL.md (review: true)
├── typescript/skills/reviewing-type-safety/SKILL.md (review: true)
└── review/skills/reviewing-code-quality/SKILL.md → references "reviewing-state-management" and "reviewing-type-safety" skills to use if reviewing typescript and react code.
```

**Usage:** `/review:multi-review` loads skills from both dynamically.

**Why:** Single command instead of N, composable, no duplication, clear separation of concerns.

---

## Anti-Patterns

| **Pattern**              | **Problem**                                                            | **Solution**                                               |
| ------------------------ | ---------------------------------------------------------------------- | ---------------------------------------------------------- |
| **God Agent**            | Handles everything; duplicates context; no differentiation; high cost  | Use skills for domain knowledge                            |
| **Redundant Command**    | Users must remember syntax; natural language is clearer                | Only for frequent simple directives                        |
| **Duplicate Skill**      | Multiple plugins teach same pattern; maintenance burden; context waste | Base plugin teaches; framework adds specifics + references |
| **Over-Engineered Hook** | Complex analysis; takes 30s; users disable; overlaps linters/typecheck | Fast validators only (<500ms)                              |
| **Unclear Boundary**     | Scope ambiguous; overlaps others; hard to maintain; unwanted features  | One domain per plugin; focused scope                       |
| **Chatty Hook**          | Logs everything; clutters output; users ignore                         | Silent on success; specific on failure                     |
| **Kitchen Sink MCP**     | Handles everything; high startup; unused features; maintenance burden  | Focused servers for specific integrations                  |

---

## Examples

### Example 1: Form Validation

**Process:** Can parent do it? YES, if asked naturally. Can skill teach? YES → `/forms/skills/form-validation.md` (client+server, zod/yup, progressive). Can hook prevent? YES → validate Server Actions have validation. Frequent directive? NO.
**Result:** ✅ Skill + Hook; ❌ No Command/Agent/MCP

### Example 2: GitHub PR Integration

**Process:** Can parent do? NO (needs API). Skill? NO (needs external tool). Hook? NO (not validation). Frequent? MAYBE. External tools? YES → MCP server.
**Result:** ✅ MCP Server; ❌ No Skill/Hook/Command/Agent

### Example 3: Code Review

**Process:** Can parent do? YES. Skill teaches review criteria? YES (per domain). Hook runs auto-checks? YES. Frequent? YES but cross-cutting (React, TypeScript, security).
**Result:** Tool Plugins: ✅ Review skills tagged `review: true` + domain hooks; ❌ No command. Cross-Cutting Review Plugin: ✅ `/review [concerns...]` orchestrates all skills; ❌ No domain knowledge.
**Key:** Single command, composable, no duplication.

### Example 4: Debugging

**Process:** Parent does this? YES. Skill teaches methodology? YES. Hook prevents bugs? YES. Frequent? NO (contextual). Agent helpful? YES (read-only, haiku for speed).
**Result:** ✅ Skill + Hook + Optional Agent (isolated investigation); ❌ No Command/MCP

### Example 5: SQL Queries

**Process:** Parent does this? YES (with schema). Skill teaches patterns? YES. External tools? YES (schema introspection, execution) → Optional MCP.
**Result:** ✅ Skill + Optional MCP; ❌ No Hook (diverse)/Command (contextual)/Agent

---

## Plugin Quality Checklist

- [ ] Every component justifies its cognitive load
- [ ] Skills use progressive disclosure; no duplication across components
- [ ] Hooks fast (<500ms); non-overlapping with existing tools
- [ ] Commands used daily; orchestrate, not duplicate logic
- [ ] Agents provide clear differentiation (permissions/model/isolation)
- [ ] MCP servers provide essential external tools
- [ ] Plugin scope clear, focused; boundaries with other plugins documented
- [ ] Other plugins can extend this one; skills referable; hooks additive
- [ ] Single source of truth for domain knowledge; components independently updateable
- [ ] No tight coupling between plugins

---

## Conclusion

**North Star:** Reduce cognitive load while increasing capability. Every component must solve a real problem parent Claude can't handle alone, be discoverable, be simple to use, compose cleanly, and justify maintenance.

Start with less. It's easier to add later than remove.

**Remember:** Skills teach • Hooks prevent • Commands orchestrate • Agents isolate • MCP servers integrate. Choose the simplest component. Stop there.

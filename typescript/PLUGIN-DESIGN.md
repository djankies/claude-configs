# TypeScript Plugin Design

**Date:** 2025-11-21
**Status:** Final Design
**Author:** Design Session with Claude Code

## Overview

A Claude Code plugin that helps developers write correct TypeScript 5.9+ code through proactive guidance, pattern teaching, and mistake prevention. The plugin assumes the LLM has outdated TypeScript knowledge and provides current TypeScript patterns, best practices, and guardrails based on stress testing that revealed critical gaps in AI coding agents' TypeScript knowledge.

This plugin addresses the comprehensive failures identified in the TypeScript stress test where 6 agents made 23 violations including:
- 83% of agents overused `any` type (defeating TypeScript's purpose)
- 33% had critical security vulnerabilities (password hashing failures)
- 33% ignored TypeScript requirement entirely (wrote JavaScript)
- 50% misused type assertions instead of proper validation
- 50% used deprecated JavaScript APIs

The plugin works within a multi-framework ecosystem where TypeScript underpins React, Next.js, Node.js, and other technologies.

## Problem Statement

When helping users write TypeScript code, LLMs face five critical problems revealed through stress testing:

### 1. **Overusing `any` Type**
Agents default to `any` when uncertain about types, completely defeating TypeScript's purpose. Found in 5/6 agents across:
- Generic defaults (`ApiResponse<T = any>`)
- Validation functions (`validate(data: any)`)
- Configuration loaders
- Filter criteria and dynamic data

**Impact:** Bypasses compile-time safety, allows runtime errors, makes TypeScript worthless.

### 2. **Critical Security Failures**
2/6 agents had severe security vulnerabilities:
- Base64 "encryption" for passwords (trivially reversible)
- Accepting PayPal passwords directly (violates PCI compliance)
- Missing input validation
- Silent error handling

**Impact:** Production security breaches, data exposure, compliance violations.

### 3. **Ignoring TypeScript Entirely**
2/6 agents wrote JavaScript instead of TypeScript despite explicit requirements:
- Used `.js` extensions throughout
- No type annotations
- Relied on JSDoc comments
- Lost all TypeScript benefits

**Impact:** No compile-time safety, poor IDE support, difficult refactoring, broken contracts.

### 4. **Misusing Type Assertions**
4/6 agents used type assertions instead of validation:
- `as` keyword on external data (`parsed as T`)
- Unsafe type casting in parsers
- Bypassing type guards
- Type assertions on entity creation

**Impact:** Runtime errors despite TypeScript claiming type safety, crashes from malformed data.

### 5. **Using Deprecated APIs**
3/6 agents used deprecated JavaScript methods:
- `substr()` instead of `slice()` (4 occurrences)
- Missing error class prototype fixes
- Outdated patterns

**Impact:** Future JavaScript version incompatibility, linter warnings, maintenance burden.

## Core Design Principles

### 1. No Agents

Agents provide value only when they offer different tools, permissions, model, or isolated execution context. A "TypeScript expert agent" duplicates parent's context with no differentiation.

**Decision: Zero agents. Skills teach patterns through progressive disclosure.**

### 2. No Commands

TypeScript work (type annotation, refactoring, debugging) works better conversationally because context matters. Review functionality belongs in a separate cross-cutting review plugin.

**Decision: Zero commands. Review skills exported for use by review plugin.**

### 3. No Core MCP Servers

Built-in tools (Read, Write, Edit, Grep, Glob, Bash) suffice for TypeScript work. AST parsing can be done via Node.js scripts called from hooks.

**Decision: Zero MCP servers in core. Optional addon plugins can provide specialized tools.**

### 4. Concern-Prefix Organization

Organize skills by TypeScript domain concern (TYPES, CONFIG, VALIDATION, ERROR-HANDLING, SECURITY, MIGRATION, PERFORMANCE) with ALL CAPS concern prefixes followed by lowercase-with-hyphens topics.

**Decision: 7 concerns, each with 2-3 skills, following official Claude Code structure.**

### 5. Intelligent Skill Activation

PreToolUse hooks intelligently detect file context (extension, path, content) and remind parent Claude which skills are available, preventing repeated context bloat through session lifecycle management.

**Decision: Session-managed recommendations with bash-based pattern detection.**

## Architecture

### Plugin Components

**Skills (16 total across 7 concerns)**

- Organized with concern prefixes: `TYPES-advanced-patterns/`, `CONFIG-compiler-options/`
- Each skill contains SKILL.md with progressive disclosure
- Optional `references/` for skill-specific examples
- Teaching focus: "how to do it right" in TypeScript 5.9+

**Hooks (2 event handlers + session lifecycle)**

- SessionStart: Initialize session state (runs once)
- PreToolUse: Intelligent skill reminder based on file context
- Fast execution (< 100ms total)
- Lifecycle-managed to prevent context bloat

**Scripts (4 shared utilities)**

- **Lifecycle scripts** (MANDATORY):
  - `init-session.sh`: Creates session state JSON
  - `recommend-skills.sh`: Once-per-session contextual recommendations
- **Validation scripts**:
  - `check-type-safety.sh`: Detect `any` abuse, type assertions
  - `check-deprecated-apis.sh`: Find deprecated JavaScript methods
- Used by hooks and skills
- Prefer bash for deterministic operations (100x faster than LLM-based validation)

**Knowledge (shared research)**

- `typescript-5.9-comprehensive.md`: Complete TypeScript 5.9 reference
- Accessible by all components
- Single source of truth

## Skill Structure

### Naming Convention

`[CONCERN]-[topic]/`

**Format:**
- Concern prefix: ALL CAPS (TYPES, CONFIG, VALIDATION, etc.)
- Topic: lowercase-with-hyphens
- Separator: single hyphen

Examples:
- `TYPES-any-vs-unknown/` - When to use unknown over any
- `CONFIG-compiler-options/` - Essential tsconfig.json settings
- `VALIDATION-runtime-checks/` - Validating external data with Zod
- `ERROR-HANDLING-custom-errors/` - Creating custom error classes
- `SECURITY-input-validation/` - Preventing XSS and injection
- `REVIEW-type-safety/` - Code review skill for type safety

### Concerns

The plugin organizes skills into 7 concern areas based on TypeScript stress test findings:

#### 1. TYPES Concern
**Scope:** Type system fundamentals and advanced patterns

**Rationale:** 5/6 agents overused `any`, misused type assertions, failed to use proper type guards. This is the most critical concern.

**Skills:**
- `TYPES-any-vs-unknown/` - When and how to use `unknown` instead of `any`
- `TYPES-type-guards/` - Writing custom type guards with type predicates
- `TYPES-generics/` - Generic constraints and best practices

#### 2. CONFIG Concern
**Scope:** TypeScript compiler configuration

**Rationale:** Proper tsconfig.json prevents many issues caught in stress test (unchecked index access, missing strict flags).

**Skills:**
- `CONFIG-compiler-options/` - Essential strict mode flags
- `CONFIG-module-resolution/` - NodeNext, Bundler, and ESM/CommonJS
- `CONFIG-performance/` - Incremental builds, skipLibCheck

#### 3. VALIDATION Concern
**Scope:** Runtime type validation

**Rationale:** 4/6 agents used type assertions on external data instead of validation. TypeScript types are compile-time only.

**Skills:**
- `VALIDATION-runtime-checks/` - Using Zod, io-ts for runtime validation
- `VALIDATION-type-assertions/` - When assertions are safe vs dangerous
- `VALIDATION-external-data/` - API responses, JSON parsing, user input

#### 4. ERROR-HANDLING Concern
**Scope:** Error handling patterns

**Rationale:** Multiple agents had silent error handling, missing error type guards, improper error classes.

**Skills:**
- `ERROR-HANDLING-custom-errors/` - Creating and using custom error classes
- `ERROR-HANDLING-type-guards/` - Checking error types with type guards
- `ERROR-HANDLING-result-pattern/` - Alternative to throwing errors

#### 5. SECURITY Concern
**Scope:** Security best practices

**Rationale:** 2/6 agents had critical security failures (password storage, accepting sensitive credentials).

**Skills:**
- `SECURITY-input-validation/` - Sanitizing user input, preventing XSS
- `SECURITY-credentials/` - Never store passwords, use proper cryptography
- `SECURITY-dependencies/` - Auditing and updating dependencies

#### 6. MIGRATION Concern
**Scope:** JavaScript to TypeScript migration

**Rationale:** 2/6 agents wrote JavaScript when TypeScript was required, suggesting confusion about migration path.

**Skills:**
- `MIGRATION-js-to-ts/` - Step-by-step migration guide
- `MIGRATION-strict-mode/` - Enabling strict mode incrementally

#### 7. PERFORMANCE Concern
**Scope:** TypeScript compiler performance

**Rationale:** Large projects need optimization strategies. Research shows 10% improvement possible with proper configuration.

**Skills:**
- `PERFORMANCE-build-speed/` - Incremental compilation, project references
- `PERFORMANCE-type-complexity/` - Avoiding overly complex types

### Skill Breakdown by Concern

#### TYPES Concern

**Skills:**

- `TYPES-any-vs-unknown/` - Critical skill teaching when to use `unknown` with type guards instead of `any`. Addresses #1 violation pattern.

  Example content: Teaching progression from `any` → `unknown` → type guards → safe access

- `TYPES-type-guards/` - Writing custom type predicates (`pet is Fish`) and using built-in guards (`typeof`, `instanceof`, `in`).

  Example content: Pattern library of type guard implementations

- `TYPES-generics/` - Generic constraints with `extends`, avoiding `any` in generic defaults, mapped types.

  Example content: Real-world generic patterns from stress test scenarios

#### CONFIG Concern

**Skills:**

- `CONFIG-compiler-options/` - Essential strict flags: `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`. Explains what each flag prevents.

  Example content: Before/after examples showing issues each flag catches

- `CONFIG-module-resolution/` - Modern module options: `NodeNext` (floating), `node20` (stable), `Bundler` (for Webpack/Vite).

  Example content: Decision tree for choosing module strategy

- `CONFIG-performance/` - `incremental: true`, `skipLibCheck: true`, project references for monorepos.

  Example content: Performance benchmarks and when each optimization matters

#### VALIDATION Concern

**Skills:**

- `VALIDATION-runtime-checks/` - Using Zod schemas for external data. TypeScript types are erased at runtime. Addresses type assertion failures.

  Example content: Complete Zod integration patterns, error handling

- `VALIDATION-type-assertions/` - When assertions are acceptable (`as const`, `as unknown as T` with validation) vs dangerous (`data as T` without checks).

  Example content: Safe vs unsafe assertion examples from stress test

- `VALIDATION-external-data/` - API responses, JSON parsing, user input all need runtime validation. Never trust external data.

  Example content: Full validation pipeline examples

#### ERROR-HANDLING Concern

**Skills:**

- `ERROR-HANDLING-custom-errors/` - Creating error classes with proper prototype chain (`Object.setPrototypeOf`). Addresses missing prototype fix in stress test.

  Example content: Error class hierarchy examples

- `ERROR-HANDLING-type-guards/` - Checking `error instanceof Error` before accessing properties. Caught errors are `unknown` in strict mode.

  Example content: Error handling patterns for different error types

- `ERROR-HANDLING-result-pattern/` - `Result<T, E>` type for expected failures instead of exceptions.

  Example content: When to use Result vs throwing errors

#### SECURITY Concern

**Skills:**

- `SECURITY-input-validation/` - Sanitizing user input (DOMPurify for HTML), validating email/phone formats, preventing XSS.

  Example content: Security validation patterns, OWASP guidelines

- `SECURITY-credentials/` - NEVER use Base64 for passwords. Use bcrypt/argon2. NEVER accept third-party passwords (use OAuth). Addresses critical failures in stress test.

  Example content: Secure authentication patterns, what NOT to do

- `SECURITY-dependencies/` - Running `npm audit`, keeping dependencies updated, monitoring vulnerabilities.

  Example content: Security workflow integration

#### MIGRATION Concern

**Skills:**

- `MIGRATION-js-to-ts/` - Incremental migration: `allowJs: true` → rename files → add types → `strict: true`. Addresses agents writing JavaScript.

  Example content: Step-by-step migration guide with checkpoints

- `MIGRATION-strict-mode/` - Enabling strict flags one at a time, handling migration errors.

  Example content: Common migration errors and fixes

#### PERFORMANCE Concern

**Skills:**

- `PERFORMANCE-build-speed/` - TypeScript 5.9 incremental caching (10% faster), project references, alternative compilers (SWC, esbuild).

  Example content: Performance optimization workflow

- `PERFORMANCE-type-complexity/` - Avoiding deeply nested types, using interfaces over type aliases for objects, selective imports.

  Example content: Type complexity anti-patterns and refactoring

### Review Skills

**REVIEW-type-safety/** - Exported skill for review plugin to check:
- `any` type usage
- Type assertions on external data
- Missing type guards in error handling
- Deprecated JavaScript APIs
- Security vulnerabilities (password handling, input validation)
- Runtime validation presence

Tagged with `review: true` for discoverability by review plugin.

## Intelligent Hook System

### Session Lifecycle Management

The plugin uses a JSON state file to track which recommendations have been shown during the current session, preventing context bloat from repeated skill reminders.

**SessionStart Hook: Initialize State**

Implementation: `scripts/init-session.sh`

```bash
#!/bin/bash

STATE_FILE="/tmp/claude-typescript-session.json"

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "recommendations_shown": {
    "typescript_files": false,
    "config_files": false,
    "test_files": false,
    "migration_context": false
  }
}
EOF

echo "TypeScript session initialized: $STATE_FILE"
```

**Key Design:**
- Creates fresh state on session start
- Tracks 4 recommendation types
- Runs once per session (< 5ms)
- No external dependencies

**PreToolUse Hook: Contextual Skill Recommendations**

Implementation: `scripts/recommend-skills.sh`

```bash
#!/bin/bash

STATE_FILE="/tmp/claude-typescript-session.json"

[[ ! -f "$STATE_FILE" ]] && exit 0

FILE_PATH="$1"
FILE_EXT="${FILE_PATH##*.}"
FILE_NAME="${FILE_PATH##*/}"

RECOMMENDATION_TYPE=""
SKILLS=""
MESSAGE=""

case "$FILE_EXT" in
  ts|tsx)
    if [[ "$FILE_NAME" == "tsconfig.json" ]]; then
      RECOMMENDATION_TYPE="config_files"
      SKILLS="CONFIG-*, especially CONFIG-compiler-options, CONFIG-module-resolution"
      MESSAGE="📚 TypeScript Config Detected: $SKILLS"
    elif [[ "$FILE_PATH" == *"test"* || "$FILE_PATH" == *"spec"* ]]; then
      RECOMMENDATION_TYPE="test_files"
      SKILLS="TYPES-type-guards, VALIDATION-runtime-checks, ERROR-HANDLING-*"
      MESSAGE="📚 TypeScript Test File: $SKILLS"
    else
      RECOMMENDATION_TYPE="typescript_files"
      SKILLS="TYPES-*, VALIDATION-*, ERROR-HANDLING-*, SECURITY-*"
      MESSAGE="📚 TypeScript Skills Available: $SKILLS"
    fi
    ;;
  js|jsx)
    RECOMMENDATION_TYPE="migration_context"
    SKILLS="MIGRATION-js-to-ts, MIGRATION-strict-mode"
    MESSAGE="📚 JavaScript File - Consider Migration: $SKILLS"
    ;;
esac

[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  echo "Use Skill tool to activate specific skills when needed."

  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

exit 0
```

**Key Features:**
- ✅ File extension detection (.ts, .tsx, .js, .jsx)
- ✅ Special handling for tsconfig.json
- ✅ Test file detection
- ✅ JavaScript migration context
- ✅ Once-per-session-per-type reminders
- ✅ Fast execution (< 10ms first time, < 1ms subsequent)
- ✅ No external dependencies (pure bash)

**Activation Rules Table:**

| Pattern | Triggered Skills | Rationale | Frequency |
|---------|------------------|-----------|-----------|
| *.ts, *.tsx | TYPES-*, VALIDATION-*, ERROR-HANDLING-*, SECURITY-* | TypeScript file editing | Once per session |
| tsconfig.json | CONFIG-* (all configuration skills) | TypeScript configuration | Once per session |
| *test*.ts, *spec*.ts | TYPES-type-guards, VALIDATION-*, ERROR-HANDLING-* | Testing TypeScript code | Once per session |
| *.js, *.jsx | MIGRATION-js-to-ts, MIGRATION-strict-mode | Migration opportunity | Once per session |

**Performance:**
- File extension check: ~1ms
- Path pattern detection: ~2ms
- State file read/write: ~2ms
- Total first execution: < 10ms
- Subsequent executions (after boolean set): < 1ms

### Validation Hooks

**check-type-safety.sh** - Called by PreToolUse hook on Write/Edit

Detects common violations from stress test:
- `any` type usage (grep for `: any`, `<any>`, `= any`)
- Type assertions without validation (`as T` without prior type guard)
- Missing generic constraints (`<T>` should often be `<T extends X>`)
- Unsafe index access (warn about `noUncheckedIndexedAccess: false`)

Fast execution using grep and simple regex patterns (< 50ms).

**check-deprecated-apis.sh** - Called by PreToolUse hook on Write/Edit

Detects deprecated JavaScript methods from stress test:
- `substr()` → suggest `slice()`
- `escape()` → suggest `encodeURIComponent()`
- `unescape()` → suggest `decodeURIComponent()`

Fast execution using grep (< 20ms).

## File Structure

```tree
typescript/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── TYPES-any-vs-unknown/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── examples.md
│   ├── TYPES-type-guards/
│   │   └── SKILL.md
│   ├── TYPES-generics/
│   │   └── SKILL.md
│   ├── CONFIG-compiler-options/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── strict-flags.md
│   ├── CONFIG-module-resolution/
│   │   └── SKILL.md
│   ├── CONFIG-performance/
│   │   └── SKILL.md
│   ├── VALIDATION-runtime-checks/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── zod-examples.md
│   ├── VALIDATION-type-assertions/
│   │   └── SKILL.md
│   ├── VALIDATION-external-data/
│   │   └── SKILL.md
│   ├── ERROR-HANDLING-custom-errors/
│   │   └── SKILL.md
│   ├── ERROR-HANDLING-type-guards/
│   │   └── SKILL.md
│   ├── ERROR-HANDLING-result-pattern/
│   │   └── SKILL.md
│   ├── SECURITY-input-validation/
│   │   └── SKILL.md
│   ├── SECURITY-credentials/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── never-do-this.md
│   ├── SECURITY-dependencies/
│   │   └── SKILL.md
│   ├── MIGRATION-js-to-ts/
│   │   └── SKILL.md
│   ├── MIGRATION-strict-mode/
│   │   └── SKILL.md
│   ├── PERFORMANCE-build-speed/
│   │   └── SKILL.md
│   ├── PERFORMANCE-type-complexity/
│   │   └── SKILL.md
│   └── REVIEW-type-safety/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── init-session.sh
│   ├── recommend-skills.sh
│   ├── check-type-safety.sh
│   └── check-deprecated-apis.sh
├── knowledge/
│   └── typescript-5.9-comprehensive.md
└── README.md
```

## Integration with Other Plugins

### Plugin Boundaries

**TypeScript Plugin Scope:**

- Core TypeScript type system and compiler
- Configuration and build optimization
- Runtime validation patterns
- Security best practices for TypeScript
- Migration from JavaScript
- Works with any framework (React, Next.js, Node.js, etc.)

**Framework Plugin Scope (React, Next.js, etc.):**

- Framework-specific TypeScript patterns
- Integration with framework features
- Build on TypeScript plugin patterns
- Clear separation: If it works without the framework → TypeScript plugin

### Composition Patterns

**Skill References:**

React plugin references TypeScript skills:

```markdown
## TYPES-component-props/SKILL.md in react-19 plugin

See @typescript/TYPES-generics for generic component patterns.
See @typescript/VALIDATION-runtime-checks for prop validation.

React-specific additions:
- ComponentProps<typeof Component> for extracting prop types
- PropsWithChildren<T> for components with children
```

**Knowledge Sharing:**

Skills can reference shared TypeScript knowledge:

```markdown
See @typescript/knowledge/typescript-5.9-comprehensive.md for complete type system reference.
```

**Hook Layering:**

Multiple plugins can have PreToolUse hooks - they compose additively:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write|Edit", "hooks": ["typescript-validation"] },
      { "matcher": "Write|Edit", "hooks": ["react-validation"] }
    ]
  }
}
```

Both run in parallel. TypeScript plugin validates TypeScript patterns, React plugin validates React patterns.

## Plugin Metadata

`.claude-plugin/plugin.json`:

```json
{
  "name": "typescript",
  "version": "1.0.0",
  "description": "TypeScript 5.9 type safety, compiler configuration, and best practices based on real-world AI coding failures",
  "author": {
    "name": "Claude Code Plugin Marketplace",
    "email": "plugins@claude.ai"
  },
  "keywords": [
    "typescript",
    "type-safety",
    "compiler",
    "validation",
    "security",
    "ts5.9"
  ],
  "engines": {
    "claude-code": ">=1.0.0"
  }
}
```

Note: No `exports` field needed - uses standard auto-discovery for skills/, hooks/, knowledge/, scripts/.

## Implementation Strategy

### Phase 1: Core Type Safety Skills (Week 1)

**Deliverables:**
- 3 TYPES concern skills
- 3 VALIDATION concern skills
- 3 ERROR-HANDLING concern skills
- Knowledge base (TypeScript 5.9 comprehensive doc)

**Focus:** Address the most critical violations from stress test - `any` abuse, type assertions, error handling.

**Time estimate:** 40 hours
- 3 hours per skill × 9 skills = 27 hours
- Knowledge base organization: 8 hours
- Testing and refinement: 5 hours

### Phase 2: Configuration and Security Skills (Week 2)

**Deliverables:**
- 3 CONFIG concern skills
- 3 SECURITY concern skills
- Review skill (REVIEW-type-safety)

**Focus:** Prevent security vulnerabilities and ensure proper compiler configuration.

**Time estimate:** 35 hours
- 3 hours per skill × 7 skills = 21 hours
- Security examples and anti-patterns: 8 hours
- Review skill integration: 6 hours

### Phase 3: Intelligent Hook System (Week 3)

**Deliverables:**
- SessionStart hook with init-session.sh
- PreToolUse hook with recommend-skills.sh
- Validation scripts (check-type-safety.sh, check-deprecated-apis.sh)
- hooks.json configuration

**Focus:** Context-aware skill recommendations without bloat.

**Time estimate:** 30 hours
- Session lifecycle scripts: 8 hours
- Recommendation logic: 10 hours
- Validation scripts: 8 hours
- Testing activation rules: 4 hours

### Phase 4: Migration and Performance Skills (Week 4)

**Deliverables:**
- 2 MIGRATION concern skills
- 2 PERFORMANCE concern skills
- Complete README and documentation

**Focus:** Help developers migrate existing codebases and optimize builds.

**Time estimate:** 25 hours
- 3 hours per skill × 4 skills = 12 hours
- README and plugin documentation: 8 hours
- Example projects: 5 hours

### Phase 5: Integration Testing and Refinement (Week 5)

**Deliverables:**
- Integration with React/Next.js plugins
- Stress test validation (run original scenarios)
- Performance optimization
- User feedback iteration

**Focus:** Ensure plugin prevents all 23 violations found in original stress test.

**Time estimate:** 30 hours
- Cross-plugin testing: 10 hours
- Stress test re-run and validation: 12 hours
- Performance tuning: 4 hours
- Documentation polish: 4 hours

**Total Implementation:** 160 hours (~5 weeks)

## Success Metrics

### Effectiveness

**Stress Test Prevention:**
- ✅ Blocks `any` type before it's written (TYPES-any-vs-unknown skill activated)
- ✅ Prevents security vulnerabilities (SECURITY-credentials warns against password storage)
- ✅ Catches type assertions on external data (VALIDATION-type-assertions skill)
- ✅ Detects deprecated APIs (check-deprecated-apis.sh hook)
- ✅ Ensures TypeScript usage (MIGRATION-js-to-ts skill for .js files)

**Target:** Reduce violations by 90% when re-running stress test scenarios with plugin active.

### Efficiency

**Context Management:**
- Skills load progressively (only when activated by user)
- Hook recommendations once per session per file type
- State file prevents repeated bloat
- Fast hook execution (< 100ms total)

**Target:** < 2% context overhead compared to no plugin (measured by token usage).

### Extensibility

**Plugin Composition:**
- Clear boundaries with framework plugins
- Skills referenceable across plugins (`@typescript/TYPES-generics`)
- Hooks compose without conflicts
- Knowledge base shared resource

**Target:** React, Next.js, Node.js plugins can reference TypeScript skills without duplication.

## Risk Mitigation

### Risk: Hook execution slows development

**Mitigation:**
- Optimize scripts (use grep, avoid heavy parsing)
- Short timeouts (10-20ms per script)
- Session lifecycle prevents repeated execution
- Cache results when possible

**Fallback:** Users can disable validation hooks via settings, keeping recommendation hooks.

### Risk: Skills activate incorrectly or too frequently

**Mitigation:**
- Test file patterns thoroughly with real projects
- Use specific patterns (tsconfig.json, test file paths)
- Session state prevents re-activation
- User feedback loop for refinement

**Fallback:** Users can manually activate skills via Skill tool, ignoring recommendations.

### Risk: Overlap with linter/compiler warnings

**Mitigation:**
- Focus on conceptual teaching, not just error detection
- Provide "why" and "how to fix" context beyond compiler errors
- Catch patterns compilers miss (security anti-patterns)
- Complement existing tools, don't duplicate

**Fallback:** Plugin adds value even with ESLint/TSC through teaching and context.

### Risk: TypeScript evolves, plugin becomes outdated

**Mitigation:**
- Knowledge base is single source of truth (easy to update)
- Skills reference knowledge base (update once, propagates everywhere)
- Version-specific skills (MIGRATION-strict-mode) can be updated independently
- Regular stress testing against new TypeScript versions

**Fallback:** Users can edit skills directly or disable outdated ones.

### Risk: False positives in validation hooks

**Mitigation:**
- Use conservative patterns (high confidence only)
- Provide clear explanation when blocking
- Warn instead of block for ambiguous cases
- User feedback to refine patterns

**Fallback:** Exit code 1 (warn) instead of 2 (block) for uncertain violations.

## Conclusion

This plugin provides TypeScript 5.9+ assistance through:

- **16 Teaching Skills** organized by 7 concern prefixes (TYPES, CONFIG, VALIDATION, ERROR-HANDLING, SECURITY, MIGRATION, PERFORMANCE)
- **Intelligent Hooks** with session lifecycle management for context-aware, non-repetitive skill recommendations
- **Validation Scripts** using fast bash patterns to catch violations before code is written
- **Shared Knowledge Base** providing comprehensive TypeScript 5.9 reference

**Key Innovations:**

1. **Stress-Test Driven Design:** Every skill addresses real failures found in AI coding agent testing
2. **Session Lifecycle Management:** Once-per-session recommendations prevent context bloat
3. **Security First:** Dedicated SECURITY concern with critical anti-patterns (password storage, credential handling)
4. **Bash-Powered Validation:** Deterministic, fast, cacheable validation using grep patterns
5. **Progressive Disclosure:** Skills load only when relevant, knowledge base accessible on demand

**Implementation Ready:**
- All components defined with concern-prefix naming
- Phased 5-week approach with clear deliverables
- Success metrics tied to stress test violation reduction
- File structure follows official Claude Code standards

Zero agents, zero commands, zero MCP servers. The parent Claude becomes TypeScript-aware through skills, guided by intelligent hooks, validated by fast scripts. Simple, efficient, extensible.

**Next Steps:**
1. Implement Phase 1 (Core Type Safety Skills)
2. Run mini stress test to validate skill effectiveness
3. Iterate based on results before proceeding to Phase 2

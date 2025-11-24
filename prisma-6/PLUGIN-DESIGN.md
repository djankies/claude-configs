# Prisma 6 Plugin Design

**Date:** 2025-11-21
**Status:** Final Design
**Author:** Design Session with Claude Code

## Overview

A Claude Code plugin that helps developers write correct Prisma 6 code through proactive guidance, pattern teaching, and mistake prevention. The plugin assumes LLMs have outdated Prisma knowledge and provides current patterns, best practices, and guardrails based on stress testing that revealed critical gaps in AI coding agents' Prisma knowledge.

This plugin addresses comprehensive failures identified in Prisma stress testing where 5 agents made 30 violations including:

- 80% created multiple PrismaClient instances (connection pool exhaustion)
- 40% used SQL injection via unsafe APIs
- 60% missed serverless connection configuration
- 20% used deprecated Buffer API (Prisma 6 breaking change)
- Multiple agents had poor error handling, missing validation, and type safety issues

The plugin works within a multi-framework ecosystem where Prisma underpins Next.js, Node.js, serverless, and other technologies.

## Problem Statement

When helping users write Prisma code, LLMs face five critical problems revealed through stress testing:

### 1. **Multiple PrismaClient Instances**

Agents create `new PrismaClient()` in functions, modules, and test files, completely defeating connection pooling. Found in 4/5 agents across:

- Module-level exports without singleton pattern
- Function-scoped client creation
- Test file instantiation
- Missing serverless global pattern

**Impact:** Connection pool exhaustion, P1017 errors, Lambda failures.

### 2. **SQL Injection via Unsafe APIs**

2/5 agents used `$queryRawUnsafe` or `Prisma.raw()` with string interpolation:

- Manual sanitization attempts
- Dynamic table/column names
- Filter conditions with user input
- JSON operators with interpolated values

**Impact:** Critical security vulnerabilities, SQL injection attacks.

### 3. **Missing Serverless Configuration**

3/5 agents deployed to serverless without `connection_limit=1`:

- Default connection pool size
- No PgBouncer consideration
- Multiple Lambda instances × pool size = exhaustion
- Production P1017 failures

**Impact:** Database connection exhaustion in production serverless deployments.

### 4. **Prisma 6 Breaking Changes**

Agents unaware of v6 breaking changes:

- Buffer API replaced with Uint8Array (1 agent used deprecated API)
- Implicit m-n primary key changes
- NotFoundError removal (P2025 handling)
- Reserved keywords (`async`, `await`, `using`)

**Impact:** Type errors, runtime failures, migration issues after upgrade.

### 5. **Poor Error Handling and Validation**

Multiple agents had:

- Generic catch blocks hiding Prisma errors
- Missing P2002/P2025 error code handling
- Type assertions without runtime validation
- No input validation before database operations

**Impact:** Poor UX, exposed errors, runtime type mismatches.

## Core Design Principles

### 1. No Agents

Agents provide value only when they offer different tools, permissions, model, or isolated execution context. A "Prisma expert agent" duplicates parent's context with no differentiation.

**Decision: Zero agents. Skills teach patterns through progressive disclosure.**

### 2. No Commands

Prisma work (schema design, queries, migrations) works better conversationally because context matters. Review functionality belongs in a separate cross-cutting review plugin.

**Decision: Zero commands. Review skills exported for use by review plugin.**

### 3. No Core MCP Servers

Built-in tools (Read, Write, Edit, Grep, Glob, Bash) suffice for Prisma work. Database introspection can be done via `npx prisma db pull` or raw SQL through Bash.

**Decision: Zero MCP servers in core. Optional addon plugins can provide database introspection tools.**

### 4. Concern-Prefix Organization

Organize skills by Prisma domain concern (CLIENT, QUERIES, TRANSACTIONS, MIGRATIONS, SECURITY, PERFORMANCE) with ALL CAPS concern prefixes followed by lowercase-with-hyphens topics.

**Decision: 6 concerns, 17 skills total, following official Claude Code structure.**

### 5. Intelligent Skill Activation

PreToolUse hooks intelligently detect file context (extension, imports, content patterns) and remind parent Claude which skills are available, preventing repeated context bloat through session lifecycle management.

**Decision: Session-managed recommendations with bash-based pattern detection.**

## Architecture

### Plugin Components

**Skills (17 total across 6 concerns)**

- Organized with gerund-form names: `creating-client-singletons/`, `ensuring-query-type-safety/`
- Each skill contains SKILL.md with progressive disclosure
- Optional `references/` for skill-specific examples
- Teaching focus: "how to do it right" in Prisma 6

**Hooks (2 event handlers + session lifecycle)**

- SessionStart: Initialize session state (runs once)
- PreToolUse: Intelligent skill reminder based on file context
- Fast execution (< 100ms total)
- Lifecycle-managed to prevent context bloat

**Scripts (6 shared utilities)**

- **Lifecycle scripts** (MANDATORY):
  - `init-session.sh`: Creates session state JSON
  - `recommend-skills.sh`: Once-per-session contextual recommendations
- **Validation scripts**:
  - `check-prisma-client.sh`: Detect multiple PrismaClient instances
  - `check-sql-injection.sh`: Find unsafe $queryRaw usage
  - `check-deprecated-apis.sh`: Detect Buffer on Bytes fields
  - `analyze-imports.sh`: Extract Prisma imports for context detection
- Used by hooks and skills
- Prefer bash for deterministic operations (100x faster than LLM-based validation)

**Knowledge (shared research)**

- `prisma-6-comprehensive.md`: Complete Prisma 6 reference from RESEARCH.md
- Accessible by all components
- Single source of truth

## Skill Structure

### Naming Convention

`[gerund-form-action]/`

**Format:**

- Action: gerund form (verb ending in -ing)
- Topic: lowercase-with-hyphens
- Separator: single hyphen

Examples:

- `creating-client-singletons/` - Reusing PrismaClient instances
- `preventing-sql-injection/` - Preventing SQL injection
- `upgrading-to-prisma-6/` - Prisma 6 breaking changes

### Concerns

The plugin organizes skills into 6 concern areas based on Prisma stress test findings:

#### 1. CLIENT Concern

**Scope:** PrismaClient instantiation, connection pooling, lifecycle management

**Rationale:** 4/5 agents created multiple instances. Most critical violation pattern causing connection pool exhaustion.

**Skills:**

- `creating-client-singletons/` - Global singleton, module-level export patterns
- `configuring-serverless-clients/` - Next.js/Lambda global pattern, connection_limit=1
- `managing-client-lifecycle/` - Graceful shutdown, $disconnect, error handling

#### 2. QUERIES Concern

**Scope:** CRUD operations, filtering, pagination, type safety

**Rationale:** Multiple agents had inefficient queries, missing type safety, N+1 problems, poor pagination.

**Skills:**

- `ensuring-query-type-safety/` - Using Prisma.validator, GetPayload, avoiding any
- `implementing-query-pagination/` - Cursor vs offset, performance implications
- `optimizing-query-selection/` - Selecting fields, avoiding N+1, include patterns

#### 3. TRANSACTIONS Concern

**Scope:** Interactive transactions, isolation, error handling

**Rationale:** Agents had poor transaction error handling, missing rollback logic, unclear isolation understanding.

**Skills:**

- `using-interactive-transactions/` - Using $transaction callback, rollback patterns
- `configuring-transaction-isolation/` - Setting isolation levels, handling concurrency
- `handling-transaction-errors/` - Proper error catching, P-code handling

#### 4. MIGRATIONS Concern

**Scope:** Development and production migration workflows

**Rationale:** Confusion between migrate dev/deploy/reset, missing v6 upgrade knowledge, schema drift issues.

**Skills:**

- `managing-dev-migrations/` - migrate dev vs db push, when to use each
- `deploying-production-migrations/` - migrate deploy in CI/CD, never reset in prod
- `upgrading-to-prisma-6/` - Breaking changes: Buffer→Uint8Array, implicit m-n PKs

#### 5. SECURITY Concern

**Scope:** SQL injection, input validation, credential handling

**Rationale:** 2/5 agents had critical SQL injection vulnerabilities. Security cannot be optional.

**Skills:**

- `preventing-sql-injection/` - $queryRaw tagged templates vs $queryRawUnsafe
- `validating-query-inputs/` - Zod validation before Prisma operations
- `preventing-error-exposure/` - Not leaking database errors to clients

#### 6. PERFORMANCE Concern

**Scope:** Connection pooling, query optimization, caching

**Rationale:** Multiple agents had inefficient queries, missing connection configuration, no optimization awareness.

**Skills:**

- `configuring-connection-pools/` - Pool sizing formula, serverless considerations
- `optimizing-query-performance/` - Indexes, batch operations, select fields
- `implementing-query-caching/` - Query result caching, Redis integration patterns

### Skill Breakdown by Concern

#### CLIENT Concern

**Skills:**

- `creating-client-singletons/` - Critical skill teaching global singleton pattern to prevent multiple PrismaClient instances. Addresses #1 violation.

  Example content: Module-level export, avoiding function-scoped creation, test file patterns

- `configuring-serverless-clients/` - Serverless-specific patterns: Next.js global singleton, Lambda connection_limit=1, PgBouncer integration.

  Example content: Next.js 13+ App Router pattern, Vercel deployment, AWS Lambda setup

- `managing-client-lifecycle/` - Graceful shutdown handlers, $disconnect timing, logging configuration.

  Example content: SIGINT/SIGTERM handlers, development vs production logging

#### QUERIES Concern

**Skills:**

- `ensuring-query-type-safety/` - Using generated types, Prisma.validator for custom types, avoiding any, GetPayload patterns.

  Example content: Type-safe partial selections, inferred types from queries

- `implementing-query-pagination/` - Cursor vs offset pagination, when to use each, performance implications on large datasets.

  Example content: 100k+ record pagination, cursor implementation patterns

- `optimizing-query-selection/` - Selecting only needed fields, avoiding N+1 with include, relation counting.

  Example content: Performance comparison, include vs select strategies

#### TRANSACTIONS Concern

**Skills:**

- `using-interactive-transactions/` - Using $transaction callback, implementing rollback logic, handling partial failures.

  Example content: Banking transfer example, inventory reservation patterns

- `configuring-transaction-isolation/` - Setting SerialIzable/RepeatableRead/ReadCommitted, database-specific defaults, concurrency handling.

  Example content: Isolation level decision tree, race condition prevention

- `handling-transaction-errors/` - Catching errors in transactions, P2002/P2025 handling, timeout configuration.

  Example content: Error recovery patterns, maxWait/timeout settings

#### MIGRATIONS Concern

**Skills:**

- `managing-dev-migrations/` - migrate dev creates migrations + applies, db push for prototyping, when to use --create-only.

  Example content: Development workflow decision tree, editing generated SQL

- `deploying-production-migrations/` - migrate deploy in CI/CD, never use dev/reset/push in prod, handling failed migrations.

  Example content: GitHub Actions example, rollback strategies

- `upgrading-to-prisma-6/` - Breaking changes: Buffer→Uint8Array, implicit m-n PK changes, NotFoundError→P2025, reserved keywords.

  Example content: Migration checklist, code update patterns, TextEncoder/TextDecoder usage

#### SECURITY Concern

**Skills:**

- `preventing-sql-injection/` - $queryRaw tagged templates for automatic parameterization, why $queryRawUnsafe is dangerous, Prisma.sql helper.

  Example content: Before/after SQL injection examples, dynamic query building

- `validating-query-inputs/` - Zod validation before Prisma, never trust external data, email/phone/URL validation.

  Example content: Complete validation pipeline, Prisma type integration

- `preventing-error-exposure/` - Not leaking P-codes to clients, sanitizing error messages, logging vs user-facing errors.

  Example content: Error transformation patterns, production error handling

#### PERFORMANCE Concern

**Skills:**

- `configuring-connection-pools/` - Pool sizing formula (cpus × 2 + 1), serverless connection_limit=1, PgBouncer for high concurrency.

  Example content: Sizing calculations, bottleneck identification

- `optimizing-query-performance/` - Adding indexes (@@index), using createMany, batching with transactions, monitoring slow queries.

  Example content: Query log analysis, index strategy

- `implementing-query-caching/` - Query result caching with Redis, cache invalidation strategies, when to cache.

  Example content: Redis integration, TTL strategies, cache key patterns

### Review Skill

**reviewing-prisma-patterns/** - Exported skill for review plugin to check:

- Multiple PrismaClient instances
- SQL injection vulnerabilities ($queryRawUnsafe usage)
- Missing serverless configuration
- Deprecated Buffer API usage
- Poor error handling (missing P-code checks)
- Missing input validation
- Inefficient queries (offset on large datasets, missing select)

Tagged with `review: true` for discoverability by review plugin.

## Intelligent Hook System

### Session Lifecycle Management

The plugin uses a JSON state file to track which recommendations have been shown during the current session, preventing context bloat from repeated skill reminders.

**SessionStart Hook: Initialize State**

Implementation: `scripts/init-session.sh`

```bash
#!/bin/bash

STATE_FILE="/tmp/claude-prisma-session.json"

if [[ -f "$STATE_FILE" ]]; then
  EXISTING_SESSION=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"session_id": "[^"]*"' | head -1)
  if [[ -n "$EXISTING_SESSION" ]]; then
    exit 0
  fi
fi

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "recommendations_shown": {
    "prisma_files": false,
    "schema_files": false,
    "migration_files": false,
    "raw_sql_context": false,
    "serverless_context": false
  }
}
EOF

echo "Prisma session initialized"
```

**Key Design:**

- Creates fresh state on session start
- Handles existing session file gracefully
- Tracks 5 recommendation types
- Runs once per session (< 5ms)
- No external dependencies

**PreToolUse Hook: Contextual Skill Recommendations**

Implementation: `scripts/recommend-skills.sh`

```bash
#!/bin/bash

STATE_FILE="/tmp/claude-prisma-session.json"

[[ ! -f "$STATE_FILE" ]] && exit 0

FILE_PATH="$1"
FILE_NAME="${FILE_PATH##*/}"
FILE_DIR="${FILE_PATH%/*}"

RECOMMENDATION_TYPE=""
SKILLS=""
MESSAGE=""

if [[ "$FILE_NAME" == "schema.prisma" ]]; then
  RECOMMENDATION_TYPE="schema_files"
  SKILLS="managing-dev-migrations, creating-client-singletons, ensuring-query-type-safety"
  MESSAGE="📚 Prisma Schema: $SKILLS"
elif [[ "$FILE_DIR" == *"migrations"* ]]; then
  RECOMMENDATION_TYPE="migration_files"
  SKILLS="managing-dev-migrations, deploying-production-migrations, upgrading-to-prisma-6"
  MESSAGE="📚 Prisma Migrations: $SKILLS"
elif [[ "$FILE_PATH" =~ \.(ts|js|tsx|jsx)$ ]]; then
  IMPORTS=$(bash "$(dirname "$0")/analyze-imports.sh" "$FILE_PATH" 2>/dev/null)

  if [[ "$IMPORTS" == *"@prisma/client"* ]]; then
    RECOMMENDATION_TYPE="prisma_files"
    SKILLS="creating-client-singletons, ensuring-query-type-safety, preventing-sql-injection"
    MESSAGE="📚 Prisma Client Usage: $SKILLS"

    if [[ "$IMPORTS" == *"\$queryRaw"* ]]; then
      RECOMMENDATION_TYPE="raw_sql_context"
      SKILLS="preventing-sql-injection (CRITICAL)"
      MESSAGE="⚠️  Raw SQL Detected: $SKILLS"
    fi
  fi

  if [[ "$FILE_PATH" == *"vercel"* || "$FILE_PATH" == *"lambda"* || "$FILE_PATH" == *"app/"* ]]; then
    SERVERLESS_SHOWN=$(grep -o '"serverless_context": true' "$STATE_FILE" 2>/dev/null)
    if [[ -z "$SERVERLESS_SHOWN" ]]; then
      echo "📚 Serverless Context: configuring-serverless-clients, configuring-connection-pools"
      sed -i.bak 's/"serverless_context": false/"serverless_context": true/' "$STATE_FILE"
    fi
  fi
fi

[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  echo "Use Skill tool to activate specific skills when needed."

  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

exit 0
```

**Supporting Script: analyze-imports.sh**

```bash
#!/bin/bash

FILE_PATH="$1"

[[ ! -f "$FILE_PATH" ]] && exit 0

grep -E "from ['\"]@prisma/client['\"]|import.*@prisma/client|\\\$queryRaw|\\\$executeRaw" "$FILE_PATH" 2>/dev/null
```

**Key Features:**

- ✅ File name detection (schema.prisma)
- ✅ Directory pattern matching (migrations/)
- ✅ Import analysis for Prisma usage
- ✅ Raw SQL detection via grep
- ✅ Serverless context detection
- ✅ Once-per-session-per-type reminders
- ✅ Fast execution (< 15ms first time, < 1ms subsequent)
- ✅ No external dependencies (pure bash + grep)

**Activation Rules Table:**

| Pattern                                  | Triggered Skills                                                            | Rationale              | Frequency        |
| ---------------------------------------- | --------------------------------------------------------------------------- | ---------------------- | ---------------- |
| schema.prisma                            | managing-dev-migrations, creating-client-singletons, ensuring-query-type-safety | Prisma schema editing  | Once per session |
| migrations/\*.sql                        | managing-dev-migrations, deploying-production-migrations, upgrading-to-prisma-6 | Migration file editing | Once per session |
| \*.ts with @prisma/client                | creating-client-singletons, ensuring-query-type-safety, preventing-sql-injection | Prisma Client usage    | Once per session |
| $queryRaw detected                       | preventing-sql-injection (CRITICAL)                                         | Raw SQL usage          | Once per session |
| Serverless path (app/, vercel/, lambda/) | configuring-serverless-clients, configuring-connection-pools                | Serverless deployment  | Once per session |

**Performance:**

- File name check: ~1ms
- Directory pattern detection: ~2ms
- Import analysis (grep): ~5ms
- State file read/write: ~2ms
- Total first execution: < 15ms
- Subsequent executions (after boolean set): < 1ms

### Validation Hooks

**check-prisma-client.sh** - Called by PreToolUse hook on Write/Edit

Detects multiple PrismaClient instantiation:

- `new PrismaClient()` count > 1 in codebase
- Missing global singleton pattern
- Function-scoped client creation

Fast execution using grep (< 30ms).

**check-sql-injection.sh** - Called by PreToolUse hook on Write/Edit

Detects unsafe SQL patterns:

- `$queryRawUnsafe` usage
- `Prisma.raw()` with string interpolation
- Missing tagged template syntax

Exits with code 1 (warn) on detection.

**check-deprecated-apis.sh** - Called by PreToolUse hook on Write/Edit

Detects Prisma 6 breaking changes:

- `Buffer.from()` on Bytes fields
- `.toString()` on Bytes
- `NotFoundError` usage (suggest P2025)

Fast execution using grep (< 20ms).

## File Structure

```tree
prisma-6/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── creating-client-singletons/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── serverless-pattern.md
│   │       └── test-pattern.md
│   ├── configuring-serverless-clients/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── nextjs-example.md
│   ├── managing-client-lifecycle/
│   │   └── SKILL.md
│   ├── ensuring-query-type-safety/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── type-helpers.md
│   ├── implementing-query-pagination/
│   │   └── SKILL.md
│   ├── optimizing-query-selection/
│   │   └── SKILL.md
│   ├── using-interactive-transactions/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── patterns.md
│   ├── configuring-transaction-isolation/
│   │   └── SKILL.md
│   ├── handling-transaction-errors/
│   │   └── SKILL.md
│   ├── managing-dev-migrations/
│   │   └── SKILL.md
│   ├── deploying-production-migrations/
│   │   └── SKILL.md
│   ├── upgrading-to-prisma-6/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── breaking-changes.md
│   ├── preventing-sql-injection/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── attack-examples.md
│   ├── validating-query-inputs/
│   │   └── SKILL.md
│   ├── preventing-error-exposure/
│   │   └── SKILL.md
│   ├── configuring-connection-pools/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── sizing-guide.md
│   ├── optimizing-query-performance/
│   │   └── SKILL.md
│   ├── implementing-query-caching/
│   │   └── SKILL.md
│   └── reviewing-prisma-patterns/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── init-session.sh
│   ├── recommend-skills.sh
│   ├── analyze-imports.sh
│   ├── check-prisma-client.sh
│   ├── check-sql-injection.sh
│   └── check-deprecated-apis.sh
├── knowledge/
│   └── prisma-6-comprehensive.md
└── README.md
```

## Integration with Other Plugins

### Plugin Boundaries

**Prisma 6 Plugin Scope:**

- Prisma ORM patterns and best practices
- PrismaClient management and configuration
- Query patterns, transactions, migrations
- Prisma-specific security (SQL injection via Prisma APIs)
- Works with any framework (Next.js, Express, Fastify, etc.)
- Works with any database (PostgreSQL, MySQL, MongoDB, SQLite)

**Framework Plugin Scope (Next.js, Express, etc.):**

- Framework-specific Prisma integration
- Server Actions with Prisma, API route patterns
- Build on Prisma plugin patterns
- Clear separation: If it works without the framework → Prisma plugin

### Composition Patterns

**Skill References:**

Next.js plugin references Prisma skills:

```markdown
## Server Actions with Prisma (in nextjs-15 plugin)

Use the configuring-serverless-clients skill from the prisma-6 plugin for Next.js global singleton pattern.
Use the validating-query-inputs skill from the prisma-6 plugin for validating form data before Prisma.

Next.js-specific additions:

- revalidatePath() after mutations
- redirect() for navigation after database operations
```

**Knowledge Sharing:**

Skills can reference shared Prisma knowledge:

```markdown
See @prisma-6/knowledge/prisma-6-comprehensive.md for complete API reference.
```

**Hook Layering:**

Multiple plugins can have PreToolUse hooks - they compose additively:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "command": "prisma-6/scripts/check-prisma-client.sh" }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{ "command": "nextjs-15/scripts/check-nextjs-patterns.sh" }]
      }
    ]
  }
}
```

Both run in parallel. Prisma plugin validates Prisma patterns, Next.js plugin validates framework patterns.

## Plugin Metadata

`.claude-plugin/plugin.json`:

```json
{
  "name": "prisma-6",
  "version": "1.0.0",
  "description": "Prisma 6 ORM patterns, client management, query optimization, and security best practices based on real-world AI coding failures",
  "author": {
    "name": "Claude Code Plugin Marketplace",
    "email": "plugins@claude.ai"
  },
  "keywords": ["prisma", "orm", "database", "typescript", "postgresql", "mysql", "security"],
  "engines": {
    "claude-code": ">=1.0.0"
  }
}
```

Note: No `exports` field needed - uses standard auto-discovery for skills/, hooks/, knowledge/, scripts/.

## Implementation Strategy

### Phase 1: Critical Safety Skills (Week 1)

**Deliverables:**

- 3 CLIENT concern skills (singleton, serverless, lifecycle)
- 3 SECURITY concern skills (SQL injection, validation, error exposure)
- Session lifecycle scripts (init-session.sh, recommend-skills.sh)
- Knowledge base (Prisma 6 comprehensive doc from RESEARCH.md)

**Focus:** Address the most critical violations from stress test - multiple clients, SQL injection, serverless misconfiguration.

**Time estimate:** 45 hours

- 3 hours per skill × 6 skills = 18 hours
- Session lifecycle scripts: 8 hours
- Knowledge base organization: 12 hours
- Testing and refinement: 7 hours

### Phase 2: Query and Transaction Skills (Week 2)

**Deliverables:**

- 3 QUERIES concern skills (type safety, pagination, optimization)
- 3 TRANSACTIONS concern skills (interactive, isolation, error handling)
- Validation scripts (check-prisma-client.sh, check-sql-injection.sh, check-deprecated-apis.sh)

**Focus:** Prevent performance issues and ensure proper transaction handling.

**Time estimate:** 40 hours

- 3 hours per skill × 6 skills = 18 hours
- Validation scripts: 12 hours
- Integration with hooks: 6 hours
- Testing and examples: 4 hours

### Phase 3: Migrations and Performance Skills (Week 3)

**Deliverables:**

- 3 MIGRATIONS concern skills (dev workflow, production, v6 upgrade)
- 3 PERFORMANCE concern skills (pooling, optimization, caching)
- Complete hooks.json configuration
- analyze-imports.sh script

**Focus:** Help developers manage schema evolution and optimize production performance.

**Time estimate:** 35 hours

- 3 hours per skill × 6 skills = 18 hours
- Migration workflow examples: 6 hours
- Performance benchmarking examples: 6 hours
- Hook configuration and testing: 5 hours

### Phase 4: Review Skill and Documentation (Week 4)

**Deliverables:**

- REVIEW-prisma-patterns skill
- Complete README with examples
- Integration documentation for Next.js/Express
- Contribution guidelines

**Focus:** Enable review plugin integration and provide comprehensive plugin documentation.

**Time estimate:** 25 hours

- Review skill with comprehensive checklist: 8 hours
- README and examples: 8 hours
- Integration guides: 6 hours
- Documentation polish: 3 hours

### Phase 5: Integration Testing and Refinement (Week 5)

**Deliverables:**

- Integration with Next.js/Express patterns
- Stress test validation (run original scenarios with plugin active)
- Performance optimization of hooks
- User feedback iteration

**Focus:** Ensure plugin prevents all 30 violations found in original stress test.

**Time estimate:** 35 hours

- Cross-plugin testing: 10 hours
- Stress test re-run and validation: 15 hours
- Hook performance tuning: 5 hours
- Bug fixes and refinement: 5 hours

**Total Implementation:** 180 hours (~5 weeks)

## Success Metrics

### Effectiveness

**Stress Test Prevention:**

- ✅ Detects multiple PrismaClient instances before code runs (check-prisma-client.sh)
- ✅ Prevents SQL injection (preventing-sql-injection skill + check-sql-injection.sh)
- ✅ Warns about missing serverless config (configuring-serverless-clients skill activation)
- ✅ Catches deprecated Buffer API (check-deprecated-apis.sh)
- ✅ Ensures proper error handling (handling-transaction-errors, preventing-error-exposure)

**Target:** Reduce violations by 95% when re-running stress test scenarios with plugin active.

### Efficiency

**Context Management:**

- Skills load progressively (only when activated by user)
- Hook recommendations once per session per file type
- State file prevents repeated bloat
- Fast hook execution (< 15ms first time, < 1ms subsequent)

**Target:** < 3% context overhead compared to no plugin (measured by token usage).

### Extensibility

**Plugin Composition:**

- Clear boundaries with framework plugins (Next.js, Express)
- Skills referenceable across plugins (`@prisma-6/configuring-serverless-clients`)
- Hooks compose without conflicts
- Knowledge base shared resource

**Target:** Next.js, Express, Fastify plugins can reference Prisma skills without duplication.

## Risk Mitigation

### Risk: Hook execution slows development

**Mitigation:**

- Optimize scripts (use grep, avoid heavy parsing)
- Keep validation simple (< 30ms per script)
- Session lifecycle prevents repeated execution
- Import analysis caches results via state file

**Fallback:** Users can disable validation hooks via settings, keeping recommendation hooks.

### Risk: Skills activate incorrectly or too frequently

**Mitigation:**

- Test file patterns thoroughly with real Prisma projects
- Use specific patterns (schema.prisma, @prisma/client imports)
- Session state prevents re-activation
- Import analysis for accurate detection

**Fallback:** Users can manually activate skills via Skill tool, ignoring recommendations.

### Risk: False positives in validation hooks

**Mitigation:**

- Use conservative patterns (high confidence only)
- Exit code 1 (warn) instead of 2 (block) for ambiguous cases
- Provide clear explanation with each warning
- User feedback to refine patterns

**Fallback:** Validation hooks are warnings only, not blocking operations.

### Risk: Overlap with ESLint/Prisma CLI warnings

**Mitigation:**

- Focus on conceptual teaching, not just error detection
- Provide "why" and "how to fix" context beyond CLI warnings
- Catch patterns CLI misses (serverless config, security anti-patterns)
- Complement existing tools, don't duplicate

**Fallback:** Plugin adds value through teaching even with ESLint/Prisma CLI active.

### Risk: Prisma 7+ breaking changes require plugin updates

**Mitigation:**

- Version plugin clearly (prisma-6 name indicates scope)
- Monitor Prisma releases for breaking changes
- Design skills to be forward-compatible where possible
- Clear migration path to prisma-7 plugin when needed

**Fallback:** Plugin continues to work for Prisma 6 projects indefinitely.

## Conclusion

This plugin provides Prisma 6 assistance through:

- **17 Teaching Skills** organized by 6 concern prefixes (CLIENT, QUERIES, TRANSACTIONS, MIGRATIONS, SECURITY, PERFORMANCE)
- **Intelligent Hooks** with session lifecycle management for context-aware, non-repetitive skill recommendations
- **Validation Scripts** using fast bash patterns to catch violations before code runs
- **Shared Knowledge Base** providing comprehensive Prisma 6 reference from RESEARCH.md

**Key Innovations:**

1. **Stress-Test Driven Design:** Every skill addresses real failures found in AI coding agent testing (30 violations across 5 agents)
2. **Session Lifecycle Management:** Once-per-session recommendations prevent context bloat while maintaining relevance
3. **Security First:** Dedicated SECURITY concern with critical SQL injection prevention and validation patterns
4. **Import Analysis:** Intelligent detection of Prisma usage via grep patterns for targeted skill activation
5. **Serverless Awareness:** Special handling for Next.js/Lambda/Vercel contexts with connection pooling guidance
6. **Progressive Disclosure:** Skills load only when relevant, knowledge base accessible on demand

**Implementation ready:** All 17 skills defined, hook system designed, validation scripts specified, phased approach clear with 180-hour estimate across 5 weeks.

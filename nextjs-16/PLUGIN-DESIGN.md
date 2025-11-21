# Next.js 16 Plugin Design

**Date:** 2025-11-21
**Status:** Draft Design
**Author:** Design Session with Claude Code

## Overview

This plugin teaches Next.js 16 breaking changes, security patterns, and the new Cache Components model. Released October 21, 2025, Next.js 16 introduces fundamental paradigm shifts that parent Claude (knowledge cutoff January 2025) cannot address. The stress test revealed 24 violations across 7 agents, with critical security vulnerabilities (CVE-2025-29927) and widespread failure to adopt the new caching model.

The plugin uses intelligent skill activation based on file context, teaching patterns progressively rather than overwhelming developers. Skills are organized by concern (SECURITY, CACHING, MIGRATION, etc.) and activated when relevant file patterns are detected.

## Problem Statement

**Critical Security Vulnerability (CVE-2025-29927):**
Three agents in the stress test used middleware for authentication, creating a critical security vulnerability. Middleware authentication can be bypassed in Next.js 16. The Data Access Layer pattern is now required, but agents without this knowledge created exploitable code.

**Cache Components Paradigm Shift:**
Six agents failed to adopt the `use cache` directive, the cornerstone of Next.js 16's new caching model. All code is dynamic by default—a fundamental change from Next.js 15's implicit caching. Agents using old patterns (unstable_cache, revalidate export) lost performance benefits and created anti-patterns.

**Breaking Changes Across Core APIs:**
Agents violated multiple breaking changes: async request APIs (params, cookies(), headers()), middleware→proxy rename, revalidateTag() signature, image configuration defaults. These aren't subtle deprecations—they're runtime errors and security holes.

**Missing Authentication in Server Actions:**
Two agents exposed server actions without authentication checks. Any client could modify any user's data. The multi-layer security pattern (route + data layer + server actions) wasn't applied despite being documented.

**Context:** These violations happened despite comprehensive research documentation, proving that knowledge must be delivered at the right moment in the workflow—not upfront—through intelligent skill activation.

## Core Design Principles

### 1. No Agents

**Decision:** No custom agents.

**Rationale:** Skills provide knowledge that parent Claude applies. No need for different permissions, isolation, or specialized models. The teaching approach works within parent's context.

### 2. No Commands

**Decision:** No slash commands.

**Rationale:** No frequent directives. Plugin teaches concepts through skills, doesn't provide shortcuts. Developers need understanding, not command shortcuts.

### 3. Next.js DevTools MCP Server

**Decision:** Include official Next.js DevTools MCP server.

**Rationale:** The official `next-devtools-mcp` provides specialized Next.js development tools that enhance the plugin's capabilities:
- Browser evaluation for testing Next.js components
- Cache component inspection and management
- Next.js runtime information and debugging
- Documentation access for Next.js 16 features
- Upgrade assistance for Next.js 16 migration

This MCP server complements the teaching skills by providing hands-on tools for developers to inspect, debug, and work with Next.js 16 features directly.

### 4. Concern-Prefix Organization

Skills organized by concern using ALL CAPS prefix: `[CONCERN]-[topic]/`

**Format:**
- Concern: ALL CAPS (SECURITY, CACHING, MIGRATION, ROUTING, FORMS, IMAGES)
- Topic: lowercase-with-hyphens
- Example: `SECURITY-data-access-layer/`, `CACHING-use-cache-directive/`

**Rationale:** Clear organization by conceptual area while following official Claude Code auto-discovery. Each concern groups related skills, making the plugin structure self-documenting.

### 5. Intelligent Skill Activation

PreToolUse hook reminds parent of available skills based on file context:
- File extension (.tsx, .jsx → React/Next.js skills)
- Path patterns (app/ → App Router, middleware.ts → migration warning)
- Session lifecycle management (show once per session per type)

**Rationale:** Progressive disclosure. Don't load all skills upfront—activate based on what the developer is doing. Reduces cognitive load, increases relevance.

## Architecture

### Plugin Components

**Skills (9 total across 7 concerns)**

- Organized with concern prefixes: `[CONCERN]-[topic]/`
- Each skill contains SKILL.md
- Optional `references/` for skill-specific examples
- Shared research in `knowledge/` directory
- Progressive disclosure through intelligent hook

**Hooks (2 event handlers)**

- SessionStart: Initialize session state JSON (runs once)
- PreToolUse: Intelligent skill reminder based on file patterns
- Fast execution (< 10ms per hook)
- Lifecycle-managed with JSON state tracking

**Scripts (5 shared utilities)**

- **Lifecycle scripts** (MANDATORY):
  - `init-session.sh`: SessionStart - creates/resets state JSON
  - `recommend-skills.sh`: PreToolUse - once-per-session recommendations
- **Validation scripts**:
  - `check-middleware-usage.sh`: Warn if middleware.ts exists
  - `check-cache-patterns.sh`: Detect old caching patterns
  - `check-security-patterns.sh`: Validate server action auth

**MCP Server (Next.js DevTools)**

- `next-devtools-mcp`: Official Next.js development tools
  - Browser evaluation and component testing
  - Cache component inspection
  - Runtime information and debugging
  - Next.js 16 documentation access
  - Migration and upgrade assistance

**Knowledge (shared research)**

- `nextjs-16-comprehensive.md`: Complete Next.js 16 reference
- Accessible by all skills via references
- Single source of truth for API patterns

## Skill Structure

### Naming Convention

`[CONCERN]-[topic]/`

**Format:**
- Concern prefix: ALL CAPS (SECURITY, CACHING, MIGRATION, ROUTING, FORMS, IMAGES, REVIEW)
- Topic: lowercase-with-hyphens
- Separator: single hyphen

**Examples:**
- `SECURITY-data-access-layer/` - CVE-2025-29927 patterns
- `CACHING-use-cache-directive/` - Cache Components model
- `MIGRATION-async-request-apis/` - Breaking changes
- `REVIEW-nextjs-16-patterns/` - Code review

### Concerns

**1. SECURITY** - Authentication, authorization, CVE-2025-29927 mitigation
- Critical for preventing exploitable auth patterns
- Teaches Data Access Layer pattern
- Covers multi-layer security strategy

**2. CACHING** - Cache Components model, use cache directive, lifecycle APIs
- Fundamental paradigm shift in Next.js 16
- Most common violation (6 agents)
- Performance critical

**3. MIGRATION** - Breaking changes from Next.js 15
- Async request APIs (params, cookies, headers)
- Middleware→Proxy rename
- Critical for upgrade path

**4. ROUTING** - Proxy configuration, parallel routes
- New proxy.ts patterns
- Parallel routes gotchas (default.tsx)
- Advanced routing features

**5. FORMS** - Server actions, validation, security
- Server action authentication
- Integration with React 19 hooks
- Form security patterns

**6. IMAGES** - Image optimization breaking changes
- Configuration updates
- Security settings
- Cache TTL changes

**7. REVIEW** - Comprehensive pattern review
- Cross-cutting concerns
- Violation detection
- Migration verification

### Skill Breakdown by Concern

#### Concern: SECURITY

**Skills:**
- `SECURITY-data-access-layer/` - Teach Data Access Layer pattern to prevent CVE-2025-29927. Covers verifySession(), multi-layer auth, route protection. Critical for all authentication scenarios.

#### Concern: CACHING

**Skills:**
- `CACHING-use-cache-directive/` - Teach Cache Components model with `use cache` directive. Covers file/component/function level caching, when to apply, anti-patterns to avoid.
- `CACHING-lifecycle-apis/` - Teach cacheLife(), cacheTag(), updateTag(), refresh(), revalidateTag() new signature. Covers cache invalidation strategies and private/remote caching.

#### Concern: MIGRATION

**Skills:**
- `MIGRATION-async-request-apis/` - Teach async params, searchParams, cookies(), headers(), draftMode(). Covers breaking changes, Promise types, common patterns.
- `MIGRATION-middleware-to-proxy/` - Teach middleware.ts → proxy.ts rename. Covers file rename, export rename, config updates, CVE-2025-29927 implications.

#### Concern: ROUTING

**Skills:**
- `ROUTING-parallel-routes/` - Teach parallel routes, default.tsx requirement, slot patterns. Covers common gotchas like missing default files.

#### Concern: FORMS

**Skills:**
- `FORMS-server-actions-security/` - Teach server action authentication patterns. Covers verifySession() in actions, authorization checks, validation with Zod.

#### Concern: IMAGES

**Skills:**
- `IMAGES-optimization-config/` - Teach image configuration breaking changes. Covers minimumCacheTTL, imageSizes, localPatterns, security settings.

#### Concern: REVIEW

**Skills:**
- `REVIEW-nextjs-16-patterns/` - Review code for Next.js 16 violations. Covers security patterns, caching, breaking changes, migration checklist.

## Intelligent Hook System

### Session Lifecycle Management

The plugin uses a JSON state file to track which recommendations have been shown during the current session, preventing context bloat from repeated reminders.

**SessionStart Hook: Initialize State**

Implementation: `scripts/init-session.sh`

```bash
#!/bin/bash
# scripts/init-session.sh
# Creates/resets session state on session start

STATE_FILE="/tmp/claude-nextjs-16-session.json"

# Check if file exists from another session
if [[ -f "$STATE_FILE" ]]; then
  rm "$STATE_FILE"
fi

# Create JSON state file with all booleans set to false
cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "plugin": "nextjs-16",
  "recommendations_shown": {
    "nextjs_skills": false,
    "security_skills": false,
    "caching_skills": false,
    "migration_skills": false,
    "middleware_warning": false
  }
}
EOF

echo "NextJS-16 session initialized"
```

**PreToolUse Hook: Contextual Skill Recommendations**

Implementation: `scripts/recommend-skills.sh`

```bash
#!/bin/bash
# scripts/recommend-skills.sh
# Recommends skills once per session based on file context

STATE_FILE="/tmp/claude-nextjs-16-session.json"

# Exit if state file doesn't exist (session not initialized)
[[ ! -f "$STATE_FILE" ]] && exit 0

# Get file path from environment or argument
FILE_PATH="${CLAUDE_FILE_PATH:-$1}"

# Exit early if no file path
[[ -z "$FILE_PATH" ]] && exit 0

# Get file info
FILE_NAME=$(basename "$FILE_PATH")
FILE_EXT="${FILE_PATH##*.}"
DIR_PATH=$(dirname "$FILE_PATH")

# Special case: middleware.ts detection
if [[ "$FILE_NAME" == "middleware.ts" || "$FILE_NAME" == "middleware.js" ]]; then
  SHOWN=$(grep -o '"middleware_warning": true' "$STATE_FILE" 2>/dev/null)

  if [[ -z "$SHOWN" ]]; then
    echo "⚠️  CRITICAL: middleware.ts is deprecated in Next.js 16"
    echo "Use MIGRATION-middleware-to-proxy skill"
    echo "Security: CVE-2025-29927 - middleware no longer safe for auth"

    sed -i.bak 's/"middleware_warning": false/"middleware_warning": true/' "$STATE_FILE" 2>/dev/null || \
      sed -i '' 's/"middleware_warning": false/"middleware_warning": true/' "$STATE_FILE"
  fi
  exit 0
fi

# Determine recommendation type based on file pattern
RECOMMENDATION_TYPE=""
SKILLS=""
MESSAGE=""

# Next.js file detection
if [[ "$FILE_EXT" == "tsx" || "$FILE_EXT" == "jsx" || "$FILE_EXT" == "ts" || "$FILE_EXT" == "js" ]]; then
  if [[ "$DIR_PATH" == *"/app/"* ]]; then
    RECOMMENDATION_TYPE="nextjs_skills"
    SKILLS="All Next.js 16 skills available"
    MESSAGE="📚 Next.js 16 App Router detected. Skills: SECURITY-*, CACHING-*, MIGRATION-*, ROUTING-*, FORMS-*"
  fi
fi

# Security-specific patterns
if [[ "$FILE_NAME" == *"action"* || "$FILE_NAME" == *"server"* ]] && [[ "$FILE_EXT" == "ts" || "$FILE_EXT" == "tsx" ]]; then
  RECOMMENDATION_TYPE="security_skills"
  SKILLS="SECURITY-data-access-layer, FORMS-server-actions-security"
  MESSAGE="🔒 Server action detected. Critical: Use SECURITY-data-access-layer for authentication"
fi

# Exit if no recommendation needed for this file type
[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

# Check if this recommendation was already shown
SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  echo "Use Skill tool to activate when needed."

  # Update state file: set boolean to true (portable sed syntax)
  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE" 2>/dev/null || \
    sed -i '' "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

# Exit silently if already shown (< 1ms)
exit 0
```

**Key Design Patterns:**

- ✅ **Centralized state**: Single JSON file tracks all recommendation types
- ✅ **Session lifecycle**: SessionStart hook creates/resets state at session start
- ✅ **Programmatic updates**: sed for fast JSON manipulation (no jq dependency)
- ✅ **Type-specific tracking**: Different booleans for different recommendation types
- ✅ **Fast**: < 1ms after recommendation shown, < 10ms for first show
- ✅ **Non-intrusive**: Silent after first recommendation per type
- ✅ **Automatic reset**: New session = new state file
- ✅ **Portable**: Works on macOS and Linux

**File Pattern Detection:**

```bash
# App Router detection
if [[ "$DIR_PATH" == *"/app/"* ]]; then
  # Next.js App Router context
fi

# Server action detection
if [[ "$FILE_NAME" == *"action"* ]]; then
  # Server action security critical
fi

# Middleware detection
if [[ "$FILE_NAME" == "middleware.ts" ]]; then
  # Migration warning
fi
```

**Activation Rules Table:**

| Pattern | Triggered Skills | Rationale | Frequency |
|---------|------------------|-----------|-----------|
| app/**/*.tsx, app/**/*.jsx | All Next.js 16 skills | Next.js App Router file | Once per session |
| middleware.ts | MIGRATION-middleware-to-proxy | Critical security warning | Once per session |
| *action*.ts, *server*.ts | SECURITY-*, FORMS-* | Server action authentication | Once per session |
| app/**/page.tsx | ROUTING-*, CACHING-* | Page component patterns | Once per session |
| next.config.* | IMAGES-*, CACHING-* | Configuration changes | Once per session |

**Performance:**

- File pattern check: ~5ms
- State file check: ~1ms
- sed update: ~3ms
- Total first execution: < 10ms
- Subsequent calls (after shown): < 1ms
- Session init: ~5ms (once per session)

### Validation Scripts

**Middleware Detection** (`scripts/check-middleware-usage.sh`)
```bash
#!/bin/bash
# Detect if middleware.ts exists (should be proxy.ts)

if [[ -f "middleware.ts" || -f "middleware.js" ]]; then
  echo "ERROR: middleware.ts found - must be renamed to proxy.ts in Next.js 16"
  exit 1
fi
```

**Cache Pattern Detection** (`scripts/check-cache-patterns.sh`)
```bash
#!/bin/bash
# Detect old caching patterns that should use 'use cache'

FILE="$1"

# Check for unstable_cache usage
if grep -q "unstable_cache" "$FILE"; then
  echo "WARNING: unstable_cache is deprecated - use 'use cache' directive"
fi

# Check for revalidate export
if grep -q "export const revalidate" "$FILE"; then
  echo "WARNING: revalidate export is deprecated - use 'use cache' with cacheLife()"
fi
```

**Security Pattern Validation** (`scripts/check-security-patterns.sh`)
```bash
#!/bin/bash
# Check server actions for authentication

FILE="$1"

# Look for 'use server' without verifySession
if grep -q "'use server'" "$FILE"; then
  if ! grep -q "verifySession" "$FILE"; then
    echo "WARNING: Server action without authentication check"
    echo "Add verifySession() call - see SECURITY-data-access-layer skill"
  fi
fi
```

## File Structure

```tree
nextjs-16/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── SECURITY-data-access-layer/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── dal-example.md
│   │       └── cve-2025-29927.md
│   ├── CACHING-use-cache-directive/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── cache-examples.md
│   ├── CACHING-lifecycle-apis/
│   │   └── SKILL.md
│   ├── MIGRATION-async-request-apis/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── async-patterns.md
│   ├── MIGRATION-middleware-to-proxy/
│   │   └── SKILL.md
│   ├── ROUTING-parallel-routes/
│   │   └── SKILL.md
│   ├── FORMS-server-actions-security/
│   │   └── SKILL.md
│   ├── IMAGES-optimization-config/
│   │   └── SKILL.md
│   └── REVIEW-nextjs-16-patterns/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── init-session.sh
│   ├── recommend-skills.sh
│   ├── check-middleware-usage.sh
│   ├── check-cache-patterns.sh
│   └── check-security-patterns.sh
├── knowledge/
│   └── nextjs-16-comprehensive.md
├── .mcp.json
├── RESEARCH.md
├── STRESS-TEST-REPORT.md
├── PLUGIN-DESIGN.md
└── README.md
```

## Integration with Other Plugins

### Plugin Boundaries

**This plugin provides:**
- Next.js 16 specific breaking changes and patterns
- Cache Components model (`use cache` directive)
- CVE-2025-29927 security patterns (Data Access Layer)
- Migration guidance from Next.js 15 to 16
- Image optimization breaking changes
- Proxy configuration (middleware replacement)

**Out of scope (other plugins):**
- React 19 general features (useActionState, useOptimistic) → `@react-19`
- TypeScript patterns → `@typescript`
- Testing strategies → `@testing`
- General security patterns → `@security`

**Related plugins provide:**
- `@react-19`: React 19 hooks (useActionState, useOptimistic, use)
- `@typescript`: TypeScript best practices
- `@testing`: Testing patterns for Next.js apps

### Composition Patterns

**Skill References:**

Skills can reference other plugins: `@react-19/HOOKS-use-action-state`

Example in `FORMS-server-actions-security/SKILL.md`:
```markdown
For form state management with server actions, see @react-19/HOOKS-use-action-state.
This skill focuses on authentication within server actions.
```

**Knowledge Sharing:**

Skills reference shared knowledge: `@nextjs-16/knowledge/nextjs-16-comprehensive.md`

Example:
```markdown
For complete API reference, see @nextjs-16/knowledge/nextjs-16-comprehensive.md
```

**Hook Layering:**

Multiple plugins can have PreToolUse hooks - they compose additively:
- `@react-19` PreToolUse: Recommends React 19 skills for .tsx/.jsx
- `@nextjs-16` PreToolUse: Recommends Next.js 16 skills for app/ directory
- Both can fire, providing progressive context

**Dependency:**
- `@nextjs-16` builds on `@react-19` (React 19 is included in Next.js 16)
- `@nextjs-16` skills can reference `@react-19` skills for React patterns
- Clear separation: Next.js specifics vs React general patterns

## Plugin Metadata

```json
{
  "name": "nextjs-16",
  "version": "1.0.0",
  "description": "Next.js 16 breaking changes, Cache Components model, and CVE-2025-29927 security patterns",
  "author": {
    "name": "Claude Code Plugin Marketplace",
    "email": "plugins@anthropic.com"
  },
  "keywords": [
    "nextjs",
    "nextjs-16",
    "react",
    "cache-components",
    "security",
    "cve-2025-29927",
    "migration"
  ],
  "engines": {
    "claude-code": ">=1.0.0"
  }
}
```

Note: No `exports` field needed - uses standard auto-discovery for skills/, hooks/, knowledge/

## MCP Server Configuration

The plugin includes the official Next.js DevTools MCP server for enhanced development capabilities.

**File: `.mcp.json`**

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

**Capabilities provided:**

- **Browser Evaluation**: Test and evaluate Next.js components in browser context
- **Cache Components**: Inspect and manage Next.js 16 cache components
- **Runtime Information**: Access Next.js runtime details and configuration
- **Documentation**: Direct access to Next.js 16 documentation
- **Upgrade Tools**: Assistance with Next.js 16 migration and upgrades

**Integration with Skills:**

Skills can reference MCP server tools in their examples:
- `CACHING-use-cache-directive/` can demonstrate cache inspection
- `MIGRATION-middleware-to-proxy/` can use upgrade tools
- `REVIEW-nextjs-16-patterns/` can leverage runtime information

The MCP server enhances the teaching experience by providing hands-on tools alongside conceptual knowledge.

## Implementation Strategy

### Phase 1: Core Security & Caching Skills (8-10 hours)

**Priority 1: Critical Security**
- Write `SECURITY-data-access-layer/SKILL.md` (2h)
  - CVE-2025-29927 explanation
  - verifySession() pattern
  - Multi-layer security strategy
  - Examples: route protection, server actions, data layer
- Create `SECURITY-data-access-layer/references/`
  - `dal-example.md`: Complete working example
  - `cve-2025-29927.md`: Security vulnerability details

**Priority 2: Cache Components Model**
- Write `CACHING-use-cache-directive/SKILL.md` (2h)
  - Paradigm shift explanation (all code dynamic by default)
  - File/component/function level caching
  - When to use vs not use
  - Anti-patterns to avoid
- Write `CACHING-lifecycle-apis/SKILL.md` (1.5h)
  - cacheLife(), cacheTag(), revalidateTag() new signature
  - updateTag(), refresh() APIs
  - Private vs remote caching

**Priority 3: Critical Migration**
- Write `MIGRATION-middleware-to-proxy/SKILL.md` (1.5h)
  - File rename, export rename
  - CVE-2025-29927 connection
  - Configuration updates
- Write `FORMS-server-actions-security/SKILL.md` (1.5h)
  - Authentication in server actions
  - Authorization patterns
  - Validation with Zod

**MCP Server Setup**
- Create `.mcp.json` with next-devtools configuration (0.25h)
- Test MCP server installation (0.25h)
- Verify tools are accessible

**Deliverables:**
- 5 critical skills written
- References created for security patterns
- MCP server configured and tested
- Ready for intelligent hook integration

### Phase 2: Intelligent Hooks & Lifecycle (4-6 hours)

**Session Lifecycle**
- Implement `scripts/init-session.sh` (0.5h)
  - JSON state file creation
  - Portable across macOS/Linux
  - Handle existing file scenarios
- Test session initialization (0.5h)

**Intelligent Activation**
- Implement `scripts/recommend-skills.sh` (2h)
  - File extension detection
  - Path pattern matching (app/, middleware.ts)
  - State file reading/updating (sed-based)
  - Middleware warning (critical)
  - Performance optimization (< 10ms)
- Create activation rules table
- Test with real file patterns

**Validation Scripts**
- Implement `scripts/check-middleware-usage.sh` (0.5h)
- Implement `scripts/check-cache-patterns.sh` (0.5h)
- Implement `scripts/check-security-patterns.sh` (0.5h)
- Test all validation scripts (0.5h)

**Hook Configuration**
- Create `hooks/hooks.json` (0.5h)
  - SessionStart → init-session.sh
  - PreToolUse → recommend-skills.sh
- Test hook triggering (0.5h)

**Deliverables:**
- Complete lifecycle management
- Intelligent skill activation working
- Validation scripts functional
- Performance verified (< 10ms)

### Phase 3: Remaining Skills & Knowledge (6-8 hours)

**Migration Skills**
- Write `MIGRATION-async-request-apis/SKILL.md` (2h)
  - params, searchParams, cookies(), headers(), draftMode()
  - Breaking changes explanation
  - Common migration patterns
  - Create `references/async-patterns.md`

**Routing & Images**
- Write `ROUTING-parallel-routes/SKILL.md` (1.5h)
  - Parallel routes explanation
  - default.tsx requirement
  - Common gotchas
- Write `IMAGES-optimization-config/SKILL.md` (1.5h)
  - Breaking changes in image config
  - minimumCacheTTL, imageSizes, localPatterns
  - Security settings

**Review Skill**
- Write `REVIEW-nextjs-16-patterns/SKILL.md` (2h)
  - Comprehensive review checklist
  - Security pattern verification
  - Caching pattern verification
  - Breaking changes checklist
  - Migration verification

**Knowledge Base**
- Create `knowledge/nextjs-16-comprehensive.md` (1.5h)
  - Consolidate RESEARCH.md
  - Organized reference format
  - Linked from skills

**Deliverables:**
- All 9 skills complete
- Knowledge base consolidated
- Review skill functional

### Phase 4: Integration & Testing (4-6 hours)

**Integration Testing**
- Test skill activation with real Next.js 16 files (2h)
  - Create test files: app/page.tsx, middleware.ts, actions.ts
  - Verify hook triggering
  - Verify correct skills recommended
  - Verify state management working

**Composition Testing**
- Test with @react-19 plugin if available (1h)
  - Verify hooks don't conflict
  - Verify skill references work
  - Test progressive context loading

**Performance Testing**
- Measure hook execution times (1h)
  - Verify < 10ms for all hooks
  - Optimize if needed
  - Test with various file patterns

**Documentation**
- Write README.md (1h)
  - Installation instructions
  - Quick start guide
  - Skill overview
  - Hook behavior explanation

**Deliverables:**
- All integration tests passing
- Performance targets met
- Documentation complete
- Plugin ready for use

### Phase 5: Refinement (2-4 hours)

**Feedback Integration**
- Gather feedback on skill activation accuracy (1h)
- Refine activation patterns if needed (1h)
- Polish skill descriptions based on usage (1h)
- Performance tuning if needed (1h)

**Deliverables:**
- Plugin refined based on real usage
- Ready for production deployment

**Total Implementation Time: 24-34 hours**

## Success Metrics

**Effectiveness:**

- ✅ Skills activate when Next.js 16 files are edited
- ✅ Security skills surface for server actions and auth code
- ✅ Middleware warning shows immediately on middleware.ts
- ✅ Parent Claude reminded of relevant skills at right moment
- ✅ Violations from stress test prevented before code written
- ✅ Developers understand new patterns (not just applying them blindly)

**Efficiency:**

- ✅ Hook execution < 10ms per call
- ✅ Session initialization < 5ms
- ✅ Skills load progressively (not all at once)
- ✅ No context bloat from repeated recommendations
- ✅ Fast validation scripts (< 100ms total)
- ✅ State management adds < 1ms overhead after first recommendation

**Extensibility:**

- ✅ Clear boundaries with @react-19 plugin
- ✅ Skill references work across plugins (`@react-19/HOOKS-*`)
- ✅ Hooks compose without conflicts
- ✅ Knowledge base reusable by other plugins
- ✅ Scripts reusable by other Next.js plugins

**Measurable Outcomes:**

- 0 middleware authentication patterns (vs 3 in stress test)
- 0 missing `use cache` where needed (vs 6 in stress test)
- 0 missing auth in server actions (vs 2 in stress test)
- 0 incorrect revalidateTag() calls (vs 3 in stress test)
- 100% of critical security patterns applied correctly

## Risk Mitigation

**Risk: Hook pattern matching too broad**

- Mitigation: Use specific patterns (app/, middleware.ts, *action*.ts)
- Test with real Next.js 16 project files
- Gather feedback on false positives
- Fallback: Allow configuration of activation patterns in future version

**Risk: Too many skills activated at once**

- Mitigation: Session lifecycle prevents repeated recommendations
- Only show recommendation once per type per session
- Group related skills in concise message
- Fallback: Summarize available skills rather than listing all

**Risk: Hook execution too slow**

- Mitigation: Use fast pattern matching (bash case statements, grep)
- Cache state file reads
- Minimize file operations
- Target: < 10ms total execution
- Fallback: Reduce pattern complexity, remove expensive checks

**Risk: Skills overlap with @react-19 plugin**

- Mitigation: Clear domain boundaries in design
- Next.js 16 specific vs React 19 general
- Document intended composition
- Use skill references instead of duplication
- Fallback: Consolidate overlapping content into knowledge base

**Risk: State file conflicts between sessions/plugins**

- Mitigation: Plugin-specific state file name
- SessionStart cleans up old sessions
- Portable sed syntax for macOS/Linux
- Graceful handling of missing state file
- Fallback: Silent failure if state management breaks (recommendations still work, just repeat)

**Risk: Developers ignore security warnings**

- Mitigation: Make middleware warning CRITICAL level
- Activate security skills automatically for server actions
- Clear, actionable messages
- Link to CVE details
- Fallback: Add PostToolUse hook to re-check security patterns after code written

## Conclusion

This plugin follows official Claude Code structure while using concern prefixes for skill organization. The intelligent hook system ensures skills are surfaced at the right time based on file context, reducing cognitive load while maximizing relevance. Critical security patterns (CVE-2025-29927) are prioritized, and the Cache Components model is taught progressively.

**Key innovations:**

- **Concern-prefix naming**: Self-documenting skill organization (SECURITY, CACHING, MIGRATION, etc.)
- **Intelligent PreToolUse hook**: Context-aware skill activation based on file patterns
- **Session lifecycle management**: Once-per-session recommendations prevent context bloat
- **Bash-based validation**: Fast, deterministic pattern detection and validation
- **Knowledge separation**: Shared research in knowledge/ directory, skill-specific examples in references/
- **Script reusability**: Validation logic in scripts/ used by hooks and skills
- **Security-first**: CVE-2025-29927 patterns prioritized, middleware warnings immediate
- **Official tooling**: Next.js DevTools MCP server for hands-on debugging and inspection

**Implementation ready:**
- All 9 skills defined with clear scope
- Intelligent hook system designed and detailed
- Session lifecycle scripts specified
- Validation scripts planned
- MCP server configured (next-devtools)
- Phased approach: 24-34 hours total
- Success metrics established
- Risk mitigation strategies in place

**Next Steps:**
1. Review this design document
2. Implement Phase 1 (Core Security & Caching Skills)
3. Implement Phase 2 (Intelligent Hooks & Lifecycle)
4. Implement remaining phases
5. Test with real Next.js 16 projects
6. Gather feedback and refine

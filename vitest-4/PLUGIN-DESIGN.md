# Vitest 4 Plugin Design

**Date:** November 24, 2025
**Status:** Draft Design
**Author:** Design Session with Claude Code

## Overview

This plugin provides Vitest 4.x knowledge to Claude Code, preventing deprecated API usage and teaching current patterns. The stress test revealed 24 violations across 5 agents—all using Vitest 2.x/3.x patterns instead of 4.x.

Vitest 4.0 (October 2025) introduced breaking changes to pool architecture, coverage configuration, and multi-project setup. Parent Claude's knowledge predates these changes, causing agents to generate invalid configurations that fail at runtime.

The plugin uses intelligent hooks to activate skills contextually: detecting config files, test files, and deprecated patterns to surface relevant knowledge exactly when needed.

## Problem Statement

**Problems This Plugin Solves:**

1. **Deprecated Pool Configuration** (12 violations) - Agents use removed options: `maxThreads`, `singleThread`, `poolOptions`, `minWorkers`
2. **Coverage Config Errors** (8 violations) - Missing `coverage.include`, using removed `ignoreEmptyLines`/`coverage.all`/`coverage.extensions`
3. **Workspace Migration Gap** (3 violations) - Using `defineWorkspace`/`poolMatchGlobs`/`environmentMatchGlobs` instead of `projects`
4. **Browser Mode Confusion** (2 violations) - Manual API implementations instead of `vitest/browser` imports
5. **Knowledge Cutoff** - Parent Claude has Vitest 2.x/3.x knowledge, not 4.x

**Why These Matter:**
- Invalid configs cause runtime failures with cryptic errors
- Deprecated patterns silently ignored or cause test failures
- Browser mode requires specific provider packages (`@vitest/browser-playwright`)
- Migration path unclear without explicit guidance

## Core Design Principles

### 1. No Agents

Skills teach patterns; agents would duplicate parent context. No differentiation in permissions/model needed—vitest configuration is straightforward.

### 2. No Commands

Testing workflows vary too much for standardized commands. Natural language handles "configure vitest", "write tests for X", "set up coverage" better than fixed commands.

### 3. No MCP Servers

Vitest runs via `npm test`/`vitest` CLI. Built-in Bash tool sufficient for all operations.

### 4. Intelligent Skill Activation

PreToolUse hook detects file patterns and content to surface relevant skills:
- Config files → configuration skills
- Test files → test writing skills
- Deprecated patterns → migration guidance

## Architecture

### Plugin Components

**Skills (5 total: 4 teaching + 1 review)**

| Skill | Type | Purpose | Activation Trigger |
|-------|------|---------|-------------------|
| `configuring-vitest-4/` | Teaching | Pool architecture, coverage, projects | `vitest.config.*` files |
| `migrating-to-vitest-4/` | Teaching | 3.x → 4.x migration patterns | Deprecated patterns detected |
| `writing-vitest-tests/` | Teaching | Test structure, mocking, assertions | `*.test.ts`, `*.spec.ts` files |
| `using-browser-mode/` | Teaching | Browser testing setup and APIs | `browser:` config detected |
| `reviewing-vitest-config/` | Review | Config validation | `/review vitest` command |

**Hooks (3 event handlers)**

- `SessionStart`: Initialize session state
- `PreToolUse`: Contextual skill recommendations based on file patterns
- `PostToolUse`: Validate written configs for deprecated patterns

**Scripts (5 shared utilities)**

- `init-session.sh`: SessionStart handler
- `recommend-skills.sh`: PreToolUse skill activation
- `validate-vitest-config.sh`: PostToolUse config validation (deprecated options)
- `validate-vitest-tests.sh`: PostToolUse test file validation (deprecated imports)
- All source `marketplace-utils/hook-lifecycle.sh`

**Knowledge (1 shared document)**

- `vitest-4-comprehensive.md`: Complete Vitest 4.x reference (from RESEARCH.md)

### File Structure

```tree
vitest-4/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── configuring-vitest-4/
│   │   └── SKILL.md
│   ├── migrating-to-vitest-4/
│   │   └── SKILL.md
│   ├── writing-vitest-tests/
│   │   └── SKILL.md
│   ├── using-browser-mode/
│   │   └── SKILL.md
│   └── reviewing-vitest-config/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── init-session.sh
│   ├── recommend-skills.sh
│   ├── validate-vitest-config.sh
│   └── validate-vitest-tests.sh
└── knowledge/
    └── vitest-4-comprehensive.md
```

## Skill Structure

### configuring-vitest-4/

**Purpose:** Teach correct Vitest 4.x configuration patterns

**Key Topics:**
- Pool architecture: `maxWorkers` (not `maxThreads`/`maxForks`)
- Single-threaded: `maxWorkers: 1, isolate: false` (not `singleThread`/`singleFork`)
- Coverage: explicit `include` patterns required, removed options
- Multi-project: `projects` array (not `workspace`)

**References:** `knowledge/vitest-4-comprehensive.md` sections on Configuration, Pool Architecture

### migrating-to-vitest-4/

**Purpose:** Guide migration from Vitest 2.x/3.x to 4.x

**Key Topics:**
- Pool options migration table
- Coverage config changes
- `defineWorkspace` → `defineConfig` with `projects`
- `deps.inline` → `server.deps.inline`
- Browser mode import paths

**References:** `knowledge/vitest-4-comprehensive.md` section on Breaking Changes

### writing-vitest-tests/

**Purpose:** Teach test structure and patterns

**Key Topics:**
- Test organization: `describe`, `test`, `it`
- Assertions: `expect`, `toMatchSnapshot`, `toMatchInlineSnapshot`
- Mocking: `vi.fn()`, `vi.mock()`, `vi.spyOn()`
- Async: `await expect().resolves`, `await expect().rejects`
- Parameterized: `test.each`, `test.for`
- Fixtures: `test.extend()`

**References:** `knowledge/vitest-4-comprehensive.md` sections on Usage Patterns, Advanced Patterns

### using-browser-mode/

**Purpose:** Teach browser testing setup

**Key Topics:**
- Provider packages: `@vitest/browser-playwright`, `@vitest/browser-webdriverio`
- Configuration: `browser.provider`, `browser.instances`
- APIs: `page`, `userEvent` from `vitest/browser`
- Component testing: `vitest-browser-react`, `vitest-browser-vue`
- Visual regression: `toMatchScreenshot()`, `toBeInViewport()`

**References:** `knowledge/vitest-4-comprehensive.md` section on Browser Mode

### reviewing-vitest-config/

**Purpose:** Review skill for config validation

**Frontmatter:**
```yaml
name: reviewing-vitest-config
description: Review Vitest configuration for deprecated patterns and best practices. Use when reviewing test configuration or vitest setup.
review: true
```

**Checks:**
- Deprecated options: `maxThreads`, `singleThread`, `poolOptions`, `coverage.ignoreEmptyLines`
- Missing required: `coverage.include` when coverage enabled
- Workspace migration: `defineWorkspace` → `projects`
- Browser mode: correct provider packages and imports

## Intelligent Hook System

### Session Lifecycle

All hooks use `marketplace-utils/hook-lifecycle.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "hook-name"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")
file_path=$(get_input_field "tool_input.file_path")
```

### Activation Rules

| Pattern | Triggered Skills | Rationale | Frequency |
|---------|------------------|-----------|-----------|
| `vitest.config.*` | configuring-vitest-4 | Config file detected | Once per session |
| `*.test.ts`, `*.spec.ts` | writing-vitest-tests | Test file detected | Once per session |
| `*.test.tsx`, `*.spec.tsx` | writing-vitest-tests | React test file | Once per session |
| Content: `maxThreads\|singleThread\|poolOptions` | migrating-to-vitest-4 | Deprecated pattern | Once per session |
| Content: `browser:` in config | using-browser-mode | Browser mode setup | Once per session |
| Content: `coverage.ignoreEmptyLines` | migrating-to-vitest-4 | Deprecated coverage | Once per session |

### Hook Scripts

**scripts/init-session.sh** (SessionStart)
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "init-session"

log_info "Vitest 4 plugin initialized"
exit 0
```

**scripts/recommend-skills.sh** (PreToolUse)
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "recommend-skills"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

[[ "$tool_name" != "Read" && "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && exit 0

file_path=$(get_input_field "tool_input.file_path")
[[ -z "$file_path" ]] && exit 0

case "$file_path" in
  *vitest.config.*)
    if ! has_shown_recommendation "vitest-4" "configuring"; then
      echo "📦 Vitest 4 config detected - see configuring-vitest-4 skill for pool/coverage patterns"
      mark_recommendation_shown "vitest-4" "configuring"
    fi
    ;;
  *.test.ts|*.spec.ts|*.test.tsx|*.spec.tsx)
    if ! has_shown_recommendation "vitest-4" "testing"; then
      echo "🧪 Vitest test file - see writing-vitest-tests skill for test patterns"
      mark_recommendation_shown "vitest-4" "testing"
    fi
    ;;
esac

exit 0
```

**scripts/validate-vitest-config.sh** (PostToolUse - config files)
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "validate-config"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && exit 0

file_path=$(get_input_field "tool_input.file_path")
[[ ! "$file_path" =~ vitest\.config\. ]] && exit 0

content=$(get_input_field "tool_input.content")
[[ -z "$content" ]] && content=$(get_input_field "tool_input.new_string")
[[ -z "$content" ]] && exit 0

deprecated_config_patterns=(
  "maxThreads"
  "minThreads"
  "singleThread"
  "singleFork"
  "poolOptions"
  "minWorkers"
  "coverage.ignoreEmptyLines"
  "coverage.all"
  "coverage.extensions"
  "defineWorkspace"
  "poolMatchGlobs"
  "environmentMatchGlobs"
  "deps.inline"
  "deps.external"
  "deps.fallbackCJS"
  "browser.testerScripts"
)

errors=""
for pattern in "${deprecated_config_patterns[@]}"; do
  if echo "$content" | grep -q "$pattern"; then
    case "$pattern" in
      "deps.inline"|"deps.external"|"deps.fallbackCJS")
        errors+="❌ Moved: $pattern → server.$pattern\n"
        ;;
      "browser.testerScripts")
        errors+="❌ Replaced: $pattern → browser.testerHtmlPath\n"
        ;;
      *)
        errors+="❌ Deprecated: $pattern\n"
        ;;
    esac
  fi
done

if [[ -n "$errors" ]]; then
  echo -e "$errors" >&2
  echo "See migrating-to-vitest-4 skill for Vitest 4.x patterns" >&2
  exit 2
fi

exit 0
```

**scripts/validate-vitest-tests.sh** (PostToolUse - test files)
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../marketplace-utils/hook-lifecycle.sh"

init_hook "vitest-4" "validate-tests"

input=$(read_hook_input)
tool_name=$(get_input_field "tool_name")

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && exit 0

file_path=$(get_input_field "tool_input.file_path")
[[ ! "$file_path" =~ \.(test|spec)\.(ts|tsx|js|jsx)$ ]] && exit 0

content=$(get_input_field "tool_input.content")
[[ -z "$content" ]] && content=$(get_input_field "tool_input.new_string")
[[ -z "$content" ]] && exit 0

errors=""

if echo "$content" | grep -q "@vitest/browser/context"; then
  errors+="❌ Deprecated import: @vitest/browser/context → vitest/browser\n"
fi

if echo "$content" | grep -q "from ['\"]vitest/execute['\"]"; then
  errors+="❌ Removed: vitest/execute entry point no longer exists\n"
fi

if echo "$content" | grep -q "VITE_NODE_DEPS_MODULE_DIRECTORIES"; then
  errors+="❌ Renamed: VITE_NODE_DEPS_MODULE_DIRECTORIES → VITEST_MODULE_DIRECTORIES\n"
fi

if [[ -n "$errors" ]]; then
  echo -e "$errors" >&2
  echo "See migrating-to-vitest-4 skill for Vitest 4.x patterns" >&2
  exit 2
fi

exit 0
```

### hooks/hooks.json

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/init-session.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Read|Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/recommend-skills.sh"
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
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-vitest-config.sh"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-vitest-tests.sh"
          }
        ]
      }
    ]
  }
}
```

### Performance

- **Target:** < 100ms total execution
- **Early exits:** Non-matching tools/files exit immediately
- **Session state:** Recommendations shown once per session
- **Config validation:** Only on `vitest.config.*` files (16 deprecated patterns)
- **Test validation:** Only on `*.(test|spec).(ts|tsx|js|jsx)` files (3 deprecated imports)

## Integration with Other Plugins

### Plugin Boundaries

**This plugin provides:**
- Vitest 4.x configuration patterns
- Test writing with Vitest API
- Mocking with `vi.*` utilities
- Browser mode setup

**Related plugins provide:**
- `react-19/`: React component/hook testing patterns (uses Vitest)
- `typescript/`: Type safety in test code
- `zod-4/`: Schema testing patterns (already uses Vitest)
- `prisma-6/`: Database testing setup

### Integration Table

| Direction | Plugin | Skill | Integration |
|-----------|--------|-------|-------------|
| Outbound | react-19 | testing-components | Reference for React Testing Library patterns |
| Outbound | react-19 | testing-hooks | Reference for hook testing with `renderHook` |
| Outbound | typescript | reviewing-type-safety | Reference for type safety in tests |
| Outbound | zod-4 | testing-zod-schemas | Example of Vitest usage (already uses vitest) |
| Inbound | react-19 | testing-* | Should reference vitest-4 for config |
| Inbound | prisma-6 | (future) | Should reference vitest-4 for setup |
| Review | review | auto-discovery | `reviewing-vitest-config` via frontmatter |

### Composition Patterns

**Skill References:**
```markdown
For React component testing patterns, see @react-19/skills/testing-components
For type testing with expectTypeOf, see @zod-4/skills/testing-zod-schemas
```

**Knowledge Sharing:**
```markdown
For complete Vitest 4 reference, see @vitest-4/knowledge/vitest-4-comprehensive.md
```

**Hook Layering:**
Multiple plugins can have PreToolUse hooks—they compose additively. Vitest-4 hooks don't conflict with react-19 or typescript hooks.

## Plugin Metadata

### plugin.json

```json
{
  "name": "vitest-4",
  "version": "1.0.0",
  "description": "Vitest 4.x testing framework patterns and configuration",
  "author": {
    "name": "Claude Code Plugin Marketplace"
  },
  "keywords": ["vitest", "testing", "vite", "coverage", "mocking"],
  "hooks": "./hooks/hooks.json"
}
```

Skills auto-discovered from `skills/` directory.

## Implementation Strategy

### Phase 1: Core Skills (Week 1)

1. Create `configuring-vitest-4/SKILL.md`
   - Pool architecture section
   - Coverage configuration
   - Multi-project setup
2. Create `migrating-to-vitest-4/SKILL.md`
   - Migration tables from stress test findings
   - Before/after examples
3. Create `writing-vitest-tests/SKILL.md`
   - Test structure
   - Mocking patterns
   - Async testing

### Phase 2: Intelligent Hooks (Week 2)

1. Create hook scripts using marketplace-utils
2. Test activation rules with real files
3. Implement validation for deprecated patterns
4. Performance testing (< 100ms)

### Phase 3: Knowledge Base (Week 2)

1. Create `knowledge/vitest-4-comprehensive.md` from RESEARCH.md
2. Link from skills using references
3. Ensure stress test violations are covered

### Phase 4: Integration & Testing (Week 3)

1. Test skill activation with Vitest projects
2. Verify hook triggering logic
3. Test composition with react-19 and typescript plugins
4. Run `/validate` and `/review-plugin vitest-4`

### Phase 5: Refinement (Week 3)

1. Gather feedback on activation accuracy
2. Refine skill descriptions for discoverability
3. Optimize hook patterns based on usage
4. Documentation polish

## Success Metrics

**Effectiveness:**
- Skills activate for vitest.config.* and test files
- Deprecated patterns caught before commit
- All 24 stress test violations would be prevented

**Efficiency:**
- Hook execution < 100ms
- Skills load progressively
- No context bloat from over-activation

**Extensibility:**
- Clear boundaries with react-19, typescript, zod-4
- Skill references work across plugins
- Hooks compose without conflicts

## Risk Mitigation

**Risk: Hook pattern matching too broad**
- Mitigation: Specific file extensions (.test.ts, vitest.config.*)
- Fallback: Allow users to configure activation rules

**Risk: Too many skills activated at once**
- Mitigation: Recommendations shown once per session per category
- Fallback: Combine related recommendations

**Risk: Hook execution too slow**
- Mitigation: Early exits, grep for pattern matching
- Fallback: Cache results, reduce complexity

**Risk: Skills overlap with react-19 testing skills**
- Mitigation: vitest-4 teaches framework, react-19 teaches React patterns
- Fallback: Cross-reference instead of duplicate

**Risk: Validation too strict**
- Mitigation: Only flag patterns that definitely fail
- Fallback: Warn instead of block for edge cases

## Conclusion

This plugin addresses the Vitest 4.x knowledge gap that caused 24 violations in stress testing. The intelligent hook system ensures skills surface at the right time—when editing configs, writing tests, or using deprecated patterns.

**Key Features:**
- PreToolUse hooks for contextual skill activation
- PostToolUse validation blocks deprecated patterns
- Shared knowledge base from comprehensive research
- Clear integration with react-19, typescript, zod-4 plugins

**Implementation Ready:** All components defined, phased approach clear, success metrics established.

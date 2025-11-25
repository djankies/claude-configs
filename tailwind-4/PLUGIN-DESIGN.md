# Tailwind CSS v4 Plugin Design

**Date:** 2025-11-24
**Status:** Draft Design
**Author:** Design Session with Claude Code

## Overview

This plugin teaches Tailwind CSS v4's breaking changes and new patterns. Tailwind v4 (released January 2025) fundamentally changes configuration from JavaScript to CSS-first, introduces oklch() color space, and adds native container queries and 3D transforms.

Stress testing revealed 5/6 agents failed basic Vite plugin configuration and 4/6 used deprecated patterns. This plugin provides skills for correct v4 usage and hooks to prevent common violations.

## Problem Statement

**Critical Configuration Failures:**
- Missing `@tailwindcss/vite` plugin (5/6 agents)
- Using deprecated `tailwind.config.js` instead of CSS `@theme` (1/6 agents)
- Missing `@tailwindcss/vite` package dependency (multiple agents)

**Deprecated Pattern Usage:**
- Hex/RGB colors instead of oklch() (4/6 agents)
- Numbered colors instead of semantic names (3/6 agents)
- Deprecated opacity modifiers (`bg-opacity-50` instead of `bg-black/50`)
- Using `@apply` instead of `@utility` directive

**Missed Modern Features:**
- Viewport breakpoints instead of container queries (2/6 agents)
- Custom CSS classes instead of `@utility` directive
- Inline styles instead of utility classes
- Arbitrary values instead of theme variables

## Core Design Principles

### 1. No Agents

Parent Claude with proper skills handles all Tailwind v4 workflows. No isolation or different permissions needed.

### 2. No Commands

Natural language handles configuration, theming, and component styling. No frequent repetitive directives identified.

### 3. No MCP Servers

Built-in Read, Write, Edit, and Bash tools sufficient for all Tailwind operations.

### 4. Intelligent Skill Activation

PreToolUse hook detects CSS files, Vite/PostCSS configs, and component files to surface relevant skills contextually.

## Architecture

### Plugin Components

**Skills (6 teaching + 1 review)**

| Skill | Purpose |
|-------|---------|
| `configuring-tailwind-v4/` | Vite plugin, CSS imports, @theme directive |
| `using-theme-variables/` | oklch colors, semantic naming, design tokens |
| `using-container-queries/` | @container, responsive component patterns |
| `creating-custom-utilities/` | @utility directive, functional utilities |
| `migrating-from-v3/` | Breaking changes, deprecated patterns, upgrade path |
| `handling-animations/` | @keyframes in @theme, animation utilities |
| `reviewing-tailwind-patterns/` | Review skill for code review integration |

**Hooks (3 event handlers)**

| Event | Script | Purpose |
|-------|--------|---------|
| SessionStart | `init-session.sh` | Initialize session state JSON |
| PreToolUse | `recommend-skills.sh` | Once-per-session skill recommendations |
| PreToolUse | `validate-config.sh` | Block deprecated patterns |

**Scripts (4 shared utilities)**

| Script | Purpose |
|--------|---------|
| `init-session.sh` | Create/reset session state |
| `recommend-skills.sh` | Contextual skill recommendations |
| `validate-config.sh` | Detect deprecated v3 patterns |
| `validate-colors.sh` | Warn about hex colors in @theme |

**Knowledge (shared research)**

| Document | Content |
|----------|---------|
| `RESEARCH.md` | Comprehensive v4 documentation (existing) |

## Skill Structure

### `configuring-tailwind-v4/`

**SKILL.md focus:**
- Vite plugin installation and configuration
- CSS import syntax (`@import 'tailwindcss'`)
- @theme directive basics
- PostCSS alternative for non-Vite projects

**references/:**
- `vite-setup.md` - Complete Vite configuration examples
- `postcss-setup.md` - PostCSS configuration examples
- `nextjs-setup.md` - Next.js specific setup

### `using-theme-variables/`

**SKILL.md focus:**
- oklch() color format and conversion from hex
- Semantic color naming patterns
- Theme variable namespaces
- Extending vs replacing defaults

**references/:**
- `color-conversion.md` - Hex to oklch conversion table
- `namespace-reference.md` - Complete namespace documentation

### `using-container-queries/`

**SKILL.md focus:**
- When to use container vs viewport queries
- @container syntax and named containers
- Component portability patterns

### `creating-custom-utilities/`

**SKILL.md focus:**
- @utility directive syntax
- Static vs functional utilities
- Theme-based utilities
- Multi-value utilities

### `migrating-from-v3/`

**SKILL.md focus:**
- Configuration migration (JS → CSS)
- Utility renames (shadow-sm → shadow-xs)
- Opacity modifier changes
- Color system migration

**references/:**
- `breaking-changes.md` - Complete breaking changes list
- `migration-checklist.md` - Step-by-step migration guide

### `handling-animations/`

**SKILL.md focus:**
- @keyframes within @theme
- Animation variable naming
- starting: variant for entry animations

### `reviewing-tailwind-patterns/`

**SKILL.md frontmatter:**
```yaml
name: reviewing-tailwind-patterns
description: Review Tailwind CSS v4 patterns for configuration, theming, and utility usage. Use when reviewing CSS files, Vite configs, or components using Tailwind.
review: true
allowed-tools: Read, Grep, Glob
```

**Review checklist:**
1. Vite plugin configured correctly
2. Using CSS @theme instead of tailwind.config.js
3. oklch() colors in theme definitions
4. Semantic color naming
5. Container queries for component responsiveness
6. @utility for custom utilities

## Intelligent Hook System

### Session Lifecycle Management

**SessionStart (`scripts/init-session.sh`):**
```bash
#!/bin/bash
STATE_FILE="/tmp/claude-tailwind-4-session.json"

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$$-$(date +%s)",
  "recommendations_shown": {
    "css_config": false,
    "vite_config": false,
    "postcss_config": false,
    "component_styling": false
  }
}
EOF

echo "[tailwind-4] Session initialized"
```

**PreToolUse recommendation (`scripts/recommend-skills.sh`):**
```bash
#!/bin/bash

STATE_FILE="/tmp/claude-tailwind-4-session.json"
[[ ! -f "$STATE_FILE" ]] && exit 0

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" && "$tool_name" != "Read" ]] && exit 0
[[ -z "$file_path" ]] && exit 0

RECOMMENDATION_TYPE=""
MESSAGE=""

case "$file_path" in
  *.css)
    RECOMMENDATION_TYPE="css_config"
    MESSAGE="📚 Tailwind v4 skills: configuring-tailwind-v4, using-theme-variables"
    ;;
  *vite.config*)
    RECOMMENDATION_TYPE="vite_config"
    MESSAGE="📚 Tailwind v4: Use @tailwindcss/vite plugin. See configuring-tailwind-v4 skill."
    ;;
  *postcss.config*)
    RECOMMENDATION_TYPE="postcss_config"
    MESSAGE="📚 Tailwind v4: Use @tailwindcss/postcss. See configuring-tailwind-v4 skill."
    ;;
  *.tsx|*.jsx)
    RECOMMENDATION_TYPE="component_styling"
    MESSAGE="📚 Tailwind v4 skills: using-container-queries, creating-custom-utilities"
    ;;
  *)
    exit 0
    ;;
esac

[[ -z "$RECOMMENDATION_TYPE" ]] && exit 0

SHOWN=$(grep -o "\"$RECOMMENDATION_TYPE\": true" "$STATE_FILE" 2>/dev/null)

if [[ -z "$SHOWN" ]]; then
  echo "$MESSAGE"
  sed -i.bak "s/\"$RECOMMENDATION_TYPE\": false/\"$RECOMMENDATION_TYPE\": true/" "$STATE_FILE"
fi

exit 0
```

### Activation Rules Table

| Pattern | Triggered Skills | Rationale | Frequency |
|---------|------------------|-----------|-----------|
| `*.css` | configuring-tailwind-v4, using-theme-variables | CSS config files | Once per session |
| `*vite.config*` | configuring-tailwind-v4 | Vite plugin setup | Once per session |
| `*postcss.config*` | configuring-tailwind-v4 | PostCSS setup | Once per session |
| `*.tsx`, `*.jsx` | using-container-queries, creating-custom-utilities | Component patterns | Once per session |
| `*tailwind.config*` | BLOCK with warning | Deprecated v3 config | Always |

### Validation Hooks

**PreToolUse validation (`scripts/validate-config.sh`):**
```bash
#!/bin/bash

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$tool_name" != "Write" ]] && exit 0

if [[ "$file_path" == *"tailwind.config"* ]]; then
  echo "❌ DEPRECATED: tailwind.config.js removed in v4" >&2
  echo "Use CSS @theme directive in your main CSS file instead." >&2
  echo "See: configuring-tailwind-v4 skill" >&2
  exit 2
fi

exit 0
```

**PreToolUse color validation (`scripts/validate-colors.sh`):**
```bash
#!/bin/bash

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
content=$(echo "$input" | jq -r '.tool_input.content // empty')

[[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]] && exit 0
[[ ! "$file_path" =~ \.css$ ]] && exit 0

if echo "$content" | grep -q "@theme" && echo "$content" | grep -qE "#[0-9a-fA-F]{3,8}"; then
  echo "⚠️  WARNING: Using hex colors in @theme" >&2
  echo "Tailwind v4 uses oklch() for wider gamut. Consider converting." >&2
  echo "See: using-theme-variables skill for conversion guide" >&2
fi

exit 0
```

## File Structure

```tree
tailwind-4/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── configuring-tailwind-v4/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── vite-setup.md
│   │       ├── postcss-setup.md
│   │       └── nextjs-setup.md
│   ├── using-theme-variables/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── color-conversion.md
│   │       └── namespace-reference.md
│   ├── using-container-queries/
│   │   └── SKILL.md
│   ├── creating-custom-utilities/
│   │   └── SKILL.md
│   ├── migrating-from-v3/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── breaking-changes.md
│   │       └── migration-checklist.md
│   ├── handling-animations/
│   │   └── SKILL.md
│   └── reviewing-tailwind-patterns/
│       └── SKILL.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── init-session.sh
│   ├── recommend-skills.sh
│   ├── validate-config.sh
│   └── validate-colors.sh
├── RESEARCH.md
└── STRESS-TEST-REPORT.md
```

## Integration with Other Plugins

### Plugin Boundaries

**This plugin provides:**
- Tailwind CSS v4 configuration patterns
- Theme customization with CSS @theme
- Utility creation with @utility directive
- Container query patterns
- v3 → v4 migration guidance

**Related plugins provide:**
- `@react-19`: React component patterns (uses Tailwind for styling)
- `@nextjs-15`: Next.js integration (includes Tailwind PostCSS setup)
- `@vite-6`: Vite configuration (plugin slot for @tailwindcss/vite)

### Composition Patterns

**Skill References:**
React/Next.js plugins can reference: `@tailwind-4/skills/using-container-queries`

**Knowledge Sharing:**
Skills reference: `@tailwind-4/RESEARCH.md` for comprehensive docs

**Hook Layering:**
Multiple plugins can have PreToolUse hooks for `*.css` - they compose additively.

## Plugin Metadata

```json
{
  "name": "tailwind-4",
  "version": "1.0.0",
  "description": "Tailwind CSS v4 patterns: CSS-first config, oklch colors, container queries, @utility directive",
  "hooks": "./hooks/hooks.json"
}
```

**hooks/hooks.json:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/init-session.sh"
        }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Read|Write|Edit",
        "hooks": [{
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/recommend-skills.sh"
        }]
      },
      {
        "matcher": "Write",
        "hooks": [{
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-config.sh"
        }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-colors.sh"
        }]
      }
    ]
  }
}
```

## Implementation Strategy

### Phase 1: Core Skills (Week 1)

1. Write `configuring-tailwind-v4/SKILL.md` with references
2. Write `using-theme-variables/SKILL.md` with color conversion guide
3. Write `migrating-from-v3/SKILL.md` with breaking changes list
4. Extract key patterns from existing RESEARCH.md

### Phase 2: Advanced Skills (Week 2)

1. Write `using-container-queries/SKILL.md`
2. Write `creating-custom-utilities/SKILL.md`
3. Write `handling-animations/SKILL.md`
4. Write `reviewing-tailwind-patterns/SKILL.md`

### Phase 3: Hook System (Week 3)

1. Implement SessionStart hook with state JSON
2. Implement PreToolUse recommendation hook
3. Implement validation hooks for config and colors
4. Test hook performance (< 100ms target)

### Phase 4: Integration & Testing (Week 4)

1. Test skill activation with real Tailwind projects
2. Verify hook triggering accuracy
3. Test composition with react-19/nextjs-15 plugins
4. Performance tuning and refinement

## Success Metrics

**Effectiveness:**
- Skills activate for relevant file types (CSS, config, components)
- Configuration validation prevents deprecated patterns
- Review skill catches v3 antipatterns

**Efficiency:**
- Hook execution < 100ms total
- Skills load progressively (not all at once)
- Recommendations shown once per session per context

**Extensibility:**
- Clear boundary with react/nextjs plugins
- Review skill integrates with review plugin
- Hooks compose without conflicts

## Risk Mitigation

**Risk: Hook pattern matching too broad**
- Mitigation: Specific file extension checks, early exit for irrelevant tools
- Fallback: Allow users to disable specific hooks

**Risk: Too many skills activated for CSS files**
- Mitigation: Group related concepts, use references for details
- Fallback: Single "tailwind-v4-overview" skill with references

**Risk: Color validation creates noise**
- Mitigation: Warning only (exit 0), not blocking
- Fallback: Disable color validation hook if too noisy

**Risk: tailwind.config.js detection too aggressive**
- Mitigation: Only block Write, not Read/Edit
- Fallback: Add escape hatch for legitimate v3 projects

**Risk: Skills overlap with Next.js plugin**
- Mitigation: tailwind-4 owns CSS patterns; nextjs owns build integration
- Fallback: Document clear boundaries and cross-references

## Conclusion

This plugin addresses critical Tailwind CSS v4 adoption failures identified in stress testing. The intelligent hook system ensures skills surface contextually while validation hooks prevent common configuration mistakes.

**Key innovations:**
- Session state tracking prevents recommendation fatigue
- PreToolUse hooks for contextual skill activation
- Blocking hook for deprecated tailwind.config.js
- Review skill integrates with cross-cutting review plugin

**Implementation ready:** All components defined, phased approach clear, success metrics established.

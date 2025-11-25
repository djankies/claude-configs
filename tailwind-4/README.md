# Tailwind CSS v4 Plugin

**Official Claude Code plugin for Tailwind CSS v4 patterns, configuration, and best practices**

> Tailwind CSS v4 (released January 2025) fundamentally changes configuration from JavaScript to CSS-first, introduces oklch() color space, and adds native container queries and 3D transforms.

## Overview

This plugin provides autonomous skills and intelligent event hooks to help you adopt Tailwind CSS v4's breaking changes and modern patterns. Stress testing revealed that 5/6 AI coding agents failed basic Vite plugin configuration and 4/6 used deprecated patterns. This plugin addresses those failures through progressive skill activation and validation hooks.

### Why This Plugin Exists

**Critical Configuration Failures Identified:**
- Missing `@tailwindcss/vite` plugin in Vite projects (83% failure rate)
- Using deprecated `tailwind.config.js` instead of CSS `@theme` directive
- Missing package dependencies (`@tailwindcss/vite`, `@tailwindcss/postcss`)

**Deprecated Pattern Usage:**
- Hex/RGB colors instead of oklch() color space (67% of agents)
- Numbered colors instead of semantic naming (50% of agents)
- Deprecated opacity modifiers (`bg-opacity-50` instead of `bg-black/50`)
- Using `@apply` instead of `@utility` directive for custom utilities

**Missed Modern Features:**
- Viewport breakpoints instead of container queries (33% of agents)
- Custom CSS classes instead of `@utility` directive
- Inline styles instead of utility classes
- Arbitrary values instead of theme variables

## Features

- **7 Autonomous Skills**: Progressive disclosure of Tailwind v4 patterns
- **Intelligent Hook System**: Contextual skill recommendations based on file types
- **Validation Guards**: Blocks deprecated patterns before they're written
- **Once-Per-Session Recommendations**: Reduces noise through session state tracking
- **Integration Ready**: Composes with react-19, nextjs-15, and vite-6 plugins

## Installation

This plugin is part of the Claude Code Plugin Marketplace.

```bash
claude-code plugin install tailwind-4
```

Or manually install by cloning into your Claude Code plugins directory:

```bash
cd ~/.claude/plugins
git clone <repository-url> tailwind-4
```

## Usage

### Automatic Skill Activation

Skills activate automatically based on the files you work with:

**CSS Files** (`*.css`):
```
📚 Tailwind v4 skills: configuring-tailwind-v4, using-theme-variables
```

**Vite Configuration** (`*vite.config*`):
```
📚 Tailwind v4: Use @tailwindcss/vite plugin. See configuring-tailwind-v4 skill.
```

**PostCSS Configuration** (`*postcss.config*`):
```
📚 Tailwind v4: Use @tailwindcss/postcss. See configuring-tailwind-v4 skill.
```

**React/JSX Components** (`*.tsx`, `*.jsx`):
```
📚 Tailwind v4 skills: using-container-queries, creating-custom-utilities
```

### Validation Hooks

**Deprecated Config Detection:**

When you attempt to create `tailwind.config.js`:

```
❌ DEPRECATED: tailwind.config.js removed in v4
Use CSS @theme directive in your main CSS file instead.
See: configuring-tailwind-v4 skill
```

**Color Space Warning:**

When using hex colors in `@theme`:

```
⚠️  WARNING: Using hex colors in @theme
Tailwind v4 uses oklch() for wider gamut. Consider converting.
See: using-theme-variables skill for conversion guide
```

### Example: Creating a Tailwind v4 Project

1. **Create a Vite + React project:**

```bash
npm create vite@latest my-app -- --template react
cd my-app
```

2. **Work with vite.config.js** - Plugin automatically recommends `configuring-tailwind-v4` skill

3. **Create CSS file with @theme** - Plugin surfaces `using-theme-variables` skill

4. **Build components** - Plugin recommends `using-container-queries` for responsive design

## Components

### Skills (7)

| Skill | Purpose | Activated When |
|-------|---------|----------------|
| **configuring-tailwind-v4** | Vite plugin setup, CSS imports, @theme directive | Working with CSS or config files |
| **using-theme-variables** | oklch colors, semantic naming, design tokens | Working with CSS files |
| **using-container-queries** | @container syntax, component portability | Working with components |
| **creating-custom-utilities** | @utility directive, functional utilities | Working with components |
| **migrating-from-v3** | Breaking changes, deprecated patterns, upgrade path | Migrating existing projects |
| **handling-animations** | @keyframes in @theme, animation utilities | Adding animations |
| **reviewing-tailwind-patterns** | Code review integration for v4 compliance | During code reviews |

Each skill includes:
- Concise SKILL.md with essential patterns
- Detailed references/ directory with comprehensive examples
- Clear guidance on when to use each pattern

### Hooks (3 Event Handlers)

| Event | Script | Purpose | Frequency |
|-------|--------|---------|-----------|
| **SessionStart** | `init-session.sh` | Initialize session state JSON | Once per session |
| **PreToolUse** | `recommend-skills.sh` | Surface relevant skills contextually | Once per context type |
| **PreToolUse** | `validate-config.sh` | Block deprecated tailwind.config.js | Every Write operation |

### Scripts (4 Shared Utilities)

| Script | Purpose |
|--------|---------|
| `init-session.sh` | Create/reset session state tracking |
| `recommend-skills.sh` | Detect file types and recommend skills |
| `validate-config.sh` | Prevent deprecated configuration files |
| `validate-colors.sh` | Warn about hex colors in @theme |

### Knowledge (Shared Research)

- **RESEARCH.md**: Comprehensive Tailwind v4 documentation (1600+ lines)
- **STRESS-TEST-REPORT.md**: Detailed analysis of agent failures
- **PLUGIN-DESIGN.md**: Plugin architecture and design decisions

## Philosophy Alignment

This plugin follows the [Claude Code Plugin Philosophy](../.claude-plugin/PHILOSOPHY.md):

### 1. Progressive Disclosure

Skills load **only when relevant**. You won't see animation skills when configuring Vite, or migration skills in new projects.

**Session State Tracking:**
```json
{
  "session_id": "12345-1234567890",
  "recommendations_shown": {
    "css_config": false,
    "vite_config": false,
    "postcss_config": false,
    "component_styling": false
  }
}
```

Each recommendation type shows **once per session**, reducing noise.

### 2. Event-Driven Hooks

Hooks respond to **actual tool usage**, not speculative patterns:

```bash
PreToolUse → Read/Write/Edit → *.css → recommend skills
PreToolUse → Write → *tailwind.config* → block (deprecated)
```

### 3. No Commands Required

All guidance surfaces through **natural language** and **contextual skill activation**. No `/tailwind-*` commands needed.

### 4. No Agents Needed

Parent Claude with proper skills handles all workflows. No isolation or different permissions required.

### 5. No MCP Servers

Built-in tools (Read, Write, Edit, Bash) sufficient for all Tailwind operations.

## Integration with Other Plugins

### Plugin Boundaries

**This plugin provides:**
- Tailwind CSS v4 configuration patterns
- Theme customization with CSS `@theme`
- Utility creation with `@utility` directive
- Container query patterns
- v3 → v4 migration guidance

**Related plugins provide:**
- `@react-19`: React component patterns (uses Tailwind for styling)
- `@nextjs-15`: Next.js integration (includes Tailwind PostCSS setup)
- `@vite-6`: Vite configuration (plugin slot for @tailwindcss/vite)

### Composition Patterns

**Skill References:**

React/Next.js plugins can reference Tailwind skills:

```markdown
For styling patterns, see: @tailwind-4/skills/using-container-queries
```

**Knowledge Sharing:**

Other plugins reference comprehensive documentation:

```markdown
Tailwind v4 setup details: @tailwind-4/RESEARCH.md
```

**Hook Layering:**

Multiple plugins can have PreToolUse hooks for `*.css` files - they compose additively without conflicts.

## Success Metrics

### Effectiveness

- ✅ Skills activate for relevant file types (CSS, config, components)
- ✅ Configuration validation prevents deprecated patterns
- ✅ Review skill catches v3 antipatterns
- ✅ Hooks surface contextually appropriate guidance

### Efficiency

- ✅ Hook execution < 100ms total per tool use
- ✅ Skills load progressively (not all at once)
- ✅ Recommendations shown once per session per context
- ✅ Minimal cognitive overhead

### Extensibility

- ✅ Clear boundaries with react/nextjs plugins
- ✅ Review skill integrates with review plugin ecosystem
- ✅ Hooks compose without conflicts
- ✅ Knowledge reusable across plugins

## Quick Reference

### Tailwind v4 at a Glance

**Old Way (v3):**
```javascript
export default {
  content: ['./src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: '#5b21b6',
      },
    },
  },
}
```

**New Way (v4):**
```css
@import 'tailwindcss';

@theme {
  --color-brand: oklch(0.65 0.25 270);
}
```

### Common Patterns

**Vite Setup:**
```javascript
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

**Container Queries:**
```html
<div class="@container">
  <div class="grid grid-cols-1 @md:grid-cols-2 @lg:grid-cols-3">
    <!-- Responsive to container, not viewport -->
  </div>
</div>
```

**Custom Utilities:**
```css
@utility content-auto {
  content-visibility: auto;
}

@utility truncate-* {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: --value(integer);
  overflow: hidden;
}
```

**Entry Animations:**
```html
<div class="opacity-100 transition-opacity duration-300 starting:opacity-0">
  Fades in smoothly on mount
</div>
```

## Troubleshooting

### Skills Not Activating

**Check session state:**
```bash
cat /tmp/claude-tailwind-4-session.json
```

**Reset session state:**
Restart Claude Code session or manually delete state file.

### Hooks Not Running

**Verify hooks.json exists:**
```bash
ls -la ~/.claude/plugins/tailwind-4/hooks/hooks.json
```

**Check script permissions:**
```bash
chmod +x ~/.claude/plugins/tailwind-4/scripts/*.sh
```

### Color Validation Too Noisy

Disable color validation hook by removing from hooks.json:
```json
{
  "matcher": "Write|Edit",
  "hooks": [{
    "type": "command",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-colors.sh"
  }]
}
```

## Contributing

Contributions are welcome! Please see the [Contributing Guidelines](../CONTRIBUTING.md).

### Development Workflow

1. **Research**: Start with `/research-tool tailwind@4`
2. **Stress Test**: Run `/stress-test tailwind` to identify failures
3. **Design**: Create comprehensive design document
4. **Implement**: Write skills, hooks, and scripts
5. **Validate**: Run `/validate` to ensure compliance
6. **Review**: Use `/review-plugin tailwind-4` for comprehensive check

### Adding New Skills

Skills must:
- Include frontmatter with `name` and `description`
- Be placed in `skills/{skill-name}/SKILL.md`
- Focus on one specific pattern or workflow
- Include practical examples
- Reference detailed documentation in `references/` directory

### Adding New Hooks

Hooks must:
- Execute in < 100ms
- Exit 0 for success (warnings)
- Exit 2 for blocking errors
- Use JSON input for PreToolUse events
- Update session state appropriately

## Resources

- **Plugin Design Document**: [PLUGIN-DESIGN.md](./PLUGIN-DESIGN.md)
- **Comprehensive Research**: [RESEARCH.md](./RESEARCH.md)
- **Stress Test Report**: [STRESS-TEST-REPORT.md](./STRESS-TEST-REPORT.md)
- **Official Tailwind Docs**: https://tailwindcss.com/
- **v4 Release Blog**: https://tailwindcss.com/blog/tailwindcss-v4

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: Report bugs or request features in the plugin marketplace
- **Discussions**: Join the Claude Code community
- **Documentation**: See the official Tailwind CSS v4 documentation

---

**Built with the Claude Code Plugin Philosophy**: Progressive disclosure, event-driven activation, and autonomous operation without commands or agents.

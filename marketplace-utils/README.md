# Marketplace Utilities

**Purpose:** Shared utilities for plugin developers to reduce code duplication and improve consistency

**Important:** These utilities are **optional** and designed for plugins within this marketplace. External plugins should copy the utilities they need to remain self-contained.

## Philosophy

These utilities support the marketplace's open architecture:

1. **Self-Containment First**: External plugins should copy utilities, not depend on this directory
2. **Reference Implementation**: These are battle-tested patterns plugins can adopt
3. **Marketplace Cohesion**: Helps marketplace plugins stay consistent
4. **No Required Dependencies**: Plugins work without these utilities

## Structure

```tree
marketplace-utils/
├── README.md                    # This file
├── session-management.sh        # Session state utilities
├── frontmatter-parsing.sh       # YAML frontmatter extraction
├── file-detection.sh            # File type and context detection
├── json-utils.sh                # JSON manipulation utilities
├── skill-discovery.sh           # Skill discovery and metadata extraction
└── hook-templates/              # Reference hook implementations
    ├── init-session.sh          # SessionStart hook template
    ├── recommend-skills.sh      # PreToolUse recommendation template
    └── validate-patterns.sh     # PreToolUse validation template
```

## Session Management v2

The marketplace-utils directory provides a centralized hook infrastructure for all Claude Code plugins.

### Core Components

- **platform-compat.sh** - Cross-platform compatibility (macOS/Linux/Windows)
- **logging.sh** - Centralized logging system with configurable levels
- **error-reporting.sh** - Structured error journal in JSON Lines format
- **session-management.sh** - Enhanced session state with file locking
- **hook-lifecycle.sh** - Universal hook wrapper (source this in all hooks)

### Quick Start

Every hook should source the lifecycle wrapper:

```bash
#!/usr/bin/env bash
source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "plugin-name" "hook-name"

INPUT=$(read_hook_input)
FILE=$(get_input_field "tool_input.file_path")

log_info "Processing file: $FILE"

pretooluse_respond "allow"
exit 0
```

### Documentation

- [Migration Guide](docs/MIGRATION-GUIDE.md) - Migrate existing plugins to v2
- [Hook Development](docs/HOOK-DEVELOPMENT.md) - Write new hooks
- [Debugging](docs/DEBUGGING.md) - Troubleshoot hook issues
- [Architecture](docs/ARCHITECTURE.md) - System design and internals
- [Design Document](docs/SESSION-MANAGEMENT-V2-DESIGN.md) - Complete specification

### Testing

Run all tests:

```bash
cd marketplace-utils
./tests/test-runner.sh
```

### Environment Variables

- `CLAUDE_DEBUG_LEVEL` - Log level (DEBUG, INFO, WARN, ERROR) - default: WARN
- `CLAUDE_SAVE_LOGS` - Preserve logs after session (0 or 1) - default: 0
- `CLAUDE_LOG_DIR` - Custom log directory - default: /tmp

## Usage Patterns

### For Marketplace Plugins

**Option 1: Source the utility** (creates dependency)

```bash
#!/bin/bash
source "$(dirname "$0")/../../../marketplace-utils/session-management.sh"

init_session "my-plugin"
```

**Option 2: Copy the utility** (self-contained, recommended)

```bash
cp marketplace-utils/session-management.sh my-plugin/hooks/lib/
```

### For External Plugins

External plugins should **copy** the utilities they need:

```bash
cp marketplace-utils/session-management.sh external-plugin/hooks/lib/
```

This keeps external plugins self-contained and independently distributable.

## Available Utilities

### session-management.sh

Session state management for hooks.

**Functions:**
- `init_session <plugin_name>` - Initialize session state file
- `get_session_value <key>` - Read value from session state
- `set_session_value <key> <value>` - Write value to session state
- `has_shown_recommendation <file_path> <skill_name>` - Check if recommendation shown
- `mark_recommendation_shown <file_path> <skill_name>` - Record shown recommendation
- `clear_session` - Clear session state

**Example:**
```bash
source marketplace-utils/session-management.sh

init_session "react-19"

if ! has_shown_recommendation "$FILE_PATH" "using-use-hook"; then
    echo "💡 Consider using the 'use()' hook for this Promise"
    mark_recommendation_shown "$FILE_PATH" "using-use-hook"
fi
```

### frontmatter-parsing.sh

YAML frontmatter extraction from Markdown files.

**Functions:**
- `extract_frontmatter <file>` - Extract raw frontmatter block
- `get_frontmatter_value <file> <key>` - Get specific frontmatter value
- `has_frontmatter_tag <file> <tag>` - Check if frontmatter has tag
- `escape_json_string <string>` - Escape string for JSON

**Example:**
```bash
source marketplace-utils/frontmatter-parsing.sh

NAME=$(get_frontmatter_value "SKILL.md" "name")
if has_frontmatter_tag "SKILL.md" "review"; then
    echo "This is a review skill: $NAME"
fi
```

### file-detection.sh

File type and context detection for smart recommendations.

**Functions:**
- `is_typescript_file <path>` - Check if file is TypeScript
- `is_test_file <path>` - Check if file is a test
- `is_component_file <path>` - Check if file is a component
- `is_server_action <content>` - Check if content has 'use server'
- `detect_framework <path>` - Detect framework from file path
- `get_file_type <path>` - Get file type category

**Example:**
```bash
source marketplace-utils/file-detection.sh

if is_test_file "$FILE_PATH"; then
    echo "📝 Recommend testing skills"
elif is_component_file "$FILE_PATH"; then
    echo "⚛️ Recommend component skills"
fi
```

### json-utils.sh

JSON manipulation utilities for hook output.

**Functions:**
- `json_escape <string>` - Escape string for JSON
- `json_object <key1> <val1> [key2] [val2] ...` - Create JSON object
- `json_array <val1> [val2] ...` - Create JSON array
- `json_bool <value>` - Convert to JSON boolean

**Example:**
```bash
source marketplace-utils/json-utils.sh

MESSAGE=$(json_object \
    "type" "warning" \
    "text" "Deprecated pattern detected" \
    "severity" "high")

echo "$MESSAGE"
```

### skill-discovery.sh

Discover and parse skills across plugins.

**Functions:**
- `discover_skills <plugin_dir>` - Find all skills in plugin
- `discover_review_skills <plugin_dirs...>` - Find skills with review: true
- `get_skill_metadata <skill_file>` - Extract skill name, description, tags
- `skill_matches_concern <skill_file> <concern>` - Check if skill matches concern

**Example:**
```bash
source marketplace-utils/skill-discovery.sh

REVIEW_SKILLS=$(discover_review_skills typescript react-19 nextjs-16)
echo "$REVIEW_SKILLS" | jq -r '.[] | .name'
```

## Hook Templates

### init-session.sh

Reference implementation of SessionStart hook.

**Features:**
- Initialize session state
- Display welcome message (optional)
- Set up environment variables
- Version checking

**Usage:**
```bash
cp marketplace-utils/hook-templates/init-session.sh my-plugin/hooks/
# Customize for your plugin
```

### recommend-skills.sh

Reference implementation of skill recommendation (PreToolUse).

**Features:**
- File type detection
- Context-aware skill recommendations
- De-duplication via session state
- Framework detection

**Usage:**
```bash
cp marketplace-utils/hook-templates/recommend-skills.sh my-plugin/hooks/
# Customize recommendations for your skills
```

### validate-patterns.sh

Reference implementation of pattern validation (PreToolUse).

**Features:**
- Check for deprecated patterns
- Validate against best practices
- Exit code 2 to block operations
- Helpful error messages

**Usage:**
```bash
cp marketplace-utils/hook-templates/validate-patterns.sh my-plugin/hooks/
# Customize validation rules for your domain
```

## Design Principles

1. **No Magic**: Every utility is a simple bash function, easy to understand
2. **No Hidden State**: State files are explicitly managed, paths are predictable
3. **Copy-Friendly**: Each utility is self-contained, can be copied individually
4. **Tested Patterns**: Based on utilities battle-tested in review, typescript, react-19 plugins
5. **Optional**: Plugins work without these utilities

## Testing

Test utilities in isolation:

```bash
cd marketplace-utils
bash session-management.sh
bash frontmatter-parsing.sh
```

Test in a plugin context:

```bash
cd my-plugin/hooks
bash -x init-session.sh < test-input.json
```

## Contributing

When adding a utility:

1. Ensure it solves a problem seen in 3+ plugins
2. Write clear function documentation
3. Include usage examples
4. Keep it simple (< 200 lines per utility)
5. Test in at least 2 marketplace plugins
6. Update this README

## Maintenance

These utilities are maintained as **reference implementations**. When updating:

1. Update the utility file
2. Update this README
3. Update hook templates if applicable
4. Consider if existing plugins should adopt the changes (don't force updates)
5. Document breaking changes if any

## FAQ

### Q: Should external plugins depend on this directory?

**A:** No. External plugins should **copy** utilities to remain self-contained and independently distributable.

### Q: Should marketplace plugins source or copy utilities?

**A:** Either works, but **copying** is recommended for consistency with the self-containment principle. Sourcing creates a dependency that breaks if the plugin is distributed externally.

### Q: What if a utility needs to change?

**A:** Update the utility and let marketplace plugins adopt the changes when convenient. Don't force updates. Utilities should be backwards compatible when possible.

### Q: Can I add dependencies (npm packages, external tools)?

**A:** No. Utilities must work with standard bash and common Unix tools (jq, awk, sed). No external dependencies.

### Q: How do I propose a new utility?

**A:** Open an issue showing:
1. The problem it solves
2. How many plugins would benefit
3. Implementation proposal
4. Examples from existing plugins

---

**Related Documents:**
- [Plugin Philosophy](../docs/PLUGIN-PHILOSOPHY.md)
- [Knowledge Structure Standard](../docs/KNOWLEDGE-STRUCTURE.md)
- [Plugin Template](../plugin-template/)

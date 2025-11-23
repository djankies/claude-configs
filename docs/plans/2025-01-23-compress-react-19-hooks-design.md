# Compress React 19 Hook Output

**Date:** 2025-01-23
**Status:** Approved
**Goal:** Reduce hook output from ~150 lines (3 messages) to ~20 lines (1 message)

## Problem

Current system outputs 3 separate PostToolUse messages with 90% redundancy:
- 16 patterns detected by multiple hooks (duplicate violations)
- Verbose explanations (~50 lines per hook)
- Skills recommended multiple times across hooks

## Solution: Merge Hooks

Consolidate 3 PostToolUse hooks into single `validate-react-19.sh`.

**Architecture:**
```
1. Strip comments
2. Pattern matching (bash/grep) - deprecated APIs
3. ESLint validation (call validate-hooks-rules.js) - Rules of Hooks
4. Contextual checks (bash/grep) - best practices
5. Aggregate violations, deduplicate skills, format output
```

**Output format:**
```
React 19 (N issues)

❌ CRITICAL (N):
  • violation 1
  • violation 2

⚠️  Issues (N):
  • issue 1
  • issue 2

💡 Skills: skill1, skill2, skill3
```

**Format rules:**
- Single line per violation (no explanations)
- Skills deduplicated, comma-separated
- Total count in header
- Sort by severity (CRITICAL → warnings)

## Changes

**File structure:**
```
react-19/scripts/
├── validate-react-19.sh          (NEW - unified hook, ~400 lines)
├── validate-hooks-rules.js       (unchanged)
├── validate-react-patterns.sh    (DELETE)
├── validate-compliance.sh        (DELETE)
└── validate-hooks-rules.sh       (DELETE)
```

**hooks.json:**
```json
{
  "hooks": [
    {
      "name": "React 19 Validation",
      "event": "PostToolUse",
      "script": "./scripts/validate-react-19.sh",
      "matchers": [{"tool": "Write|Edit", "tool_input.file_path": "\\.(jsx?|tsx?)$"}]
    }
  ]
}
```

3 PostToolUse hooks → 1 PostToolUse hook

**Pattern consolidation:**
- Take all patterns from validate-react-patterns.sh
- Take all patterns from validate-compliance.sh
- Remove 16 duplicates
- Result: ~50 unique patterns

**ESLint integration:**
- Call validate-hooks-rules.js from unified script
- Parse output, merge into violations arrays
- Preserve all Rules of Hooks detection

## Implementation

```bash
#!/usr/bin/env bash

init_hook "react-19" "PostToolUse"
FILE_PATH=$(get_input_field "tool_input.file_path")
CODE_CONTENT=$(strip_comments "$FILE_PATH")

CRITICAL_VIOLATIONS=()
WARNINGS=()
RECOMMENDED_SKILLS=()

# Pattern detection (~50 checks)
if grep -qE '\bforwardRef\s*[<(]'; then
  CRITICAL_VIOLATIONS+=("forwardRef is deprecated - use ref as prop")
  RECOMMENDED_SKILLS+=("migrating-from-forwardref")
fi

# ESLint validation
ESLINT_OUTPUT=$(node validate-hooks-rules.js "$FILE_PATH" 2>&1)
[[ $? -ne 0 ]] && parse_eslint_output "$ESLINT_OUTPUT"

# Format & deduplicate
UNIQUE_SKILLS=($(printf '%s\n' "${RECOMMENDED_SKILLS[@]}" | sort -u))
format_compressed_message
posttooluse_respond "" "" "$MESSAGE"
```

## Migration

1. Create validate-react-19.sh (consolidate patterns)
2. Test with sample violations (verify detection, no duplicates)
3. Update hooks.json (remove 3 hooks, add 1)
4. Delete old scripts (keep validate-hooks-rules.js)
5. Verify end-to-end (Write operation, compressed message)

## Impact

**Before:**
- 3 messages × ~50 lines = 150 lines
- Duplicate violations (16 patterns × 2)
- Skills repeated across messages

**After:**
- 1 message × ~20 lines = 20 lines
- Each violation once
- Each skill once

**90% reduction in output length**

**Preserved:**
- All 100+ pattern detections
- ESLint integration (Rules of Hooks/deps)
- Skill recommendations (deduplicated)
- Severity classification

**Removed:**
- Duplicate checks
- Verbose explanations (skills provide fix guidance)
- "HOW TO FIX" sections
- "REQUIRED ACTIONS" checklists

# Knowledge Structure Standard

**Purpose:** Every plugin has comprehensive docs that skills reference instead of duplicating.

## Structure

```tree
plugin-name/
├── knowledge/
│   └── {plugin-name}-comprehensive.md  # Required: single source of truth
└── skills/
    └── {skill-name}/
        ├── SKILL.md
        └── references/                 # Optional: skill-specific examples only
            └── advanced-examples.md
```

## Rules

### Required: Comprehensive Knowledge Document

**File:** `/knowledge/{plugin-name}-comprehensive.md`

**Must contain:**
- Version, release date, system requirements
- Installation/upgrade instructions
- API reference with examples
- Breaking changes and migration guide
- Common gotchas and anti-patterns

**Purpose:** Single source of truth. Update once, all skills benefit.

### Optional: Skill-Specific References

**Directory:** `/skills/{skill-name}/references/`

**When to create:**
- Skill needs extensive examples beyond SKILL.md
- Complex patterns requiring deep-dive explanation

**When NOT to create:**
- Info belongs in comprehensive doc
- Multiple skills would use it (put in comprehensive doc)
- Trivial content (< 100 lines)

## Referencing in Skills

Skills reference knowledge using relative paths:

```markdown
See [Breaking Changes](../../knowledge/react-19-comprehensive.md#breaking-changes)

For advanced examples, see [Advanced Patterns](./references/advanced-patterns.md)
```

## Examples

### Current State (All Compliant)

```
typescript/knowledge/typescript-5.9-comprehensive.md    (37K)
nextjs-16/knowledge/nextjs-16-comprehensive.md          (37K)
react-19/knowledge/react-19-comprehensive.md            (49K)
zod-4/knowledge/zod-4-comprehensive.md                  (28K)
```

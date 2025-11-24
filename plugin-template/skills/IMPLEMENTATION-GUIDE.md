# Skill Implementation Guide

This guide provides comprehensive instructions for implementing skills in Claude Code plugins.

## Frontmatter Configuration

See @docs/claude-code/skills.md for complete frontmatter field reference.

**Key points for implementation:**

- **name**: Use gerund form (verb + -ing) for action-focused skills
- **description**: Include specific trigger words ("Does X. Use when Y.")
- **allowed-tools**: Restrict tool access for security/focus
- **version**: Optional tracking for troubleshooting
- **model**: Optional override (haiku/sonnet/opus)

## Description Writing

Your description determines when Claude activates this skill. Write it carefully.

**Good Descriptions** (specific triggers):

```yaml
description: "Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDFs or forms."

description: "Systematically debug bugs through root cause investigation, pattern analysis, hypothesis testing. Use when encountering bugs, test failures, unexpected behavior or when users mention bugs, errors, or unexpected behavior."

description: "Create generative art using p5.js with seeded randomness, flow fields, particle systems. Use when creating algorithmic art or computational visualizations."
```

**Bad Descriptions** (too vague):

```yaml
description: "Helps with documents"
description: "General purpose utility"
description: "Provides assistance"
```

**Key Rule:** Include specific triggers to enable proper discovery among 100+ potential skills.

## Progressive Disclosure System

See @docs/claude-code/skills.md for complete progressive disclosure documentation.

**Implementation pattern:**

- Keep SKILL.md under 500 lines (overview + workflow)
- Use `references/` directory for detailed examples
- Claude loads references only when needed
- Pattern: SKILL.md is table of contents, references/ are details

## File Organization Patterns

**Keep References One Level Deep:**

```
skill-name/
├── SKILL.md                 (core instructions)
├── references/              (loaded on-demand)
│   ├── api-reference.md
│   ├── examples.md
│   └── advanced.md
├── scripts/                 (executable automation)
│   ├── validate.py
│   └── process.sh
└── assets/                  (templates/binaries)
    ├── template.html
    └── config.json
```

**Important:** Keep references one level deep from SKILL.md to ensure Claude reads complete files.

## Skill Templates

Choose the template that best matches your skill's workflow pattern:

### Available Templates

**Location:** `plugin-template/skills/`

1. **search-analyze-report-template/**

   - **Use when:** Skill searches codebase, analyzes findings, generates reports
   - **Pattern:** Search → Analyze → Report
   - **Examples:** Code quality analysis, security audits, pattern detection
   - **Key features:** Structured search phases, categorized findings, actionable recommendations
   - **Reference example:** Security vulnerability analysis with remediation steps

2. **plan-validate-execute-template/**

   - **Use when:** Skill plans work, validates plan, executes with verification
   - **Pattern:** Plan → Validate → Execute → Verify
   - **Examples:** Refactoring, migrations, deployments
   - **Key features:** Approval gates, validation scripts, rollback procedures
   - **Reference example:** Database schema migration with transformation validation

3. **conditional-domain-specific-template/**

   - **Use when:** Skill behavior varies by domain/technology/context
   - **Pattern:** Detect context → Load domain rules → Apply domain-specific logic
   - **Examples:** Multi-framework support, cross-platform tools, polyglot operations
   - **Key features:** Decision trees, progressive disclosure by domain, domain-specific references
   - **Reference example:** Financial data analysis with QoQ calculations and forecasts

4. **template-based-generation-template/**

   - **Use when:** Skill generates structured content from templates
   - **Pattern:** Gather requirements → Select template → Fill template → Validate output
   - **Examples:** Boilerplate generation, documentation creation, config file generation
   - **Key features:** Template selection logic, placeholder filling, output validation
   - **Reference example:** Production configuration file generation with security best practices

5. **reference-educational-template/**
   - **Use when:** Skill teaches concepts, patterns, or best practices
   - **Pattern:** Explain concept → Show examples → Demonstrate patterns → Highlight pitfalls
   - **Examples:** Language features, design patterns, anti-patterns, best practices
   - **Key features:** Educational content, comparison examples, common mistakes
   - **Reference example:** TypeScript type guards with type predicates and narrowing

### Choosing a Template

**Decision process:**

1. **Does your skill teach concepts or best practices?** → Use reference-educational-template
2. **Does your skill search and analyze code?** → Use search-analyze-report-template
3. **Does your skill need approval gates or validation steps?** → Use plan-validate-execute-template
4. **Does your skill behave differently by domain/technology?** → Use conditional-domain-specific-template
5. **Does your skill generate structured output from templates?** → Use template-based-generation-template
6. **None of the above?** → Start with reference-educational-template and adapt

**Each template includes:**

- Complete SKILL.md structure with XML sections
- Frontmatter configuration examples
- Workflow patterns specific to that template type
- One reference example demonstrating the complete pattern
- Guidance on progressive disclosure

**All reference examples follow best practices:**

- Gerund form names (e.g., `analyzing-security-issues`, `migrating-database-schema`)
- Clear descriptions with "Does X. Use when Y" format
- Specified `allowed-tools` for focused operations
- No `version` field (optional, can be added if needed)

**To use a template:**

1. Copy the entire template directory
2. Review the template and examplesand understand the pattern
3. Rename to your skill name (kebab-case)
4. Update frontmatter (name, description, allowed-tools)
5. Fill in the SKILL.md file with your own content
6. Remove or replace the example reference file with your own

**Each template includes one reference example:**

- `search-analyze-report-template/` → `references/example-security-analysis.md`
- `plan-validate-execute-template/` → `references/example-database-migration.md`
- `template-based-generation-template/` → `references/example-config-file.md`
- `reference-educational-template/` → `references/example-using-type-guards.md`
- `conditional-domain-specific-template/` → `references/example-finance-analysis.md`

These examples demonstrate the complete pattern in action with real-world scenarios.

## Best Practices

**Conciseness**:

- Only include information Claude doesn't already possess
- Assume Claude has baseline knowledge
- Challenge each piece of content's token cost
- Remove redundant explanations

**Appropriate Freedom Levels**:

- **High freedom**: Flexible tasks (provide general guidance)
- **Medium freedom**: Patterns with variations (provide examples and principles)
- **Low freedom**: Error-prone operations (provide step-by-step instructions)

**Single Responsibility**:

- One skill = one capability
- Avoid combining unrelated functionalities
- Skills can work together automatically
- Create separate skills for different workflows

**Progressive Disclosure Usage**:

See the templates for complete examples of progressive disclosure patterns:

- `conditional-domain-specific-template/` - Domain-specific reference loading
- `search-analyze-report-template/` - Analysis pattern references
- `plan-validate-execute-template/` - Validation script references

Only the relevant reference file gets loaded when needed.

## Skill Checklist

Before finalizing your skill, verify:

### Discovery

- [ ] Description includes specific trigger keywords
- [ ] Description explains both WHAT and WHEN
- [ ] Name uses gerund form (verb + -ing) for actions
- [ ] Name is descriptive and specific (not vague)

### Structure

- [ ] SKILL.md is under 500 lines
- [ ] References are one level deep
- [ ] Progressive disclosure is implemented
- [ ] Supporting files are organized appropriately

### Content

- [ ] Workflows have clear sequential steps
- [ ] Conditional branches are explicit
- [ ] Examples show input/output patterns
- [ ] Scripts handle deterministic logic
- [ ] Validation steps are mandatory and specific

### Quality

- [ ] Only includes information Claude needs (not baseline knowledge)
- [ ] Freedom level matches task complexity
- [ ] Single, focused responsibility
- [ ] No duplication with other skills
- [ ] Constraints specify both DO and DON'T

### Testing

- [ ] Tested with real use cases (not just synthetic)
- [ ] Tested across multiple models (Haiku, Sonnet, Opus)
- [ ] Iteratively refined based on actual usage
- [ ] Scripts have proper error handling

## Anti-Patterns to Avoid

**Vague Description:**

- Problem: Generic descriptions like "Helps with documents" don't trigger skill discovery
- Solution: Include specific trigger words and use cases (see templates for examples)

**Context Overload:**

- Problem: Including 500+ lines of detailed content in SKILL.md
- Solution: Use progressive disclosure with references/ directory (see all templates)

**Deeply Nested References:**

- Problem: Multi-level reference chains (SKILL.md → level1.md → level2.md)
- Solution: Keep references one level deep from SKILL.md (see template structures)

**Too Much Freedom:**

- Problem: Vague instructions like "Handle this however you think is best"
- Solution: Provide structured workflows with clear steps (see plan-validate-execute-template)

**Wrong Template Choice:**

- Problem: Using search-analyze-report-template for generation tasks
- Solution: Match template to workflow pattern (see "Choosing a Template" above)

For correct patterns, examine the template that matches your use case.

## Validation Scripts

When skills include validation scripts, see `plan-validate-execute-template/` for complete examples.

**Script Invocation Pattern:**

```bash
{scriptType} {baseDir}/scripts/{scriptName} {arguments}
```

**Output Handling:**

- Scripts return structured data (JSON preferred)
- Claude reads output and takes action
- Iterate until validation passes

**Benefits:**

- Deterministic logic handled by scripts
- Only script output consumes context tokens
- Reliable, repeatable validation

**Template reference:** See `plan-validate-execute-template/SKILL.md` for detailed script integration patterns.

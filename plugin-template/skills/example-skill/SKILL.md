---
name: example-skill
description: Brief description of what this skill does and when Claude should use it (max 1024 chars)
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite, WebFetch, WebSearch, NotebookEdit, AskUserQuestion
version: 1.0.0
---

# Skill Template for Effective Skills

This template demonstrates best practices for creating powerful, maintainable skills using progressive disclosure.

---

## Template Instructions

### 1. Frontmatter Configuration

The YAML frontmatter above controls skill behavior:

**Required Fields:**

- **name**: Skill identifier in kebab-case (lowercase, hyphens only)

  - Max 64 characters
  - Use gerund form for actions: `processing-pdfs`, `generating-reports`
  - Avoid vague names: `helper`, `utils`, `toolkit`
  - Avoid reserved words: `anthropic`, `claude`

- **description**: What this skill does AND when Claude should use it
  - Max 1024 characters
  - Written in third person
  - Must include specific trigger words for discovery
  - Critical for Claude's decision-making about when to invoke
  - No XML tags allowed

**Optional Fields:**

- **allowed-tools**: Comma-separated list of permitted tools

  - Restricts tool access for security and focus
  - Examples: `"Read, Write"`, `"Bash, Read, Grep"`
  - Can restrict bash patterns: `"Bash(git add:*), Bash(git status:*)"`

- **version**: Semantic version tracking (e.g., "1.0.0")

  - Helps with troubleshooting and rollbacks
  - Primarily for documentation

- **model**: Optional model override for complex reasoning
  - `haiku` for fast/cheap iteration
  - `sonnet` for balanced reasoning
  - `opus` for complex decisions

### 2. Description Writing

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

### 3. Progressive Disclosure System

Skills use a three-tier context management system:

**Level 1 - Metadata (~100 tokens)**:

- Name and description load at startup
- Always present for skill discovery
- No context cost

**Level 2 - Full SKILL.md (<5,000 tokens)**:

- Loaded when Claude determines skill matches task
- Keep under 500 lines
- Serves as table of contents with references

**Level 3+ - Linked Resources (on-demand)**:

- Additional files referenced in SKILL.md
- Only loaded when specifically needed
- Enables unbounded skill complexity

**Pattern:** SKILL.md is the overview; references are the details.

### 4. File Organization Patterns

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

### 5. Content Patterns

**Workflows** - Sequential steps with checklists:

```markdown
## Workflow

1. Scan codebase for pattern

   - Use Grep with appropriate regex
   - Filter results by file type

2. Analyze each occurrence

   - Read surrounding context
   - Identify issue severity

3. Generate report
   - Group by severity
   - Provide remediation steps
```

**Conditional Workflows** - Decision points with clear branching:

```markdown
## Decision Flow

If request includes authentication:

1. Check for existing auth implementation
2. If found: enhance existing
3. If not found: implement new auth system

If request includes database operations:

1. Determine database type
2. Load database-specific reference (see references/[db-type].md)
3. Follow database-specific patterns
```

**Examples** - Input/output pairs showing desired behavior:

```markdown
## Examples

### Example 1: Simple Query

**Input**: "Find all TODO comments"
**Output**:
Found 15 TODO comments:

- src/main.py:45 - TODO: Add error handling
- src/utils.py:12 - TODO: Optimize performance
```

**Script Usage** - Executable automation:

````markdown
## Validation Process

Run validator script:

```bash
python {baseDir}/scripts/validate_form.py {extracted_data_json}
```
````

Output format:

```json
{
  "valid": false,
  "errors": [{ "field": "email", "error": "Invalid format" }]
}
```

Iterate until valid: true

````

### 6. Best Practices

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

```markdown
For detailed analysis methods by domain:
- Finance data: See `references/finance.md`
- Sales data: See `references/sales.md`
- Product data: See `references/product.md`
````

Only the relevant reference file gets loaded when needed.

---

## Skill Template

Replace the sections below with your actual skill:

---

<role>
This skill teaches Claude how to [specific capability] following [methodology/framework/pattern].
</role>

<when-to-activate>
This skill activates when:

- User mentions [trigger keyword 1], [trigger keyword 2], or [trigger keyword 3]
- Working with [file types or contexts]
- Request involves [specific task patterns]
  </when-to-activate>

<overview>
Brief overview of what this skill provides and why it's valuable.

Key capabilities:

1. [Primary capability]
2. [Secondary capability]
3. [Tertiary capability]
   </overview>

<workflow>
## Standard Workflow

**Phase 1: [Discovery/Analysis]**

1. [Specific step with clear action]
2. [Analyze/Gather/Identify specific information]
3. [Classify or prioritize based on criteria]

**Phase 2: [Implementation/Processing]**

1. [Create plan or strategy]
2. [Execute specific actions]
3. [Use appropriate tools]

**Phase 3: [Validation/Reporting]**

1. [Run validation or checks]
2. [Verify success criteria]
3. [Provide structured output]
   </workflow>

<conditional-workflows>
## Decision Points

**If [condition A]:**

1. [Action sequence for condition A]
2. See `references/[topic-a].md` for detailed guidance

**If [condition B]:**

1. [Action sequence for condition B]
2. See `references/[topic-b].md` for detailed guidance

**If [condition C]:**

1. [Action sequence for condition C]
   </conditional-workflows>

<progressive-disclosure>
## Reference Files

For detailed information on specific topics:

- **[Topic A]**: See `references/topic-a.md`
- **[Topic B]**: See `references/topic-b.md`
- **[Topic C]**: See `references/topic-c.md`

Load references only when needed for the specific task at hand.
</progressive-disclosure>

<script-automation>
## Automation Scripts

**Validation Script:**

```bash
python {baseDir}/scripts/validate.py [arguments]
```

**Processing Script:**

```bash
bash {baseDir}/scripts/process.sh [arguments]
```

Scripts handle deterministic logic efficiently. Only script output consumes context tokens.
</script-automation>

<examples>
## Examples

### Example 1: [Common Use Case]

**Input**: "[User request]"

**Steps:**

1. [What Claude does first]
2. [What Claude does next]
3. [Final action]

**Output**: [What user receives]

### Example 2: [Complex Use Case]

**Input**: "[User request]"

**Workflow:**

- [Phase 1 actions]
- [Phase 2 actions with reference to external file]
- [Phase 3 validation and output]

**Output**: [Detailed structured result]
</examples>

<output-format>
## Output Format

Provide results in this structure:

**For [output type A]:**

```
[Exact format specification]
```

**For [output type B]:**

```
[Flexible guidance while maintaining clarity]
```

</output-format>

<constraints>
## Constraints and Guidelines

**MUST:**

- [Critical requirement 1]
- [Critical requirement 2]
- [Critical requirement 3]

**SHOULD:**

- [Best practice 1]
- [Best practice 2]

**NEVER:**

- [Anti-pattern 1]
- [Anti-pattern 2]
  </constraints>

<validation>
## Validation

After completing work:

1. **[Validation type 1]:**

   - Run: `[validation command]`
   - Expected: [success criteria]
   - If fails: [specific remediation]

2. **[Validation type 2]:**
   - Check: [what to verify]
   - Iterate until: [completion condition]
     </validation>

---

## Skill Pattern Examples

### Pattern 1: Search-Analyze-Report

For codebase analysis skills:

```markdown
## Workflow

1. **Search Phase**

   - Use Grep to find patterns across codebase
   - Filter by file type and context

2. **Analysis Phase**

   - Read relevant files identified
   - Analyze patterns and issues
   - Identify severity and priority

3. **Report Phase**
   - Generate structured report
   - Provide specific remediation steps
```

### Pattern 2: Plan-Validate-Execute

For complex operations requiring validation:

```markdown
## Workflow

1. **Planning**

   - Generate plan as structured JSON
   - Write plan to temporary file

2. **Validation**

   - Run validation script: `python {baseDir}/scripts/validate_plan.py plan.json`
   - Review validation output

3. **Execution**
   - If validation passes: execute plan
   - If validation fails: revise plan based on errors
   - Repeat until validation passes
```

### Pattern 3: Conditional Domain-Specific Processing

For skills handling multiple domains:

```markdown
## Workflow

1. **Domain Detection**

   - Identify data domain from context
   - Determine appropriate processing method

2. **Domain-Specific Processing**

   - For finance data: Read `references/finance.md`
   - For sales data: Read `references/sales.md`
   - For product data: Read `references/product.md`

3. **Apply Domain Patterns**
   - Follow domain-specific guidelines
   - Use domain-specific validation
```

### Pattern 4: Template-Based Generation

For skills that generate structured output:

```markdown
## Workflow

1. **Template Selection**

   - Load appropriate template from `assets/templates/`
   - Identify placeholders

2. **Content Generation**

   - Generate content for each placeholder
   - Follow template structure

3. **Output**
   - Fill template with generated content
   - Validate against requirements
   - Write to appropriate location
```

---

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

---

## Anti-Patterns to Avoid

**Vague Description:**

```yaml
description: 'Helps with documents'
```

Use specific triggers:

```yaml
description: 'Extract text from PDFs, fill forms, merge documents. Use when working with PDF files or forms.'
```

**Context Overload:**

```markdown
[500 lines of detailed content in SKILL.md]
```

Use progressive disclosure:

```markdown
For detailed API patterns, see references/api-patterns.md
```

**Deeply Nested References:**

```
SKILL.md → level1.md → level2.md → level3.md
```

Keep one level deep:

```
SKILL.md → topic-a.md
SKILL.md → topic-b.md
```

**Too Much Freedom:**

```markdown
Handle this however you think is best
```

Provide appropriate guidance:

```markdown
1. First check [specific condition]
2. Then apply [specific pattern]
3. Validate using [specific method]
```

---

**Remember:** The best skill is concise, focused, and uses progressive disclosure effectively. Start with the overview in SKILL.md, reference details in external files, and let Claude load only what's needed for the specific task.

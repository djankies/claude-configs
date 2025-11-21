# Claude Code Skills Research

## Overview

- **Version**: Latest (as of November 2025)
- **Purpose in Project**: Creating and using custom skills in Claude Code to enhance AI-assisted development workflows
- **Official Documentation**:
  - https://code.claude.com/docs/en/skills
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
  - https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- **Last Updated**: 2025-11-19

## Core Concepts

### What Are Agent Skills?

Agent Skills are modular packages that extend Claude's capabilities through organized folders containing instructions, scripts, and resources. Unlike slash commands that users explicitly trigger, skills are **model-invoked**—Claude autonomously decides when to activate them based on context and the skill's description field.

A skill consists of:

- A required `SKILL.md` file with YAML frontmatter and markdown instructions
- Optional supporting files (scripts, templates, reference documentation)
- Resources organized alongside the main skill file

### Key Characteristics

**Automatic Invocation**: Skills activate automatically when their description matches the task context. Claude uses the description field to decide which skills are relevant without user intervention.

**Progressive Disclosure**: Skills implement a three-tier context management system that loads information only as needed, enabling effectively unbounded skill complexity without overwhelming the context window.

**Model-Agnostic**: Skills work across Haiku, Sonnet, and Opus models, though effectiveness depends on the underlying model's capabilities.

### Skills vs Other Claude Code Features

**Skills vs Slash Commands**: Slash commands are user-invoked (explicit trigger), while skills are model-invoked (automatic activation). Use slash commands for user-controlled workflows and skills for automatic capability enhancement.

**Skills vs MCP Servers**: MCP connects Claude to data; Skills teach Claude what to do with that data. Use both together: MCP for connectivity, Skills for procedural knowledge.

**Skills vs Prompts**: Skills provide reusable, versioned, shareable capabilities with progressive disclosure, while prompts are one-time instructions that consume full context immediately.

## Installation

### Directory Locations

Skills exist in three scopes:

**Personal Skills** (User-level):

```bash
~/.claude/skills/skill-name/
```

Available across all projects for the current user.

**Project Skills** (Team-shared):

```bash
.claude/skills/skill-name/
```

Committed to version control and shared with team members.

**Plugin Skills**:
Bundled with installed plugins from marketplaces.

### Creating a Skill Directory

```bash
mkdir -p ~/.claude/skills/my-skill-name
cd ~/.claude/skills/my-skill-name
touch SKILL.md
```

### Installing from Plugin Marketplaces

```bash
/plugin marketplace add anthropics/skills
/plugin install example-skills@anthropic-agent-skills
```

### Installing Individual Skills

Many community repositories provide installation via npm:

```bash
npx claude-code-templates@latest --skill pdf-processing-pro
```

## Configuration

### SKILL.md Structure

Every skill requires a `SKILL.md` file with YAML frontmatter and markdown content:

```yaml
---
name: skill-name
description: Brief description of what this skill does and when to use it
allowed-tools: "Bash, Read, Write"
version: 1.0.0
---

# Skill Instructions

Detailed instructions Claude follows when this skill is active.

## Examples
- Example usage patterns
- Input/output demonstrations

## Guidelines
- Step-by-step procedures
- Conditional workflows
```

### Required Frontmatter Fields

**name** (required):

- Uses lowercase letters, numbers, and hyphens only
- Maximum 64 characters
- Must match directory name
- Avoid vague names like "helper" or "utils"
- Avoid reserved words containing "anthropic" or "claude"
- Use gerund form (verb + -ing) for action-oriented skills

**description** (required):

- Maximum 1024 characters
- Should describe both what the skill does AND when Claude should use it
- Written in third person
- Must be specific with usage triggers to enable proper discovery
- Critical for Claude's decision-making about when to invoke the skill
- No XML tags allowed

Example descriptions:

```yaml
description: "Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDFs or forms."

description: "Create generative art using p5.js with seeded randomness, flow fields, and particle systems. Use when creating algorithmic art or computational visualizations."
```

### Optional Frontmatter Fields

**allowed-tools**:

- Comma-separated list of tools Claude can use when skill is active
- Only supported in Claude Code (not claude.ai or API)
- Restricts tool access for security and focus

Examples:

```yaml
allowed-tools: "Bash, Read"
allowed-tools: "Read, Grep, Glob"
allowed-tools: "Bash(git add:*), Bash(git status:*), Bash(git commit:*)"
```

**version**:

- Tracks skill iterations using semantic versioning
- Format: "major.minor.patch" (e.g., "1.0.0")
- Primarily used for documentation and skill management
- Helps with troubleshooting and rollbacks

**model** (advanced):

- Optional model override for complex reasoning tasks
- Specifies which Claude model to use when skill is active

### File Organization Patterns

```
skill-name/
├── SKILL.md                 (core instructions + frontmatter)
├── scripts/                 (executable Python/Bash automation)
│   ├── validate.py
│   └── process.sh
├── references/              (documentation loaded into context)
│   ├── api-reference.md
│   └── examples.md
└── assets/                  (templates/binaries referenced by path)
    ├── template.html
    └── config.json
```

**Important**: Keep references one level deep from SKILL.md to ensure Claude reads complete files rather than partial previews.

## Usage Patterns

### Basic Usage

Skills activate automatically based on description matching. Users simply work naturally, and Claude loads relevant skills when needed.

**Checking Available Skills**:

```
Ask Claude: "What Skills are available?"
```

**Viewing Skill Status**:
Claude shows skill activation via XML tags in responses:

```xml
<command-message>The "skill-name" skill is loading</command-message>
```

### Progressive Disclosure Implementation

The three-tier context management system:

**Level 1 - Metadata (~100 tokens)**:

- Skill name and description load into system prompt at startup
- Enables skill discovery without consuming context
- Always present for all available skills

**Level 2 - Full SKILL.md Content (<5,000 tokens)**:

- Loaded when Claude determines skill matches current task
- Contains detailed instructions and guidance
- Keep under 500 lines

**Level 3+ - Linked Resources (on-demand)**:

- Additional files referenced in SKILL.md
- Claude discovers dynamically as needed
- Only loaded when specifically required

Example progressive disclosure pattern:

```markdown
---
name: data-analysis
description: Analyze datasets with domain-specific methods for finance, sales, and product data
---

# Data Analysis Skill

## Overview

This skill provides specialized analysis methods for different data domains.

## Domain-Specific Analysis

For detailed analysis methods by domain:

- Finance data: See `references/finance.md`
- Sales data: See `references/sales.md`
- Product data: See `references/product.md`

## Workflow

1. Identify data domain
2. Read relevant reference file
3. Apply domain-specific analysis
4. Generate structured output
```

When analyzing revenue data, Claude reads SKILL.md, sees the reference to `finance.md`, and invokes bash to read just that file. The `sales.md` and `product.md` files remain on the filesystem, consuming zero context tokens until needed.

### Advanced Patterns

**Search-Analyze-Report**:

```markdown
1. Use Grep to find patterns across codebase
2. Read relevant files identified
3. Analyze patterns and issues
4. Generate structured report
```

**Script Automation**:

```markdown
1. Execute deterministic logic in Python/Bash
2. Process script output
3. Apply results to task
```

**Template-Based Generation**:

```markdown
1. Load template from `assets/template.html`
2. Fill placeholders with generated content
3. Write output to appropriate location
```

**Iterative Refinement**:

```markdown
1. Broad scan using Grep/Glob
2. Deep analysis of identified files
3. Generate recommendations
4. Validate with scripts
5. Iterate based on feedback
```

**Plan-Validate-Execute**:

```markdown
1. Generate plan as structured JSON
2. Validate plan with validation script
3. Review validation output
4. Execute plan if valid, otherwise revise
```

### Integration Examples

**Using {baseDir} for Portable Paths**:

```markdown
Execute the initialization script:
Read({baseDir}/scripts/init.py)
```

**Referencing MCP Tools**:
Use fully qualified names to avoid "tool not found" errors:

```markdown
Use the Slack MCP server to send notifications:
SlackServer:send_message
```

**Conditional Workflows**:

```markdown
## Workflow Decision Points

If user request includes PDF files:

1. Read `references/pdf-processing.md`
2. Execute PDF extraction workflow

If user request includes data analysis:

1. Read `references/data-analysis.md`
2. Determine data domain
3. Load domain-specific reference
```

## Best Practices

### Design Principles

**Conciseness**:
"The context window is a public good. Your Skill shares the context window with everything else Claude needs to know."

- Only include information Claude doesn't already possess
- Assume Claude has baseline knowledge
- Challenge each piece of content's token cost
- Remove redundant explanations

**Appropriate Freedom Levels**:
Match specificity to task fragility:

- **High freedom**: Flexible tasks requiring adaptation (provide general guidance)
- **Medium freedom**: Patterns exist with variations (provide examples and principles)
- **Low freedom**: Error-prone operations requiring exact sequences (provide step-by-step instructions)

**Single Responsibility**:
"Create separate Skills for different workflows. Multiple focused Skills compose better than one large Skill."

- One skill = one capability
- Avoid combining unrelated functionalities
- Skills can work together automatically

### Naming Conventions

**Skill Names**:

- Use gerund form (verb + -ing): `processing-invoices`, `generating-reports`
- Lowercase letters, numbers, and hyphens only
- Maximum 64 characters
- Avoid vague names like `helper`, `utils`, `toolkit`
- Avoid reserved words containing `anthropic` or `claude`

**File Names**:

- Use lowercase with hyphens
- Be descriptive and specific
- Match content purpose

### Description Writing

Write descriptions in third person describing both functionality and when to use the skill.

**Good Descriptions** (specific triggers):

```yaml
description: "Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDFs or forms."

description: "Systematically debug bugs through root cause investigation, pattern analysis, hypothesis testing, and implementation. Use when encountering any bug, test failure, or unexpected behavior before proposing fixes."

description: "Create animated GIFs optimized for Slack's size constraints using PIL primitives. Use when creating Slack emoji GIFs or message GIFs."
```

**Bad Descriptions** (too vague):

```yaml
description: "Helps with documents"

description: "General purpose utility"

description: "Provides assistance"
```

Include specific triggers to enable proper discovery among 100+ potential skills.

### File Organization

**Keep SKILL.md Under 500 Lines**:
Structure skills like a table of contents—SKILL.md serves as the overview with references to detailed files loaded only when needed.

**Reference Structure Patterns**:

Pattern 1 - High-level guide with external references:

```
skill-name/
├── SKILL.md
├── FORMS.md
├── REFERENCE.md
└── EXAMPLES.md
```

Pattern 2 - Domain-specific organization:

```
skill-name/
├── SKILL.md
└── references/
    ├── finance.md
    ├── sales.md
    └── product.md
```

Pattern 3 - Conditional details:

```
skill-name/
├── SKILL.md              (basic content inline)
└── references/
    └── advanced.md       (advanced features linked)
```

**Critical Rule**: Keep references one level deep from SKILL.md.

### Content Patterns

**Templates**:

- Provide exact format templates for strict requirements
- Provide flexible guidance for adaptable tasks
- Match strictness to necessity

Example:

````markdown
## Output Format

For API responses, use this exact structure:

```json
{
  "status": "success|error",
  "data": {},
  "message": ""
}
```
````

For documentation, adapt to context while maintaining clarity.

````

**Examples**:
Include input/output pairs showing desired style and detail level. Examples are more effective than descriptions alone.

```markdown
## Examples

### Example 1: Simple Query
**Input**: "Find all TODO comments"
**Output**:
````

Found 15 TODO comments:

- src/main.py:45 - TODO: Add error handling
- src/utils.py:12 - TODO: Optimize performance
  ...

```

### Example 2: Complex Analysis
**Input**: "Analyze security vulnerabilities"
**Output**: [Detailed structured report]
```

**Workflows**:
Break complex operations into sequential steps with checklists:

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

4. Validate findings
   - Run validation script
   - Fix any errors
   - Repeat validation until clean
```

**Conditional Workflows**:
Guide Claude through decision points with clear branching paths:

```markdown
## Decision Flow

If request includes authentication:

1. Check for existing auth implementation
2. If found: enhance existing
3. If not found: implement new auth system

If request includes database operations:

1. Determine database type
2. Load database-specific reference
3. Follow database-specific patterns
```

### Testing and Iteration

**Evaluation-First Development**:

1. Create test cases before extensive documentation
2. Build three scenarios testing identified gaps
3. Establish baseline performance without the skill
4. Write minimal instructions
5. Iterate based on real performance

**Iterative Development with Claude**:

1. Work with one Claude instance for skill refinement
2. Test with another Claude instance for real tasks
3. Observe behavior patterns
4. Refine based on actual usage rather than assumptions

**Observation Focus**:
Watch for:

- Unexpected exploration paths
- Missed connections between concepts
- Overreliance on certain sections
- Ignored content that should be relevant

**Multi-Model Testing**:
Verify skills work across Haiku, Sonnet, and Opus, as effectiveness depends on the underlying model's capabilities.

### Code-Based Skills

**Error Handling**:
Solve problems in scripts rather than deferring to Claude. Handle errors explicitly with helpful messages instead of failing ungracefully.

```python
try:
    result = process_data(input_file)
except FileNotFoundError:
    print(f"Error: Input file '{input_file}' not found")
    sys.exit(1)
except InvalidDataError as e:
    print(f"Error: Invalid data format - {e}")
    sys.exit(1)
```

**Utility Scripts**:
Prefer pre-made scripts over generated code for:

- Reliability: Scripts are tested and validated
- Token savings: Only output consumes context, not code
- Consistency: Same script produces same results

Clearly distinguish between scripts to execute versus scripts to read as reference.

**Script Execution Efficiency**:
When Claude runs a script like `validate_form.py`, the script's code never loads into the context window. Only the script's output (like "Validation passed" or specific error messages) consumes tokens.

**Dependencies**:
List required packages and verify availability in the code execution environment.

```python
import sys
try:
    import pandas as pd
    import numpy as np
except ImportError as e:
    print(f"Error: Required package not installed - {e}")
    print("Install with: pip install pandas numpy")
    sys.exit(1)
```

Note: claude.ai supports package installation while the Anthropic API does not.

**Intermediate Validation**:
For complex operations, implement plan-validate-execute patterns using structured intermediate files that scripts can verify before applying changes.

```markdown
## Workflow

1. Generate refactoring plan as JSON
2. Write plan to `plan.json`
3. Run `scripts/validate_plan.py plan.json`
4. If validation passes: execute plan
5. If validation fails: revise plan based on error messages
6. Repeat until validation passes
```

## Common Gotchas

### Description-Related Issues

**Issue**: Claude doesn't use skill
**Solutions**:

- Check description specificity—vague descriptions prevent discovery
- Verify YAML syntax is valid
- Confirm file path is correct
- Ensure description includes "when to use" information

**Issue**: Wrong skill activates
**Solutions**:

- Use distinct trigger terms in each description
- Be more specific about context and requirements
- Avoid overlapping trigger words

### Context Management Issues

**Issue**: Skill activates but performs poorly
**Solutions**:

- Keep SKILL.md under 500 lines
- Move detailed content to reference files
- Use progressive disclosure properly
- Remove redundant information

**Issue**: Claude ignores linked references
**Solutions**:

- Keep references one level deep from SKILL.md
- Explicitly mention when to read references
- Use clear file references

### Execution Issues

**Issue**: Skill fails silently
**Solutions**:

- Check dependencies are installed
- Verify script permissions
- Use `claude --debug` for detailed logs
- Add error handling to scripts

**Issue**: Scripts don't execute
**Solutions**:

- Use Unix-style paths (`/`) not Windows-style (`\`)
- Verify {baseDir} variable usage
- Check file permissions
- Test scripts independently

### Permission Issues

**Issue**: Permission denied errors
**Solutions**:

- Configure allowed-tools appropriately
- Add necessary tools to allow list
- Check file access permissions
- Review permission denylists

## Anti-Patterns to Avoid

### Structural Anti-Patterns

**Windows-Style Paths**:

```yaml
Read({baseDir}\scripts\init.py)
```

Use Unix-style:

```yaml
Read({baseDir}/scripts/init.py)
```

**Deeply Nested References**:

```
SKILL.md → level1.md → level2.md → level3.md
```

Keep references one level deep:

```
SKILL.md → finance.md
SKILL.md → sales.md
```

**Vague Descriptions**:

```yaml
description: 'Helps with documents'
```

Be specific:

```yaml
description: 'Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDFs or forms.'
```

### Content Anti-Patterns

**Excessive Options**:
Instead of presenting 10 options, provide a sensible default with escape hatches:

```markdown
Use standard REST API pattern. For GraphQL, see references/graphql.md.
```

**Time-Sensitive Information**:
Avoid:

```markdown
As of October 2025, the API version is v2.
```

Use:

```markdown
Check API version in package.json or documentation.
```

**Inconsistent Terminology**:
Pick one term and use it consistently throughout the skill.

**Magic Numbers Without Justification**:
Bad:

```python
threshold = 0.73
```

Good:

```python
threshold = 0.73
```

### Workflow Anti-Patterns

**Skipping Planning**:
Don't jump straight to implementation for complex tasks. Use planning steps:

```markdown
1. Analyze requirements
2. Design approach
3. Implement solution
4. Validate results
```

**Context Overload**:
Don't dump large reference files into SKILL.md. Use progressive disclosure.

**Assuming Skills Auto-Compose**:
While skills can work together, don't assume Claude will always select the right combination. Be explicit when multiple skills should work together.

### Security Anti-Patterns

**Hardcoded Credentials**:
Never include API keys, passwords, or tokens in skills:

```python
api_key = "sk-..."
```

Use environment variables or MCP connections:

```python
api_key = os.environ.get("API_KEY")
if not api_key:
    print("Error: API_KEY environment variable not set")
    sys.exit(1)
```

**Accessing Sensitive Files**:
Don't include sensitive files in allowed-tools:

```yaml
allowed-tools: 'Read(.env)'
```

**Executing Dangerous Commands**:
Avoid allowing risky bash commands:

```yaml
allowed-tools: 'Bash(rm *), Bash(sudo *)'
```

### Testing Anti-Patterns

**No Real-World Testing**:
Don't rely only on synthetic examples. Test with actual use cases.

**Single-Model Testing**:
Always test across Haiku, Sonnet, and Opus models.

**No Iteration**:
Skills require refinement based on actual usage patterns.

## Error Handling

### Skill Loading Errors

**YAML Syntax Errors**:

```
Error: Invalid YAML frontmatter in SKILL.md
```

Solution: Validate YAML syntax, ensure proper formatting, check for special characters.

**Missing Required Fields**:

```
Error: Missing required field 'description' in SKILL.md
```

Solution: Ensure name and description fields are present.

**Invalid Tool References**:

```
Error: Tool 'InvalidTool' not found
```

Solution: Use valid tool names (Bash, Read, Write, Edit, Grep, Glob, WebFetch, etc.).

### Script Execution Errors

**Dependency Missing**:

```python
try:
    import required_package
except ImportError:
    print("Error: required_package not installed")
    print("Install with: pip install required_package")
    sys.exit(1)
```

**File Not Found**:

```python
if not os.path.exists(input_file):
    print(f"Error: File '{input_file}' not found")
    sys.exit(1)
```

**Permission Denied**:

```python
try:
    with open(file_path, 'r') as f:
        content = f.read()
except PermissionError:
    print(f"Error: Permission denied accessing '{file_path}'")
    sys.exit(1)
```

### Runtime Errors

**Context Window Exhaustion**:
If skill + context exceeds limits, reduce SKILL.md size or split into multiple focused skills.

**Tool Permission Denied**:
Configure allowed-tools or adjust permission settings.

**MCP Server Connection Failed**:
Verify MCP server is running and properly configured.

## Security Considerations

### Permission System

Claude Code uses strict read-only permissions by default. When additional actions are needed (editing files, running tests, executing commands), Claude Code requests explicit permission.

**Three-Tier Permission Strategy**:

1. **Allowlists**: 100% harmless commands (always permitted)
2. **Asklists**: Useful but risky commands requiring approval
3. **Denylists**: Blocking dangerous operations

### File Access Controls

**Write Operation Boundaries**:
Claude Code can only write to the folder where it was started and its subfolders—it cannot modify files in parent directories without explicit permission.

**Read Operation Scope**:
Reading extends beyond the project scope to access system libraries and dependencies, but write operations remain confined.

### Security Best Practices

**Protect Sensitive Files**:
Configure permission denylists to prevent access to sensitive files:

```json
{
  "permissions": {
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(secrets/**)",
      "Read(.aws/**)",
      "Read(.ssh/**)",
      "Read(*.pem)",
      "Read(*.key)"
    ]
  }
}
```

**Use Environment Variables**:
Store secrets in environment variables, not in code:

```python
import os
api_key = os.environ.get("API_KEY")
if not api_key:
    raise ValueError("API_KEY environment variable not set")
```

**Avoid Hardcoded Credentials**:
Never include API keys, passwords, or tokens in skills or scripts.

**Command Blocklisting**:
Default blocklist includes risky tools like `curl` and `wget`. Maintain this for security.

**Review Downloaded Skills**:
Carefully review skills from unknown sources before installation. Check for:

- Suspicious bash commands
- Network requests to unknown URLs
- File operations outside project scope
- Hardcoded credentials

**Use MCP Connections**:
For external service access, use MCP connections instead of embedding credentials in scripts.

**Sandboxed Bash Execution**:
Claude Code provides sandboxed bash execution with filesystem and network isolation.

**Encrypted Credential Storage**:
API keys and tokens are encrypted for secure credential storage.

**Trust Verification**:
New codebases and MCP servers require trust verification before access.

### Security Audit Checklist

Before deploying a skill:

- [ ] No hardcoded credentials in any file
- [ ] No access to .env or secrets files
- [ ] Scripts use environment variables for sensitive data
- [ ] Bash commands are restricted appropriately
- [ ] External network requests are documented
- [ ] File operations are scoped to project directory
- [ ] Dependencies are from trusted sources
- [ ] Error messages don't expose sensitive information

## Performance Tips

### Context Window Optimization

**Progressive Disclosure**:
Use the three-tier system effectively:

- Level 1: Keep descriptions concise (<1024 chars)
- Level 2: Keep SKILL.md under 500 lines
- Level 3: Split extensive content into reference files

**Token Efficiency**:

- Remove redundant explanations
- Assume Claude has baseline knowledge
- Use scripts for deterministic operations
- Only load references when needed

### Script Performance

**Pre-computation**:
When possible, pre-compute values in scripts rather than having Claude calculate them:

```python
statistics = {
    "mean": np.mean(data),
    "median": np.median(data),
    "std": np.std(data)
}
print(json.dumps(statistics))
```

**Caching**:
Implement caching for expensive operations:

```python
@lru_cache(maxsize=128)
def expensive_computation(input_data):
    return result
```

**Batch Processing**:
Process items in batches rather than one-by-one:

```python
def process_batch(items):
    return [process_item(item) for item in items]
```

### Skill Organization

**Focused Skills**:
Multiple small, focused skills perform better than one large skill:

- Faster loading
- Better discovery
- Clearer responsibilities
- Easier maintenance

**Smart References**:
Only reference files that are actually needed:

```markdown
For PDF processing: See references/pdf.md
For Excel processing: See references/excel.md
```

Don't load all references upfront.

## Version-Specific Notes

### Current Capabilities (November 2025)

**Supported Environments**:

- Claude Code CLI
- claude.ai (paid plans: Pro, Max, Team, Enterprise)
- Claude API (with Agent Skills support)

**Model Availability**:

- Claude Sonnet 4.5 (model ID: claude-sonnet-4-5-20250929)
- Claude Opus
- Claude Haiku

**Package Installation**:

- claude.ai: Automatic package installation supported
- Claude API: Package installation NOT supported
- Claude Code: Automatic package installation with permission

### Breaking Changes & Deprecations

**URL Redirects**:
Documentation URLs have changed:

- Old: `https://docs.claude.com/en/docs/claude-code/skills`
- New: `https://code.claude.com/docs/en/skills`

**Version Tracking**:

- API uses Unix epoch timestamps for version identifiers
- User-facing version field uses semantic versioning
- No automated semantic version enforcement as of November 2025

### Feature Announcements

**Skills Release Date**: November 14, 2025

**Progressive Disclosure**: Core architectural principle enabling unbounded skill complexity

**Plugin Marketplaces**: Support for distributing skills via GitHub, GitLab, local paths, and remote URLs

## Code Examples

### Example 1: Simple Template Skill

```markdown
---
name: code-reviewer
description: Review code for bugs, security issues, and best practices. Use when reviewing pull requests or code changes.
allowed-tools: 'Read, Grep, Glob'
version: 1.0.0
---

# Code Review Skill

## Workflow

1. Scan changed files using Grep or Glob
2. Read each file completely
3. Analyze for:
   - Security vulnerabilities
   - Performance issues
   - Code quality problems
   - Best practice violations

## Output Format

Provide structured feedback:

### Security Issues

- [File:Line] Description and remediation

### Performance Issues

- [File:Line] Description and optimization suggestion

### Code Quality

- [File:Line] Description and improvement

## Guidelines

- Focus on substantive issues, not style preferences
- Provide specific remediation steps
- Reference best practices with explanations
- Prioritize security and correctness over optimization
```

### Example 2: Skill with Scripts

````markdown
---
name: api-validator
description: Validate API endpoint implementations against OpenAPI specifications. Use when reviewing API changes or implementing new endpoints.
allowed-tools: 'Bash, Read, Write'
version: 1.0.0
---

# API Validator Skill

## Overview

Validates API implementations against OpenAPI/Swagger specifications.

## Workflow

1. Read OpenAPI specification file
2. Identify API endpoints to validate
3. Run validation script
4. Review validation results
5. Generate compliance report

## Validation Process

Execute validation:

```bash
python {baseDir}/scripts/validate_api.py --spec openapi.yaml --implementation src/api/
```
````

## Error Categories

The validator checks:

- Request/response schema compliance
- Required field presence
- Type correctness
- Endpoint path matching
- HTTP method accuracy

## Output

Validation results include:

- Compliance score
- List of violations with file locations
- Suggested fixes
- Documentation references

````

scripts/validate_api.py:
```python
#!/usr/bin/env python3
import sys
import json
import yaml
from pathlib import Path

def validate_api(spec_path, implementation_path):
    try:
        with open(spec_path) as f:
            spec = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: Specification file '{spec_path}' not found")
        sys.exit(1)

    violations = []

    impl_files = list(Path(implementation_path).rglob("*.py"))
    for impl_file in impl_files:
        file_violations = check_implementation(impl_file, spec)
        violations.extend(file_violations)

    report = {
        "total_violations": len(violations),
        "compliance_score": calculate_compliance(violations, spec),
        "violations": violations
    }

    print(json.dumps(report, indent=2))
    return len(violations) == 0

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    parser.add_argument("--implementation", required=True)
    args = parser.parse_args()

    success = validate_api(args.spec, args.implementation)
    sys.exit(0 if success else 1)
````

### Example 3: Skill with Progressive Disclosure

````markdown
---
name: database-migration
description: Create and validate database migrations with support for PostgreSQL, MySQL, and SQLite. Use when creating database schema changes or migrations.
allowed-tools: 'Bash, Read, Write'
version: 1.0.0
---

# Database Migration Skill

## Overview

Creates type-safe database migrations with validation and rollback support.

## Workflow

1. Identify database type from project configuration
2. Load database-specific reference
3. Generate migration files
4. Validate migration syntax
5. Test migration (up and down)

## Database Type Detection

Check these files to determine database:

- `package.json` for dependencies
- `requirements.txt` for Python packages
- `.env` for database connection strings

## Database-Specific References

For detailed migration patterns:

- PostgreSQL: See `references/postgresql.md`
- MySQL: See `references/mysql.md`
- SQLite: See `references/sqlite.md`

## Migration Template

Create migrations using this structure:

```sql
-- Migration: {migration_name}
-- Created: {timestamp}
-- Database: {database_type}

-- UP
{up_sql}

-- DOWN
{down_sql}
```
````

## Validation

Run validation script before applying:

```bash
python {baseDir}/scripts/validate_migration.py {migration_file}
```

## Safety Checks

Before applying migration:

1. Verify syntax with validation script
2. Check for destructive operations
3. Confirm backup exists
4. Test rollback capability

````

references/postgresql.md:
```markdown
# PostgreSQL Migration Patterns

## Table Creation

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
````

## Adding Columns

```sql
ALTER TABLE users
ADD COLUMN last_login TIMESTAMP;
```

## Indexes

```sql
CREATE INDEX idx_users_email ON users(email);
```

## Foreign Keys

```sql
ALTER TABLE posts
ADD CONSTRAINT fk_user_id
FOREIGN KEY (user_id)
REFERENCES users(id)
ON DELETE CASCADE;
```

## Rollback Patterns

For table creation:

```sql
DROP TABLE IF EXISTS users;
```

For column addition:

```sql
ALTER TABLE users DROP COLUMN last_login;
```

For index creation:

```sql
DROP INDEX IF EXISTS idx_users_email;
```

````

### Example 4: Algorithmic Art Skill (Real-World)

```markdown
---
name: algorithmic-art
description: Create generative art using p5.js with seeded randomness, flow fields, and particle systems. Use when creating algorithmic art, computational visualizations, or generative aesthetics.
allowed-tools: "Read, Write"
version: 1.0.0
---

# Algorithmic Art Skill

## Overview

Creates computational generative art using p5.js with seeded randomness and interactive parameter exploration.

## Process

1. Develop algorithmic philosophy (computational aesthetic manifesto)
2. Implement philosophy through p5.js code
3. Create interactive viewer with parameter controls

## Algorithmic Philosophy

The philosophy should be 4-6 substantive paragraphs addressing:
- Mathematical and procedural beauty
- Emergent behavior from rules
- Seeded randomness enabling reproducibility
- Computational processes and mathematical relationships
- Particle behaviors and field dynamics

## Technical Requirements

### Fixed Components (Always Include)

- Layout: Header, sidebar, main canvas area
- Anthropic branding: Specific colors, fonts (Poppins/Lora)
- Seed navigation: Display, Previous/Next, Random, Jump-to-seed inputs
- Action buttons: Regenerate, Reset, Download PNG

### Seeded Randomness Pattern

```javascript
function setup() {
  randomSeed(seed);
  noiseSeed(seed);

}
````

Same seed must always produce identical output.

### Parameters Design

Parameters should define:

- Quantities (particle counts, iterations)
- Scales (dimensions, speeds)
- Probabilities (likelihood of behaviors)
- Ratios (proportional relationships)
- Angles and thresholds

## Template Foundation

STEP 0: Read `templates/viewer.html` first.

Keep unchanged:

- Layout structure and sidebar organization
- Anthropic UI colors and fonts
- Seed control implementation
- Action button structure

Replace only:

- p5.js algorithm code
- Parameter definitions
- Parameter control UI in sidebar

## Output Format

Deliver:

1. Algorithmic philosophy as markdown
2. Single self-contained HTML artifact

## Craftsmanship Standards

- Balance complexity without visual noise
- Thoughtful color harmony over random values
- Visual hierarchy and flow maintained
- Smooth, optimized execution
- Reproducibility across seeds

````

### Example 5: Skill with Validation Workflow

```markdown
---
name: form-processor
description: Extract, validate, and process form data from PDF and web forms. Use when working with forms, form validation, or form data extraction.
allowed-tools: "Bash, Read, Write"
version: 1.0.0
---

# Form Processor Skill

## Workflow

1. Identify form type (PDF or web)
2. Extract form fields
3. Validate extracted data
4. Generate validation report
5. Fix validation errors
6. Re-validate until clean

## Form Field Extraction

For PDF forms:
```bash
python {baseDir}/scripts/extract_pdf_fields.py {pdf_file}
````

For web forms:

```bash
python {baseDir}/scripts/extract_web_fields.py {html_file}
```

## Validation Process

After extraction, validate:

```bash
python {baseDir}/scripts/validate_form.py {extracted_data_json}
```

Output format:

```json
{
  "valid": false,
  "errors": [
    {
      "field": "email",
      "error": "Invalid email format",
      "value": "notanemail"
    }
  ]
}
```

## Iterative Validation

1. Run validator
2. If errors exist:
   - Review error messages
   - Fix data issues
   - Re-run validator
3. Repeat until `"valid": true`

## Error Categories

- **Format errors**: Field value doesn't match expected format
- **Required errors**: Required field is missing
- **Range errors**: Numeric value out of acceptable range
- **Constraint errors**: Value violates business rules

## Output Format

Generate processed form data:

```json
{
  "form_type": "contact_form",
  "fields": {
    "name": "John Doe",
    "email": "john@example.com",
    "message": "Hello world"
  },
  "validation_status": "passed",
  "timestamp": "2025-11-19T10:30:00Z"
}
```

```

## References

### Official Documentation
- Claude Code Skills Documentation: https://code.claude.com/docs/en/skills
- Agent Skills Best Practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Agent Skills Engineering Deep Dive: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- Skills Announcement: https://www.anthropic.com/news/skills
- Plugin Marketplaces: https://code.claude.com/docs/en/plugin-marketplaces
- Security Documentation: https://code.claude.com/docs/en/security

### Official Repositories
- Anthropic Skills Repository: https://github.com/anthropics/skills
- Skills Specification: https://github.com/anthropics/skills/blob/main/agent_skills_spec.md

### Community Resources
- Awesome Claude Skills: https://github.com/travisvn/awesome-claude-skills
- Claude Skills Collection: https://github.com/ComposioHQ/awesome-claude-skills
- Superpowers Skills Library: https://github.com/obra/superpowers

### Technical Articles
- Inside Claude Code Skills (Mikhail Shilkov): https://mikhail.io/2025/10/claude-code-skills/
- Claude Agent Skills Deep Dive: https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/
- Claude Skills Explained (Simon Willison): https://simonwillison.net/2025/Oct/16/claude-skills/

### Support Articles
- How to Create Custom Skills: https://support.claude.com/en/articles/12512198-how-to-create-custom-skills
- Using Skills in Claude: https://support.claude.com/en/articles/12512180-using-skills-in-claude
- What Are Skills: https://support.claude.com/en/articles/12512176-what-are-skills
- API Key Best Practices: https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure
```

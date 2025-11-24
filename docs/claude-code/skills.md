# Agent Skills

> Create, manage, and share Skills to extend Claude's capabilities in Claude Code.

## Prerequisites

- Claude Code version 1.0 or later
- Basic familiarity with [Claude Code](/en/quickstart)

## What are Agent Skills?

Agent Skills package expertise into discoverable capabilities. Each Skill consists of a `SKILL.md` file with instructions that Claude reads when relevant, plus optional supporting files (scripts, templates, etc.).

**Invocation**: Skills are **model-invoked**—Claude autonomously decides when to use them based on your request and description—unlike slash commands which are **user-invoked** (explicit `/command` trigger).

**Benefits**: Extend Claude's capabilities for specific workflows; share expertise across teams via git; reduce repetitive prompting; compose multiple Skills for complex tasks.

Learn more in the [Agent Skills overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) and [engineering blog](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills).

## Create a Skill

Skills are directories containing a `SKILL.md` file.

| Type         | Location                               | Scope             | Details                                                    |
| ------------ | -------------------------------------- | ----------------- | ---------------------------------------------------------- |
| **Personal** | `~/.claude/skills/`                    | All projects      | Individual workflows, experiments, personal tools          |
| **Project**  | `.claude/skills/`                      | Team              | Shared conventions, expertise, utilities; checked into git |
| **Plugin**   | Via [Claude Code plugins](/en/plugins) | Installed plugins | Bundled automatically when plugin is installed             |

Create directories:

```bash
# Personal
mkdir -p ~/.claude/skills/my-skill-name

# Project
mkdir -p .claude/skills/my-skill-name
```

## Write SKILL.md

Create a `SKILL.md` file with YAML frontmatter and Markdown content:

```yaml
---
name: your-skill-name
description: Brief description of what this Skill does and when to use it
---

# Your Skill Name

## Instructions
Provide clear, step-by-step guidance for Claude.

## Examples
Show concrete examples of using this Skill.
```

**Field requirements**:

**Required fields:**

- `name`: Skill identifier in kebab-case

  - Lowercase letters, numbers, hyphens only (max 64 characters)
  - Use gerund form (verb + -ing) for action-focused skills: `processing-pdfs`, `validating-forms`, `reviewing-code`
  - Avoid vague names: `helper`, `utils`, `toolkit`
  - Avoid reserved words: `anthropic`, `claude`

- `description`: What the Skill does AND when Claude should use it
  - Max 1024 characters
  - Written in third person
  - Must include specific trigger words for discovery
  - Critical for Claude's decision-making about when to invoke
  - No XML tags allowed
  - Format: "Does X. Use when Y." or "Does X when Y."

**Optional fields:**

- `allowed-tools`: Comma-separated list of permitted tools (e.g., `"Read, Write, Grep, Glob"`)

  - Restricts tool access during skill execution
  - Useful for read-only skills or security-sensitive operations
  - Can restrict bash patterns: `"Bash(git add:*), Bash(git status:*)"`

- `version`: Semantic version tracking (e.g., "1.0.0")

  - Helps with troubleshooting and rollbacks
  - Primarily for documentation purposes

- `model`: Optional model override for complex reasoning
  - `haiku` for fast/cheap iteration
  - `sonnet` for balanced reasoning (default)
  - `opus` for complex decisions

See the [best practices guide](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices) for complete authoring guidance.

## Add supporting files

```
my-skill/
├── SKILL.md (required)
├── reference.md (optional documentation)
├── examples.md (optional examples)
├── scripts/
│   └── helper.py (optional utility)
└── templates/
    └── template.txt (optional template)
```

Reference files from SKILL.md:

````markdown
For advanced usage, see [reference.md](reference.md).

Run the helper script:

```bash
python scripts/helper.py input.txt
```
````

````

Claude reads files only when needed via progressive disclosure.

## Progressive disclosure system

Skills use a three-tier context management system to minimize token usage while maximizing capability:

**Level 1 - Metadata (loaded at startup)**
- Name and description from frontmatter
- Always present for skill discovery
- Zero context cost during execution
- Enables Claude to find relevant skills

**Level 2 - SKILL.md (loaded when skill is activated)**
- Core instructions and workflows
- Keep under 500 lines for optimal context usage
- Serves as table of contents with references to detailed content
- Contains high-level guidance and workflow steps

**Level 3 - Referenced files (loaded on-demand)**
- Detailed examples in `references/` directory
- Comprehensive API documentation
- Advanced patterns and edge cases
- Loaded only when Claude specifically needs them
- Enables unbounded skill complexity without context bloat

**Pattern:** SKILL.md is the overview; `references/` are the details. Claude loads deeper levels only when the task requires them.

**Example structure:**
```
skill-name/
├── SKILL.md                    (Level 2: ~300 lines)
├── references/                 (Level 3: loaded on-demand)
│   ├── api-reference.md
│   ├── examples.md
│   └── advanced-patterns.md
└── scripts/
    └── helper.sh
```

## Restrict tool access with allowed-tools

Use the `allowed-tools` field to limit which tools Claude can use when a Skill is active:

```yaml
---
name: safe-file-reader
description: Read files without making changes. Use when you need read-only file access.
allowed-tools: Read, Grep, Glob
---

# Safe File Reader

This Skill provides read-only file access.

## Instructions
1. Use Read to view file contents
2. Use Grep to search within files
3. Use Glob to find files by pattern
````

Useful for read-only Skills, limited-scope operations (e.g., data analysis only), and security-sensitive workflows. If not specified, Claude asks for permission as normal.

<Note>
  `allowed-tools` is only supported for Skills in Claude Code.
</Note>

## View available Skills

Skills are auto-discovered from: Personal (`~/.claude/skills/`), Project (`.claude/skills/`), and Plugin Skills.

**Ask Claude directly**:

```
What Skills are available?
```

**Inspect via filesystem**:

```bash
# List personal Skills
ls ~/.claude/skills/

# List project Skills
ls .claude/skills/

# View a specific Skill
cat ~/.claude/skills/my-skill/SKILL.md
```

## Test a Skill

After creating a Skill, ask questions matching your description. If your description mentions "PDF files":

```
Can you help me extract text from this PDF?
```

Claude autonomously activates your Skill based on context; no explicit invocation needed.

## Debug a Skill

If Claude doesn't use your Skill, verify:

**Description too vague?**

- ✗ `description: Helps with documents`
- ✓ `description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDFs, forms, or document extraction.`

Include both what the Skill does and when to use it.

**File path correct?**

```bash
# Personal: ~/.claude/skills/skill-name/SKILL.md
# Project: .claude/skills/skill-name/SKILL.md
ls ~/.claude/skills/my-skill/SKILL.md
ls .claude/skills/my-skill/SKILL.md
```

**YAML syntax valid?** Verify frontmatter has opening/closing `---`, proper indentation, no tabs:

```bash
cat SKILL.md | head -n 10
```

**View errors**: Run with debug mode:

```bash
claude --debug
```

## Share Skills with your team

**Recommended approach**: Distribute via [plugins](/en/plugins).

1. Create a plugin with Skills in the `skills/` directory
2. Add the plugin to a marketplace
3. Team members install the plugin

See [Add Skills to your plugin](/en/plugins#add-skills-to-your-plugin) for complete instructions.

**Alternative (direct project sharing)**:

1. Create `.claude/skills/team-skill` in your project
2. Commit and push:

```bash
git add .claude/skills/
git commit -m "Add team Skill for PDF processing"
git push
```

3. Team members pull changes; Skills immediately available:

```bash
git pull
```

## Update a Skill

Edit SKILL.md directly:

```bash
# Personal Skill
code ~/.claude/skills/my-skill/SKILL.md

# Project Skill
code .claude/skills/my-skill/SKILL.md
```

Changes take effect on next Claude Code restart.

## Remove a Skill

```bash
# Personal
rm -rf ~/.claude/skills/my-skill

# Project
rm -rf .claude/skills/my-skill
git commit -m "Remove unused Skill"
```

## Best practices

**Keep Skills focused**: One Skill, one capability.

- ✓ **Focused**: "PDF form filling", "Excel data analysis", "Git commit messages"
- ✗ **Too broad**: "Document processing", "Data tools" (split into focused Skills)

**Write clear descriptions**: Include specific triggers and use cases.

- ✓ `description: Analyze Excel spreadsheets, create pivot tables, and generate charts. Use when working with Excel files, spreadsheets, or analyzing tabular data in .xlsx format.`
- ✗ `description: For files`

**Test with your team**: Verify Skills activate when expected, instructions are clear, edge cases covered.

**Document Skill versions**: Add version history to track changes:

```markdown
# My Skill

## Version History

- v2.0.0 (2025-10-01): Breaking changes to API
- v1.1.0 (2025-09-15): Added new features
- v1.0.0 (2025-09-01): Initial release
```

## Troubleshooting

**Claude doesn't use my Skill**

- Is the description specific enough? Vague descriptions impede discovery. Include both what the Skill does and when to use it with key terms users mention.

  - ✗ `description: Helps with data`
  - ✓ `description: Analyze Excel spreadsheets, generate pivot tables, create charts. Use when working with Excel files, spreadsheets, or .xlsx files.`

- Is the YAML valid? View frontmatter and check for: missing `---`, tabs instead of spaces, unquoted strings with special characters.

  ```bash
  cat .claude/skills/my-skill/SKILL.md | head -n 15
  ```

- Is the Skill in the correct location?
  ```bash
  ls ~/.claude/skills/*/SKILL.md  # Personal
  ls .claude/skills/*/SKILL.md    # Project
  ```

**Skill has errors**

- Are dependencies available? Claude auto-installs or requests permission.
- Do scripts have execute permissions?
  ```bash
  chmod +x .claude/skills/my-skill/scripts/*.py
  ```
- Are file paths correct? Use forward slashes (Unix style): `scripts/helper.py` not `scripts\helper.py`

**Multiple Skills conflict**

Use distinct trigger terms in descriptions instead of vague similarities:

- ✗ Skill 1: `description: For data analysis`; Skill 2: `description: For analyzing data`
- ✓ Skill 1: `description: Analyze sales data in Excel files and CRM exports. Use for sales reports, pipeline analysis, and revenue tracking.`; Skill 2: `description: Analyze log files and system metrics data. Use for performance monitoring, debugging, and system diagnostics.`

## Examples

**Simple Skill (single file)**:

```
commit-helper/
└── SKILL.md
```

```yaml
---
name: generating-commit-messages
description: Generates clear commit messages from git diffs. Use when writing commit messages or reviewing staged changes.
---

# Generating Commit Messages

## Instructions

1. Run `git diff --staged` to see changes
2. Suggest a commit message with:
   - Summary under 50 characters
   - Detailed description
   - Affected components

## Best practices

- Use present tense
- Explain what and why, not how
```

**Skill with tool permissions**:

```
code-reviewer/
└── SKILL.md
```

```yaml
---
name: code-reviewer
description: Review code for best practices and potential issues. Use when reviewing code, checking PRs, or analyzing code quality.
allowed-tools: Read, Grep, Glob
---

# Code Reviewer

## Review checklist

1. Code organization and structure
2. Error handling
3. Performance considerations
4. Security concerns
5. Test coverage

## Instructions

1. Read target files using Read tool
2. Search for patterns using Grep
3. Find related files using Glob
4. Provide detailed feedback on code quality
```

**Multi-file Skill**:

```
pdf-processing/
├── SKILL.md
├── FORMS.md
├── REFERENCE.md
└── scripts/
    ├── fill_form.py
    └── validate.py
```

**SKILL.md**:

````yaml
---
name: pdf-processing
description: Extract text, fill forms, merge PDFs. Use when working with PDF files, forms, or document extraction. Requires pypdf and pdfplumber packages.
---

# PDF Processing

## Quick start

Extract text:
```python
import pdfplumber
with pdfplumber.open("doc.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

For form filling, see [FORMS.md](FORMS.md).
For detailed API reference, see [REFERENCE.md](REFERENCE.md).

## Requirements

Packages must be installed in your environment:
```bash
pip install pypdf pdfplumber
```
````

<Note>
  List required packages in the description. Packages must be installed in your environment before Claude can use them.
</Note>

Claude loads additional files only when needed.

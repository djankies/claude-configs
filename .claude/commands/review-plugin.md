---
description: Comprehensive review, validation, and remediation of a Claude Code plugin
argument-hint: <plugin-name>
allowed-tools: Read, Glob, Bash, Task, Write, TodoWrite, Skill, AskUserQuestion
model: sonnet
---

# Review Plugin Command

<role>
You orchestrate plugin validation by coordinating review agents in parallel, synthesizing findings, and remediating issues.
</role>

<context>
Plugin: $ARGUMENTS
Location: @$ARGUMENTS/
Philosophy: @docs/PLUGIN-PHILOSOPHY.md
</context>

## Phase 1: Discovery

Enumerate components:

```bash
find $ARGUMENTS -type f \( -name "*.md" -o -name "*.json" -o -name "*.sh" \)
```

## Phase 2: Parallel Review

### Shared Context

```
Plugin: {name} @ {path}/
Components: {list with counts and paths}
Design: $ARGUMENTS/PLUGIN-DESIGN.md
Research: $ARGUMENTS/RESEARCH.md
Plugin Philosophy: docs/PLUGIN-PHILOSOPHY.md
Plugin Documentation: docs/claude-code/plugins.md
```

### Deploy All Review Agents (Single Message)

subagent_type: "general-purpose" for Tasks 1-8
subagent_type: "Explore" for Task 9 (integration opportunities)

```
Task 1: Review plugin metadata
- Run: node scripts/validate-plugin-manifest.js $ARGUMENTS/.claude-plugin/plugin.json
- Align with docs/claude-code/plugins.md
- Check: required fields, kebab-case name, component paths match structure, semver
- Return: {"review_type": "metadata", "issues": [{severity, file, line, description, recommendation}], "compliant": bool}

Task 2: Review plugin skills (skip dispatching an agent if no skills in design)
- Run: node scripts/validate-skill-frontmatter.js for each $ARGUMENTS/skills/*/SKILL.md
- REQUIRED: See docs/claude-code/skills.md for complete skill principles
- Check: frontmatter (name gerund, description specific, allowed-tools), <500 lines, focused scope, progressive disclosure, no duplication
- Cross-ref design: matches spec, justification preserved
- Gerund form: both skill folder name and metadata name contain a gerund (verb + -ing) (e.g., "reviewing-react-hooks")
- Ensure skills have relevant scripts to assist with validation of deterministic operations
- provides accurate knowledge that aligns with $ARGUMENTS/RESEARCH.md
- Plugin has at least one REVIEW skill
- Philosophy alignment: Each skill justified against cognitive load (discovery cost + usage cost < value provided)
- Progressive disclosure: Skills use references/ for detailed content and all examples, main SKILL.md under 500 lines, acts as a table of contents for the skill if multiple references are present
- Single responsibility: Each skill owns one concern, no overlap with other skills
- Composability: Skills reference other skills via "use skill-name to..." pattern, no duplication
- Return: {"review_type": "skills", "issues": [], "skills_reviewed": [{name, compliant, issues_count, philosophy_aligned: bool}], "compliant": bool}

Task 3: Review plugin commands (skip dispatching an agent if no commands in design)
- Run: node scripts/validate-command-frontmatter.js for each $ARGUMENTS/commands/*.md
- Check: frontmatter, orchestrates (doesn't duplicate), daily use justified, not replaceable by natural language
- Cross-ref design: matches spec, justification valid
- Philosophy alignment: Used multiple times per day, clearer than natural language, orchestrates existing capabilities
- Design hierarchy: Commands justified in design doc (not just defaulting to commands for convenience)
- Cognitive load: Discovery cost (remembering command exists) + usage cost (syntax) < value provided (time saved)
- Return: {"review_type": "commands", "issues": [], "commands_reviewed": [{name, compliant, daily_use_justified: bool, philosophy_aligned: bool}], "compliant": bool}

Task 4: Review plugin hooks
- Run: node scripts/validate-hooks.js $ARGUMENTS/hooks/hooks.json
- REQUIRED: See docs/claude-code/hooks.md for complete hook principles
- Check: valid schema, scripts exist/executable/<500ms, objective validation, rare false positives, clear errors, no overlap with built-ins
- Cross-ref design: matches spec, performance met
- Philosophy alignment: Event-driven (context is expensive), fast execution, objective validation, justified in design doc
- Cognitive load: Hooks run automatically (zero usage cost), prevent critical mistakes (high value)
- Design hierarchy: Hooks justified (can't be done with skills/parent Claude alone)
- MANDATORY INTEGRATION TESTING: Test ALL hook scripts against actual code violations
  1. Identify violation patterns from design doc (e.g., "83% any abuse", "Base64 passwords", "deprecated APIs")
  2. Extract real violation examples from $ARGUMENTS/stress-test/stress-test-report.md
  3. For each hook script, create JSON input with actual violation code and verify:
     - Hook DETECTS the violation (outputs warning/error)
     - Exit code matches severity (0=warning, 2=block for critical)
     - Output message is clear and actionable
     - No false positives on clean code
  4. Test edge cases: return statements, function bodies, different variable names, nested structures
  5. Document test results: {script_name: {violations_tested: N, detected: N, missed: N, false_positives: N}}
  6. CRITICAL: If hook misses documented violations from stress test → HIGH severity issue
- Return: {"review_type": "hooks", "issues": [], "hooks_reviewed": [{name, compliant, philosophy_aligned: bool, integration_tests: {violations_tested, detected, missed, false_positives}}], "compliant": bool}

Task 5: Review plugin agents (skip dispatching an agent if no agents in design)
- Run: node scripts/validate-agent-frontmatter.js for each $ARGUMENTS/agents/*.md
- Check: frontmatter, differentiation (permissions OR model OR context - at least one), justification (why not skill?), clear I/O boundary
- Cross-ref design: meets 3 criteria
- CRITICAL: If no differentiation → HIGH severity
- Philosophy alignment: Agent provides clear differentiation (different permissions/model/tools), not just domain knowledge
- Design hierarchy: Agent justified (skills can't solve this), has isolated execution need
- Cognitive load: Agent overhead (separate context, communication boundary) < value provided (isolation, different capabilities)
- Anti-pattern check: Not a "God Agent" with same capabilities as parent
- Return: {"review_type": "agents", "issues": [], "agents_reviewed": [{name, compliant, differentiation_criteria_met, philosophy_aligned: bool, issues_count}], "compliant": bool}

Task 6: Review MCP (skip dispatching an agent if no MCP in design)
- Run: node scripts/validate-mcp.js $ARGUMENTS/.mcp.json
- Check: valid JSON, server type required, paths use ${CLAUDE_PLUGIN_ROOT}, env vars documented, tools not in built-ins, justified
- Cross-ref design: justified, matches spec
- Philosophy alignment: MCP provides essential external tools not available in built-ins (Read, Write, Edit, Bash, Grep, Glob)
- Design hierarchy: MCP justified (built-in tools insufficient), provides external API access or specialized parsing
- Cognitive load: MCP startup cost + dependencies < value provided (essential capabilities)
- Anti-pattern check: Not a "Kitchen Sink MCP" with overlapping built-in functionality
- Return: {"review_type": "mcp", "issues": [], "mcp_servers_reviewed": [{name, compliant, philosophy_aligned: bool}], "compliant": bool}

Task 7: Review philosophy compliance
- REQUIRED: See docs/PLUGIN-PHILOSOPHY.md for complete principles
- Minimal Cognitive Load: every component justified (discovery + usage cost < value)
- Design Hierarchy: stopped at right level (skills → hooks → commands → MCP → agents)
- Progressive Disclosure: skills load when relevant (see @docs/claude-code/skills.md)
- Context Efficiency: no duplication, single source of truth
- Single Responsibility: focused domain
- Composability: extensible, referenceable, no tight coupling
- Cross-ref design: implementation matches philosophy
- Return: {"review_type": "philosophy", "principles": [{principle, compliant, issues: []}], "overall_compliant": bool}

Task 8: Explore integration opportunities (use Explore agent)
- Scan ALL other plugins in parent directory (../) for integration opportunities
- For each skill in target plugin:
  - Search other plugins for skills that could reference it
  - Check if related concepts in other plugins duplicate knowledge instead of referencing
  - Identify framework plugins that should reference target plugin's foundational skills
- For target plugin hooks:
  - Check if other plugins have overlapping validation (opportunity to consolidate or reference)
  - Identify gaps where target hooks could benefit other plugins
- For target plugin commands:
  - Check if other plugins have similar commands (opportunity for cross-cutting plugin)
  - Identify orchestration opportunities across plugins
- Integration patterns to check:
  - Other plugin's relevant skills referencing target plugin's skills (e.g., "if, [condition], use skill-name to...")
  - Target plugin's skills referencing other plugin's relevant skills (e.g., "if, [condition], use skill-name to...")
  - Review plugin referencing $ARGUMENTS plugins for specialized review capabilities (e.g., "if, [condition], use review-skill-name to...")
  - Validation hooks composing across plugins without duplication
- Return: {"review_type": "integration", "opportunities": [{other_plugin, opportunity_type, description, benefit, recommendation}], "missed_references": [{other_plugin_file, should_reference, target_skill, rationale}], "duplication_detected": [{other_plugin_file, duplicates_target_skill, recommendation}], "compliant": bool}
```

## Phase 3: Synthesis

Parse all agent JSON outputs.

Aggregate:

```text
total_issues = sum(all issues)
by_severity = {critical, high, medium, nitpick}
components_compliant = {metadata, skills, commands, hooks, agents, mcp, documentation, philosophy, integration}
philosophy_aligned = all component philosophy_aligned flags
integration_opportunities = count(missed_references + duplication_detected)
overall_compliant = all(components_compliant) AND philosophy_aligned
priority_1 = critical issues
priority_2 = high issues
priority_3 = medium issues + integration opportunities
priority_4 = nitpick issues
```

## Phase 4: Remediation

Ask user with AskUserQuestion tool:

```text
Question: "Found {total} issues ({critical} critical, {high} high, {medium} medium, {nitpick} nitpick) and {integration_opportunities} integration opportunities. Proceed?"
multi-select: true
Options:
  - Auto-fix medium/nitpick issues: {list of fixes to be applied}
  - Auto-fix critical/high issues: {list of fixes to be applied}
  - Auto-fix integration opportunities: {list of fixes to be applied}

```

**If auto-fix selected, deploy remediation agents (single message):**

subagent_type: "general-purpose"

```text
{for each issue in selected scope}
Task {n}: Fix {issue.description}
- Issue: {severity, file, line, description, recommendation}
- Fix per recommendation, preserve other content, maintain formatting
- Write corrected file to original location
{end}
```

Validate fixes:

- Files valid (JSON parseable, markdown well-formed)
- Issues resolved
- No new issues

## Constraints

**CRITICAL:**

- STOP if plugin not found
- Deploy ALL review agents in SINGLE message
- Deploy ALL remediation agents in SINGLE message
- Validate all outputs as valid JSON
- Never skip validation after remediation
- Never mark compliant with critical issues

**NEVER:**

- Deploy sequentially
- Skip philosophy check
- Auto-fix without confirmation

## Validation

**After review:** ✓ All JSON valid, all components reviewed, issues aggregated, philosophy checked
**After remediation:** ✓ Fixes applied, files valid, issues resolved, no new issues, `pnpm run validate` passes (no errors or warnings)
**Before completing:** ✓ Report generated, summary presented

## Error Recovery

**Plugin not found:** STOP → "Plugin not found"
**Agent fails:** Continue with others, note in report
**Remediation fails:** Mark unresolved in report
**All fail:** Generate diagnostic, suggest manual review
**Validation fails:** Document, suggest manual intervention

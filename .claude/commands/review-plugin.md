---
description: Plugin validation, review & remediation
argument-hint: <plugin-name>
allowed-tools: Read, Glob, Bash, Task, Write, TodoWrite, Skill, AskUserQuestion
model: sonnet
---

# Review Plugin Command

<role>
Orchestrate parallel plugin validation agents, synthesize findings, remediate issues.
</role>

<context>
Plugin: $ARGUMENTS
Location: @$ARGUMENTS/
Philosophy: @docs/PLUGIN-PHILOSOPHY.md
</context>

## Phase 1: Discovery & Structure Validation

!`find $ARGUMENTS -type f \( -name "*.md" -o -name "*.json" -o -name "*.sh" \)`

**Run deterministic structure check:**

!`node scripts/validate-plugin-structure.js $ARGUMENTS 2>&1`

Note any structure errors/warnings in the final report.

## Phase 2: Parallel Review

**Shared Context:** Plugin {name} @ {path}/, Components {list}, Design: $ARGUMENTS/PLUGIN-DESIGN.md, Research: $ARGUMENTS/RESEARCH.md, Philosophy: docs/PLUGIN-PHILOSOPHY.md, Docs: docs/claude-code/plugins.md, Hook Utils: marketplace-utils/

**Deploy All Review Agents (Single Message):**
subagent_type: "general-purpose" (Tasks 1-8), "Explore" (Task 9)

---

**Task 1: Metadata** | node scripts/validate-plugin-manifest.js $ARGUMENTS/.claude-plugin/plugin.json
Check: required fields, kebab-case name, component paths, semver | Cross-ref: docs/claude-code/plugins.md
Return: {"review_type": "metadata", "issues": [{severity, file, line, description, recommendation}], "compliant": bool}

---

**Task 2: Skills** (skip if no skills in design) | node scripts/validate-skill-frontmatter.js $ARGUMENTS/skills/\*/SKILL.md && node scripts/validate-skill-line-count.js $ARGUMENTS
REQUIRED: docs/claude-code/skills.md
Check: frontmatter (gerund name, specific description, allowed-tools), <500 lines (validate-skill-line-count.js), focused scope, progressive disclosure (references/ detailed content), no duplication, deterministic operations scripted, accurate knowledge aligned to $ARGUMENTS/RESEARCH.md
Verify: At least one REVIEW skill present
Cross-ref: design matches spec, gerund folders (verb + -ing), each owns single concern, references other skills via "use skill-name" pattern
Philosophy: Justified against cognitive load (discovery + usage cost < value), progressive disclosure, composability, single responsibility
Return: {"review_type": "skills", "issues": [], "skills_reviewed": [{name, compliant, issues_count, philosophy_aligned}], "compliant": bool}

---

**Task 3: Commands** (skip if no commands in design) | node scripts/validate-command-frontmatter.js $ARGUMENTS/commands/\*.md
Check: frontmatter, orchestrates existing (no duplication), daily-use justified, not replaceable by NLP
Cross-ref: design spec matches, justification valid
Philosophy: Multiple daily uses, clearer than NLP, orchestrates capabilities, justified (not convenience default), cognitive load justified
Return: {"review_type": "commands", "issues": [], "commands_reviewed": [{name, compliant, daily_use_justified, philosophy_aligned}], "compliant": bool}

---

**Task 4: Hooks** | node scripts/validate-hooks.js $ARGUMENTS/hooks/hooks.json
REQUIRED: docs/claude-code/hooks.md, marketplace-utils/docs/HOOK-DEVELOPMENT.md
Check: valid schema, scripts executable/<500ms, objective validation, rare false positives, clear errors, no built-in overlap
Cross-ref: design matches, performance met, uses marketplace-utils infrastructure
Philosophy: Event-driven (context expensive), fast, objective, zero usage cost (high value preventing mistakes), justifiable vs skills/parent

**DETERMINISTIC INFRASTRUCTURE CHECK:** (run for each hook script in $ARGUMENTS/hooks/)

```bash
./scripts/validate-hook-infrastructure.sh $ARGUMENTS/hooks/<script>.sh
```

Validates: sources hook-lifecycle.sh, calls init_hook(), uses response helpers, has logging

**DETERMINISTIC EXIT CODE TESTING:** (if test cases exist)

```bash
./scripts/validate-hook-exit-codes.sh $ARGUMENTS/hooks/<script>.sh $ARGUMENTS/hooks/test-cases/<script>-tests.json
```

**MANUAL INTEGRATION TESTING:**

1. Extract violation patterns from design doc & $ARGUMENTS/stress-test/stress-test-report.md
2. For each hook script, test JSON input with actual violations: detects violation (warning/error), exit code matches severity (0=warning, 2=block critical), output actionable, no false positives on clean code
3. Test edge cases: returns, function bodies, nested structures
4. CRITICAL: Hooks missing documented violations → HIGH severity
5. CRITICAL: Hooks not using marketplace-utils infrastructure (validate-hook-infrastructure.sh fails) → MEDIUM severity
   Return: {"review_type": "hooks", "issues": [], "hooks_reviewed": [{name, compliant, philosophy_aligned, infrastructure_check: {passed, failed, issues}, exit_code_tests: {passed, failed}, integration_tests: {violations_tested, detected, missed, false_positives}}], "compliant": bool}

---

**Task 5: Agents** (skip if no agents in design) | node scripts/validate-agent-frontmatter.js $ARGUMENTS/agents/\*.md
Check: frontmatter, differentiation (permissions OR model OR context), justification (why not skill?), clear I/O boundary
Cross-ref: design meets 3+ criteria
CRITICAL: No differentiation → HIGH severity
Philosophy: Clear differentiation, not "God Agent" duplicating parent, isolated execution need, overhead < value
Return: {"review_type": "agents", "issues": [], "agents_reviewed": [{name, compliant, differentiation_criteria_met, philosophy_aligned, issues_count}], "compliant": bool}

---

**Task 6: MCP** (skip if no MCP in design) | node scripts/validate-mcp.js $ARGUMENTS/.mcp.json
Check: valid JSON, server type required, paths use ${CLAUDE_PLUGIN_ROOT}, env vars documented, tools not in built-ins (Read, Write, Edit, Bash, Grep, Glob), justified
Cross-ref: design justified, matches spec
Philosophy: Essential external tools unavailable in built-ins, justified (built-in insufficient), provides API/specialized parsing, startup cost < value, not "Kitchen Sink MCP"
Return: {"review_type": "mcp", "issues": [], "mcp_servers_reviewed": [{name, compliant, philosophy_aligned}], "compliant": bool}

---

**Task 7: Philosophy Compliance**
REQUIRED: docs/PLUGIN-PHILOSOPHY.md
Verify: Minimal Cognitive Load (all justified), Design Hierarchy (skills→hooks→commands→MCP→agents), Progressive Disclosure, Context Efficiency (no duplication), Single Responsibility, Composability, implementation matches philosophy
Return: {"review_type": "philosophy", "principles": [{principle, compliant, issues}], "overall_compliant": bool}

---

**Task 8: Integration Opportunities** (Explore agent)
Scan ../ for opportunities:

- For each skill: search cross-plugin references, identify duplicated knowledge, framework plugins referencing foundational skills
- For hooks: overlapping validation consolidation gaps
- For commands: similar commands (cross-cutting plugin), orchestration opportunities
- Check patterns: skills referencing other plugins, Review plugin referencing $ARGUMENTS specialized review, validation hooks composing without duplication
  Return: {"review_type": "integration", "opportunities": [{other_plugin, opportunity_type, description, benefit}], "missed_references": [{file, should_reference, target_skill}], "duplication_detected": [{file, duplicates_target_skill}], "compliant": bool}

---

## Phase 3: Synthesis

Parse agent JSON outputs.

Aggregate: total_issues = sum(all), by_severity = {critical, high, medium, nitpick}, components_compliant = {metadata, skills, commands, hooks, agents, mcp, documentation, philosophy, integration}, philosophy_aligned = all flags, integration_opportunities = count(missed + duplicates), overall_compliant = all(components) AND philosophy_aligned

Prioritize: Priority 1 = critical, Priority 2 = high, Priority 3 = medium + integration, Priority 4 = nitpick

## Phase 4: Remediation

**AskUserQuestion:**
"Found {total} issues ({critical} critical, {high} high, {medium} medium, {nitpick} nitpick) and {integration_opportunities} integration opportunities. Proceed?"

Options:

- Auto-fix medium/nitpick: {list}
- Auto-fix critical/high: {list}
- Update other plugins to reference the new skills: {list}
- Add existing skills references to the new skills

**If selected, deploy remediation agents (Single Message):**
subagent_type: "general-purpose"

```text
{for each issue in scope}
Task {n}: Fix {issue.description}
- Issue: {severity, file, line, description, recommendation}
- Fix per recommendation, preserve other content, maintain formatting
- Write to original location
{end}
```

Validate: JSON parseable/markdown well-formed, issues resolved, no new issues, pnpm run validate passes

---

## Constraints

**CRITICAL:** STOP if plugin not found | Deploy ALL agents in SINGLE message | Validate outputs as valid JSON | Never skip validation post-remediation | Never mark compliant with critical issues

**NEVER:** Deploy sequentially | Skip philosophy check | Auto-fix without confirmation

---

## Validation

**After review:** ✓ JSON valid, all components reviewed, issues aggregated, philosophy checked
**After remediation:** ✓ Fixes applied, files valid, issues resolved, no new issues, pnpm run validate passes
**Before completing:** ✓ Report generated, summary presented

---

## Error Recovery

Plugin not found → STOP | Agent fails → Continue, note in report | Remediation fails → Mark unresolved | All fail → Generate diagnostic, suggest manual review | Validation fails → Document, suggest manual intervention

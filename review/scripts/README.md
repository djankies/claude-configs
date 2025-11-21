# Review Scripts

Framework-agnostic bash scripts for JavaScript/TypeScript code review automation. Each script has a single responsibility, handles errors gracefully, and limits output to avoid context pollution.

## Usage

All scripts are executable and can be run directly:

```bash
./review-diff.sh
./review-todos.sh
./review-lint.sh
```

## Git & Diff Scripts

### review-diff.sh

Shows recent changes with smart filtering.

```bash
./review-diff.sh [max_commits] [max_lines]
```

- Default: Last 5 commits, max 500 lines
- Excludes: lock files, minified files, build artifacts
- Truncates output if too large

### review-changed-files.sh

Lists changed files with addition/deletion stats.

```bash
./review-changed-files.sh [max_files]
```

- Default: Max 50 files
- Compares against origin/main (auto-detected)
- Shows file statistics

### review-commits.sh

Shows recent commits in current branch.

```bash
./review-commits.sh [max_commits]
```

- Default: Last 10 commits
- Format: hash author time message
- Compares against base branch

## Code Quality Scripts

### review-todos.sh

Finds TODO/FIXME/HACK/XXX/NOTE comments.

```bash
./review-todos.sh [max_per_type]
```

- Default: Max 20 per type
- Searches: .js, .ts, .jsx, .tsx files
- Excludes: node_modules, dist, build

### review-debug-statements.sh

Finds console.log, debugger, and similar statements.

```bash
./review-debug-statements.sh [max_results]
```

- Default: Max 50 results
- Detects: console.*, debugger
- Shows file:line with context

### review-large-files.sh

Finds files exceeding line count threshold.

```bash
./review-large-files.sh [min_lines] [max_results]
```

- Default: 500 lines, max 30 results
- Excludes: test files, build artifacts
- Sorted by size descending

## Tool-Based Scripts (Graceful Degradation)

### review-lint.sh

Runs ESLint with formatted output.

```bash
./review-lint.sh [max_errors]
```

- Default: Max 100 errors
- Requires: eslint (checks if installed)
- Truncates if output too large
- Suggests auto-fix command

**Install:** `npm install -D eslint`

### review-types.sh

Runs TypeScript type checking.

```bash
./review-types.sh [max_errors]
```

- Default: Max 100 errors
- Requires: typescript, tsconfig.json
- Shows only type errors
- Groups by file

**Install:** `npm install -D typescript`

### review-unused-deps.sh

Finds unused dependencies.

```bash
./review-unused-deps.sh
```

- Requires: depcheck (optional)
- Falls back to manual check if unavailable
- Shows unused deps and devDeps separately

**Install:** `npm install -g depcheck`

### review-tree.sh

Shows project structure.

```bash
./review-tree.sh [max_depth]
```

- Default: Depth 3
- Requires: tree (optional)
- Falls back to find-based tree
- Excludes: node_modules, build dirs

**Install:** `brew install tree` (macOS) or `apt install tree` (Linux)

### review-unused-code.sh

Finds unused code, exports, and dependencies.

```bash
./review-unused-code.sh [max_results]
```

- Default: Max 100 results
- Prefers: knip (comprehensive)
- Falls back to: ts-prune (exports only)
- Shows installation instructions if neither found

**Install:**
- `npm install -D knip` (recommended)
- `npm install -D ts-prune` (simpler alternative)

### review-complexity.sh

Analyzes cyclomatic complexity.

```bash
./review-complexity.sh [max_results] [complexity_threshold]
```

- Default: Max 30 results, threshold 15
- Requires: lizard
- Shows: NLOC, CCN, tokens, parameters
- Sorted by complexity

**Install:** `pip install lizard`

### review-security.sh

Runs security pattern scanning.

```bash
./review-security.sh [max_results]
```

- Default: Max 50 results
- Requires: semgrep
- Uses: auto config (community rules)
- Shows: ERROR and WARNING severity

**Install:** `pip install semgrep`

### review-duplicates.sh

Detects duplicate code blocks.

```bash
./review-duplicates.sh [max_results] [min_lines]
```

- Default: Max 30 results, min 5 lines
- Prefers: jsinspect (JS/TS specific)
- Falls back to: lizard (basic)
- Shows duplicate locations

**Install:**
- `npm install -g jsinspect` (recommended)
- `pip install lizard` (alternative)

## Design Principles

1. **Single Responsibility** - Each script does one thing well
2. **Graceful Degradation** - Checks for tool availability, doesn't fail if missing
3. **Filtered Output** - Limits results to avoid context pollution
4. **Robust Error Handling** - Handles edge cases (empty repos, long output, etc.)
5. **Framework Agnostic** - Works with any JS/TS project structure

## Common Options

Most scripts accept parameters to control output:

- `max_results` - Limit number of results shown
- `max_lines` - Limit line count in output
- `threshold` - Minimum value to report

Example:

```bash
./review-large-files.sh 300 20
```

## Exit Codes

- `0` - Success (no errors, or tool not found)
- `1` - Error (not in git repo, invalid parameters, etc.)

Scripts never fail due to missing optional tools. They show installation instructions instead.

## Integration

These scripts are designed for use by AI code review agents. They:

- Output clean, parseable text
- Limit context consumption
- Handle edge cases automatically
- Provide actionable information

Use them in review workflows, pre-commit hooks, or CI/CD pipelines.

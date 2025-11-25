# Review Workflow Reference

## Complete Review Process

### Step 1: Identify Config Files

Find all Vitest configuration files:

```bash
glob "vitest.config.{ts,js,mts,mjs}"
glob "vite.config.{ts,js,mts,mjs}"
```

Common locations:
- `vitest.config.ts`
- `vitest.config.js`
- `vite.config.ts` (with test configuration)

### Step 2: Check Pool Options

For each config file:

1. Search for deprecated pool options:
   ```bash
   grep -E "(maxThreads|maxForks|minThreads|minForks|singleThread|singleFork)" vitest.config.ts
   ```

2. Check if `maxWorkers` is used correctly

3. Verify single-threaded mode uses correct pattern:
   ```typescript
   maxWorkers: 1
   isolate: false
   ```

4. Check for nested `poolOptions`:
   ```bash
   grep -A 5 "poolOptions" vitest.config.ts
   ```

### Step 3: Check Coverage Config

1. Verify `coverage.include` is present if coverage enabled:
   ```bash
   grep -A 10 "coverage:" vitest.config.ts | grep "include:"
   ```

2. Check for removed coverage options:
   ```bash
   grep -E "(ignoreEmptyLines|coverage\.all|coverage\.extensions|experimentalAstAwareRemapping)" vitest.config.ts
   ```

3. Verify exclude patterns if needed:
   ```bash
   grep -A 15 "coverage:" vitest.config.ts | grep "exclude:"
   ```

### Step 4: Check Workspace Setup

1. Look for `defineWorkspace` usage:
   ```bash
   grep "defineWorkspace" vitest.config.ts
   ```

2. Check for deprecated match globs:
   ```bash
   grep -E "(poolMatchGlobs|environmentMatchGlobs)" vitest.config.ts
   ```

3. Verify migration to `projects` array:
   ```bash
   grep -A 10 "projects:" vitest.config.ts
   ```

### Step 5: Check Browser Mode

1. Verify provider package is imported:
   ```bash
   grep "from '@vitest/browser-" vitest.config.ts
   ```

2. Check `instances` array is used:
   ```bash
   grep -A 5 "browser:" vitest.config.ts | grep "instances:"
   ```

3. Check for deprecated browser options:
   ```bash
   grep -E "(browser\.name|testerScripts)" vitest.config.ts
   ```

4. Verify import paths in test files:
   ```bash
   grep -r "@vitest/browser/context" tests/
   ```

### Step 6: Check Dependencies

1. Verify `deps.*` moved to `server.deps.*`:
   ```bash
   grep -A 5 "deps:" vitest.config.ts
   grep -A 5 "server:" vitest.config.ts | grep -A 5 "deps:"
   ```

### Step 7: Check Test Files

Find all test files:

```bash
glob "**/*.{test,spec}.{ts,tsx,js,jsx}"
```

For each test file:

1. Check for `@vitest/browser/context` imports:
   ```bash
   grep "@vitest/browser/context" **/*.test.ts
   ```

2. Check for `vitest/execute` imports:
   ```bash
   grep "vitest/execute" **/*.test.ts
   ```

3. Verify correct import paths:
   ```bash
   grep "from 'vitest/browser'" **/*.test.ts
   ```

### Step 8: Generate Report

Compile findings into categories:

1. **Critical**: Config will fail at runtime
2. **Deprecated**: Will show warnings
3. **Best Practice**: Improvements recommended

## Review Report Template

```markdown
# Vitest Configuration Review

## Summary
- Config files reviewed: X
- Test files reviewed: Y
- Critical issues: Z
- Deprecated patterns: W
- Best practice suggestions: V

## Critical Issues

### 1. [File]: [Issue]
**Pattern:** [Code snippet]
**Problem:** [Description]
**Remediation:** [Fix]

## Deprecated Patterns

### 1. [File]: [Issue]
**Pattern:** [Code snippet]
**Problem:** [Description]
**Remediation:** [Fix]

## Best Practices

### 1. [File]: [Suggestion]
**Current:** [Code snippet]
**Suggestion:** [Improvement]
```

## Common Findings

### Finding: maxThreads Used

**Severity:** Critical

**Pattern:**
```typescript
export default defineConfig({
  test: {
    maxThreads: 4,
  },
});
```

**Remediation:**
```typescript
export default defineConfig({
  test: {
    maxWorkers: 4,
  },
});
```

### Finding: Missing coverage.include

**Severity:** Critical

**Pattern:**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
    },
  },
});
```

**Remediation:**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      include: ['src/**/*.{ts,tsx}'],
    },
  },
});
```

### Finding: defineWorkspace Used

**Severity:** Critical

**Pattern:**
```typescript
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([...]);
```

**Remediation:**
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [...],
  },
});
```

### Finding: Wrong Browser Import

**Severity:** Critical

**Pattern:**
```typescript
import { page } from '@vitest/browser/context';
```

**Remediation:**
```typescript
import { page } from 'vitest/browser';
```

### Finding: Browser Provider Not Function

**Severity:** Critical

**Pattern:**
```typescript
export default defineConfig({
  test: {
    browser: {
      provider: 'playwright',
    },
  },
});
```

**Remediation:**
```typescript
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    browser: {
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
    },
  },
});
```

### Finding: deps Not Under server

**Severity:** Deprecated

**Pattern:**
```typescript
export default defineConfig({
  test: {
    deps: {
      inline: ['vue'],
    },
  },
});
```

**Remediation:**
```typescript
export default defineConfig({
  test: {
    server: {
      deps: {
        inline: ['vue'],
      },
    },
  },
});
```

## Automated Review Script

```bash
#!/bin/bash

echo "=== Vitest 4.x Configuration Review ==="
echo ""

echo "Checking for deprecated pool options..."
grep -rn "maxThreads\|maxForks\|singleThread\|singleFork" . --include="*.config.ts" --include="*.config.js"

echo ""
echo "Checking for missing coverage.include..."
grep -rn "coverage:" . --include="*.config.ts" --include="*.config.js" -A 5 | grep -v "include:"

echo ""
echo "Checking for defineWorkspace..."
grep -rn "defineWorkspace" . --include="*.config.ts" --include="*.config.js"

echo ""
echo "Checking for wrong browser imports..."
grep -rn "@vitest/browser/context" . --include="*.ts" --include="*.tsx"

echo ""
echo "Checking for deprecated deps namespace..."
grep -rn "^\s*deps:" . --include="*.config.ts" --include="*.config.js" -A 3 | grep -v "server:"

echo ""
echo "Review complete!"
```

## Quick Checklist

Use this during review:

- [ ] No `maxThreads` or `maxForks`
- [ ] No `singleThread` or `singleFork`
- [ ] No nested `poolOptions`
- [ ] Coverage has explicit `include`
- [ ] No `coverage.ignoreEmptyLines`
- [ ] No `coverage.all`
- [ ] No `defineWorkspace`
- [ ] No `poolMatchGlobs`
- [ ] No `environmentMatchGlobs`
- [ ] Browser provider is function call
- [ ] Browser has `instances` array
- [ ] No `@vitest/browser/context` imports
- [ ] Dependencies under `server.deps`
- [ ] No `reporters: ['basic']`
- [ ] No `VITE_NODE_DEPS_MODULE_DIRECTORIES`
- [ ] No `vitest/execute` imports

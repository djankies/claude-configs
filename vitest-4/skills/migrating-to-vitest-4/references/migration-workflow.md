# Migration Workflow Reference

## Step-by-Step Migration Process

### Step 1: Update Package

```bash
npm install -D vitest@latest
```

### Step 2: Update Config

Run through configuration changes:

1. Replace `maxThreads`/`maxForks` with `maxWorkers`
2. Replace `singleThread`/`singleFork` with `maxWorkers: 1, isolate: false`
3. Add `coverage.include` patterns
4. Replace `defineWorkspace` with `projects` in `defineConfig`
5. Move `deps.*` to `server.deps.*`
6. Update browser provider imports and config

### Step 3: Update Test Files

Update browser mode imports:

```bash
grep -r "@vitest/browser/context" . --include="*.ts" --include="*.tsx"
```

Replace with:
```typescript
import { page, userEvent } from 'vitest/browser';
```

### Step 4: Install Browser Providers

If using browser mode:

```bash
npm install -D @vitest/browser-playwright
```

Or:
```bash
npm install -D @vitest/browser-webdriverio
```

### Step 5: Run Tests

```bash
vitest --run
```

Check for deprecation warnings and address them.

### Step 6: Verify Coverage

```bash
vitest --coverage
```

Ensure coverage reports generate correctly with new `include` patterns.

## Migration Checklist

### Package Updates
- [ ] Update `vitest` to 4.x
- [ ] Install browser provider package (if using browser mode)
- [ ] Remove `@vitest/browser` (if present)

### Pool Configuration
- [ ] Replace `maxThreads`/`maxForks` with `maxWorkers`
- [ ] Replace `singleThread`/`singleFork` with `maxWorkers: 1, isolate: false`
- [ ] Remove `poolOptions` nesting
- [ ] Remove `minThreads`/`minForks`

### Coverage Configuration
- [ ] Add explicit `coverage.include` patterns
- [ ] Remove `coverage.ignoreEmptyLines`
- [ ] Remove `coverage.all`
- [ ] Remove `coverage.extensions`
- [ ] Remove `coverage.experimentalAstAwareRemapping`
- [ ] Add explicit `coverage.exclude` if needed

### Workspace/Projects
- [ ] Replace `defineWorkspace` with `defineConfig` + `projects`
- [ ] Remove `poolMatchGlobs`
- [ ] Remove `environmentMatchGlobs`
- [ ] Convert workspace array to projects array

### Dependencies
- [ ] Move `deps.*` to `server.deps.*`
- [ ] Update `deps.inline` to `server.deps.inline`
- [ ] Update `deps.external` to `server.deps.external`
- [ ] Update `deps.fallbackCJS` to `server.deps.fallbackCJS`

### Browser Mode
- [ ] Install browser provider package
- [ ] Update browser provider config to function syntax
- [ ] Replace `browser.name` with `browser.instances`
- [ ] Update imports from `@vitest/browser/context` to `vitest/browser`
- [ ] Replace `browser.testerScripts` with `browser.testerHtmlPath`

### Module Runner
- [ ] Replace `VITE_NODE_DEPS_MODULE_DIRECTORIES` with `VITEST_MODULE_DIRECTORIES`
- [ ] Remove `vitest/execute` imports
- [ ] Update custom environment `transformMode` to `viteEnvironment`

### Reporter
- [ ] Replace `basic` reporter with `default` + `summary: false`

### Verification
- [ ] Run tests and verify no deprecation warnings
- [ ] Verify coverage reports generate correctly
- [ ] Check CI/CD pipeline still works

## Common Migration Issues

### Issue: Tests Fail with "maxThreads is not a valid option"

**Cause:** Using deprecated pool option

**Solution:** Replace `maxThreads` with `maxWorkers`

**Before:**
```typescript
export default defineConfig({
  test: {
    maxThreads: 4,
  },
});
```

**After:**
```typescript
export default defineConfig({
  test: {
    maxWorkers: 4,
  },
});
```

### Issue: Coverage Reports Empty

**Cause:** Missing explicit `include` patterns

**Solution:** Add explicit `coverage.include` patterns

**Before:**
```typescript
coverage: {
  provider: 'v8',
}
```

**After:**
```typescript
coverage: {
  provider: 'v8',
  include: ['src/**/*.{ts,tsx}'],
}
```

### Issue: Workspace Config Not Working

**Cause:** Using deprecated `defineWorkspace`

**Solution:** Replace with `defineConfig` and use `projects` array

**Before:**
```typescript
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([
  { test: { name: 'unit' } },
]);
```

**After:**
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      { test: { name: 'unit' } },
    ],
  },
});
```

### Issue: Browser Tests Fail with Import Error

**Cause:** Using wrong import path or missing provider package

**Solution:** Install separate provider package and update imports

**Install:**
```bash
npm install -D @vitest/browser-playwright
```

**Update config:**
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

**Update test imports:**
```typescript
import { page } from 'vitest/browser';
```

### Issue: "deps.inline is not a valid option"

**Cause:** Dependencies not under `server` namespace

**Solution:** Move to `server.deps.inline`

**Before:**
```typescript
test: {
  deps: {
    inline: ['vue'],
  },
}
```

**After:**
```typescript
test: {
  server: {
    deps: {
      inline: ['vue'],
    },
  },
}
```

## Mock Implementation Changes

### Mock Names

**Changed behavior:** `getMockName()` returns `vi.fn()` instead of `spy`

**Migration:** Update tests that check mock names

**Before (Vitest 3.x):**
```typescript
const mock = vi.fn();
expect(mock.getMockName()).toBe('spy');
```

**After (Vitest 4.x):**
```typescript
const mock = vi.fn();
expect(mock.getMockName()).toBe('vi.fn()');
```

### Invocation Order

**Changed behavior:** Starts at `1` (matching Jest) instead of `0`

**Migration:** Update assertions that check invocation order

**Before (Vitest 3.x):**
```typescript
expect(mock.invocationCallOrder).toBe(0);
```

**After (Vitest 4.x):**
```typescript
expect(mock.invocationCallOrder).toBe(1);
```

### Restore Mocks

**Changed behavior:** No longer affects automocks

**Migration:** Use `vi.unmock()` for automocks if needed

## Automated Migration Script

Here's a basic script to help with common migrations:

```bash
#!/bin/bash

find . -name "*.config.ts" -o -name "*.config.js" | while read file; do
  sed -i '' 's/maxThreads:/maxWorkers:/g' "$file"
  sed -i '' 's/maxForks:/maxWorkers:/g' "$file"
  sed -i '' 's/defineWorkspace/defineConfig/g' "$file"
done

find . -name "*.test.ts" -o -name "*.test.tsx" | while read file; do
  sed -i '' 's/@vitest\/browser\/context/vitest\/browser/g' "$file"
done

echo "Migration complete! Please review changes and run tests."
```

**Note:** Always review automated changes before committing.

## Testing Migration

### Create Migration Test Plan

1. **Unit tests**: Should pass without changes
2. **Integration tests**: May need timeout adjustments
3. **Browser tests**: Require provider package
4. **Coverage**: Verify reports generate

### Run Incremental Tests

```bash
vitest --run --project unit
vitest --run --project integration
vitest --run --project browser
```

### Verify Coverage

```bash
vitest --coverage --run
```

Check that:
- Coverage reports generate
- Thresholds are met
- Include/exclude patterns work

### Check CI/CD

Update CI configuration:

```yaml
- name: Install dependencies
  run: npm ci

- name: Install browser provider
  run: npm install -D @vitest/browser-playwright

- name: Run tests
  run: npm test

- name: Run coverage
  run: npm run test:coverage
```

## Post-Migration

### Update Documentation

1. Update README with new configuration
2. Update contributing guidelines
3. Document any breaking changes

### Team Communication

1. Share migration guide with team
2. Update onboarding documentation
3. Schedule knowledge sharing session

### Monitor for Issues

1. Watch for deprecation warnings
2. Monitor test execution time
3. Check coverage trends

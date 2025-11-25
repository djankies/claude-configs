# Vitest 4 Research

## Overview

- **Version**: 4.0.10 (latest stable as of Nov 2025)
- **Release Date**: October 22, 2025
- **Purpose in Project**: Fast unit testing framework for modern JavaScript/TypeScript projects
- **Official Documentation**: https://vitest.dev/
- **GitHub Repository**: https://github.com/vitest-dev/vitest
- **Last Updated**: November 19, 2025

## Installation

### Requirements

- Vite >=v6.0.0
- Node >=v20.0.0

### Basic Installation

```bash
npm install -D vitest
```

### With Coverage Providers

```bash
npm i -D @vitest/coverage-v8
```

or

```bash
npm i -D @vitest/coverage-istanbul
```

### Browser Mode Providers

```bash
npm install -D vitest @vitest/browser-preview
npm install -D vitest @vitest/browser-playwright
npm install -D vitest @vitest/browser-webdriverio
```

### Quick Setup for Browser Mode

```bash
npx vitest init browser
```

### Package Manager Options

```bash
npm install -D vitest
yarn add -D vitest
pnpm add -D vitest
bun add -D vitest
```

## Core Concepts

### Next Generation Testing Framework

Vitest is a testing framework powered by Vite that provides:

- **Fast execution**: Leverages Vite's transformation pipeline and hot module reloading
- **ESM-first**: Native ES Module support with first-class TypeScript and JSX support
- **Jest-compatible API**: Familiar API for easy migration from Jest
- **Watch mode**: Smart watch mode with hot module reloading for tests
- **Multi-threading**: Multi-process test execution using `node:child_process` or `node:worker_threads`
- **Environment isolation**: Prevents state leakage between test files

### Configuration Inheritance

Vitest reads your root `vite.config.ts` automatically, inheriting:

- Plugins configuration
- Resolve aliases
- Transform rules
- Global variable definitions

### Test File Convention

Test files must include `.test.` or `.spec.` in their filename:

- `sum.test.js`
- `component.spec.ts`
- `utils.test.tsx`

## Configuration

### Configuration Files

Vitest supports three configuration approaches (in order of precedence):

1. **`vitest.config.ts`** - Dedicated Vitest config (highest priority)
2. **`vite.config.ts`** - Shared Vite config with test property
3. **CLI flag** - `vitest --config ./path/to/config.ts`

### Basic Setup

#### Using defineConfig from vitest/config

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
  },
});
```

#### Using defineConfig from Vite

```typescript
import { defineConfig } from 'vite';

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './vitest.setup.ts',
  },
});
```

### TypeScript Configuration

Add type reference for proper TypeScript support:

```typescript
/// <reference types="vitest/config" />
import { defineConfig } from 'vite';

export default defineConfig({
  test: {},
});
```

For global types (describe, it, expect), add to `tsconfig.json`:

```json
{
  "compilerOptions": {
    "types": ["vitest/globals"]
  }
}
```

### Conditional Configuration

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig(({ mode }) => {
  if (mode === 'test') {
    return {
      test: {},
    };
  }
  return {};
});
```

Or using environment variable:

```typescript
export default defineConfig({
  test: process.env.VITEST ? {} : undefined,
});
```

### Key Configuration Options

#### Test Execution

- `include` - Test file patterns (default: `['**/*.{test,spec}.?(c|m)[jt]s?(x)']`)
- `exclude` - Excluded patterns (default: `['node_modules', '.git']`)
- `testTimeout` - Test timeout in ms (default: 5000)
- `hookTimeout` - Hook timeout in ms (default: 10000)
- `teardownTimeout` - Teardown timeout in ms
- `maxWorkers` - Max concurrent workers
- `fileParallelism` - Enable parallel file execution (default: true)
- `maxConcurrency` - Max concurrent tests per file
- `isolate` - Run files in isolation (default: true)
- `bail` - Stop after N failures

#### Environment

- `environment` - Test environment: 'node', 'jsdom', 'happy-dom', 'edge-runtime'
- `environmentOptions` - Environment-specific options
- `globals` - Inject APIs globally (default: false)
- `pool` - Pool type: 'forks', 'threads', 'vmThreads' (default: 'forks')

#### Reporting

- `reporters` - Reporter types: 'default', 'verbose', 'dot', 'json', 'tap', 'junit', 'tree', 'blob'
- `outputFile` - Write results to file
- `ui` - Enable UI (default: false)
- `api` - Enable API server
- `silent` - Suppress console output

#### Mocking

- `clearMocks` - Clear mock history before each test
- `mockReset` - Reset mocks before each test
- `restoreMocks` - Restore mocks before each test
- `unstubEnvs` - Restore environment variables after each test
- `unstubGlobals` - Restore global variables after each test

#### Coverage

- `coverage.enabled` - Enable coverage
- `coverage.provider` - 'v8' or 'istanbul'
- `coverage.reporter` - Coverage reporters
- `coverage.include` - Files to include in coverage
- `coverage.exclude` - Files to exclude from coverage
- `coverage.thresholds` - Coverage thresholds

#### Browser Mode

- `browser.enabled` - Enable browser mode
- `browser.provider` - Browser provider configuration
- `browser.instances` - Browser instances to use
- `browser.headless` - Run in headless mode

### Multi-Project Configuration

Run multiple test configurations simultaneously:

```typescript
export default defineConfig({
  test: {
    projects: [
      {
        test: {
          include: ['tests/unit/**/*.test.ts'],
          name: 'unit',
          environment: 'node',
        },
      },
      {
        test: {
          include: ['tests/browser/**/*.test.ts'],
          name: 'browser',
          browser: {
            enabled: true,
            provider: playwright(),
            instances: [{ browser: 'chromium' }],
          },
        },
      },
    ],
  },
});
```

## Usage Patterns

### Basic Test Structure

```typescript
import { expect, test, describe, beforeEach, afterEach } from 'vitest';
import { sum } from './sum.js';

describe('Math utilities', () => {
  beforeEach(() => {});

  afterEach(() => {});

  test('adds 1 + 2 to equal 3', () => {
    expect(sum(1, 2)).toBe(3);
  });

  test('subtracts correctly', () => {
    expect(sum(5, -2)).toBe(3);
  });
});
```

### Test Modifiers

```typescript
test.skip('skipped test', () => {});

test.only('run only this test', () => {});

test.todo('implement later');

test.fails('should fail', () => {
  expect(1).toBe(2);
});

test.concurrent('runs in parallel', async () => {});

test.skipIf(process.env.CI)('skip in CI', () => {});

test.runIf(!process.env.CI)('run only locally', () => {});
```

### Parameterized Tests with test.each

```typescript
test.each([
  [1, 1, 2],
  [1, 2, 3],
  [2, 1, 3],
])('add(%i, %i) -> %i', (a, b, expected) => {
  expect(a + b).toBe(expected);
});
```

Object syntax:

```typescript
test.each([
  { a: 1, b: 1, expected: 2 },
  { a: 1, b: 2, expected: 3 },
  { a: 2, b: 1, expected: 3 },
])('$a + $b should equal $expected', ({ a, b, expected }) => {
  expect(a + b).toBe(expected);
});
```

### Parameterized Tests with test.for

```typescript
test.for([
  [1, 1, 2],
  [1, 2, 3],
])('add(%i, %i) -> %i', ([a, b, expected]) => {
  expect(a + b).toBe(expected);
});
```

### Async Tests

```typescript
test('async test', async () => {
  const data = await fetchData();
  expect(data).toBeDefined();
});

test('promise resolves', async () => {
  await expect(fetchData()).resolves.toBe('data');
});

test('promise rejects', async () => {
  await expect(fetchBadData()).rejects.toThrow('error');
});
```

### Lifecycle Hooks

```typescript
describe('Suite with hooks', () => {
  beforeAll(() => {});

  afterAll(() => {});

  beforeEach(() => {});

  afterEach(() => {});

  test('test', () => {
    expect(true).toBe(true);
  });
});
```

### Test Context and Fixtures

```typescript
import { test as baseTest } from 'vitest';

const test = baseTest.extend({
  todos: async ({}, use) => {
    const todos = [];
    await use(todos);
    todos.length = 0;
  },
});

test('add item', ({ todos }) => {
  expect(todos.length).toBe(0);
  todos.push('item');
  expect(todos.length).toBe(1);
});
```

Automatic fixtures:

```typescript
const test = baseTest.extend({
  fixture: [
    async ({}, use) => {
      setup();
      await use();
      teardown();
    },
    { auto: true },
  ],
});
```

File-scoped fixtures:

```typescript
const test = baseTest.extend({
  database: [
    async ({}, use) => {
      const db = await connectDatabase();
      await use(db);
      await db.close();
    },
    { scope: 'file' },
  ],
});
```

## Advanced Patterns

### Mocking with vi

#### Mock Functions

```typescript
import { vi, expect, test } from 'vitest';

const mockFn = vi.fn();
mockFn.mockReturnValue('result');
mockFn.mockImplementation(() => 'custom');

test('calls mock', () => {
  mockFn('arg');
  expect(mockFn).toHaveBeenCalledWith('arg');
  expect(mockFn).toHaveBeenCalledTimes(1);
});
```

#### Module Mocking

```typescript
vi.mock('./example.js', () => ({
  method: vi.fn(),
}));
```

Partial module mocking:

```typescript
vi.mock(import('./module.js'), async (importOriginal) => {
  const mod = await importOriginal();
  return {
    ...mod,
    mocked: vi.fn(),
  };
});
```

#### Spy on Existing Methods

```typescript
import * as exports from './example.js';

vi.spyOn(exports, 'method').mockImplementation(() => {});
```

#### Class Mocking

```typescript
vi.mock(import('./example.js'), () => {
  const SomeClass = vi.fn(
    class FakeClass {
      someMethod = vi.fn();
    }
  );
  return { SomeClass };
});
```

#### Timer Mocking

```typescript
import { vi, test, expect } from 'vitest';

test('fast forwards time', () => {
  vi.useFakeTimers();

  const callback = vi.fn();
  setTimeout(callback, 1000);

  vi.advanceTimersByTime(1000);
  expect(callback).toHaveBeenCalled();

  vi.useRealTimers();
});
```

#### Date Mocking

```typescript
vi.setSystemTime(new Date(2022, 0, 1));
expect(Date.now()).toBe(new Date(2022, 0, 1).getTime());
vi.useRealTimers();
```

#### Global Variable Mocking

```typescript
vi.stubGlobal('__VERSION__', '1.0.0');
expect(__VERSION__).toBe('1.0.0');
vi.unstubAllGlobals();
```

#### Environment Variable Mocking

```typescript
vi.stubEnv('VITE_ENV', 'staging');
expect(process.env.VITE_ENV).toBe('staging');
vi.unstubAllEnvs();
```

### Snapshot Testing

#### Basic Snapshot

```typescript
import { expect, test } from 'vitest';

test('toUpperCase', () => {
  const result = toUpperCase('foobar');
  expect(result).toMatchSnapshot();
});
```

Creates `__snapshots__/test.spec.ts.snap`:

```
exports['toUpperCase 1'] = '"FOOBAR"'
```

#### Inline Snapshot

```typescript
test('toUpperCase', () => {
  const result = toUpperCase('foobar');
  expect(result).toMatchInlineSnapshot('"FOOBAR"');
});
```

#### File Snapshot

```typescript
await expect(result).toMatchFileSnapshot('./test/basic.output.html');
```

#### Updating Snapshots

Watch mode: Press `u`

CLI: `vitest -u` or `vitest --update`

### Browser Mode

#### Setup with Playwright

```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
    },
  },
});
```

#### Setup with WebDriverIO

```typescript
import { webdriverio } from '@vitest/browser-webdriverio';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    browser: {
      provider: webdriverio(),
      instances: [{ browser: 'chrome' }],
    },
  },
});
```

#### Browser Test Example

```typescript
import { page, userEvent } from 'vitest/browser';

test('user interaction', async () => {
  const input = page.getByLabelText(/username/i);
  await userEvent.fill(input, 'Bob');

  const button = page.getByRole('button');
  await button.click();

  await expect.element(page.getByText('Hello Bob')).toBeInTheDocument();
});
```

#### Component Testing (React)

```typescript
import { render } from 'vitest-browser-react';

test('loads and displays greeting', async () => {
  const screen = render(<Fetch url="/greeting" />);
  await screen.getByText('Load Greeting').click();
  const heading = screen.getByRole('heading');
  await expect.element(heading).toHaveTextContent('hello there');
});
```

#### Component Testing (Vue)

```typescript
import { render } from 'vitest-browser-vue';
import Component from './Component.vue';

test('handles v-model', async () => {
  const screen = render(Component);
  await expect.element(screen.getByText('Hi, my name is Alice')).toBeInTheDocument();
  const input = screen.getByLabelText(/username/i);
  await input.fill('Bob');
});
```

#### Visual Regression Testing

```typescript
test('visual regression', async () => {
  await expect(page.getByRole('main')).toMatchScreenshot();
});

test('element in viewport', async () => {
  await expect.element(page.getByRole('banner')).toBeInViewport();
});
```

### Coverage

#### V8 Provider

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'clover', 'json'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['**/node_modules/**', '**/dist/**'],
    },
  },
});
```

#### Istanbul Provider

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      reporter: ['text', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
```

#### Run Coverage

```bash
vitest --coverage
```

Or via package.json:

```json
{
  "scripts": {
    "coverage": "vitest run --coverage"
  }
}
```

#### Ignore Code from Coverage

V8 syntax:

```typescript
/* v8 ignore if -- @preserve */
if (condition) {
}
```

Istanbul syntax:

```typescript
/* istanbul ignore if -- @preserve */
if (condition) {
}
```

## Best Practices

### Test Organization

1. **Keep tests close to source code**: Place test files in the same directory as the components
2. **Use descriptive test names**: Test names should clearly describe what is being tested
3. **Follow AAA pattern**: Arrange, Act, Assert structure for clarity
4. **One assertion per test**: Keep tests focused on a single behavior

### State Management

1. **Isolate state**: When testing code with state management, isolate the state being tested
2. **Mock actions and getters**: Control state during testing by mocking store actions
3. **Reset state between tests**: Use `beforeEach` to ensure clean state

### Edge Cases

1. **Test null/undefined**: Cover scenarios where values are null or undefined
2. **Test empty values**: Ensure handling of empty strings or arrays
3. **Test boundary values**: Test minimum and maximum values for numeric types
4. **Test error conditions**: Verify proper error handling

### User-Centric Testing

1. **Simulate real user behavior**: Use Vitest's Interactivity API with `page.getByRole()` and `userEvent`
2. **Test keyboard navigation**: Ensure components work with keyboard
3. **Test focus management**: Verify focus behavior
4. **Test ARIA attributes**: Ensure accessibility

### Mocking Best Practices

1. **Avoid over-mocking**: Only mock dependencies not under test
2. **Use mocks to verify interactions**: Check functions are called with correct arguments
3. **Use stubs to control behavior**: Simulate different scenarios
4. **Clean up mocks**: Use `vi.clearAllMocks()`, `vi.resetAllMocks()`, or `vi.restoreAllMocks()`

### Performance

1. **Disable isolation when safe**: Use `--no-isolate` for faster tests without side effects
2. **Choose appropriate pool**: Use `pool: 'threads'` for large projects
3. **Use happy-dom over jsdom**: Faster in most cases
4. **Limit search directory**: Use `test.dir` to improve search speed
5. **Disable file parallelism for startup**: Use `--no-file-parallelism` if startup time is critical

## Common Gotchas

### Module Hoisting

`vi.mock()` calls are hoisted to the top of the file and execute before all imports. Be aware of execution order.

### Browser Mode Limitations

1. **Thread-blocking dialogs**: Functions like `alert()` and `confirm()` block execution
2. **Spying on module exports**: Browser modules use sealed namespaces - use `vi.mock('./module.js', { spy: true })`
3. **Variable mocking**: Export a function to modify internal state instead of trying to mock variables directly

### Test File Naming

Files must include `.test.` or `.spec.` in the filename to be discovered by Vitest.

### Globals Configuration

Jest has globals enabled by default. Vitest does not. Either:

- Enable `globals: true` in config
- Import `test`, `describe`, `expect` explicitly

### Snapshot Testing with Async

When using snapshots with async concurrent tests, use `expect` from the local test context.

### TypeScript Path Aliases

Use `vite-tsconfig-paths` plugin to resolve TypeScript path aliases in tests.

### Vue Components with Style Sections

Breakpoints may stop at incorrect line numbers in Vue SFCs containing `<style>` sections due to sourcemap issues.

## Anti-Patterns

### Testing Implementation Details

Don't test internal implementation. Test public API and behavior instead.

```typescript
test('user can submit form', async () => {
  await userEvent.fill(input, 'data');
  await userEvent.click(submitButton);
  await expect.element(successMessage).toBeInTheDocument();
});
```

### Over-Mocking

Only mock what's necessary. Over-mocking leads to brittle tests.

```typescript
test('adds items', () => {
  const store = { items: [] };
  store.items.push('item');
  expect(store.items).toHaveLength(1);
});
```

### Not Cleaning Up Mocks

Always restore mocks to prevent test pollution:

```typescript
afterEach(() => {
  vi.restoreAllMocks();
});
```

Or use config:

```typescript
export default defineConfig({
  test: {
    restoreMocks: true,
  },
});
```

### Writing Comments in Tests

Tests should be self-documenting through clear naming and structure.

```typescript
test('user cannot submit empty form', async () => {
  await userEvent.click(submitButton);
  await expect.element(errorMessage).toBeVisible();
});
```

### Not Testing Error Cases

Always test both happy path and error conditions:

```typescript
test('handles fetch error', async () => {
  vi.mocked(fetch).mockRejectedValue(new Error('Network error'));
  await expect(fetchData()).rejects.toThrow('Network error');
});
```

## Error Handling

### Try-Catch in Async Tests

```typescript
test('handles errors', async () => {
  try {
    await riskyOperation();
    expect.fail('should have thrown');
  } catch (error) {
    expect(error.message).toBe('expected error');
  }
});
```

### Using expect.rejects

```typescript
test('handles errors', async () => {
  await expect(riskyOperation()).rejects.toThrow('expected error');
});
```

### Testing Error Boundaries (React)

```typescript
test('error boundary catches errors', async () => {
  const { getByText } = render(
    <ErrorBoundary>
      <ThrowError />
    </ErrorBoundary>
  );
  await expect.element(getByText('Error occurred')).toBeInTheDocument();
});
```

## Security Considerations

### Critical Vulnerability CVE-2025-24964

Vitest versions prior to the patch are vulnerable to remote code execution via Cross-site WebSocket Hijacking (CSWSH) when the API server is enabled.

**Risk**: When `api` option is enabled (automatically enabled by Vitest UI), an attacker can execute arbitrary code by:

1. Injecting code into a test file via the `saveTestFile` API
2. Running that file via the `rerun` API

**Mitigation**:

1. Upgrade to latest Vitest version with the security patch
2. Disable API server when not needed
3. Never run Vitest with API enabled while browsing untrusted websites

### Subresource Integrity (SRI)

If loading Vitest-related assets from a CDN, use SRI to ensure files haven't been tampered with:

```html
<script
  src="https://cdn.example.com/vitest.js"
  integrity="sha384-..."
  crossorigin="anonymous"></script>
```

### Content Security Policy

Configure CSP as an added security layer to prevent XSS and data injection attacks.

### Input Sanitization

Always sanitize user input and encode output to prevent XSS vulnerabilities in test utilities.

### Version Management

Use the latest version of Vitest to benefit from security patches and updates.

## Performance Tips

### Disable Test Isolation

Significant speed improvement for tests without side effects:

```bash
vitest --no-isolate
```

Or in config:

```typescript
export default defineConfig({
  test: {
    isolate: false,
  },
});
```

Note: Cannot disable with `vmThreads` pool.

### Switch Thread Pools

```typescript
export default defineConfig({
  test: {
    pool: 'threads',
  },
});
```

### Disable File Parallelism

Improves startup time:

```bash
vitest --no-file-parallelism
```

### Limit Search Directory

```typescript
export default defineConfig({
  test: {
    dir: './src',
  },
});
```

### Use happy-dom

```typescript
export default defineConfig({
  test: {
    environment: 'happy-dom',
  },
});
```

### Test Sharding

Distribute tests across multiple machines:

```bash
vitest run --reporter=blob --shard=1/4
vitest run --reporter=blob --shard=2/4
vitest run --reporter=blob --shard=3/4
vitest run --reporter=blob --shard=4/4
vitest --merge-reports
```

### Advanced Performance Configuration

```typescript
export default defineConfig({
  test: {
    maxConcurrency: 20,
    pool: 'threads',
    isolate: false,
    css: false,
    deps: {
      optimizer: {
        web: {
          enabled: true,
        },
      },
    },
  },
});
```

## Version-Specific Notes

### Breaking Changes in Vitest 4.0

#### V8 Coverage Overhaul

- Removed `coverage.ignoreEmptyLines` option
- Removed `coverage.experimentalAstAwareRemapping` (now default)
- AST-based remapping now provides Istanbul-level accuracy with V8 speed

#### Coverage Configuration

- Removed `coverage.all` and `coverage.extensions` defaults
- Must explicitly define `coverage.include` patterns

#### Default Exclusions

- Now only excludes `node_modules` and `.git` by default
- Previously excluded directories require manual exclusion patterns

#### Mock Implementation

- Spies and mocks support constructor patterns with `new` keyword
- Must use `function` or `class` keywords, not arrow functions
- `vi.fn().getMockName()` returns `vi.fn()` instead of `spy`
- `vi.restoreAllMocks()` no longer affects automocks
- `mock.invocationCallOrder` starts at `1` (matching Jest)

#### Pool Architecture

- Removed tinypool dependency
- `maxThreads` and `maxForks` consolidated to `maxWorkers`
- `singleThread` and `singleFork` replaced by `maxWorkers: 1, isolate: false`
- `poolOptions` flattened to top-level configuration

#### Browser Provider

- Browser configuration accepts objects instead of strings
- `@vitest/browser` package is optional
- Import paths shifted from `@vitest/browser/context` to `vitest/browser`

#### Configuration Deprecations Removed

- `workspace` replaced by `projects`
- `poolMatchGlobs` and `environmentMatchGlobs` superseded by `projects`
- `deps.external`, `deps.inline`, `deps.fallbackCJS` moved under `server.deps`
- `browser.testerScripts` replaced by `browser.testerHtmlPath`
- `minWorkers` option eliminated
- Test options as third argument no longer supported

#### Module Runner

- `vite-node` replaced with Vite's Module Runner
- `VITE_NODE_DEPS_MODULE_DIRECTORIES` becomes `VITEST_MODULE_DIRECTORIES`
- Custom environments use `viteEnvironment` instead of `transformMode`
- `vitest/execute` entry point removed

#### Reporter Changes

- `basic` reporter removed; use `default` reporter with `summary: false`
- `default` reporter only shows tree format for single-file runs
- New `tree` reporter for consistent tree output
- `verbose` reporter always prints tests individually

### New Features in Vitest 4.0

#### Browser Mode Stability

Browser Mode promoted from experimental to stable. Separate provider packages now required.

#### Visual Regression Testing

- `toMatchScreenshot()` assertion for UI screenshots
- `toBeInViewport()` matcher using IntersectionObserver API

#### Playwright Traces

Enhanced debugging with trace generation via `--browser.trace` flag.

Trace states: `off`, `on`, `on-first-retry`, `on-all-retries`, `retain-on-failure`

#### Locator Improvements

- `page.frameLocator()` API for iframe elements (Playwright)
- All locators expose `length` property compatible with `toHaveLength()`

#### New Assertions

- `expect.assert` - Direct access to Chai assertions for type narrowing
- `expect.schemaMatching` - Validates against Standard Schema v1 objects (Zod, Valibot, ArkType)

#### Advanced API Methods

- `experimental_parseSpecifications()` - Parse test file without execution
- `watcher` - Methods for custom watcher implementations
- `enableCoverage()` / `disableCoverage()` - Dynamic coverage control
- `getSeed()` - Returns randomization seed
- `getGlobalTestNamePattern()` - Returns current test filter pattern
- `waitForTestRunEnd()` - Promise that resolves when tests finish

#### Type-Aware Hooks

When extending tests with `test.extend()`, lifecycle hooks access extended context directly.

## Migration from Jest

### Key Differences

#### 1. Global APIs

Jest enables globals by default. Vitest does not.

Either enable in config:

```typescript
export default defineConfig({
  test: {
    globals: true,
  },
});
```

Or import explicitly:

```typescript
import { describe, test, expect } from 'vitest';
```

#### 2. Mocking Syntax

Replace `jest` with `vi`:

```typescript
jest.fn()          → vi.fn()
jest.spyOn()       → vi.spyOn()
jest.mock()        → vi.mock()
jest.useFakeTimers() → vi.useFakeTimers()
```

#### 3. Module Mocking

Jest factory returns default export. Vitest factory must return object with explicit exports:

```typescript
vi.mock('./module', () => ({
  default: vi.fn(),
  namedExport: vi.fn(),
}));
```

#### 4. Async Imports

Import actual modules asynchronously:

```typescript
vi.mock(import('./module'), async (importOriginal) => {
  const mod = await importOriginal();
  return {
    ...mod,
    mocked: vi.fn(),
  };
});
```

#### 5. Auto-mocking

Modules in `<root>/__mocks__` not loaded unless `vi.mock()` called. Mock in `setupFiles` for automatic mocking.

#### 6. Timers

Vitest doesn't support Jest's legacy timers.

#### 7. JSX File Extensions

JSX must use `.jsx` or `.tsx` extension.

#### 8. Environment Variables

`JEST_WORKER_ID` becomes `VITEST_POOL_ID`

#### 9. Import Statements

Replace:

```typescript
import { expect, test } from '@jest/globals';
```

With:

```typescript
import { expect, test } from 'vitest';
```

## CLI Reference

### Commands

```bash
vitest                 # Watch mode (dev) or run mode (CI)
vitest run            # Single run without watch
vitest watch          # Watch mode
vitest dev            # Watch mode (alias)
vitest related        # Test files covering specified sources
vitest bench          # Run benchmarks only
vitest init <name>    # Setup config (supports: browser)
vitest list           # Print matching tests
```

### Watch Mode Shortcuts

When running in watch mode:

- `h` - Show help
- `q` - Quit
- `a` - Rerun all tests
- `f` - Rerun only failed tests
- `u` - Update snapshots
- `p` - Filter by filename
- `t` - Filter by test name regex

### Key Flags

#### Test Filtering

```bash
vitest <filter>                    # Run tests matching filename
vitest <file>:<line>               # Run tests at specific line
vitest -t, --testNamePattern <pattern>  # Filter by test name
```

#### General Options

```bash
-r, --root <path>          # Root directory
-c, --config <path>        # Config file path
-w, --watch                # Watch mode
-u, --update               # Update snapshots
--run                      # Disable watch mode
--dir <path>               # Base directory for test files
```

#### UI & Output

```bash
--ui                       # Enable UI
--open                     # Auto-open UI
--reporter <name>          # Specify reporter
--outputFile <filename>    # Write results to file
--silent                   # Suppress console output
--silent=passed-only       # Only suppress passed tests
```

#### Performance

```bash
--pool <pool>              # Pool type (forks, threads, vmThreads)
--maxWorkers <workers>     # Max concurrent workers
--fileParallelism          # Parallel file execution
--isolate                  # Run files in isolation
--no-isolate               # Disable isolation
--no-file-parallelism      # Disable parallel execution
```

#### Coverage

```bash
--coverage.enabled                  # Enable coverage
--coverage.provider <name>          # v8, istanbul, or custom
--coverage.reporter <name>          # Coverage format
--coverage.include <pattern>        # Include patterns
--coverage.exclude <pattern>        # Exclude patterns
--coverage.thresholds.lines <num>   # Line coverage threshold
```

#### Browser Mode

```bash
--browser.enabled          # Run in browser
--browser.name <name>      # Specific browser
--browser.headless         # Headless mode
--browser.provider <name>  # webdriverio, playwright, preview
--browser.trace            # Enable Playwright traces
```

#### Advanced

```bash
--bail <number>            # Stop after N failures
--retry <times>            # Retry failed tests
--globals                  # Inject APIs globally
--inspect                  # Enable Node.js debugger
--inspectBrk               # Debugger with breakpoint
--changed                  # Run tests for changed files
--shard <index>/<count>    # Distribute tests
--merge-reports            # Merge blob reports
```

## Debugging

### VSCode JavaScript Debug Terminal

Quickest method - open JavaScript Debug Terminal and run:

```bash
npm run test
```

Set breakpoints in editor and they will be hit automatically.

### VSCode Launch Configuration

`.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Current Test File",
      "autoAttachChildProcesses": true,
      "skipFiles": ["<node_internals>/**", "**/node_modules/**"],
      "program": "${workspaceRoot}/node_modules/vitest/vitest.mjs",
      "args": ["run", "${relativeFile}"],
      "smartStep": true,
      "console": "integratedTerminal"
    }
  ]
}
```

Open test file, press F5 to start debugging.

### Vitest VS Code Extension

Official extension provides:

- Run tests from editor
- Debug tests with breakpoints
- Watch mode integration
- Test explorer

Install from VSCode marketplace: `vitest.explorer`

### Node.js Inspector

```bash
vitest --inspect-brk
```

Open `chrome://inspect` in Chrome to attach debugger.

## Code Examples

### Complete Test Suite Example

```typescript
import { describe, test, expect, beforeEach, afterEach, vi } from 'vitest';
import { UserService } from './UserService';
import { Database } from './Database';

vi.mock('./Database');

describe('UserService', () => {
  let userService: UserService;
  let mockDb: Database;

  beforeEach(() => {
    mockDb = new Database();
    userService = new UserService(mockDb);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('createUser', () => {
    test('creates user with valid data', async () => {
      const userData = { name: 'John', email: 'john@example.com' };
      vi.mocked(mockDb.insert).mockResolvedValue({ id: 1, ...userData });

      const result = await userService.createUser(userData);

      expect(result).toEqual({ id: 1, ...userData });
      expect(mockDb.insert).toHaveBeenCalledWith('users', userData);
    });

    test('throws error for invalid email', async () => {
      const userData = { name: 'John', email: 'invalid' };

      await expect(userService.createUser(userData)).rejects.toThrow('Invalid email');
    });
  });

  describe('getUser', () => {
    test('returns user when found', async () => {
      const user = { id: 1, name: 'John', email: 'john@example.com' };
      vi.mocked(mockDb.findOne).mockResolvedValue(user);

      const result = await userService.getUser(1);

      expect(result).toEqual(user);
    });

    test('returns null when not found', async () => {
      vi.mocked(mockDb.findOne).mockResolvedValue(null);

      const result = await userService.getUser(999);

      expect(result).toBeNull();
    });
  });
});
```

### React Component Test Example

```typescript
import { test, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LoginForm } from './LoginForm';

test('submits form with user credentials', async () => {
  const handleSubmit = vi.fn();
  const user = userEvent.setup();

  render(<LoginForm onSubmit={handleSubmit} />);

  await user.type(screen.getByLabelText(/email/i), 'user@example.com');
  await user.type(screen.getByLabelText(/password/i), 'password123');
  await user.click(screen.getByRole('button', { name: /submit/i }));

  expect(handleSubmit).toHaveBeenCalledWith({
    email: 'user@example.com',
    password: 'password123',
  });
});

test('displays validation errors', async () => {
  const user = userEvent.setup();

  render(<LoginForm onSubmit={vi.fn()} />);

  await user.click(screen.getByRole('button', { name: /submit/i }));

  expect(screen.getByText(/email is required/i)).toBeInTheDocument();
  expect(screen.getByText(/password is required/i)).toBeInTheDocument();
});
```

### API Integration Test Example

```typescript
import { test, expect, beforeAll, afterAll } from 'vitest';
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';
import { fetchUserData } from './api';

const server = setupServer(
  http.get('/api/user/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      name: 'John Doe',
      email: 'john@example.com',
    });
  })
);

beforeAll(() => server.listen());
afterAll(() => server.close());

test('fetches user data', async () => {
  const user = await fetchUserData(1);

  expect(user).toEqual({
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
  });
});

test('handles fetch error', async () => {
  server.use(
    http.get('/api/user/:id', () => {
      return new HttpResponse(null, { status: 500 });
    })
  );

  await expect(fetchUserData(1)).rejects.toThrow('Failed to fetch');
});
```

### Custom Matcher Example

```typescript
import { expect } from 'vitest';

expect.extend({
  toBeWithinRange(received: number, floor: number, ceiling: number) {
    const pass = received >= floor && received <= ceiling;
    return {
      pass,
      message: () =>
        pass
          ? `expected ${received} not to be within range ${floor} - ${ceiling}`
          : `expected ${received} to be within range ${floor} - ${ceiling}`,
    };
  },
});

test('custom matcher', () => {
  expect(100).toBeWithinRange(90, 110);
  expect(101).not.toBeWithinRange(0, 100);
});
```

## References

### Official Documentation

- Main Documentation: https://vitest.dev/
- API Reference: https://vitest.dev/api/
- Configuration Reference: https://vitest.dev/config/
- CLI Reference: https://vitest.dev/guide/cli
- Migration Guide: https://vitest.dev/guide/migration.html

### Release Information

- Vitest 4.0 Announcement: https://vitest.dev/blog/vitest-4
- VoidZero Announcement: https://voidzero.dev/posts/announcing-vitest-4
- GitHub Releases: https://github.com/vitest-dev/vitest/releases

### Guides

- Getting Started: https://vitest.dev/guide/
- Features: https://vitest.dev/guide/features
- Coverage: https://vitest.dev/guide/coverage
- Mocking: https://vitest.dev/guide/mocking
- Snapshot Testing: https://vitest.dev/guide/snapshot
- Browser Mode: https://vitest.dev/guide/browser/
- Test Context: https://vitest.dev/guide/test-context
- Debugging: https://vitest.dev/guide/debugging
- Improving Performance: https://vitest.dev/guide/improving-performance

### GitHub

- Repository: https://github.com/vitest-dev/vitest
- VSCode Extension: https://github.com/vitest-dev/vscode

### Security

- Security Advisories: https://github.com/vitest-dev/vitest/security/advisories
- CVE-2025-24964 Information: https://thesecmaster.com/blog/how-to-fix-cve-2025-24964-critical-remote-code-execution-vulnerability-in-vitest

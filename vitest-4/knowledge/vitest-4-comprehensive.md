# Vitest 4 Comprehensive Reference

## Configuration

### Pool Architecture

Pool types determine how tests are executed in parallel:

- `pool: 'forks'` - Uses `node:child_process` (default in v4)
- `pool: 'threads'` - Uses `node:worker_threads` for large projects
- `pool: 'vmThreads'` - VM threads for additional isolation

Worker configuration has changed from v3 to v4:

**Deprecated Options (v3):**
- `maxThreads` - Maximum threads for thread pool
- `maxForks` - Maximum forks for fork pool
- `singleThread` - Run in single thread
- `singleFork` - Run in single fork
- `poolOptions` - Pool-specific options

**Current Options (v4):**
- `maxWorkers` - Maximum concurrent workers (consolidated)
- `maxWorkers: 1, isolate: false` - Replaces singleThread/singleFork
- Pool options moved to top-level config (poolOptions flattened)

Configuration example:

```typescript
export default defineConfig({
  test: {
    pool: 'forks',
    maxWorkers: 4,
    fileParallelism: true,
    isolate: true,
  },
});
```

### Coverage Configuration

V8 provider (recommended for speed):

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

Istanbul provider (for legacy compatibility):

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

**Important Changes in v4:**
- `coverage.include` patterns are now **required** (no defaults)
- `coverage.all` and `coverage.extensions` removed
- `coverage.ignoreEmptyLines` removed
- `coverage.experimentalAstAwareRemapping` removed (now default behavior)
- AST-based remapping now provides Istanbul-level accuracy with V8 speed

### Multi-Project Setup

Run multiple test configurations simultaneously using the `projects` array:

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

**Migration Note:** The `workspace` option has been replaced by `projects`.

### Browser Mode Configuration

Browser mode requires separate provider packages:

**Installation:**

```bash
npm install -D vitest @vitest/browser-playwright
```

**Configuration with Playwright:**

```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
      headless: true,
    },
  },
});
```

**Configuration with WebDriverIO:**

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

**Key Changes in v4:**
- Browser configuration accepts objects instead of strings
- `@vitest/browser` package is optional
- Import paths changed from `@vitest/browser/context` to `vitest/browser`
- `browser.testerScripts` replaced by `browser.testerHtmlPath`

## Breaking Changes

### Pool Options Migration

| Deprecated (v3) | Current (v4) |
|----------------|--------------|
| `maxThreads` | `maxWorkers` |
| `maxForks` | `maxWorkers` |
| `singleThread` | `maxWorkers: 1, isolate: false` |
| `singleFork` | `maxWorkers: 1, isolate: false` |
| `poolOptions.*` | Move to top-level config |

### Coverage Config Changes

| Removed Option | Migration |
|---------------|-----------|
| `coverage.all` | No longer has defaults |
| `coverage.extensions` | No longer has defaults |
| `coverage.ignoreEmptyLines` | Removed (no replacement) |
| `coverage.experimentalAstAwareRemapping` | Now default behavior |

**Critical:** Must explicitly define `coverage.include` patterns in v4.

### Workspace → Projects Migration

| Deprecated (v3) | Current (v4) |
|----------------|--------------|
| `workspace` | `projects` |
| `poolMatchGlobs` | `projects` with separate configs |
| `environmentMatchGlobs` | `projects` with separate configs |

### Import Path Changes

| Old Path (v3) | New Path (v4) |
|--------------|--------------|
| `@vitest/browser/context` | `vitest/browser` |
| `vitest/execute` | Removed (use Vite Module Runner) |

### Deprecated APIs

#### Module Runner Changes

- `vite-node` replaced with Vite's Module Runner
- `VITE_NODE_DEPS_MODULE_DIRECTORIES` → `VITEST_MODULE_DIRECTORIES`
- Custom environments use `viteEnvironment` instead of `transformMode`

#### Reporter Changes

- `basic` reporter removed; use `default` reporter with `summary: false`
- `default` reporter only shows tree format for single-file runs
- New `tree` reporter for consistent tree output
- `verbose` reporter always prints tests individually

#### Dependency Options

Moved under `server.deps`:

| Old Path (v3) | New Path (v4) |
|--------------|--------------|
| `deps.external` | `server.deps.external` |
| `deps.inline` | `server.deps.inline` |
| `deps.fallbackCJS` | `server.deps.fallbackCJS` |

#### Mock Behavior Changes

- `vi.fn().getMockName()` returns `vi.fn()` instead of `spy`
- `vi.restoreAllMocks()` no longer affects automocks
- `mock.invocationCallOrder` starts at `1` (matching Jest)
- Spies and mocks support constructor patterns with `new` keyword
- Must use `function` or `class` keywords, not arrow functions

#### Removed Options

- `minWorkers` - Eliminated
- Test options as third argument no longer supported
- `browser.testerScripts` → `browser.testerHtmlPath`

## Usage Patterns

### Test Organization

Basic test structure:

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

Test file naming conventions:
- Must include `.test.` or `.spec.` in filename
- Examples: `sum.test.js`, `component.spec.ts`, `utils.test.tsx`

Lifecycle hooks:

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

### Assertions and Matchers

Common matchers:

```typescript
expect(value).toBe(expected)
expect(value).toEqual(expected)
expect(value).toBeTruthy()
expect(value).toBeFalsy()
expect(value).toBeNull()
expect(value).toBeUndefined()
expect(value).toBeDefined()
expect(array).toContain(item)
expect(string).toMatch(/pattern/)
expect(fn).toThrow('error')
expect(fn).toHaveBeenCalled()
expect(fn).toHaveBeenCalledWith(arg1, arg2)
expect(fn).toHaveBeenCalledTimes(n)
```

Async matchers:

```typescript
await expect(promise).resolves.toBe('value')
await expect(promise).rejects.toThrow('error')
```

New in v4:

```typescript
expect.assert
expect.schemaMatching
```

### Mocking

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

Full module mock:

```typescript
vi.mock('./example.js', () => ({
  method: vi.fn(),
}));
```

Partial module mock:

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

### Async Testing

Basic async tests:

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

Error handling:

```typescript
test('handles errors', async () => {
  await expect(riskyOperation()).rejects.toThrow('expected error');
});
```

Try-catch pattern:

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

## Advanced Patterns

### Parameterized Tests

#### test.each (Array Syntax)

```typescript
test.each([
  [1, 1, 2],
  [1, 2, 3],
  [2, 1, 3],
])('add(%i, %i) -> %i', (a, b, expected) => {
  expect(a + b).toBe(expected);
});
```

#### test.each (Object Syntax)

```typescript
test.each([
  { a: 1, b: 1, expected: 2 },
  { a: 1, b: 2, expected: 3 },
  { a: 2, b: 1, expected: 3 },
])('$a + $b should equal $expected', ({ a, b, expected }) => {
  expect(a + b).toBe(expected);
});
```

#### test.for

```typescript
test.for([
  [1, 1, 2],
  [1, 2, 3],
])('add(%i, %i) -> %i', ([a, b, expected]) => {
  expect(a + b).toBe(expected);
});
```

### Fixtures (test.extend)

Basic fixture:

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

**New in v4:** Type-aware hooks - when extending tests with `test.extend()`, lifecycle hooks access extended context directly.

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

### Component Testing

#### React Component Testing

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
```

#### React with vitest-browser-react

```typescript
import { render } from 'vitest-browser-react';

test('loads and displays greeting', async () => {
  const screen = render(<Fetch url="/greeting" />);
  await screen.getByText('Load Greeting').click();
  const heading = screen.getByRole('heading');
  await expect.element(heading).toHaveTextContent('hello there');
});
```

#### Vue Component Testing

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

## Browser Mode

### Provider Setup

**Playwright Provider:**

Installation:

```bash
npm install -D vitest @vitest/browser-playwright
```

Configuration:

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

Quick setup:

```bash
npx vitest init browser
```

**WebDriverIO Provider:**

Installation:

```bash
npm install -D vitest @vitest/browser-webdriverio
```

Configuration:

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

### APIs (page, userEvent)

Browser test with page and userEvent:

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

**New in v4:** Frame locator API:

```typescript
const frame = page.frameLocator('iframe');
```

All locators expose `length` property:

```typescript
expect(page.getByRole('button')).toHaveLength(3);
```

### Visual Regression Testing

Screenshot matching:

```typescript
test('visual regression', async () => {
  await expect(page.getByRole('main')).toMatchScreenshot();
});
```

Viewport testing:

```typescript
test('element in viewport', async () => {
  await expect.element(page.getByRole('banner')).toBeInViewport();
});
```

### Playwright Traces (New in v4)

Enhanced debugging with trace generation:

```bash
vitest --browser.trace
```

Trace states: `off`, `on`, `on-first-retry`, `on-all-retries`, `retain-on-failure`

### Browser Mode Limitations

1. **Thread-blocking dialogs**: Functions like `alert()` and `confirm()` block execution
2. **Spying on module exports**: Browser modules use sealed namespaces - use `vi.mock('./module.js', { spy: true })`
3. **Variable mocking**: Export a function to modify internal state instead of trying to mock variables directly

## Test Modifiers

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

## Best Practices

### Test Organization

1. Keep tests close to source code
2. Use descriptive test names
3. Follow AAA pattern (Arrange, Act, Assert)
4. One assertion per test

### State Management

1. Isolate state being tested
2. Mock store actions
3. Reset state between tests with `beforeEach`

### Edge Cases

1. Test null/undefined
2. Test empty values
3. Test boundary values
4. Test error conditions

### User-Centric Testing

1. Simulate real user behavior with `page.getByRole()` and `userEvent`
2. Test keyboard navigation
3. Test focus management
4. Test ARIA attributes

### Mocking Best Practices

1. Avoid over-mocking
2. Use mocks to verify interactions
3. Use stubs to control behavior
4. Clean up mocks with `vi.clearAllMocks()`, `vi.resetAllMocks()`, or `vi.restoreAllMocks()`

### Mock Cleanup

Always restore mocks:

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

## Anti-Patterns

### Testing Implementation Details

Don't test internal implementation. Test public API and behavior:

```typescript
test('user can submit form', async () => {
  await userEvent.fill(input, 'data');
  await userEvent.click(submitButton);
  await expect.element(successMessage).toBeInTheDocument();
});
```

### Over-Mocking

Only mock what's necessary:

```typescript
test('adds items', () => {
  const store = { items: [] };
  store.items.push('item');
  expect(store.items).toHaveLength(1);
});
```

### Not Cleaning Up Mocks

Always restore mocks to prevent test pollution.

### Not Testing Error Cases

Always test both happy path and error conditions:

```typescript
test('handles fetch error', async () => {
  vi.mocked(fetch).mockRejectedValue(new Error('Network error'));
  await expect(fetchData()).rejects.toThrow('Network error');
});
```

## Security Considerations

### Critical Vulnerability CVE-2025-24964

Vitest versions prior to the patch are vulnerable to remote code execution via Cross-site WebSocket Hijacking (CSWSH) when the API server is enabled.

**Risk**: When `api` option is enabled (automatically enabled by Vitest UI), an attacker can execute arbitrary code.

**Mitigation**:

1. Upgrade to latest Vitest version with security patch
2. Disable API server when not needed
3. Never run Vitest with API enabled while browsing untrusted websites

### Version Management

Use the latest version of Vitest to benefit from security patches and updates.

### Input Sanitization

Always sanitize user input and encode output to prevent XSS vulnerabilities in test utilities.

## Performance Tips

### Disable Test Isolation

```typescript
export default defineConfig({
  test: {
    isolate: false,
  },
});
```

Or CLI:

```bash
vitest --no-isolate
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

## Migration from Jest

### Key Differences

#### Global APIs

Jest enables globals by default. Vitest does not.

Enable in config:

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

#### Mocking Syntax

Replace `jest` with `vi`:

```typescript
jest.fn()          → vi.fn()
jest.spyOn()       → vi.spyOn()
jest.mock()        → vi.mock()
jest.useFakeTimers() → vi.useFakeTimers()
```

#### Module Mocking

Jest factory returns default export. Vitest factory must return object with explicit exports:

```typescript
vi.mock('./module', () => ({
  default: vi.fn(),
  namedExport: vi.fn(),
}));
```

#### Async Imports

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

#### Auto-mocking

Modules in `<root>/__mocks__` not loaded unless `vi.mock()` called. Mock in `setupFiles` for automatic mocking.

#### Environment Variables

`JEST_WORKER_ID` becomes `VITEST_POOL_ID`

#### Import Statements

Replace:

```typescript
import { expect, test } from '@jest/globals';
```

With:

```typescript
import { expect, test } from 'vitest';
```

## Common Gotchas

### Module Hoisting

`vi.mock()` calls are hoisted to the top of the file and execute before all imports.

### Test File Naming

Files must include `.test.` or `.spec.` in the filename to be discovered by Vitest.

### Globals Configuration

Jest has globals enabled by default. Vitest does not. Either enable `globals: true` in config or import explicitly.

### Snapshot Testing with Async

When using snapshots with async concurrent tests, use `expect` from the local test context.

### TypeScript Path Aliases

Use `vite-tsconfig-paths` plugin to resolve TypeScript path aliases in tests.

### Vue Components with Style Sections

Breakpoints may stop at incorrect line numbers in Vue SFCs containing `<style>` sections due to sourcemap issues.

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

Open JavaScript Debug Terminal and run:

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

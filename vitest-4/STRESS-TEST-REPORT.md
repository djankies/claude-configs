# Stress Test Report: Vitest 4

**Date:** November 24, 2025 | **Research:** vitest-4/RESEARCH.md | **Agents:** 5

## Executive Summary

| Metric | Count |
|--------|-------|
| Total Violations | 24 |
| Critical | 14 |
| High | 5 |
| Medium | 4 |
| Low | 1 |

**Most Common:** Deprecated configuration options (5 agents)
**Deprecated APIs:** 14/24
**Incorrect APIs:** 3/24
**Legacy/anti-patterns:** 5/24
**Legacy configurations:** 14/24

---

## Pattern Analysis

### Most Common Violations

1. **Deprecated pool configuration options** - 12 occurrences (3 agents)
2. **`coverage.ignoreEmptyLines` removed** - 3 occurrences (1 agent)
3. **`workspace`/`defineWorkspace` replaced by `projects`** - 2 occurrences (2 agents)
4. **Missing `coverage.include` patterns** - 3 occurrences (2 agents)
5. **Using globals without explicit imports** - 2 occurrences (2 agents)

### Frequently Misunderstood

- **Pool Architecture**: 3 agents struggled
  - Common mistake: Using `maxThreads`, `minThreads`, `singleThread`, `singleFork`, `poolOptions`
  - Research says: "maxThreads and maxForks consolidated to maxWorkers; singleThread and singleFork replaced by maxWorkers: 1, isolate: false; poolOptions flattened to top-level"
  - Recommendation: Use `maxWorkers` and `isolate` at top-level test config

- **Coverage Configuration**: 3 agents struggled
  - Common mistake: Using `coverage.ignoreEmptyLines`, `coverage.all`, `coverage.extensions`
  - Research says: "Removed coverage.ignoreEmptyLines, coverage.all, coverage.extensions; Must explicitly define coverage.include patterns"
  - Recommendation: Remove deprecated options, explicitly define `include` patterns

- **Multi-project Configuration**: 2 agents struggled
  - Common mistake: Using `workspace`, `poolMatchGlobs`, `environmentMatchGlobs`
  - Research says: "workspace replaced by projects; poolMatchGlobs and environmentMatchGlobs superseded by projects"
  - Recommendation: Use `projects` array in defineConfig

- **Browser Mode**: 1 agent struggled
  - Common mistake: Manual implementation of browser APIs, wrong import paths
  - Research says: "Import paths shifted from @vitest/browser/context to vitest/browser"
  - Recommendation: Import `page`, `userEvent` from `vitest/browser`

---

## Scenarios Tested

1. **Auth Service** - coverage.ignoreEmptyLines, workspace config, mocking
2. **Timer Utility** - maxThreads, singleFork, poolMatchGlobs, fake timers
3. **Shopping Cart** - coverage.all, deps.inline location, globals
4. **Notification Service** - browser mode, testerScripts, basic reporter
5. **Data Validation Pipeline** - environmentMatchGlobs, minWorkers, poolOptions, coverage.extensions

---

## Deduplicated Individual Findings

### [CRITICAL] Removed `coverage.ignoreEmptyLines`

**Found Instances:** 3

```javascript
coverage: {
  provider: 'v8',
  ignoreEmptyLines: true
}
```

**Research Doc says:** (section "V8 Coverage Overhaul")

> Removed `coverage.ignoreEmptyLines` option. AST-based remapping now provides Istanbul-level accuracy with V8 speed.

**Correct:**

```javascript
coverage: {
  provider: 'v8'
}
```

**Impact:** Configuration fails in Vitest 4. V8 coverage now uses AST-based remapping by default.

---

### [CRITICAL] Removed `defineWorkspace` / `workspace`

**Found Instances:** 2

```javascript
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([
  { test: { name: 'unit', include: ['tests/unit/**'] } },
  { test: { name: 'integration', include: ['tests/integration/**'] } }
]);
```

**Research Doc says:** (section "Configuration Deprecations Removed")

> `workspace` replaced by `projects`

**Correct:**

```javascript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      { test: { name: 'unit', include: ['tests/unit/**'] } },
      { test: { name: 'integration', include: ['tests/integration/**'] } }
    ]
  }
});
```

**Impact:** defineWorkspace removed in Vitest 4. Configuration fails to load.

---

### [CRITICAL] Removed `poolOptions` nested structure

**Found Instances:** 2

```typescript
poolOptions: {
  threads: {
    maxThreads: 4,
    minThreads: 1,
    singleThread: false
  },
  forks: {
    singleFork: true
  }
}
```

**Research Doc says:** (section "Pool Architecture")

> `poolOptions` flattened to top-level configuration. `maxThreads` and `maxForks` consolidated to `maxWorkers`. `singleThread` and `singleFork` replaced by `maxWorkers: 1, isolate: false`.

**Correct:**

```typescript
export default defineConfig({
  test: {
    pool: 'threads',
    maxWorkers: 4,
    isolate: true
  }
});
```

**Impact:** Nested poolOptions structure invalid in Vitest 4.

---

### [CRITICAL] Removed `maxThreads`/`maxForks`

**Found Instances:** 2

```typescript
maxThreads: 4,
```

**Research Doc says:** (section "Pool Architecture")

> `maxThreads` and `maxForks` consolidated to `maxWorkers`

**Correct:**

```typescript
maxWorkers: 4,
```

**Impact:** Option no longer exists. Use `maxWorkers` at top-level.

---

### [CRITICAL] Removed `singleThread`/`singleFork`

**Found Instances:** 2

```typescript
singleThread: false,
singleFork: true
```

**Research Doc says:** (section "Pool Architecture")

> `singleThread` and `singleFork` replaced by `maxWorkers: 1, isolate: false`

**Correct:**

```typescript
maxWorkers: 1,
isolate: false
```

**Impact:** Options no longer exist in Vitest 4.

---

### [CRITICAL] Removed `poolMatchGlobs`

**Found Instances:** 1

```typescript
poolMatchGlobs: [
  ['**/*.test.ts', 'threads']
],
```

**Research Doc says:** (section "Configuration Deprecations Removed")

> `poolMatchGlobs` and `environmentMatchGlobs` superseded by `projects`

**Correct:**

```typescript
projects: [
  {
    test: {
      include: ['**/*.test.ts'],
      pool: 'threads'
    }
  }
]
```

**Impact:** Option removed. Use `projects` for per-pattern pool configuration.

---

### [CRITICAL] Removed `environmentMatchGlobs`

**Found Instances:** 1

```typescript
environmentMatchGlobs: [
  ['**/*.dom.test.ts', 'jsdom'],
  ['**/*.browser.test.ts', 'jsdom']
],
```

**Research Doc says:** (section "Configuration Deprecations Removed")

> `poolMatchGlobs` and `environmentMatchGlobs` superseded by `projects`

**Correct:**

```typescript
projects: [
  {
    test: {
      include: ['**/*.dom.test.ts', '**/*.browser.test.ts'],
      environment: 'jsdom'
    }
  },
  {
    test: {
      include: ['**/*.test.ts'],
      exclude: ['**/*.dom.test.ts', '**/*.browser.test.ts'],
      environment: 'node'
    }
  }
]
```

**Impact:** Option removed. Use `projects` for per-pattern environment.

---

### [CRITICAL] Removed `minWorkers`/`minThreads`

**Found Instances:** 2

```typescript
minWorkers: 2,
minThreads: 1,
```

**Research Doc says:** (section "Configuration Deprecations Removed")

> `minWorkers` option eliminated

**Correct:**

Remove option entirely. Vitest 4 manages minimum workers automatically.

**Impact:** Option no longer exists and will cause configuration error.

---

### [CRITICAL] Removed `coverage.all`

**Found Instances:** 1

```javascript
coverage: {
  all: true,
  include: ['src/**/*.js']
}
```

**Research Doc says:** (section "Coverage Configuration")

> Removed `coverage.all` and `coverage.extensions` defaults. Must explicitly define `coverage.include` patterns.

**Correct:**

```javascript
coverage: {
  include: ['src/**/*.js']
}
```

**Impact:** Option removed. Use explicit `include` patterns instead.

---

### [CRITICAL] Removed `coverage.extensions`

**Found Instances:** 1

```typescript
coverage: {
  extensions: ['.ts', '.tsx', '.js', '.jsx']
}
```

**Research Doc says:** (section "Coverage Configuration")

> Removed `coverage.all` and `coverage.extensions` defaults. Must explicitly define `coverage.include` patterns.

**Correct:**

```typescript
coverage: {
  include: ['src/**/*.{ts,tsx,js,jsx}']
}
```

**Impact:** Option removed. Extensions inferred from `include` glob patterns.

---

### [CRITICAL] Deprecated `deps.inline` location

**Found Instances:** 1

```javascript
deps: {
  inline: ['problematic-dependency']
}
```

**Research Doc says:** (section "Configuration Deprecations Removed")

> `deps.external`, `deps.inline`, `deps.fallbackCJS` moved under `server.deps`

**Correct:**

```javascript
server: {
  deps: {
    inline: ['problematic-dependency']
  }
}
```

**Impact:** Configuration ignored. Dependencies won't be inlined correctly.

---

### [CRITICAL] Missing browser mode configuration

**Found Instances:** 1

```javascript
export default defineConfig({
  test: {
    environment: 'happy-dom'
  }
});
```

**Research Doc says:** (section "Browser Mode")

> Browser configuration accepts objects instead of strings. Import paths shifted from `@vitest/browser/context` to `vitest/browser`.

**Correct:**

```typescript
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }]
    }
  }
});
```

**Impact:** Browser tests run in DOM emulation instead of real browser.

---

### [CRITICAL] Manual browser API implementation

**Found Instances:** 1

```javascript
const userEvent = {
  async fill(element, value) {
    element.value = value;
    element.dispatchEvent(new Event('input', { bubbles: true }));
  }
};
```

**Research Doc says:** (section "Browser Test Example")

> ```typescript
> import { page, userEvent } from 'vitest/browser';
> ```

**Correct:**

```typescript
import { page, userEvent } from 'vitest/browser';

test('user interaction', async () => {
  await userEvent.fill(page.getByLabelText(/username/i), 'Bob');
});
```

**Impact:** Manual implementations incomplete and don't match Vitest's browser mode behavior.

---

### [HIGH] Missing `coverage.include` patterns

**Found Instances:** 3

```javascript
coverage: {
  provider: 'v8',
  exclude: ['node_modules/**', 'tests/**']
}
```

**Research Doc says:** (section "Coverage Configuration")

> Must explicitly define `coverage.include` patterns

**Correct:**

```javascript
coverage: {
  provider: 'v8',
  include: ['src/**/*.{js,ts,tsx}'],
  exclude: ['node_modules/**', 'tests/**']
}
```

**Impact:** Coverage collection may be incomplete without explicit includes.

---

### [HIGH] Using globals without explicit import

**Found Instances:** 2

```javascript
describe('CartService', () => {
  it('should add item', () => {
    expect(result).toBe(true);
  });
});
```

**Research Doc says:** (section "Globals Configuration")

> Jest has globals enabled by default. Vitest does not. Either enable `globals: true` in config or import explicitly.

**Correct:**

```javascript
import { describe, it, expect } from 'vitest';

describe('CartService', () => {
  it('should add item', () => {
    expect(result).toBe(true);
  });
});
```

**Impact:** Relies on hidden config dependency. Less portable.

---

### [HIGH] Missing browser mode assertions

**Found Instances:** 1

```javascript
const list = container.querySelector('#notification-list');
expect(list).toBeTruthy();
```

**Research Doc says:** (section "Browser Test Example")

> `await expect.element(page.getByText('Hello Bob')).toBeInTheDocument();`

**Correct:**

```javascript
const list = page.getByRole('list');
await expect.element(list).toBeInTheDocument();
```

**Impact:** Missing proper async element assertions. May have race conditions.

---

### [MEDIUM] Not using user-centric locators

**Found Instances:** 2

```javascript
const messageInput = container.querySelector('#message-input');
const sendBtn = container.querySelector('#send-btn');
```

**Research Doc says:** (section "User-Centric Testing")

> Simulate real user behavior: Use Vitest's Interactivity API with `page.getByRole()` and `userEvent`

**Correct:**

```javascript
const messageInput = page.getByLabelText(/message/i);
const sendBtn = page.getByRole('button', { name: /send/i });
```

**Impact:** Tests brittle, tied to implementation details, don't encourage accessibility.

---

### [MEDIUM] Missing default exclusions in coverage

**Found Instances:** 1

```javascript
exclude: [
  'src/**/*.test.js',
  'node_modules/**'
]
```

**Research Doc says:** (section "Default Exclusions")

> Now only excludes `node_modules` and `.git` by default. Previously excluded directories require manual exclusion patterns.

**Correct:**

```javascript
exclude: [
  'src/**/*.test.js',
  '**/node_modules/**',
  '**/dist/**',
  '**/coverage/**',
  '**/__snapshots__/**'
]
```

**Impact:** Coverage may include build artifacts and generated files.

---

### [MEDIUM] Outdated Vitest version

**Found Instances:** 5

```json
"devDependencies": {
  "vitest": "^2.0.0"
}
```

**Research Doc says:** (section "Overview")

> Version: 4.0.10 (latest stable as of Nov 2025)

**Correct:**

```json
"devDependencies": {
  "vitest": "^4.0.10"
}
```

**Impact:** Missing Vitest 4 features, security patches including CVE-2025-24964 fix.

---

### [LOW] Missing performance optimizations

**Found Instances:** 1

```javascript
export default defineConfig({
  test: {
    globals: true
  }
});
```

**Research Doc says:** (section "Advanced Performance Configuration")

> ```typescript
> maxConcurrency: 20,
> pool: 'threads',
> isolate: false,
> deps: { optimizer: { web: { enabled: true } } }
> ```

**Correct:**

```javascript
export default defineConfig({
  test: {
    globals: true,
    pool: 'threads',
    maxConcurrency: 20,
    deps: {
      optimizer: { web: { enabled: true } }
    }
  }
});
```

**Impact:** Suboptimal test execution speed.

---

## Summary

- **Report path:** vitest-4/STRESS-TEST-REPORT.md
- **Total violations:** 24 across 5 agents
- **Top 3 issues:** Pool architecture changes (12), coverage config changes (8), workspace→projects migration (3)
- **Critical findings:** All 5 agents used deprecated Vitest 3.x configuration patterns
- **Research gaps:** Browser mode setup complexity, pool architecture migration path
- **Next steps:** Update configurations to use `projects`, `maxWorkers`, explicit `coverage.include`

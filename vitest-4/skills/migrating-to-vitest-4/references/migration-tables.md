# Migration Tables Reference

## Pool Configuration Migration

### Worker Options

| Vitest 3.x | Vitest 4.x | Notes |
|------------|-----------|-------|
| `maxThreads: 4` | `maxWorkers: 4` | Consolidated option |
| `maxForks: 4` | `maxWorkers: 4` | Same as maxThreads |
| `minThreads: 2` | Removed | No replacement |
| `minForks: 2` | Removed | No replacement |
| `singleThread: true` | `maxWorkers: 1, isolate: false` | Two-option pattern |
| `singleFork: true` | `maxWorkers: 1, isolate: false` | Same as singleThread |
| `poolOptions.threads.singleThread` | `maxWorkers: 1, isolate: false` | Flattened config |
| `poolOptions.forks.singleFork` | `maxWorkers: 1, isolate: false` | Flattened config |

### Nested poolOptions Migration

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    pool: 'forks',
    poolOptions: {
      forks: {
        maxForks: 4,
        minForks: 2,
      },
    },
  },
});
```

**After (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    pool: 'forks',
    maxWorkers: 4,
  },
});
```

## Coverage Configuration Migration

### Coverage Migration Table

| Vitest 3.x | Vitest 4.x | Reason |
|------------|-----------|--------|
| `coverage.ignoreEmptyLines` | Removed | AST-aware remapping is default |
| `coverage.all` | Removed | Use explicit `include` |
| `coverage.extensions` | Removed | Use explicit `include` with patterns |
| `coverage.experimentalAstAwareRemapping` | Removed | Now default behavior |

### Explicit Include Patterns

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
    },
  },
});
```

**After (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/**/*.{ts,tsx}'],
    },
  },
});
```

### Removed Coverage Options

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      ignoreEmptyLines: true,
      all: true,
      extensions: ['.ts', '.tsx'],
      experimentalAstAwareRemapping: true,
    },
  },
});
```

**After (Vitest 4.x):**
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

## Workspace to Projects Migration

### Workspace Migration Table

| Vitest 3.x | Vitest 4.x | Notes |
|------------|-----------|-------|
| `defineWorkspace([...])` | `defineConfig({ test: { projects: [...] } })` | Function change |
| `poolMatchGlobs` | `projects[].test.pool` | Per-project pool |
| `environmentMatchGlobs` | `projects[].test.environment` | Per-project env |

### defineWorkspace to defineConfig

**Before (Vitest 3.x):**
```typescript
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([
  {
    test: {
      name: 'unit',
      include: ['tests/unit/**/*.test.ts'],
      environment: 'node',
    },
  },
  {
    test: {
      name: 'browser',
      include: ['tests/browser/**/*.test.ts'],
      environment: 'jsdom',
    },
  },
]);
```

**After (Vitest 4.x):**
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      {
        test: {
          name: 'unit',
          include: ['tests/unit/**/*.test.ts'],
          environment: 'node',
        },
      },
      {
        test: {
          name: 'browser',
          include: ['tests/browser/**/*.test.ts'],
          environment: 'jsdom',
        },
      },
    ],
  },
});
```

### Match Globs to Projects

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    poolMatchGlobs: [
      ['**/*.node.test.ts', 'threads'],
      ['**/*.browser.test.ts', 'forks'],
    ],
    environmentMatchGlobs: [
      ['**/*.node.test.ts', 'node'],
      ['**/*.browser.test.ts', 'jsdom'],
    ],
  },
});
```

**After (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    projects: [
      {
        test: {
          include: ['**/*.node.test.ts'],
          pool: 'threads',
          environment: 'node',
        },
      },
      {
        test: {
          include: ['**/*.browser.test.ts'],
          pool: 'forks',
          environment: 'jsdom',
        },
      },
    ],
  },
});
```

## Dependency Configuration Migration

### Dependency Migration Table

| Vitest 3.x | Vitest 4.x |
|------------|-----------|
| `deps.inline` | `server.deps.inline` |
| `deps.external` | `server.deps.external` |
| `deps.fallbackCJS` | `server.deps.fallbackCJS` |

### Server Namespace

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    deps: {
      inline: ['vue', 'lodash-es'],
      external: ['aws-sdk'],
      fallbackCJS: true,
    },
  },
});
```

**After (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    server: {
      deps: {
        inline: ['vue', 'lodash-es'],
        external: ['aws-sdk'],
        fallbackCJS: true,
      },
    },
  },
});
```

## Browser Mode Migration

### Browser Migration Table

| Vitest 3.x | Vitest 4.x | Notes |
|------------|-----------|-------|
| `@vitest/browser` package | `@vitest/browser-playwright` or `@vitest/browser-webdriverio` | Separate packages |
| `browser.name: 'chromium'` | `browser.instances: [{ browser: 'chromium' }]` | Array of instances |
| `browser.provider: 'playwright'` | `browser.provider: playwright()` | Function call |
| `@vitest/browser/context` | `vitest/browser` | Import path change |
| `browser.testerScripts` | `browser.testerHtmlPath` | Renamed option |

### Provider Packages

**Before (Vitest 3.x):**
```bash
npm install -D vitest @vitest/browser
```

**After (Vitest 4.x):**
```bash
npm install -D vitest @vitest/browser-playwright
```

Or:
```bash
npm install -D vitest @vitest/browser-webdriverio
```

### Configuration Migration

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    browser: {
      enabled: true,
      name: 'chromium',
      provider: 'playwright',
    },
  },
});
```

**After (Vitest 4.x):**
```typescript
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

### Import Path Migration

**Before (Vitest 3.x):**
```typescript
import { page, userEvent } from '@vitest/browser/context';
```

**After (Vitest 4.x):**
```typescript
import { page, userEvent } from 'vitest/browser';
```

### Multiple Browsers

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    browser: {
      enabled: true,
      name: 'chromium',
      provider: 'playwright',
    },
  },
});
```

**After (Vitest 4.x):**
```typescript
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [
        { browser: 'chromium' },
        { browser: 'firefox' },
        { browser: 'webkit' },
      ],
    },
  },
});
```

## Reporter Migration

### Reporter Migration Table

| Vitest 3.x | Vitest 4.x | Notes |
|------------|-----------|-------|
| `reporters: ['basic']` | `reporters: ['default'], summary: false` | Removed reporter |

### Basic Reporter

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    reporters: ['basic'],
  },
});
```

**After (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    reporters: ['default'],
    summary: false,
  },
});
```

## Module Runner Migration

### Environment Variables

**Before (Vitest 3.x):**
```bash
VITE_NODE_DEPS_MODULE_DIRECTORIES=/custom/path vitest
```

**After (Vitest 4.x):**
```bash
VITEST_MODULE_DIRECTORIES=/custom/path vitest
```

### Custom Environments

**Before (Vitest 3.x):**
```typescript
export default {
  name: 'custom',
  transformMode: 'web',
  setup() {},
};
```

**After (Vitest 4.x):**
```typescript
export default {
  name: 'custom',
  viteEnvironment: 'web',
  setup() {},
};
```

### Removed Entry Points

**Before (Vitest 3.x):**
```typescript
import { execute } from 'vitest/execute';
```

**After (Vitest 4.x):**
The `vitest/execute` entry point no longer exists. Use Vite's Module Runner directly if needed.

## Default Exclusions Change

### Vitest 3.x

Many directories excluded by default:
- `node_modules`
- `.git`
- `dist`
- `build`
- `coverage`
- And many more...

### Vitest 4.x

Only excludes:
- `node_modules`
- `.git`

**Migration:** Add explicit excludes if needed:

```typescript
export default defineConfig({
  test: {
    coverage: {
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        '**/node_modules/**',
        '**/dist/**',
        '**/*.test.ts',
        '**/*.spec.ts',
        '**/test/**',
        '**/tests/**',
      ],
    },
  },
});
```

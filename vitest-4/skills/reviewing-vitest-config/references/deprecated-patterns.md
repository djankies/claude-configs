# Deprecated Patterns Reference

## Pool Options

### Removed Options

- `maxThreads` → Use `maxWorkers`
- `maxForks` → Use `maxWorkers`
- `minThreads` → No replacement
- `minForks` → No replacement
- `singleThread` → Use `maxWorkers: 1, isolate: false`
- `singleFork` → Use `maxWorkers: 1, isolate: false`
- `poolOptions` → Flatten to top-level

### Examples

**Deprecated (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    maxThreads: 4,
    minThreads: 2,
  },
});
```

**Correct (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    maxWorkers: 4,
  },
});
```

**Deprecated (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: true,
      },
    },
  },
});
```

**Correct (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    pool: 'threads',
    maxWorkers: 1,
    isolate: false,
  },
});
```

## Coverage Options

### Removed Options

- `coverage.ignoreEmptyLines` → No longer needed
- `coverage.all` → Use explicit `include`
- `coverage.extensions` → Use explicit `include`
- `coverage.experimentalAstAwareRemapping` → Now default

### Examples

**Deprecated (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      ignoreEmptyLines: true,
      all: true,
      extensions: ['.ts', '.tsx'],
    },
  },
});
```

**Correct (Vitest 4.x):**
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

## Workspace Options

### Removed Options

- `defineWorkspace` → Use `defineConfig` with `projects`
- `poolMatchGlobs` → Use `projects` with `include`
- `environmentMatchGlobs` → Use `projects` with `environment`

### Examples

**Deprecated (Vitest 3.x):**
```typescript
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([
  {
    test: {
      name: 'unit',
      include: ['tests/unit/**/*.test.ts'],
    },
  },
]);
```

**Correct (Vitest 4.x):**
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      {
        test: {
          name: 'unit',
          include: ['tests/unit/**/*.test.ts'],
        },
      },
    ],
  },
});
```

**Deprecated (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    poolMatchGlobs: [
      ['**/*.node.test.ts', 'threads'],
    ],
    environmentMatchGlobs: [
      ['**/*.dom.test.ts', 'jsdom'],
    ],
  },
});
```

**Correct (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    projects: [
      {
        test: {
          include: ['**/*.node.test.ts'],
          pool: 'threads',
        },
      },
      {
        test: {
          include: ['**/*.dom.test.ts'],
          environment: 'jsdom',
        },
      },
    ],
  },
});
```

## Browser Mode Options

### Removed/Changed Options

- `browser.name` → Use `browser.instances`
- `browser.provider: 'playwright'` → Use `browser.provider: playwright()`
- `browser.testerScripts` → Use `browser.testerHtmlPath`
- Package `@vitest/browser` → Use provider-specific packages

### Examples

**Deprecated (Vitest 3.x):**
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

**Correct (Vitest 4.x):**
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

**Deprecated import (Vitest 3.x):**
```typescript
import { page } from '@vitest/browser/context';
```

**Correct import (Vitest 4.x):**
```typescript
import { page } from 'vitest/browser';
```

## Dependency Options

### Moved Options

- `deps.inline` → Use `server.deps.inline`
- `deps.external` → Use `server.deps.external`
- `deps.fallbackCJS` → Use `server.deps.fallbackCJS`

### Examples

**Deprecated (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    deps: {
      inline: ['vue'],
      external: ['aws-sdk'],
    },
  },
});
```

**Correct (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    server: {
      deps: {
        inline: ['vue'],
        external: ['aws-sdk'],
      },
    },
  },
});
```

## Reporter Options

### Removed Options

- `reporters: ['basic']` → Use `reporters: ['default'], summary: false`

### Examples

**Deprecated (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    reporters: ['basic'],
  },
});
```

**Correct (Vitest 4.x):**
```typescript
export default defineConfig({
  test: {
    reporters: ['default'],
    summary: false,
  },
});
```

## Environment Variables

### Renamed Variables

- `VITE_NODE_DEPS_MODULE_DIRECTORIES` → Use `VITEST_MODULE_DIRECTORIES`

### Examples

**Deprecated:**
```bash
VITE_NODE_DEPS_MODULE_DIRECTORIES=/custom/path vitest
```

**Correct:**
```bash
VITEST_MODULE_DIRECTORIES=/custom/path vitest
```

## Module Runner

### Removed Entry Points

- `vitest/execute` → No longer exists

### Examples

**Deprecated (Vitest 3.x):**
```typescript
import { execute } from 'vitest/execute';
```

**Correct (Vitest 4.x):**
Use Vite's Module Runner directly if needed, or remove if not required.

## Custom Environments

### Changed Options

- `transformMode` → Use `viteEnvironment`

### Examples

**Deprecated (Vitest 3.x):**
```typescript
export default {
  name: 'custom',
  transformMode: 'web',
  setup() {},
};
```

**Correct (Vitest 4.x):**
```typescript
export default {
  name: 'custom',
  viteEnvironment: 'web',
  setup() {},
};
```

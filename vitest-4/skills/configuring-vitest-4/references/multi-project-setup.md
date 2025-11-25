# Multi-Project Configuration Reference

## Projects Array

Use `projects` for multiple test configurations:

```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

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
          name: 'integration',
          include: ['tests/integration/**/*.test.ts'],
          environment: 'node',
          testTimeout: 30000,
        },
      },
      {
        test: {
          name: 'browser',
          include: ['tests/browser/**/*.test.ts'],
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

## Project-Specific Settings

Each project can override test configuration:

```typescript
export default defineConfig({
  test: {
    globals: true,
    projects: [
      {
        test: {
          name: 'unit',
          include: ['tests/unit/**/*.test.ts'],
          globals: false,
          setupFiles: ['./tests/unit/setup.ts'],
        },
      },
      {
        test: {
          name: 'e2e',
          include: ['tests/e2e/**/*.test.ts'],
          testTimeout: 60000,
          setupFiles: ['./tests/e2e/setup.ts'],
        },
      },
    ],
  },
});
```

## Multi-Environment Testing

```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

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
          name: 'component',
          include: ['tests/component/**/*.test.tsx'],
          environment: 'jsdom',
        },
      },
      {
        test: {
          name: 'browser',
          include: ['tests/browser/**/*.test.ts'],
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

## Per-Project Environments

Use projects for different environments:

```typescript
export default defineConfig({
  test: {
    projects: [
      {
        test: {
          include: ['**/*.node.test.ts'],
          environment: 'node',
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

## Deprecated Workspace Options

**Never use these (removed in Vitest 4.0):**

| Vitest 3.x | Vitest 4.x | Migration |
|-----------|-----------|-----------|
| `defineWorkspace` | `defineConfig` with `projects` | Function change |
| `poolMatchGlobs` | Use `projects` with `include` | Per-project config |
| `environmentMatchGlobs` | Use `projects` with `environment` | Per-project config |

## Project Configuration Patterns

### By Test Type

```typescript
projects: [
  {
    test: {
      name: 'unit',
      include: ['**/*.unit.test.ts'],
      environment: 'node',
      maxWorkers: 4,
    },
  },
  {
    test: {
      name: 'integration',
      include: ['**/*.integration.test.ts'],
      environment: 'node',
      maxWorkers: 2,
      testTimeout: 30000,
    },
  },
  {
    test: {
      name: 'e2e',
      include: ['**/*.e2e.test.ts'],
      environment: 'node',
      maxWorkers: 1,
      testTimeout: 60000,
    },
  },
]
```

### By Directory

```typescript
projects: [
  {
    test: {
      name: 'api',
      include: ['tests/api/**/*.test.ts'],
      setupFiles: ['./tests/api/setup.ts'],
    },
  },
  {
    test: {
      name: 'ui',
      include: ['tests/ui/**/*.test.ts'],
      setupFiles: ['./tests/ui/setup.ts'],
      environment: 'jsdom',
    },
  },
]
```

### By Framework

```typescript
projects: [
  {
    test: {
      name: 'react',
      include: ['src/**/*.react.test.tsx'],
      environment: 'jsdom',
      setupFiles: ['./vitest.react.setup.ts'],
    },
  },
  {
    test: {
      name: 'vue',
      include: ['src/**/*.vue.test.ts'],
      environment: 'jsdom',
      setupFiles: ['./vitest.vue.setup.ts'],
    },
  },
]
```

## Running Specific Projects

### CLI

```bash
vitest --project unit
vitest --project integration
vitest --project unit --project e2e
```

### Programmatic

```typescript
import { startVitest } from 'vitest/node';

await startVitest('test', [], {
  project: ['unit'],
});
```

## Project Inheritance

### Shared Configuration

```typescript
const sharedConfig = {
  globals: true,
  restoreMocks: true,
};

export default defineConfig({
  test: {
    ...sharedConfig,
    projects: [
      {
        test: {
          ...sharedConfig,
          name: 'unit',
          include: ['**/*.test.ts'],
        },
      },
    ],
  },
});
```

### Extract Common Config

```typescript
const baseTest = {
  globals: true,
  clearMocks: true,
  restoreMocks: true,
};

export default defineConfig({
  test: {
    projects: [
      {
        test: {
          ...baseTest,
          name: 'unit',
          include: ['tests/unit/**/*.test.ts'],
        },
      },
      {
        test: {
          ...baseTest,
          name: 'integration',
          include: ['tests/integration/**/*.test.ts'],
          testTimeout: 30000,
        },
      },
    ],
  },
});
```

## Advanced Multi-Project Patterns

### Conditional Projects

```typescript
const projects = [
  {
    test: {
      name: 'unit',
      include: ['tests/unit/**/*.test.ts'],
    },
  },
];

if (process.env.RUN_E2E) {
  projects.push({
    test: {
      name: 'e2e',
      include: ['tests/e2e/**/*.test.ts'],
      testTimeout: 60000,
    },
  });
}

export default defineConfig({
  test: { projects },
});
```

### Cross-Browser Testing

```typescript
import { playwright } from '@vitest/browser-playwright';

const browsers = ['chromium', 'firefox', 'webkit'];

export default defineConfig({
  test: {
    projects: browsers.map((browser) => ({
      test: {
        name: `browser-${browser}`,
        include: ['tests/browser/**/*.test.ts'],
        browser: {
          enabled: true,
          provider: playwright(),
          instances: [{ browser }],
        },
      },
    })),
  },
});
```

### Monorepo Workspace

```typescript
import { defineConfig } from 'vitest/config';
import { glob } from 'glob';

const packages = glob.sync('packages/*/vitest.config.ts');

export default defineConfig({
  test: {
    projects: packages.map((pkg) => pkg.replace('/vitest.config.ts', '')),
  },
});
```

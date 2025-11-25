# Coverage Configuration Reference

## Required Settings

Coverage in Vitest 4.x **requires explicit include patterns**:

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'json'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['**/node_modules/**', '**/dist/**', '**/*.test.ts'],
    },
  },
});
```

## V8 Provider (Recommended)

Fast coverage with AST-aware remapping:

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'clover', 'json'],
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

**Advantages:**
- Fast execution
- Accurate source mapping
- AST-aware remapping built-in

**Disadvantages:**
- May include compiler-generated code
- Less compatible with older tools

## Istanbul Provider

Alternative provider for compatibility:

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      reporter: ['text', 'html'],
      include: ['src/**/*.{ts,tsx}'],
    },
  },
});
```

**Advantages:**
- Wide tool compatibility
- Industry standard
- Predictable behavior

**Disadvantages:**
- Slower than V8
- Requires manual source mapping

## Reporter Options

### Available Reporters

```typescript
coverage: {
  reporter: [
    'text',           // Console output
    'html',           // HTML report
    'json',           // JSON output
    'json-summary',   // Summary JSON
    'lcov',           // LCOV format
    'clover',         // Clover XML
    'cobertura',      // Cobertura XML
    'text-summary',   // Summary to console
  ],
}
```

### Multiple Reporters

```typescript
coverage: {
  reporter: ['text', 'html', 'json'],
  reportsDirectory: './coverage',
}
```

### Custom Reporter Directory

```typescript
coverage: {
  reporter: ['html'],
  reportsDirectory: './test-coverage',
}
```

## Threshold Configuration

### Basic Thresholds

```typescript
coverage: {
  thresholds: {
    lines: 80,
    functions: 80,
    branches: 80,
    statements: 80,
  },
}
```

### Per-File Thresholds

```typescript
coverage: {
  thresholds: {
    perFile: true,
    lines: 80,
    functions: 80,
    branches: 80,
    statements: 80,
  },
}
```

### Auto-Update Thresholds

```typescript
coverage: {
  thresholds: {
    autoUpdate: true,
    lines: 80,
  },
}
```

## Include/Exclude Patterns

### Include Patterns

```typescript
coverage: {
  include: [
    'src/**/*.ts',
    'src/**/*.tsx',
    'lib/**/*.js',
  ],
}
```

### Exclude Patterns

```typescript
coverage: {
  include: ['src/**/*.{ts,tsx}'],
  exclude: [
    '**/node_modules/**',
    '**/dist/**',
    '**/build/**',
    '**/*.test.ts',
    '**/*.spec.ts',
    '**/test/**',
    '**/tests/**',
    '**/*.d.ts',
    '**/types/**',
  ],
}
```

### Exclude After Remap

```typescript
coverage: {
  include: ['src/**/*.{ts,tsx}'],
  excludeAfterRemap: true,
  exclude: ['**/*.test.ts'],
}
```

## Deprecated Coverage Options

**Never use these (removed in Vitest 4.0):**

| Deprecated Option | Replacement | Reason |
|------------------|-------------|---------|
| `coverage.ignoreEmptyLines` | None needed | AST-aware remapping is default |
| `coverage.all` | `coverage.include` | Explicit patterns required |
| `coverage.extensions` | `coverage.include` | Use glob patterns |
| `coverage.experimentalAstAwareRemapping` | None needed | Now default behavior |

## Coverage Workflow Integration

### Running Coverage

```bash
vitest --coverage
```

### CI/CD Integration

```bash
vitest --coverage --run
```

### Watch Mode with Coverage

```bash
vitest --coverage --watch
```

## Advanced Configuration

### Clean on Re-run

```typescript
coverage: {
  clean: true,
  cleanOnRerun: true,
}
```

### Skip Files

```typescript
coverage: {
  skipFull: false,
  include: ['src/**/*.ts'],
}
```

### Watermarks

```typescript
coverage: {
  watermarks: {
    statements: [50, 80],
    functions: [50, 80],
    branches: [50, 80],
    lines: [50, 80],
  },
}
```

## Common Patterns

### TypeScript Project

```typescript
coverage: {
  provider: 'v8',
  reporter: ['text', 'html', 'json-summary'],
  include: ['src/**/*.{ts,tsx}'],
  exclude: [
    '**/*.test.ts',
    '**/*.spec.ts',
    '**/*.d.ts',
  ],
  thresholds: {
    lines: 80,
    functions: 80,
    branches: 80,
    statements: 80,
  },
}
```

### Monorepo Package

```typescript
coverage: {
  provider: 'v8',
  reporter: ['text', 'json-summary'],
  include: ['packages/*/src/**/*.ts'],
  reportsDirectory: './coverage',
}
```

### Library with Strict Coverage

```typescript
coverage: {
  provider: 'v8',
  reporter: ['text', 'lcov'],
  include: ['src/**/*.ts'],
  exclude: ['**/*.test.ts', 'src/types/**'],
  thresholds: {
    perFile: true,
    lines: 90,
    functions: 90,
    branches: 85,
    statements: 90,
    autoUpdate: true,
  },
}
```

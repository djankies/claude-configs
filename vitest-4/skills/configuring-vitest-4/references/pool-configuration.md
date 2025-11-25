# Pool Configuration Reference

## Worker Management

### maxWorkers Configuration

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'forks',
    maxWorkers: 4,
    isolate: true,
    fileParallelism: true,
  },
});
```

### Available Pools

- **forks** (default) - Node.js child processes
  - Best for: General purpose testing
  - Provides: Process isolation
  - Performance: Good

- **threads** - Worker threads
  - Best for: Fast unit tests
  - Provides: Shared memory
  - Performance: Faster than forks

- **vmThreads** - Isolated VM threads
  - Best for: Maximum isolation
  - Provides: VM-level isolation
  - Performance: Slower but safest

### Single-Threaded Mode

For sequential test execution:

```typescript
export default defineConfig({
  test: {
    maxWorkers: 1,
    isolate: false,
  },
});
```

**When to use:**
- Tests that can't run in parallel
- Tests with shared global state
- Debugging race conditions

## Deprecated Options (Vitest 3.x)

**Never use these (removed in Vitest 4.0):**

| Deprecated Option | Replacement | Notes |
|------------------|-------------|-------|
| `maxThreads` | `maxWorkers` | Consolidated option |
| `maxForks` | `maxWorkers` | Same as maxThreads |
| `singleThread` | `maxWorkers: 1, isolate: false` | Two-option pattern |
| `singleFork` | `maxWorkers: 1, isolate: false` | Same as singleThread |
| `poolOptions` | Flatten to top-level | No nesting |
| `minThreads` | No replacement | Removed entirely |
| `minForks` | No replacement | Removed entirely |

## Pool Selection Guide

### Use forks when:
- Default choice for most projects
- Need process isolation
- Testing Node.js APIs

### Use threads when:
- Fast unit tests needed
- Memory efficiency important
- Tests don't modify process state

### Use vmThreads when:
- Maximum isolation required
- Testing code that modifies globals
- Security-critical testing

## Performance Optimization

### Fast Unit Tests

```typescript
export default defineConfig({
  test: {
    pool: 'threads',
    isolate: false,
    fileParallelism: true,
    maxWorkers: 4,
  },
});
```

**Trade-offs:**
- Faster execution
- Less isolation
- May expose test interdependence

### Maximum Isolation

```typescript
export default defineConfig({
  test: {
    pool: 'vmThreads',
    isolate: true,
    fileParallelism: true,
    maxWorkers: 2,
  },
});
```

**Trade-offs:**
- Slower execution
- Maximum safety
- Best for integration tests

## Worker Count Tuning

### CPU-Bound Tests

```typescript
export default defineConfig({
  test: {
    maxWorkers: Math.max(1, os.cpus().length - 1),
  },
});
```

### I/O-Bound Tests

```typescript
export default defineConfig({
  test: {
    maxWorkers: os.cpus().length * 2,
  },
});
```

### CI Environment

```typescript
export default defineConfig({
  test: {
    maxWorkers: process.env.CI ? 2 : 4,
  },
});
```

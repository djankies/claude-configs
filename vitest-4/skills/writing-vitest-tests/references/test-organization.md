# Test Organization Reference

## Test File Structure

### Basic Test

```typescript
import { test, expect } from 'vitest';

test('adds numbers correctly', () => {
  expect(1 + 2).toBe(3);
});
```

### Test Suite with describe

```typescript
import { describe, test, expect } from 'vitest';

describe('Math utilities', () => {
  test('adds numbers', () => {
    expect(1 + 2).toBe(3);
  });

  test('subtracts numbers', () => {
    expect(5 - 2).toBe(3);
  });
});
```

### Alternative: it instead of test

```typescript
import { describe, it, expect } from 'vitest';

describe('Math utilities', () => {
  it('adds numbers', () => {
    expect(1 + 2).toBe(3);
  });

  it('subtracts numbers', () => {
    expect(5 - 2).toBe(3);
  });
});
```

## Lifecycle Hooks

### Setup and Teardown

```typescript
import { describe, test, expect, beforeEach, afterEach, beforeAll, afterAll } from 'vitest';

describe('User service', () => {
  beforeAll(() => {
  });

  afterAll(() => {
  });

  beforeEach(() => {
  });

  afterEach(() => {
  });

  test('creates user', () => {
    expect(true).toBe(true);
  });
});
```

### Hook Execution Order

1. `beforeAll` - Once before all tests in suite
2. `beforeEach` - Before each test
3. Test execution
4. `afterEach` - After each test
5. `afterAll` - Once after all tests in suite

## Test Modifiers

### Skip Tests

```typescript
test.skip('skipped test', () => {
});
```

Skip entire suite:

```typescript
describe.skip('skipped suite', () => {
  test('will not run', () => {
  });
});
```

### Run Only Specific Tests

```typescript
test.only('run only this test', () => {
});
```

Run only this suite:

```typescript
describe.only('run only this suite', () => {
  test('will run', () => {
  });
});
```

### Mark Test as TODO

```typescript
test.todo('implement later');
```

### Expected Failures

```typescript
test.fails('should fail', () => {
  expect(1).toBe(2);
});
```

### Concurrent Tests

```typescript
test.concurrent('runs in parallel', async () => {
  await someAsyncOperation();
});
```

### Conditional Tests

```typescript
test.skipIf(process.env.CI)('skip in CI', () => {
});

test.runIf(!process.env.CI)('run only locally', () => {
});
```

## Parameterized Tests

### test.each with Arrays

```typescript
test.each([
  [1, 1, 2],
  [1, 2, 3],
  [2, 1, 3],
])('add(%i, %i) -> %i', (a, b, expected) => {
  expect(a + b).toBe(expected);
});
```

### test.each with Objects

```typescript
test.each([
  { a: 1, b: 1, expected: 2 },
  { a: 1, b: 2, expected: 3 },
  { a: 2, b: 1, expected: 3 },
])('$a + $b should equal $expected', ({ a, b, expected }) => {
  expect(a + b).toBe(expected);
});
```

### test.for Alternative

```typescript
test.for([
  [1, 1, 2],
  [1, 2, 3],
])('add(%i, %i) -> %i', ([a, b, expected]) => {
  expect(a + b).toBe(expected);
});
```

## Nested Describes

```typescript
describe('UserService', () => {
  describe('createUser', () => {
    test('creates user with valid data', () => {
    });

    test('throws error for invalid data', () => {
    });
  });

  describe('getUser', () => {
    test('returns user when found', () => {
    });

    test('returns null when not found', () => {
    });
  });
});
```

## Shared Setup

```typescript
describe('Database operations', () => {
  let db;

  beforeEach(async () => {
    db = await connectDb();
  });

  afterEach(async () => {
    await db.close();
  });

  test('inserts record', async () => {
    await db.insert('users', { name: 'Bob' });
    const user = await db.findOne('users', { name: 'Bob' });
    expect(user).toBeDefined();
  });
});
```

## Fixtures

### Basic Fixture

```typescript
import { test as baseTest } from 'vitest';

const test = baseTest.extend({
  todos: async ({}, use) => {
    const todos = [];
    await use(todos);
    todos.length = 0;
  },
});

test('adds item', ({ todos }) => {
  todos.push('item');
  expect(todos).toHaveLength(1);
});
```

### Automatic Fixture

```typescript
const test = baseTest.extend({
  setupDb: [
    async ({}, use) => {
      await connectDb();
      await use();
      await disconnectDb();
    },
    { auto: true },
  ],
});

test('uses db', () => {
});
```

### File-Scoped Fixture

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

## Async Testing

### Async/Await

```typescript
test('fetches data', async () => {
  const data = await fetchData();
  expect(data).toBeDefined();
});
```

### Promise Resolves

```typescript
test('promise resolves', async () => {
  await expect(fetchData()).resolves.toBe('data');
});
```

### Promise Rejects

```typescript
test('promise rejects', async () => {
  await expect(fetchBadData()).rejects.toThrow('error');
});
```

### Multiple Async Operations

```typescript
test('multiple operations', async () => {
  const [result1, result2] = await Promise.all([
    operation1(),
    operation2(),
  ]);

  expect(result1).toBe('expected1');
  expect(result2).toBe('expected2');
});
```

## Common Patterns

### Testing Async Functions

```typescript
test('async operation', async () => {
  const result = await asyncOperation();
  expect(result).toBe('expected');
});
```

### Testing Callbacks

```typescript
test('callback called', (done) => {
  callWithCallback((result) => {
    expect(result).toBe('expected');
    done();
  });
});
```

### Testing Promises

```typescript
test('promise resolves', () => {
  return fetchData().then((data) => {
    expect(data).toBe('expected');
  });
});
```

### Testing Event Emitters

```typescript
test('emits event', () => {
  const listener = vi.fn();
  emitter.on('event', listener);

  emitter.emit('event', 'data');

  expect(listener).toHaveBeenCalledWith('data');
});
```

## Best Practices

1. **One assertion per test**: Keep tests focused
2. **Descriptive test names**: Explain what is being tested
3. **AAA pattern**: Arrange, Act, Assert
4. **Clean up mocks**: Restore after each test
5. **Test behavior, not implementation**: Focus on public API
6. **Avoid test interdependence**: Tests should run independently
7. **Use fixtures for shared setup**: Reduce duplication

## Test Organization Strategies

### By Feature

```
tests/
├── user/
│   ├── create.test.ts
│   ├── update.test.ts
│   └── delete.test.ts
├── product/
│   ├── create.test.ts
│   └── list.test.ts
```

### By Type

```
tests/
├── unit/
│   ├── utils.test.ts
│   └── helpers.test.ts
├── integration/
│   ├── api.test.ts
│   └── database.test.ts
└── e2e/
    └── flows.test.ts
```

### By Module

```
src/
├── user/
│   ├── user.ts
│   └── user.test.ts
├── product/
│   ├── product.ts
│   └── product.test.ts
```

## Common Mistakes

1. **Not awaiting async operations**: Use `async/await`
2. **Not cleaning up mocks**: Use `afterEach` or config options
3. **Testing implementation details**: Test public behavior
4. **Overly complex tests**: Break into smaller tests
5. **Not using parameterized tests**: Reduce duplication
6. **Shared state between tests**: Tests should be isolated
7. **Not using fixtures**: Duplicating setup code

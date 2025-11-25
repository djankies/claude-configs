# Mocking Reference

## Mock Functions

### Basic Mock

```typescript
import { vi } from 'vitest';

const mockFn = vi.fn();

mockFn('arg1', 'arg2');

expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');
expect(mockFn).toHaveBeenCalledTimes(1);
```

### Mock Return Values

```typescript
const mockFn = vi.fn();
mockFn.mockReturnValue('result');

expect(mockFn()).toBe('result');
```

### Mock Return Value Once

```typescript
const mockFn = vi.fn();
mockFn.mockReturnValueOnce('first').mockReturnValueOnce('second');

expect(mockFn()).toBe('first');
expect(mockFn()).toBe('second');
expect(mockFn()).toBeUndefined();
```

### Mock Implementation

```typescript
const mockFn = vi.fn();
mockFn.mockImplementation((a, b) => a + b);

expect(mockFn(1, 2)).toBe(3);
```

### Mock Implementation Once

```typescript
const mockFn = vi.fn();
mockFn.mockImplementationOnce(() => 'first').mockImplementationOnce(() => 'second');

expect(mockFn()).toBe('first');
expect(mockFn()).toBe('second');
```

### Mock Resolved/Rejected Promises

```typescript
const mockFn = vi.fn();
mockFn.mockResolvedValue('data');

const result = await mockFn();
expect(result).toBe('data');
```

```typescript
const mockFn = vi.fn();
mockFn.mockRejectedValue(new Error('failed'));

await expect(mockFn()).rejects.toThrow('failed');
```

## Module Mocking

### Basic Module Mock

```typescript
vi.mock('./module', () => ({
  method: vi.fn(),
  constant: 'mocked',
}));
```

### Partial Module Mock

```typescript
vi.mock(import('./module'), async (importOriginal) => {
  const mod = await importOriginal();
  return {
    ...mod,
    specificMethod: vi.fn(),
  };
});
```

### Mock Default Export

```typescript
vi.mock('./module', () => ({
  default: vi.fn(),
}));
```

### Automatic Mocks

```typescript
vi.mock('./module');

import { method } from './module';
expect(vi.isMockFunction(method)).toBe(true);
```

### Unmock Module

```typescript
vi.unmock('./module');
```

## Spying

### Spy on Existing Method

```typescript
import { vi } from 'vitest';
import * as exports from './module';

const spy = vi.spyOn(exports, 'method');

exports.method('arg');

expect(spy).toHaveBeenCalledWith('arg');
```

### Spy with Mock Implementation

```typescript
vi.spyOn(exports, 'method').mockImplementation(() => 'mocked');

expect(exports.method()).toBe('mocked');
```

### Restore Original

```typescript
const spy = vi.spyOn(exports, 'method');

spy.mockRestore();
```

## Timer Mocking

### Fake Timers

```typescript
import { vi } from 'vitest';

vi.useFakeTimers();

const callback = vi.fn();
setTimeout(callback, 1000);

vi.advanceTimersByTime(1000);
expect(callback).toHaveBeenCalled();

vi.useRealTimers();
```

### Advance to Next Timer

```typescript
vi.useFakeTimers();

setTimeout(() => console.log('1000ms'), 1000);
setTimeout(() => console.log('500ms'), 500);

vi.advanceTimersToNextTimer();
```

### Run All Timers

```typescript
vi.useFakeTimers();

setTimeout(() => console.log('first'), 100);
setTimeout(() => console.log('second'), 200);

vi.runAllTimers();
```

### Clear All Timers

```typescript
vi.clearAllTimers();
```

## Date Mocking

### Set System Time

```typescript
import { vi } from 'vitest';

vi.setSystemTime(new Date(2022, 0, 1));

expect(Date.now()).toBe(new Date(2022, 0, 1).getTime());

vi.useRealTimers();
```

### Advance System Time

```typescript
vi.useFakeTimers();
vi.setSystemTime(new Date(2022, 0, 1));

vi.advanceTimersByTime(1000 * 60 * 60 * 24);

expect(new Date().getDate()).toBe(2);
```

## Global Mocking

### Stub Global Variables

```typescript
vi.stubGlobal('__VERSION__', '1.0.0');

expect(__VERSION__).toBe('1.0.0');

vi.unstubAllGlobals();
```

### Stub Environment Variables

```typescript
vi.stubEnv('NODE_ENV', 'test');

expect(process.env.NODE_ENV).toBe('test');

vi.unstubAllEnvs();
```

## Mock Cleanup

### Per-Test Cleanup

```typescript
import { afterEach, vi } from 'vitest';

afterEach(() => {
  vi.restoreAllMocks();
});
```

### Config-Based Cleanup

```typescript
export default defineConfig({
  test: {
    restoreMocks: true,
    clearMocks: true,
    mockReset: false,
  },
});
```

**Options:**
- `clearMocks` - Clear mock history
- `mockReset` - Reset mocks to initial state
- `restoreMocks` - Restore original implementation

## Mock Utilities

### Check if Mock

```typescript
expect(vi.isMockFunction(mockFn)).toBe(true);
```

### Get Mock Name

```typescript
const mockFn = vi.fn().mockName('myMock');
expect(mockFn.getMockName()).toBe('myMock');
```

### Mock Results

```typescript
const mockFn = vi.fn();
mockFn.mockReturnValue('result');

mockFn();

expect(mockFn.mock.results[0]).toEqual({
  type: 'return',
  value: 'result',
});
```

### Mock Calls

```typescript
const mockFn = vi.fn();
mockFn('arg1', 'arg2');

expect(mockFn.mock.calls[0]).toEqual(['arg1', 'arg2']);
expect(mockFn.mock.lastCall).toEqual(['arg1', 'arg2']);
```

### Mock Instances

```typescript
const MockClass = vi.fn();
const instance = new MockClass();

expect(MockClass.mock.instances[0]).toBe(instance);
```

## Advanced Mocking

### Mock with Context

```typescript
const mockFn = vi.fn(function(this: any, value: number) {
  return this.base + value;
});

expect(mockFn.call({ base: 10 }, 5)).toBe(15);
```

### Mock Generator

```typescript
const mockGen = vi.fn(function* () {
  yield 1;
  yield 2;
  yield 3;
});

const gen = mockGen();
expect(gen.next().value).toBe(1);
expect(gen.next().value).toBe(2);
```

### Mock Async Generator

```typescript
const mockAsyncGen = vi.fn(async function* () {
  yield 1;
  yield 2;
  yield 3;
});

const gen = mockAsyncGen();
expect((await gen.next()).value).toBe(1);
```

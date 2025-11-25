# Assertions Reference

## Basic Matchers

```typescript
expect(value).toBe(expected);
expect(value).toEqual(expected);
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();
```

## Numeric Matchers

```typescript
expect(value).toBeGreaterThan(3);
expect(value).toBeGreaterThanOrEqual(3);
expect(value).toBeLessThan(5);
expect(value).toBeLessThanOrEqual(5);
expect(value).toBeCloseTo(0.3, 5);
expect(value).toBeNaN();
```

## String Matchers

```typescript
expect(string).toMatch(/pattern/);
expect(string).toMatch('substring');
expect(string).toContain('substring');
expect(string).toHaveLength(10);
```

## Array Matchers

```typescript
expect(array).toContain(item);
expect(array).toHaveLength(3);
expect(array).toContainEqual({ a: 1 });
```

## Object Matchers

```typescript
expect(object).toHaveProperty('key');
expect(object).toHaveProperty('key', 'value');
expect(object).toMatchObject({ key: 'value' });
expect(object).toStrictEqual({ key: 'value' });
```

## toBe vs toEqual

### toBe: Reference Equality (===)

```typescript
const obj = { a: 1 };
expect(obj).toBe(obj);
```

Use for:
- Primitives
- Same reference checks
- Identity comparisons

### toEqual: Deep Equality

```typescript
expect({ a: 1 }).toEqual({ a: 1 });
expect([1, 2]).toEqual([1, 2]);
```

Use for:
- Objects
- Arrays
- Deep comparisons

### toStrictEqual: Strict Deep Equality

```typescript
expect({ a: 1 }).toStrictEqual({ a: 1 });
```

Use for:
- Exact match including undefined values
- No extra properties
- Strict type checking

## Error Testing

### Expect Throw

```typescript
expect(() => {
  throw new Error('failed');
}).toThrow('failed');

expect(() => {
  throw new Error('failed');
}).toThrow(/fail/);
```

### Expect Throw with Class

```typescript
expect(() => {
  throw new TypeError('wrong type');
}).toThrow(TypeError);
```

### Async Error Testing

```typescript
await expect(async () => {
  throw new Error('failed');
}).rejects.toThrow('failed');
```

## Promise Assertions

### Resolves

```typescript
await expect(fetchData()).resolves.toBe('data');
await expect(fetchData()).resolves.toEqual({ id: 1 });
```

### Rejects

```typescript
await expect(fetchBadData()).rejects.toThrow('error');
await expect(fetchBadData()).rejects.toEqual(new Error('error'));
```

## Snapshot Testing

### Basic Snapshot

```typescript
expect(result).toMatchSnapshot();
```

### Inline Snapshot

```typescript
expect(result).toMatchInlineSnapshot('"expected output"');
```

### File Snapshot

```typescript
await expect(result).toMatchFileSnapshot('./output.html');
```

### Update Snapshots

**Watch mode:** Press `u`

**CLI:** `vitest -u`

## Negation

```typescript
expect(value).not.toBe(expected);
expect(value).not.toEqual(expected);
expect(array).not.toContain(item);
```

## Mock Assertions

### toHaveBeenCalled

```typescript
expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(1);
```

### toHaveBeenCalledWith

```typescript
expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');
expect(mockFn).toHaveBeenLastCalledWith('arg');
expect(mockFn).toHaveBeenNthCalledWith(1, 'arg');
```

### toHaveReturned

```typescript
expect(mockFn).toHaveReturned();
expect(mockFn).toHaveReturnedTimes(1);
expect(mockFn).toHaveReturnedWith('value');
expect(mockFn).toHaveLastReturnedWith('value');
```

## Type Assertions

```typescript
expect(value).toBeTypeOf('string');
expect(value).toBeTypeOf('number');
expect(value).toBeTypeOf('boolean');
expect(value).toBeInstanceOf(MyClass);
```

## Custom Matchers

```typescript
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling;
    return {
      pass,
      message: () => `expected ${received} to be within range ${floor} - ${ceiling}`,
    };
  },
});

expect(100).toBeWithinRange(90, 110);
```

## Asymmetric Matchers

```typescript
expect({ a: 1, b: 2 }).toEqual({
  a: 1,
  b: expect.any(Number),
});

expect(['apple', 'banana']).toEqual([
  expect.stringContaining('app'),
  expect.stringMatching(/ban/),
]);

expect(value).toEqual(expect.arrayContaining([1, 2]));
expect(value).toEqual(expect.objectContaining({ a: 1 }));
```

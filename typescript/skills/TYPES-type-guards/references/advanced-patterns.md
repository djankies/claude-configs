# Advanced Type Guard Patterns

This reference provides detailed examples of advanced type guard patterns.

## Pattern 1: Optional Property Guard

```typescript
interface Config {
  apiKey: string;
  timeout?: number;
}

function isConfig(value: unknown): value is Config {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const obj = value as Record<string, unknown>;

  if (typeof obj.apiKey !== "string") {
    return false;
  }

  if ("timeout" in obj && typeof obj.timeout !== "number") {
    return false;
  }

  return true;
}
```

## Pattern 2: Array Element Guard

```typescript
function everyElementIs<T>(
  arr: unknown[],
  guard: (item: unknown) => item is T
): arr is T[] {
  return arr.every(guard);
}

const data: unknown = ["a", "b", "c"];

if (Array.isArray(data) && everyElementIs(data, (item): item is string => typeof item === "string")) {
  const lengths = data.map(str => str.length);
}
```

## Pattern 3: Tuple Guard

```typescript
function isTuple<T, U>(
  value: unknown,
  guard1: (item: unknown) => item is T,
  guard2: (item: unknown) => item is U
): value is [T, U] {
  return (
    Array.isArray(value) &&
    value.length === 2 &&
    guard1(value[0]) &&
    guard2(value[1])
  );
}

const isStringNumberPair = (value: unknown): value is [string, number] =>
  isTuple(
    value,
    (item): item is string => typeof item === "string",
    (item): item is number => typeof item === "number"
  );
```

## Pattern 4: Record Guard

```typescript
function isStringRecord(value: unknown): value is Record<string, string> {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  return Object.values(value).every(val => typeof val === "string");
}
```

## Pattern 5: Enum Guard

```typescript
enum Status {
  Active = "active",
  Inactive = "inactive",
  Pending = "pending"
}

function isStatus(value: unknown): value is Status {
  return Object.values(Status).includes(value as Status);
}
```

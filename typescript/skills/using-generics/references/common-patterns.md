# Common Generic Patterns

## Array Operations

Generic array utilities maintain type safety while providing reusable functionality:

```typescript
function last<T>(arr: T[]): T | undefined {
  return arr[arr.length - 1];
}

function first<T>(arr: T[]): T | undefined {
  return arr[0];
}

function chunk<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

function flatten<T>(arr: T[][]): T[] {
  return arr.reduce((acc, item) => acc.concat(item), []);
}

function unique<T>(arr: T[]): T[] {
  return Array.from(new Set(arr));
}

function partition<T>(arr: T[], predicate: (item: T) => boolean): [T[], T[]] {
  const truthy: T[] = [];
  const falsy: T[] = [];

  for (const item of arr) {
    if (predicate(item)) {
      truthy.push(item);
    } else {
      falsy.push(item);
    }
  }

  return [truthy, falsy];
}
```

## Object Utilities

Type-safe object manipulation:

```typescript
function pick<T extends object, K extends keyof T>(
  obj: T,
  ...keys: K[]
): Pick<T, K> {
  const result = {} as Pick<T, K>;
  for (const key of keys) {
    result[key] = obj[key];
  }
  return result;
}

function omit<T extends object, K extends keyof T>(
  obj: T,
  ...keys: K[]
): Omit<T, K> {
  const result = { ...obj };
  for (const key of keys) {
    delete result[key];
  }
  return result as Omit<T, K>;
}

function keys<T extends object>(obj: T): (keyof T)[] {
  return Object.keys(obj) as (keyof T)[];
}

function values<T extends object>(obj: T): T[keyof T][] {
  return Object.values(obj) as T[keyof T][];
}

function entries<T extends object>(obj: T): [keyof T, T[keyof T]][] {
  return Object.entries(obj) as [keyof T, T[keyof T]][];
}

function mapValues<T extends object, U>(
  obj: T,
  fn: (value: T[keyof T], key: keyof T) => U
): Record<keyof T, U> {
  const result = {} as Record<keyof T, U>;

  for (const key in obj) {
    result[key] = fn(obj[key], key);
  }

  return result;
}
```

## Promise Utilities

Generic async operations:

```typescript
async function retry<T>(
  fn: () => Promise<T>,
  maxAttempts: number
): Promise<T> {
  let lastError: Error;

  for (let i = 0; i < maxAttempts; i++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
    }
  }

  throw lastError!;
}

async function timeout<T>(
  promise: Promise<T>,
  ms: number
): Promise<T> {
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => reject(new Error("Timeout")), ms);
  });

  return Promise.race([promise, timeoutPromise]);
}

async function sequence<T>(
  promises: (() => Promise<T>)[]
): Promise<T[]> {
  const results: T[] = [];

  for (const promiseFn of promises) {
    results.push(await promiseFn());
  }

  return results;
}
```

## Class Generics

Generic classes for reusable data structures:

```typescript
class Container<T> {
  constructor(private value: T) {}

  getValue(): T {
    return this.value;
  }

  setValue(value: T): void {
    this.value = value;
  }

  map<U>(fn: (value: T) => U): Container<U> {
    return new Container(fn(this.value));
  }

  flatMap<U>(fn: (value: T) => Container<U>): Container<U> {
    return fn(this.value);
  }
}

class Result<T, E = Error> {
  private constructor(
    private readonly value?: T,
    private readonly error?: E
  ) {}

  static ok<T, E = Error>(value: T): Result<T, E> {
    return new Result(value, undefined);
  }

  static err<T, E = Error>(error: E): Result<T, E> {
    return new Result(undefined, error);
  }

  isOk(): this is Result<T, never> {
    return this.value !== undefined;
  }

  isErr(): this is Result<never, E> {
    return this.error !== undefined;
  }

  unwrap(): T {
    if (this.error !== undefined) {
      throw this.error;
    }
    return this.value!;
  }

  map<U>(fn: (value: T) => U): Result<U, E> {
    if (this.error !== undefined) {
      return Result.err(this.error);
    }
    return Result.ok(fn(this.value!));
  }
}
```

## Builder Pattern

Fluent API with type safety:

```typescript
class QueryBuilder<T extends object> {
  private filters: Array<(item: T) => boolean> = [];
  private sortFn?: (a: T, b: T) => number;
  private limitValue?: number;

  where<K extends keyof T>(key: K, value: T[K]): this {
    this.filters.push(item => item[key] === value);
    return this;
  }

  whereFn(predicate: (item: T) => boolean): this {
    this.filters.push(predicate);
    return this;
  }

  sort<K extends keyof T>(key: K, direction: "asc" | "desc" = "asc"): this {
    this.sortFn = (a, b) => {
      const aVal = a[key];
      const bVal = b[key];

      if (aVal < bVal) return direction === "asc" ? -1 : 1;
      if (aVal > bVal) return direction === "asc" ? 1 : -1;
      return 0;
    };
    return this;
  }

  limit(n: number): this {
    this.limitValue = n;
    return this;
  }

  execute(data: T[]): T[] {
    let result = data.filter(item =>
      this.filters.every(filter => filter(item))
    );

    if (this.sortFn) {
      result = result.sort(this.sortFn);
    }

    if (this.limitValue !== undefined) {
      result = result.slice(0, this.limitValue);
    }

    return result;
  }
}

const users = [
  { id: 1, name: "Alice", active: true, age: 30 },
  { id: 2, name: "Bob", active: false, age: 25 },
  { id: 3, name: "Charlie", active: true, age: 35 }
];

const active = new QueryBuilder<typeof users[0]>()
  .where("active", true)
  .sort("age", "desc")
  .limit(5)
  .execute(users);
```

## Event Emitter Pattern

Type-safe event handling:

```typescript
type EventMap = Record<string, any>;

class TypedEventEmitter<Events extends EventMap> {
  private listeners: {
    [K in keyof Events]?: Array<(data: Events[K]) => void>;
  } = {};

  on<K extends keyof Events>(
    event: K,
    listener: (data: Events[K]) => void
  ): this {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event]!.push(listener);
    return this;
  }

  emit<K extends keyof Events>(event: K, data: Events[K]): void {
    const listeners = this.listeners[event];
    if (listeners) {
      for (const listener of listeners) {
        listener(data);
      }
    }
  }

  off<K extends keyof Events>(
    event: K,
    listener: (data: Events[K]) => void
  ): this {
    const listeners = this.listeners[event];
    if (listeners) {
      this.listeners[event] = listeners.filter(l => l !== listener);
    }
    return this;
  }
}

interface AppEvents {
  userLogin: { userId: string; timestamp: number };
  userLogout: { userId: string };
  dataUpdated: { id: string; changes: Record<string, unknown> };
}

const emitter = new TypedEventEmitter<AppEvents>();

emitter.on("userLogin", (data) => {
  console.log(`User ${data.userId} logged in at ${data.timestamp}`);
});
```

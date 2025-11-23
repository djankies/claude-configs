# Detailed Generic Examples

## Deep Partial Implementation

The `DeepPartial` type recursively makes all properties optional, including nested objects:

```typescript
type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

interface DatabaseConfig {
  host: string;
  port: number;
  credentials: {
    username: string;
    password: string;
    ssl: {
      enabled: boolean;
      cert: string;
    };
  };
}

const partialConfig: DeepPartial<DatabaseConfig> = {
  host: "localhost",
  credentials: {
    username: "admin",
    ssl: {
      enabled: true
    }
  }
};

function mergeConfig(
  defaults: DatabaseConfig,
  override: DeepPartial<DatabaseConfig>
): DatabaseConfig {
  return {
    ...defaults,
    ...override,
    credentials: {
      ...defaults.credentials,
      ...override.credentials,
      ssl: {
        ...defaults.credentials.ssl,
        ...override.credentials?.ssl
      }
    }
  };
}
```

## Conditional Return Types

Use conditional types to change return types based on input:

```typescript
type ParseResult<T extends "json" | "text"> =
  T extends "json" ? unknown : string;

function parse<T extends "json" | "text">(
  response: Response,
  type: T
): Promise<ParseResult<T>> {
  if (type === "json") {
    return response.json() as Promise<ParseResult<T>>;
  }
  return response.text() as Promise<ParseResult<T>>;
}

async function example() {
  const json = await parse(response, "json");

  const text = await parse(response, "text");
}

type QueryResult<T extends boolean> = T extends true
  ? Array<{ id: string; data: unknown }>
  : { id: string; data: unknown } | undefined;

function query<Multiple extends boolean = false>(
  sql: string,
  multiple?: Multiple
): QueryResult<Multiple> {
  if (multiple) {
    return [] as QueryResult<Multiple>;
  }
  return undefined as QueryResult<Multiple>;
}

const single = query("SELECT * FROM users WHERE id = 1");
const many = query("SELECT * FROM users", true);
```

## Filter by Type Pattern

Extract only properties of a specific type from an object:

```typescript
type FilterByType<T, U> = {
  [P in keyof T as T[P] extends U ? P : never]: T[P];
};

interface User {
  id: string;
  name: string;
  age: number;
  active: boolean;
  createdAt: Date;
  score: number;
  tags: string[];
}

type StringProps = FilterByType<User, string>;

type NumberProps = FilterByType<User, number>;

type FilterByValueType<T, U> = Pick<
  T,
  {
    [K in keyof T]: T[K] extends U ? K : never;
  }[keyof T]
>;

type BooleanProps = FilterByValueType<User, boolean>;
```

## Unwrap Nested Promises

Extract the final resolved type from nested Promises:

```typescript
type Awaited<T> = T extends Promise<infer U>
  ? Awaited<U>
  : T;

type A = Awaited<Promise<string>>;

type B = Awaited<Promise<Promise<number>>>;

type C = Awaited<Promise<Promise<Promise<boolean>>>>;

async function deepFetch(): Promise<Promise<{ data: string }>> {
  return Promise.resolve(
    Promise.resolve({ data: "nested" })
  );
}

type DeepFetchResult = Awaited<ReturnType<typeof deepFetch>>;
```

## Extract Function Parameters

Get parameter types from function signatures:

```typescript
type Parameters<T> = T extends (...args: infer P) => any ? P : never;

function processUser(id: string, name: string, age: number): void {
  console.log(id, name, age);
}

type ProcessUserParams = Parameters<typeof processUser>;

function callWithParams<F extends (...args: any[]) => any>(
  fn: F,
  ...args: Parameters<F>
): ReturnType<F> {
  return fn(...args);
}

callWithParams(processUser, "123", "Alice", 30);

type FirstParameter<T> = T extends (first: infer F, ...args: any[]) => any
  ? F
  : never;

type FirstParam = FirstParameter<typeof processUser>;
```

## Constructable Types

Work with classes and constructors generically:

```typescript
interface Constructable<T> {
  new (...args: any[]): T;
}

function create<T>(Constructor: Constructable<T>): T {
  return new Constructor();
}

function createWithArgs<T, Args extends any[]>(
  Constructor: new (...args: Args) => T,
  ...args: Args
): T {
  return new Constructor(...args);
}

class User {
  constructor(public name: string, public age: number) {}
}

const user1 = create(User);
const user2 = createWithArgs(User, "Alice", 30);

function inject<T>(
  Constructor: Constructable<T>,
  dependencies: Map<Constructable<any>, any>
): T {
  const args = getDependencies(Constructor, dependencies);
  return new Constructor(...args);
}
```

## Mapped Type Transformations

Complex property transformations using mapped types:

```typescript
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface Person {
  name: string;
  age: number;
}

type PersonGetters = Getters<Person>;

type Setters<T> = {
  [K in keyof T as `set${Capitalize<string & K>}`]: (value: T[K]) => void;
};

type PersonSetters = Setters<Person>;

type ReadonlyKeys<T> = {
  [K in keyof T]-?: T[K] extends { readonly [key: string]: any }
    ? K
    : never;
}[keyof T];

type WritableKeys<T> = {
  [K in keyof T]-?: T[K] extends { readonly [key: string]: any }
    ? never
    : K;
}[keyof T];
```

## Type-Safe Event Handlers

Generic event handler system with strict typing:

```typescript
interface EventHandlers<T> {
  onCreate?: (item: T) => void;
  onUpdate?: (item: T, changes: Partial<T>) => void;
  onDelete?: (id: string) => void;
}

class Store<T extends { id: string }> {
  private items = new Map<string, T>();
  private handlers: EventHandlers<T> = {};

  setHandlers(handlers: EventHandlers<T>): void {
    this.handlers = handlers;
  }

  create(item: T): void {
    this.items.set(item.id, item);
    this.handlers.onCreate?.(item);
  }

  update(id: string, changes: Partial<T>): void {
    const item = this.items.get(id);
    if (item) {
      const updated = { ...item, ...changes };
      this.items.set(id, updated);
      this.handlers.onUpdate?.(updated, changes);
    }
  }

  delete(id: string): void {
    this.items.delete(id);
    this.handlers.onDelete?.(id);
  }
}

interface Todo {
  id: string;
  title: string;
  completed: boolean;
}

const todoStore = new Store<Todo>();

todoStore.setHandlers({
  onCreate: (todo) => console.log("Created:", todo.title),
  onUpdate: (todo, changes) => console.log("Updated:", changes),
  onDelete: (id) => console.log("Deleted:", id)
});
```

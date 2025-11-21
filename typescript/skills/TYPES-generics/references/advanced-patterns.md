# Advanced Generic Patterns

## Recursive Generics

Use recursive generics to apply transformations deeply through nested object structures:

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object
    ? DeepReadonly<T[P]>
    : T[P];
};

interface Config {
  database: {
    host: string;
    credentials: {
      username: string;
      password: string;
    };
  };
}

const config: DeepReadonly<Config> = {
  database: {
    host: "localhost",
    credentials: {
      username: "admin",
      password: "secret"
    }
  }
};
```

## Variadic Tuple Types

TypeScript 4.0+ supports variadic tuple types for precise array concatenation:

```typescript
function concat<T extends readonly unknown[], U extends readonly unknown[]>(
  arr1: T,
  arr2: U
): [...T, ...U] {
  return [...arr1, ...arr2];
}

const result = concat([1, 2], ["a", "b"]);

function curry<T extends unknown[], U extends unknown[], R>(
  fn: (...args: [...T, ...U]) => R,
  ...first: T
): (...args: U) => R {
  return (...rest: U) => fn(...first, ...rest);
}
```

## Template Literal Types

Combine string literals with generics for type-safe string manipulation:

```typescript
type EventName<T extends string> = `on${Capitalize<T>}`;

type ClickEvent = EventName<"click">;
type HoverEvent = EventName<"hover">;

type HTTPMethod = "GET" | "POST" | "PUT" | "DELETE";
type Endpoint<M extends HTTPMethod, P extends string> = `${M} ${P}`;

type UserEndpoint = Endpoint<"GET", "/users/:id">;
```

## Branded Types

Create nominal types in TypeScript's structural type system:

```typescript
type Brand<K, T> = K & { __brand: T };

type UserId = Brand<string, "UserId">;
type EmailAddress = Brand<string, "Email">;
type OrderId = Brand<string, "OrderId">;

function sendEmail(to: EmailAddress, from: EmailAddress): void {
  console.log(`Sending email from ${from} to ${to}`);
}

function getUser(id: UserId): void {
  console.log(`Fetching user ${id}`);
}

const email = "user@example.com" as EmailAddress;
const userId = "user-123" as UserId;

sendEmail(email, email);
getUser(userId);
```

## Distributive Conditional Types

Conditional types distribute over unions when the checked type is a naked type parameter:

```typescript
type ToArray<T> = T extends any ? T[] : never;

type Nums = ToArray<number | string>;

type NonNullable<T> = T extends null | undefined ? never : T;

type SafeString = NonNullable<string | null | undefined>;
```

## Mapped Type Modifiers

Use `+`, `-`, `readonly`, and `?` modifiers in mapped types:

```typescript
type Mutable<T> = {
  -readonly [P in keyof T]: T[P];
};

type Required<T> = {
  [P in keyof T]-?: T[P];
};

type ReadonlyPartial<T> = {
  +readonly [P in keyof T]+?: T[P];
};
```

## Inference in Conditional Types

Use `infer` to extract types within conditional types:

```typescript
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

type ArrayElement<T> = T extends (infer E)[] ? E : never;

type PromiseValue<T> = T extends Promise<infer V> ? V : T;

type FirstParameter<T> = T extends (first: infer F, ...args: any[]) => any
  ? F
  : never;
```

## Higher-Kinded Types (Simulation)

While TypeScript doesn't have true HKTs, you can simulate them:

```typescript
interface Functor<F> {
  map<A, B>(fa: HKT<F, A>, f: (a: A) => B): HKT<F, B>;
}

interface HKT<F, A> {
  _F: F;
  _A: A;
}

interface ArrayF {}

type ArrayHKT<A> = HKT<ArrayF, A> & A[];

const arrayFunctor: Functor<ArrayF> = {
  map: (fa, f) => fa.map(f)
};
```

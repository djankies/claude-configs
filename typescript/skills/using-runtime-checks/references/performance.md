# Validation Performance Optimization

## Schema Reuse

**BAD: Creating schemas repeatedly**
```typescript
function validateUser(data: unknown) {
  const UserSchema = z.object({
    id: z.string(),
    name: z.string()
  });
  return UserSchema.parse(data);
}
```

**GOOD: Reusing schemas**
```typescript
const UserSchema = z.object({
  id: z.string(),
  name: z.string()
});

function validateUser(data: unknown) {
  return UserSchema.parse(data);
}
```

## Boundary Validation

Validate once at system boundaries, not internally:

```typescript
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data: unknown = await response.json();

  return UserSchema.parse(data);
}

function processUser(user: User) {
  const fullName = formatName(user);
  return fullName;
}
```

## Lazy Schema Definition

For schemas with circular dependencies:

```typescript
const CategorySchema: z.ZodType<Category> = z.lazy(() => z.object({
  id: z.string(),
  name: z.string(),
  parent: CategorySchema.optional()
}));
```

## Selective Validation

Validate only what's needed:

```typescript
const FullUserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
  profile: z.object({
    bio: z.string(),
    avatar: z.string().url()
  }),
  settings: z.object({
    theme: z.enum(["light", "dark"]),
    notifications: z.boolean()
  })
});

const BasicUserSchema = FullUserSchema.pick({
  id: true,
  name: true,
  email: true
});
```

## Batch Validation

For arrays, validate the array once rather than each item:

```typescript
const UsersSchema = z.array(UserSchema);

async function fetchAllUsers(): Promise<User[]> {
  const response = await fetch("/api/users");
  const data: unknown = await response.json();

  return UsersSchema.parse(data);
}
```

## Early Validation

Fail fast on critical fields:

```typescript
const CriticalFirstSchema = z.object({
  apiKey: z.string().uuid(),
  timestamp: z.number()
}).strict();

const FullRequestSchema = CriticalFirstSchema.extend({
  payload: z.unknown()
});
```

## Caching Parsed Results

```typescript
const schemaCache = new WeakMap<object, User>();

function getCachedUser(data: unknown): User {
  if (typeof data === "object" && data !== null) {
    const cached = schemaCache.get(data);
    if (cached) return cached;
  }

  const user = UserSchema.parse(data);

  if (typeof data === "object" && data !== null) {
    schemaCache.set(data, user);
  }

  return user;
}
```

## Avoiding Redundant Validation

```typescript
class UserService {
  private validated = new WeakSet<object>();

  async processUser(data: unknown): Promise<void> {
    if (typeof data !== "object" || data === null) {
      throw new Error("Invalid data");
    }

    if (!this.validated.has(data)) {
      UserSchema.parse(data);
      this.validated.add(data);
    }

    const user = data as User;
  }
}
```

## Performance Monitoring

```typescript
async function validateWithMetrics<T>(
  data: unknown,
  schema: z.ZodType<T>,
  name: string
): Promise<T> {
  const start = performance.now();

  try {
    const result = schema.parse(data);
    const duration = performance.now() - start;

    metrics.record(`validation.${name}.success`, duration);
    return result;
  } catch (error) {
    const duration = performance.now() - start;
    metrics.record(`validation.${name}.failure`, duration);
    throw error;
  }
}
```

## Alternative Libraries for Performance

For maximum performance in hot paths:

**TypeBox** (compile-time optimized):
```typescript
import { Type, Static } from "@sinclair/typebox";
import { Value } from "@sinclair/typebox/value";

const UserType = Type.Object({
  id: Type.String(),
  name: Type.String(),
  email: Type.String({ format: "email" })
});

type User = Static<typeof UserType>;

const user = Value.Parse(UserType, data);
```

**Valibot** (smaller bundle size):
```typescript
import * as v from "valibot";

const UserSchema = v.object({
  id: v.string(),
  name: v.string(),
  email: v.pipe(v.string(), v.email())
});

type User = v.InferOutput<typeof UserSchema>;
```

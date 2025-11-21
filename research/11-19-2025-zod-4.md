# Zod 4 Research

## Overview

- **Version**: 4.1.12 (Latest Stable)
- **Purpose in Project**: TypeScript-first schema validation library with static type inference
- **Official Documentation**: https://zod.dev/
- **GitHub Repository**: https://github.com/colinhacks/zod
- **NPM Package**: https://www.npmjs.com/package/zod
- **Last Updated**: 2025-11-19

## Installation

### Package Managers

```bash
npm install zod
```

```bash
yarn add zod
```

```bash
pnpm add zod
```

```bash
bun add zod
```

### Upgrading to Zod 4

```bash
npm install zod@^4.0.0
```

### Alternative Distributions

**Zod Mini** (Lightweight, tree-shakable variant):

```bash
npm install @zod/mini
```

**JSR Registry**:

```bash
# Available as @zod/zod on jsr.io
```

### Requirements

- **TypeScript**: v5.5 or later
- **tsconfig.json**: Must enable `"strict": true`

### Bundle Sizes

| Distribution     | Gzipped Size | Use Case                          |
| ---------------- | ------------ | --------------------------------- |
| Zod 3            | 12.47kb      | Legacy version                    |
| Zod 4 (standard) | 5.36kb       | Standard usage                    |
| Zod 4 Mini       | 1.88kb       | Performance-critical environments |

## Core Concepts

### Zero Dependencies

Zod has no external dependencies, making it lightweight and reducing the risk of dependency conflicts.

### TypeScript-First Design

Schemas are defined in a TypeScript-native way, with automatic static type inference. No need to define types separately.

### Immutable API

All methods return new schema instances rather than mutating existing ones, ensuring predictable behavior.

### Cross-Platform

Works in Node.js, Deno, Bun, and all modern browsers (no legacy browser support required).

### Runtime Validation

Unlike TypeScript's compile-time checking, Zod validates data at runtime, making it essential for validating external data sources.

## Configuration

### Global Configuration

```typescript
import * as z from 'zod';

z.config({
  customError: (iss) => 'Globally modified error',
  reportInput: true,
});
```

### Internationalization

```typescript
import { en, es, fr, ja, zh } from 'zod/locales';

z.config(en());
z.config(z.locales.es());
```

Supports 40+ locales including:

- English (en)
- Spanish (es)
- French (fr)
- German (de)
- Japanese (ja)
- Chinese Simplified (zh)
- Arabic (ar)
- And many more

### Registry for Metadata

```typescript
const myRegistry = z.registry<{ title: string; description: string }>();
const emailSchema = z.string().email();
myRegistry.add(emailSchema, {
  title: 'Email',
  description: 'User email address',
});
```

Global registry with `.meta()`:

```typescript
z.string().meta({
  id: 'email_address',
  title: 'Email address',
  description: 'Provide your email',
});
```

## Usage Patterns

### Basic Schema Definition

```typescript
import * as z from 'zod';

const User = z.object({
  name: z.string(),
  age: z.number(),
  email: z.string().email(),
});
```

### Parsing Data (Throws on Error)

```typescript
const data = User.parse({
  name: 'Alice',
  age: 30,
  email: 'alice@example.com',
});
```

### Safe Parsing (No Exceptions)

```typescript
const result = User.safeParse(input);

if (result.success) {
  console.log(result.data);
} else {
  console.error(result.error);
}
```

### Type Inference

```typescript
type User = z.infer<typeof User>;

type UserInput = z.input<typeof User>;

type UserOutput = z.output<typeof User>;
```

### Async Validation

```typescript
await schema.parseAsync(data);

const result = await schema.safeParseAsync(data);
```

## Advanced Patterns

### Object Schemas

#### Basic Objects

```typescript
const Person = z.object({
  name: z.string(),
  age: z.number(),
});
```

#### Strict Objects (Reject Unknown Keys)

```typescript
const StrictPerson = z.strictObject({
  name: z.string(),
  age: z.number(),
});
```

#### Loose Objects (Allow Unknown Keys)

```typescript
const LoosePerson = z.looseObject({
  name: z.string(),
  age: z.number(),
});
```

#### Extending Objects

```typescript
const Employee = Person.extend({
  employeeId: z.string(),
  department: z.string(),
});
```

#### Picking Fields

```typescript
const NameOnly = Person.pick({ name: true });
```

#### Omitting Fields

```typescript
const WithoutAge = Person.omit({ age: true });
```

#### Partial (All Optional)

```typescript
const PartialPerson = Person.partial();
```

#### Required (All Required)

```typescript
const RequiredPerson = OptionalPerson.required();
```

#### Catchall (Validate Unknown Keys)

```typescript
const PersonWithExtras = Person.catchall(z.string());
```

#### Passthrough (Allow Unknown Keys Without Validation)

```typescript
const PersonPassthrough = Person.passthrough();
```

### Array Schemas

```typescript
const StringArray = z.array(z.string());

const NumberArray = z.array(z.number()).min(1).max(10).length(5);
```

### Array of Objects

```typescript
const Users = z.array(
  z.object({
    name: z.string(),
    email: z.string().email(),
  })
);
```

### Tuple Schemas

```typescript
const Coordinates = z.tuple([z.number(), z.number()]);

const MixedTuple = z.tuple([z.string(), z.number(), z.boolean()]);
```

### Record Schemas

```typescript
const StringRecord = z.record(z.string(), z.string());

const NumberRecord = z.record(z.string(), z.number());
```

### Map and Set Schemas

```typescript
const UserMap = z.map(z.string(), User);

const NumberSet = z.set(z.number());
```

### Union Schemas

```typescript
const StringOrNumber = z.union([z.string(), z.number()]);
```

### Discriminated Unions

```typescript
const Success = z.object({
  status: z.literal('success'),
  value: z.string(),
});

const Error = z.object({
  status: z.literal('error'),
  message: z.string(),
});

const Result = z.discriminatedUnion('status', [Success, Error]);
```

Usage with type narrowing:

```typescript
const result = Result.parse(data);

switch (result.status) {
  case 'success':
    console.log(result.value);
    break;
  case 'error':
    console.error(result.message);
    break;
}
```

### Nested Discriminated Unions

```typescript
const BaseError = z.object({
  status: z.literal('error'),
  timestamp: z.string(),
});

const MyResult = z.discriminatedUnion('status', [
  z.object({ status: z.literal('success'), data: z.string() }),
  z.discriminatedUnion('code', [
    BaseError.extend({ code: z.literal(400) }),
    BaseError.extend({ code: z.literal(401) }),
  ]),
]);
```

### Intersection Schemas

```typescript
const Named = z.object({ name: z.string() });
const Aged = z.object({ age: z.number() });

const Person = z.intersection(Named, Aged);
```

### Recursive Schemas

```typescript
const Category = z.object({
  name: z.string(),
  get subcategories() {
    return z.array(Category);
  },
});

type Category = z.infer<typeof Category>;
```

### Lazy Schemas (For Complex Recursion)

```typescript
const Node = z.lazy(() =>
  z.object({
    value: z.string(),
    children: z.array(Node),
  })
);
```

## Primitive Types

### Strings

```typescript
z.string();
z.string().min(5);
z.string().max(10);
z.string().length(8);
z.string().regex(/^\d+$/);
z.string().startsWith('hello');
z.string().endsWith('world');
z.string().includes('foo');
```

### String Transformations (Zod 4)

```typescript
z.string().trim();
z.string().toLowerCase();
z.string().toUpperCase();
```

### Specialized String Formats (Top-Level in v4)

```typescript
z.email();
z.url();
z.uuid();
z.uuidv4();
z.ipv4();
z.ipv6();
z.base64();
z.jwt();
z.iso.datetime();
z.hash('sha256');
```

### Email with Custom Patterns

```typescript
z.email({ pattern: z.regexes.html5Email });
z.email({ pattern: z.regexes.rfc5322Email });
z.email({ pattern: z.regexes.unicodeEmail });
```

### Template Literal Types (v4)

```typescript
const hello = z.templateLiteral(['hello, ', z.string()]);

const css = z.templateLiteral([z.number(), z.enum(['px', 'em'])]);
```

### Numbers

```typescript
z.number();
z.number().gt(5);
z.number().gte(5);
z.number().lt(10);
z.number().lte(10);
z.number().positive();
z.number().negative();
z.number().nonnegative();
z.number().nonpositive();
z.number().multipleOf(5);
```

### Number Format Schemas (v4)

```typescript
z.int();
z.int32();
z.uint32();
z.int64();
z.uint64();
z.float32();
```

### BigInt

```typescript
z.bigint();
z.bigint().gt(100n);
z.bigint().gte(100n);
z.bigint().lt(1000n);
z.bigint().lte(1000n);
z.bigint().positive();
z.bigint().negative();
z.bigint().nonnegative();
z.bigint().nonpositive();
z.bigint().multipleOf(10n);
```

### Boolean

```typescript
z.boolean();
```

### String Boolean Coercion (v4)

```typescript
const strbool = z.stringbool();
strbool.parse('true');
strbool.parse('yes');
strbool.parse('false');
strbool.parse('no');
```

### Dates

```typescript
z.date();
z.date().min(new Date('2020-01-01'));
z.date().max(new Date('2025-12-31'));
```

### Symbol

```typescript
z.symbol();
```

### Undefined and Null

```typescript
z.undefined();
z.null();
```

### File Validation (v4)

```typescript
const fileSchema = z.file();
fileSchema.min(10_000);
fileSchema.max(1_000_000);
fileSchema.mime(['image/png', 'image/jpeg']);
```

## Coercion

```typescript
z.coerce.string();
z.coerce.number();
z.coerce.boolean();
z.coerce.bigint();
z.coerce.date();
```

Example:

```typescript
const coercedInt = z.coerce.number();
coercedInt.parse('42');
```

## Type Modifiers

### Optional

```typescript
z.string().optional();
```

### Nullable

```typescript
z.string().nullable();
```

### Nullish (null or undefined)

```typescript
z.string().nullish();
```

## Default Values

### Static Default

```typescript
z.string().default('default value');
z.number().default(0);
```

### Dynamic Default

```typescript
const randomDefault = z.number().default(() => Math.random());
```

### Prefault (Parsed Default)

```typescript
z.string().prefault(() => 'default');
```

## Catch (Fallback on Error)

```typescript
const numberWithCatch = z.number().catch(42);
numberWithCatch.parse('invalid');
```

### Dynamic Catch

```typescript
const numberWithRandomCatch = z.number().catch((ctx) => {
  console.log(ctx.error);
  return Math.random();
});
```

## Transformations

### Basic Transform

```typescript
const stringToNumber = z.string().transform((val) => val.length);

type Input = z.input<typeof stringToNumber>;
type Output = z.output<typeof stringToNumber>;
```

### Chaining Transforms

```typescript
const schema = z
  .string()
  .transform((val) => val.trim())
  .transform((val) => val.toLowerCase())
  .transform((val) => val.length);
```

### Overwrite (Non-Type-Changing Transforms in v4)

```typescript
z.number()
  .overwrite((val) => val ** 2)
  .max(100);

z.string().trim();
z.string().toLowerCase();
z.string().toUpperCase();
```

### Preprocess

```typescript
const coercedInt = z.preprocess((val) => {
  if (typeof val === 'string') {
    return Number.parseInt(val);
  }
  return val;
}, z.int());
```

### Codecs (Bidirectional Transforms - v4)

```typescript
const stringToDate = z.codec(z.iso.datetime(), z.date(), {
  decode: (isoString) => new Date(isoString),
  encode: (date) => date.toISOString(),
});

stringToDate.decode('2025-08-21T20:59:45.500Z');
stringToDate.encode(new Date());
```

#### Async Codecs

```typescript
z.codec(inputSchema, outputSchema, {
  decode: async (val) => await fetchData(val),
  encode: async (val) => await serializeData(val),
});
```

#### Safe Codecs

```typescript
stringToDate.safeDecode(data);
stringToDate.safeEncode(data);
```

## Refinements & Custom Validation

### Basic Refinement

```typescript
const passwordSchema = z.string().refine((val) => /[A-Z]/.test(val), {
  message: 'Password must contain at least one uppercase letter',
});
```

### Multiple Refinements

```typescript
const passwordSchema = z
  .string()
  .refine((val) => val.length >= 8, 'Too short')
  .refine((val) => /[A-Z]/.test(val), 'Missing uppercase')
  .refine((val) => /[0-9]/.test(val), 'Missing number');
```

### Refinement with Custom Error Path

```typescript
z.object({
  password: z.string(),
  confirm: z.string(),
}).refine((data) => data.password === data.confirm, {
  message: "Passwords don't match",
  path: ['confirm'],
});
```

### SuperRefine (Multiple Issues)

```typescript
const UniqueStringArray = z.array(z.string()).superRefine((val, ctx) => {
  if (val.length > 3) {
    ctx.addIssue({
      code: 'too_big',
      maximum: 3,
      inclusive: true,
      message: 'Too many items',
    });
  }
  if (val.length !== new Set(val).size) {
    ctx.addIssue({
      code: 'custom',
      message: 'No duplicates allowed.',
    });
  }
});
```

### Async Refinements

```typescript
const checkUsernameAvailability = async (username: string): Promise<boolean> => {
  const res = await fetch(`/api/check-username?username=${username}`);
  const data = await res.json();
  return data.available;
};

const userSchema = z.object({
  username: z
    .string()
    .min(1, 'Username is required')
    .refine(async (username) => {
      return await checkUsernameAvailability(username);
    }, 'Username is not available'),
});

await userSchema.parseAsync(data);
```

### Async SuperRefine

```typescript
const registerSchema = z
  .object({
    email: z.string().email(),
    password: z.string().min(7),
    confirm: z.string(),
  })
  .superRefine(async ({ password, confirm, email }, ctx) => {
    const emailExists = await checkEmailExists(email);

    if (emailExists) {
      ctx.addIssue({
        code: 'custom',
        message: 'The email already exists',
        path: ['email'],
      });
    }

    if (password !== confirm) {
      ctx.addIssue({
        code: 'custom',
        message: 'Passwords do not match',
        path: ['confirm'],
      });
    }
  });
```

### Abort Early

```typescript
z.string().min(5, {
  error: 'Too short',
  abort: true,
});
```

## Branded Types (Nominal Typing)

```typescript
const EmailAddress = z.string().email().brand<'EmailAddress'>();
type EmailAddress = z.infer<typeof EmailAddress>;

const Price = z.number().positive().brand<'Price'>();
type Price = z.infer<typeof Price>;
```

Usage:

```typescript
function sendEmail(to: EmailAddress) {}

const email = EmailAddress.parse('user@example.com');
sendEmail(email);
```

### Custom Brands with Type Guards

```typescript
const isUserId = (val: string): val is string & { __brand: 'UserId' } => {
  return /^user_\d+$/.test(val);
};

const UserId = z.string().min(1).refine(isUserId);
```

## Readonly Types

```typescript
const ReadonlyUser = User.readonly();
type ReadonlyUser = z.infer<typeof ReadonlyUser>;
```

## Literal Values

### Single Literal

```typescript
const TRUE = z.literal(true);
const HELLO = z.literal('hello');
const ZERO = z.literal(0);
```

### Multiple Literals (v4)

```typescript
const httpCodes = z.literal([200, 201, 202, 204, 206]);
```

## Enums

### Native TypeScript Enum

```typescript
enum Color {
  Red = 'red',
  Green = 'green',
  Blue = 'blue',
}

const ColorSchema = z.nativeEnum(Color);
```

### Zod Enum

```typescript
const ColorEnum = z.enum(['red', 'green', 'blue']);
type Color = z.infer<typeof ColorEnum>;

ColorEnum.enum.red;
ColorEnum.options;
```

## Function Schemas

```typescript
const addFunc = z.function().args(z.number(), z.number()).returns(z.number());

const add = addFunc.implement((a, b) => a + b);

add(1, 2);
```

### With Error Handling

```typescript
const fetchUser = z.function().args(z.string()).returns(z.promise(User));
```

## Custom Schemas

```typescript
const CustomType = z.custom<MyType>((val) => {
  return val instanceof MyType;
});
```

## Promises

```typescript
const promiseSchema = z.promise(z.string());

await promiseSchema.parse(Promise.resolve('hello'));
```

## Any and Unknown

```typescript
z.any();
z.unknown();
```

## Never and Void

```typescript
z.never();
z.void();
```

## Error Handling

### Error Structure

```typescript
const result = schema.safeParse(data);

if (!result.success) {
  result.error.issues.forEach((issue) => {
    console.log(issue.code);
    console.log(issue.message);
    console.log(issue.path);
  });
}
```

### Error Customization (v4)

#### Inline Error Messages

```typescript
z.string({ error: 'Not a string!' });
z.string().min(5, { error: 'Too short!' });
z.email({ error: 'Invalid email format' });
```

#### Dynamic Error Messages

```typescript
z.string({
  error: (iss) => (iss.input === undefined ? 'Field is required.' : 'Invalid input.'),
});
```

#### Error Maps with Context

```typescript
z.string({
  error: (iss) => {
    if (iss.code === 'invalid_type') return 'Expected string';
    if (iss.code === 'too_small') return `Minimum: ${iss.minimum}`;
    return undefined;
  },
});
```

### Error Precedence

From highest to lowest priority:

1. Schema-level error (hard-coded into schema)
2. Per-parse error map (passed into `.parse()` method)
3. Global error map (passed into `z.config()`)
4. Locale error map

### Per-Parse Error Customization

```typescript
schema.parse(data, {
  error: (iss) => 'Custom error',
  reportInput: true,
});
```

### Global Error Map

```typescript
z.config({
  customError: (iss) => 'Globally modified error',
});
```

### Pretty-Printing Errors (v4)

```typescript
try {
  schema.parse(data);
} catch (error) {
  console.log(z.prettifyError(error));
}
```

### Error Formatting

#### Format Method

```typescript
const result = schema.safeParse(data);

if (!result.success) {
  const formatted = result.error.format();
}
```

#### Flatten Method

```typescript
const result = schema.safeParse(data);

if (!result.success) {
  const flattened = result.error.flatten();
  console.log(flattened.fieldErrors);
  console.log(flattened.formErrors);
}
```

## JSON Schema Conversion (v4)

### Basic Conversion

```typescript
const schema = z.object({
  name: z.string(),
  age: z.number(),
});

z.toJSONSchema(schema);
```

### Target Specific Versions

```typescript
z.toJSONSchema(schema, { target: 'draft-4' });
z.toJSONSchema(schema, { target: 'draft-7' });
z.toJSONSchema(schema, { target: 'draft-2020-12' });
z.toJSONSchema(schema, { target: 'openapi-3.0' });
```

### With Metadata

```typescript
const mySchema = z.object({
  firstName: z.string().describe('Your first name'),
  lastName: z.string().meta({ title: 'last_name' }),
  age: z.number().meta({ examples: [12, 99] }),
});

z.toJSONSchema(mySchema);
```

### Handling Unrepresentable Types

```typescript
z.toJSONSchema(z.bigint(), { unrepresentable: 'any' });
```

## Zod Mini (Functional API)

Zod Mini is a lightweight, tree-shakable variant using wrapper functions instead of methods.

```typescript
import * as z from 'zod/mini';

z.optional(z.string());
z.union([z.string(), z.number()]);
z.array(z.number()).check(z.minLength(5), z.maxLength(10));
```

## Best Practices

### 1. Enable TypeScript Strict Mode

Always enable `"strict": true` in tsconfig.json. This is required for Zod and is a best practice for all TypeScript projects.

### 2. Infer Types from Schemas

Use `z.infer<typeof Schema>` instead of defining separate interfaces. This ensures your types always match your validation.

```typescript
const User = z.object({
  name: z.string(),
  age: z.number(),
});

type User = z.infer<typeof User>;
```

### 3. Use safeParse() in Production

For graceful error handling without exceptions, use `safeParse()` instead of `parse()`.

```typescript
const result = schema.safeParse(data);

if (result.success) {
  return result.data;
} else {
  return handleError(result.error);
}
```

### 4. Validate at System Entry Points

Validate untrusted data (APIs, user input, external sources) at the boundary. For trusted internal data, TypeScript types are sufficient.

```typescript
app.post('/api/users', (req, res) => {
  const result = UserSchema.safeParse(req.body);

  if (!result.success) {
    return res.status(400).json(result.error);
  }

  processUser(result.data);
});
```

### 5. Define Schemas Once, Reuse Everywhere

Define schemas at module level and reuse them for both code clarity and performance.

```typescript
export const UserSchema = z.object({
  name: z.string(),
  email: z.email(),
});

export type User = z.infer<typeof UserSchema>;
```

### 6. Avoid Redundant Validations

Once data is validated and trusted, don't validate it again within your system.

### 7. Cache Parsed Data

For performance-critical applications, cache parsed results to reduce overhead.

### 8. Start with Schemas, Infer Types

Define Zod schemas first, then infer TypeScript types. This keeps your validation and types in sync.

### 9. Use Transform for Data Reshaping

Use `.transform()` not just for validation, but also for reshaping data to match your internal models.

```typescript
const UserInput = z
  .object({
    first_name: z.string(),
    last_name: z.string(),
  })
  .transform((data) => ({
    firstName: data.first_name,
    lastName: data.last_name,
  }));
```

### 10. Leverage Discriminated Unions

For union types with a discriminator field, always use discriminated unions for better performance and type narrowing.

## Common Gotchas

### 1. Async Transforms Require parseAsync

If you use async transforms or refinements, you MUST use `.parseAsync()` or `.safeParseAsync()`.

```typescript
const schema = z.string().refine(async (val) => {
  return await checkDatabase(val);
});

await schema.parseAsync(data);
```

### 2. TypeScript Only Validates at Compile Time

TypeScript types don't provide runtime validation. Always use Zod for untrusted data.

### 3. Default Values Must Match Schema Type

Default values are not validated through the schema - ensure they match the expected type.

### 4. Refinements Run After Base Schema Validation

Custom refinements only run if the base schema validation passes.

### 5. Passthrough vs Strict

`.passthrough()` allows unknown keys to pass through without validation. `.strict()` rejects unknown keys entirely.

### 6. Parse Throws, SafeParse Doesn't

`.parse()` throws a `ZodError` on validation failure. Use `.safeParse()` to avoid try/catch blocks.

### 7. Object Deep Copy (Zod 3)

In Zod 3, successful validation creates a deep copy of objects. Zod 4 can return the original object for better performance.

### 8. Missing Default Values in Forms

When using Zod with form libraries like React Hook Form, forgetting to set proper default values can lead to bugs with form submission and state checking.

## Anti-Patterns

### 1. Using Any Type

Avoid using `z.any()` as it eliminates Zod's type safety benefits.

```typescript
const Bad = z.object({
  data: z.any(),
});

const Good = z.object({
  data: z.unknown(),
});
```

### 2. Separate Type Definitions

Don't define types separately from schemas - use `z.infer` instead.

```typescript
interface User {
  name: string;
  age: number;
}

const UserSchema = z.object({
  name: z.string(),
  age: z.number(),
});

type User = z.infer<typeof UserSchema>;
```

### 3. Using Intersections for Object Merging

Use `.extend()` instead of `z.intersection()` for merging object schemas.

```typescript
const A = z.object({ name: z.string() });
const B = z.object({ age: z.number() });

const Bad = z.intersection(A, B);

const Good = A.extend(B.shape);
```

### 4. Using Deprecated APIs

Zod 4 deprecated `.merge()` in favor of `.extend()`. Update your code accordingly.

### 5. Validating Trusted Internal Data

Don't over-validate. If data has already been validated at the entry point, trust it within your system.

### 6. Parse in Try/Catch When safeParse Exists

Use `safeParse()` instead of wrapping `.parse()` in try/catch for better performance.

```typescript
try {
  const data = schema.parse(input);
} catch (error) {}

const result = schema.safeParse(input);
if (!result.success) {
}
```

## Security Considerations

### 1. Validation vs. Sanitization

Zod is primarily for validation, not sanitization. If user input doesn't match the schema, reject it.

### 2. Use Strict Mode for Security Monitoring

`.strict()` can help identify security breach attempts by rejecting unexpected keys.

```typescript
const StrictUser = z.strictObject({
  name: z.string(),
  email: z.email(),
});
```

### 3. Sanitization with Transforms

Use `.transform()` for sanitization after validation.

```typescript
const sanitizedString = z
  .string()
  .transform((val) => val.trim())
  .transform((val) => escapeHtml(val));
```

### 4. XSS Protection

For XSS protection, use dedicated libraries like `zod-xss-sanitizer` or implement custom sanitization.

### 5. Validate on Both Frontend and Backend

Always validate on the backend, even if you validate on the frontend. Client-side validation can be bypassed.

### 6. Use Specific Constraints

Define specific constraints (length, format, range) to limit attack surface.

```typescript
const SafeInput = z
  .string()
  .min(1)
  .max(100)
  .regex(/^[a-zA-Z0-9\s]+$/);
```

### 7. Whitelist Over Blacklist

Define what IS allowed rather than what ISN'T allowed.

### 8. Reject Early

Catch and reject invalid input as early as possible in your application flow.

## Performance Tips

### 1. Upgrade to Zod v4

Zod 4 offers dramatic performance improvements:

- 14x faster string parsing
- 7x faster array parsing
- 6.5x faster object parsing
- 100x reduction in TypeScript instantiations

### 2. Use Zod Mini for Bundle-Sensitive Applications

For performance-critical environments (serverless, edge runtimes), use `@zod/mini` (1.88kb gzipped).

### 3. Return Original Objects

Zod 4 can return the original object instead of creating deep copies, significantly improving performance.

### 4. Implement Caching

Cache parse results for immutable inputs using WeakMap (objects) or Map (primitives).

```typescript
const cache = new WeakMap();

function cachedParse(schema, data) {
  if (cache.has(data)) {
    return cache.get(data);
  }
  const result = schema.parse(data);
  cache.set(data, result);
  return result;
}
```

### 5. Use safeParse Over parse in Try/Catch

Throwing exceptions is expensive. Use `safeParse()` in performance-critical code.

### 6. Define Schemas Once

Define schemas at module initialization and reuse them for each validation.

### 7. Keep Schemas Simple

The simpler your schemas, the faster validation runs.

### 8. Validate Arrays in Bulk

Validate an array schema in one go rather than item by item in a loop.

```typescript
const users = UsersArraySchema.parse(data);

const users = data.map((item) => UserSchema.parse(item));
```

### 9. Use .passthrough() for Performance

If you don't need to strip unknown properties, use `.passthrough()` to avoid the cost.

### 10. Flatten Deep Schemas

Instead of chaining many `.extend()` or `.pick()` calls, break schemas into smaller pieces.

```typescript
const fields = {
  name: z.string(),
  age: z.number(),
};

const User = z.object(fields);
const Employee = z.object({
  ...fields,
  employeeId: z.string(),
});
```

### 11. Consider AOT Compilation

For production, implement build-time compilation to transform Zod schemas into highly optimized functions.

## Version-Specific Notes (v4)

### New Features

1. **Zod Mini** - Lightweight functional API variant
2. **Metadata & Registries** - Attach strongly-typed metadata to schemas
3. **JSON Schema Conversion** - Native `z.toJSONSchema()` support
4. **Recursive Types** - Properly typed recursive schemas without casting
5. **File Validation** - Built-in `z.file()` schema
6. **Top-Level String Formats** - `z.email()`, `z.uuid()`, etc.
7. **Template Literal Types** - `z.templateLiteral()` support
8. **Number Format Schemas** - `z.int32()`, `z.float32()`, etc.
9. **String Boolean Coercion** - `z.stringbool()` for env variables
10. **Error Pretty-Printing** - `z.prettifyError()` API
11. **Unified Error Customization** - Single `error` parameter
12. **Enhanced Discriminated Unions** - Support for nested unions
13. **Multiple Literal Values** - `z.literal([200, 201, 202])`
14. **Refinements Inside Schemas** - Chain methods after `.refine()`
15. **`.overwrite()` Method** - Non-type-changing transformations
16. **Internationalization** - Global locale configuration
17. **Codecs** - Bidirectional transformations with `.codec()`

### Breaking Changes

1. **Error Customization API** - Unified `error` parameter replaces `message`, `invalid_type_error`, `required_error`, and `errorMap`
2. **`.merge()` Deprecated** - Use `.extend()` instead
3. **String Format Methods Deprecated** - Use top-level functions like `z.email()` instead of `z.string().email()`
4. **Type System Redesign** - Reduced TypeScript instantiation complexity
5. **Error Structure Changes** - Error formatting and structure refined
6. **`.nonempty()` Behavior** - Changes to empty array/string handling
7. **Refinement Architecture** - Refinements now integrated into schema classes

### Migration Guide

Full migration guide available at: https://zod.dev/v4/changelog

Key migration steps:

1. Update error customization to use `error` parameter
2. Replace `.merge()` with `.extend()`
3. Update string format methods to top-level functions
4. Review and update discriminated union definitions
5. Check for uses of deprecated APIs
6. Test thoroughly, especially async validation and transformations

## Code Examples

### Complete Form Validation Example

```typescript
import * as z from 'zod';

const RegisterSchema = z
  .object({
    username: z
      .string()
      .min(3, 'Username must be at least 3 characters')
      .max(20, 'Username must be at most 20 characters')
      .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores'),

    email: z.email('Invalid email address'),

    password: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .refine((val) => /[A-Z]/.test(val), 'Password must contain at least one uppercase letter')
      .refine((val) => /[a-z]/.test(val), 'Password must contain at least one lowercase letter')
      .refine((val) => /[0-9]/.test(val), 'Password must contain at least one number')
      .refine(
        (val) => /[^A-Za-z0-9]/.test(val),
        'Password must contain at least one special character'
      ),

    confirmPassword: z.string(),

    age: z.coerce
      .number()
      .int('Age must be an integer')
      .positive('Age must be positive')
      .min(13, 'You must be at least 13 years old')
      .max(120, 'Invalid age'),

    terms: z.literal(true, { error: 'You must accept the terms and conditions' }),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ['confirmPassword'],
  });

type RegisterInput = z.infer<typeof RegisterSchema>;

function handleRegistration(data: unknown) {
  const result = RegisterSchema.safeParse(data);

  if (!result.success) {
    const errors = result.error.flatten();
    return { success: false, errors };
  }

  return { success: true, data: result.data };
}
```

### API Request Validation Example

```typescript
const CreateProductSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  price: z.number().positive(),
  category: z.enum(['electronics', 'clothing', 'food', 'other']),
  tags: z.array(z.string()).min(1).max(10),
  inStock: z.boolean().default(true),
  metadata: z.record(z.string(), z.unknown()).optional(),
});

type CreateProductInput = z.infer<typeof CreateProductSchema>;

app.post('/api/products', async (req, res) => {
  const result = CreateProductSchema.safeParse(req.body);

  if (!result.success) {
    return res.status(400).json({
      error: 'Validation failed',
      details: result.error.flatten(),
    });
  }

  const product = await createProduct(result.data);
  res.status(201).json(product);
});
```

### Complex Nested Schema Example

```typescript
const AddressSchema = z.object({
  street: z.string(),
  city: z.string(),
  state: z.string().length(2),
  zipCode: z.string().regex(/^\d{5}(-\d{4})?$/),
  country: z.string().default('US'),
});

const PhoneSchema = z.object({
  type: z.enum(['home', 'work', 'mobile']),
  number: z.string().regex(/^\+?1?\d{10,14}$/),
  primary: z.boolean().default(false),
});

const CompanySchema = z.object({
  name: z.string(),
  employees: z
    .array(
      z.object({
        id: z.string().uuid(),
        firstName: z.string(),
        lastName: z.string(),
        email: z.email(),
        role: z.enum(['admin', 'manager', 'employee']),
        addresses: z.array(AddressSchema).min(1),
        phones: z.array(PhoneSchema).min(1).max(5),
        startDate: z.coerce.date(),
        salary: z.number().positive().optional(),
      })
    )
    .min(1),
});

type Company = z.infer<typeof CompanySchema>;
```

### Discriminated Union with Type Narrowing

```typescript
const SuccessResponse = z.object({
  status: z.literal('success'),
  data: z.unknown(),
});

const ErrorResponse = z.object({
  status: z.literal('error'),
  error: z.object({
    code: z.string(),
    message: z.string(),
  }),
});

const ApiResponse = z.discriminatedUnion('status', [SuccessResponse, ErrorResponse]);

type ApiResponse = z.infer<typeof ApiResponse>;

function handleResponse(response: ApiResponse) {
  switch (response.status) {
    case 'success':
      console.log('Data:', response.data);
      break;
    case 'error':
      console.error(`Error ${response.error.code}: ${response.error.message}`);
      break;
  }
}
```

### Async Validation with Database Check

```typescript
import * as z from 'zod';

async function checkEmailExists(email: string): Promise<boolean> {
  const user = await db.users.findOne({ email });
  return !!user;
}

async function checkUsernameExists(username: string): Promise<boolean> {
  const user = await db.users.findOne({ username });
  return !!user;
}

const UniqueUserSchema = z.object({
  username: z
    .string()
    .min(3)
    .max(20)
    .refine(async (username) => {
      const exists = await checkUsernameExists(username);
      return !exists;
    }, 'Username already taken'),

  email: z.email().refine(async (email) => {
    const exists = await checkEmailExists(email);
    return !exists;
  }, 'Email already registered'),

  password: z.string().min(8),
});

async function registerUser(data: unknown) {
  const result = await UniqueUserSchema.safeParseAsync(data);

  if (!result.success) {
    throw new ValidationError(result.error);
  }

  return await db.users.create(result.data);
}
```

### Transform and Reshape Data

```typescript
const ApiUserSchema = z
  .object({
    user_id: z.string(),
    first_name: z.string(),
    last_name: z.string(),
    email_address: z.string().email(),
    created_at: z.string(),
    is_active: z.string(),
  })
  .transform((data) => ({
    id: data.user_id,
    firstName: data.first_name,
    lastName: data.last_name,
    email: data.email_address,
    createdAt: new Date(data.created_at),
    isActive: data.is_active === 'true',
  }));

type User = z.output<typeof ApiUserSchema>;
```

### Codec Example for Date Serialization

```typescript
const DateCodec = z.codec(z.string(), z.date(), {
  decode: (isoString) => new Date(isoString),
  encode: (date) => date.toISOString(),
});

const UserWithDates = z.object({
  name: z.string(),
  createdAt: DateCodec,
  updatedAt: DateCodec,
});

const apiData = {
  name: 'Alice',
  createdAt: '2025-01-01T00:00:00.000Z',
  updatedAt: '2025-11-19T12:00:00.000Z',
};

const decoded = UserWithDates.decode(apiData);

const encoded = UserWithDates.encode(decoded);
```

## References

### Official Documentation

- Main Documentation: https://zod.dev/
- API Reference: https://zod.dev/api
- v4 Release Notes: https://zod.dev/v4
- Migration Guide: https://zod.dev/v4/changelog
- Error Customization: https://zod.dev/error-customization
- JSON Schema: https://zod.dev/json-schema
- Codecs: https://zod.dev/codecs

### Repository & Package

- GitHub: https://github.com/colinhacks/zod
- NPM: https://www.npmjs.com/package/zod
- JSR: https://jsr.io/@zod/zod

### Articles & Guides

- "Introducing Zod Codecs" by Colin Hacks: https://colinhacks.com/essays/introducing-zod-codecs
- "Designing the perfect TypeScript schema validation library": https://colinhacks.com/essays/zod
- "9 Best Practices for Using Zod in 2025": https://javascript.plainenglish.io/9-best-practices-for-using-zod-in-2025-31ee7418062e
- "How we doubled Zod performance": https://numeric.substack.com/p/how-we-doubled-zod-performance-to
- InfoQ: "Zod v4 Available with Major Performance Improvements": https://www.infoq.com/news/2025/08/zod-v4-available/

### Community Resources

- Discord Community (linked from zod.dev)
- Stack Overflow: #zod tag
- TypeScript Discord: #zod channel

### Ecosystem Integrations

- tRPC: https://trpc.io/
- React Hook Form: https://react-hook-form.com/
- zod-validation-error: https://www.npmjs.com/package/zod-validation-error
- zod-xss-sanitizer: https://github.com/AhmedAdelFahim/zod-xss-sanitizer

### Related Tools

- TypeScript: https://www.typescriptlang.org/
- JSON Schema: https://json-schema.org/

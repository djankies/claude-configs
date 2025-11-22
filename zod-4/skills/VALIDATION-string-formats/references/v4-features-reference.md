# V4 Features Reference

See SKILL.md for core concepts. This file contains comprehensive format reference and advanced features.


### Complete Format Reference

| Format | v4 Function | Example |
|--------|-------------|---------|
| Email | `z.email()` | `user@example.com` |
| UUID | `z.uuid()` | `550e8400-e29b-41d4-a716-446655440000` |
| Datetime | `z.iso.datetime()` | `2024-01-01T12:00:00Z` |
| URL | `z.url()` | `https://example.com` |
| IPv4 | `z.ipv4()` | `192.168.1.1` |
| IPv6 | `z.ipv6()` | `2001:0db8:85a3::8a2e:0370:7334` |
| JWT | `z.jwt()` | `eyJhbGc...` |
| Base64 | `z.base64()` | `SGVsbG8gV29ybGQ=` |
| Hash | `z.hash('sha256')` | 64 hex chars for SHA-256 |

## String Transformation Methods

### Trim

Remove leading/trailing whitespace:

```typescript
const schema = z.string().trim();

const result = schema.parse('  hello  ');
```

**Use case:** User input fields always need trimming

```typescript
const userInputSchema = z.object({
  name: z.string().trim().min(1),
  email: z.email().trim().toLowerCase(),
  bio: z.string().trim().optional()
});
```

### Lower Case

Convert to lowercase:

```typescript
const schema = z.string().toLowerCase();

const result = schema.parse('HELLO');
```

**Use case:** Email and username normalization

```typescript
const loginSchema = z.object({
  email: z.email().trim().toLowerCase(),
  password: z.string()
});
```

### Upper Case

Convert to uppercase:

```typescript
const schema = z.string().toUpperCase();

const result = schema.parse('hello');
```

**Use case:** Code/identifier normalization

```typescript
const productSchema = z.object({
  sku: z.string().trim().toUpperCase(),
  name: z.string().trim()
});
```

### Chaining Transformations

**Order matters:**

```typescript
const schema = z.string()
  .trim()
  .toLowerCase()
  .min(3);

const result = schema.parse('  HELLO  ');
```

Execution order: trim → toLowerCase → validation (min length)

**Common pattern for email:**
```typescript
const emailSchema = z.email().trim().toLowerCase();
```

## StringBool Type

### Overview

New in v4: Parse string representations of booleans.

```typescript
const boolSchema = z.stringbool();

boolSchema.parse('true');
boolSchema.parse('false');
boolSchema.parse('1');
boolSchema.parse('0');
```

**Use case:** Query parameters and form data

```typescript
const querySchema = z.object({
  active: z.stringbool(),
  verified: z.stringbool()
});

const params = new URLSearchParams('?active=true&verified=1');
const result = querySchema.safeParse({
  active: params.get('active'),
  verified: params.get('verified')
});
```

**Type inference:**
```typescript
const schema = z.stringbool();
type Output = z.output<typeof schema>;  // boolean
```

## Codec Type

### Overview

New in v4: Bidirectional transformations for encode/decode patterns.

```typescript
const dateCodec = z.codec({
  decode: z.string().transform(s => new Date(s)),
  encode: z.date().transform(d => d.toISOString())
});

const decoded = dateCodec.parse('2024-01-01T00:00:00Z');

const encoded = dateCodec.encode(new Date());
```

### Use Cases

**Date serialization:**
```typescript
const dateCodec = z.codec({
  decode: z.iso.datetime().transform(s => new Date(s)),
  encode: z.date().transform(d => d.toISOString())
});

const userSchema = z.object({
  name: z.string(),
  createdAt: dateCodec
});

type User = z.infer<typeof userSchema>;

const parsed = userSchema.parse({
  name: 'John',
  createdAt: '2024-01-01T00:00:00Z'
});

const serialized = userSchema.encode(parsed);
```

**Safe decode/encode:**
```typescript
const result = dateCodec.safeDecode('invalid-date');
if (!result.success) {
  console.error(result.error);
}
```

**Custom data formats:**
```typescript
const base64Codec = z.codec({
  decode: z.base64().transform(s => Buffer.from(s, 'base64')),
  encode: z.instanceof(Buffer).transform(b => b.toString('base64'))
});
```

## Template Literal Types

### Overview

Type-safe template literal string validation:

```typescript
const idSchema = z.templateLiteral('user_${string}');

idSchema.parse('user_123');
idSchema.parse('user_abc');
```

**Complex patterns:**
```typescript
const colorSchema = z.templateLiteral('rgb(${number}, ${number}, ${number})');
colorSchema.parse('rgb(255, 0, 128)');
```

**With constraints:**
```typescript
const schema = z.templateLiteral('v${number}')
  .refine(s => {
    const version = parseInt(s.slice(1));
    return version >= 1 && version <= 10;
  }, { error: "Version must be between 1 and 10" });
```

## Branded Types

### Overview

Nominal typing for stronger type safety:

```typescript
const userId = z.string().brand<'UserId'>();
const productId = z.string().brand<'ProductId'>();

type UserId = z.infer<typeof userId>;
type ProductId = z.infer<typeof productId>;

function getUser(id: UserId) { }
function getProduct(id: ProductId) { }

const uid = userId.parse('user-123');
const pid = productId.parse('prod-456');

getUser(uid);
getProduct(pid);
```

**Benefits:**
- Prevent mixing different ID types
- Self-documenting code
- Compile-time type safety

## Performance Optimizations

### Bulk Array Validation

**v4 optimized array parsing (7x faster):**

```typescript
const itemSchema = z.object({
  id: z.string(),
  name: z.string()
});

const arraySchema = z.array(itemSchema);

const items = arraySchema.parse([
  { id: '1', name: 'Item 1' },
  { id: '2', name: 'Item 2' }
]);
```

**Anti-pattern:**
```typescript
items.forEach(item => itemSchema.parse(item));
```

### Passthrough for Performance

Skip property stripping when not needed:

```typescript
const schema = z.object({
  id: z.string()
}).passthrough();

const result = schema.parse({
  id: '123',
  extra: 'data'
});
```

## Advanced Features

### Recursive Types

```typescript
interface Category {
  name: string;
  subcategories: Category[];
}

const categorySchema: z.ZodType<Category> = z.lazy(() =>
  z.object({
    name: z.string(),
    subcategories: z.array(categorySchema)
  })
);
```

### Discriminated Unions

```typescript
const eventSchema = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('click'),
    x: z.number(),
    y: z.number()
  }),
  z.object({
    type: z.literal('keypress'),
    key: z.string()
  })
]);
```

**Faster parsing than regular unions.**

### Pipeline Transformations

```typescript
const schema = z.string()
  .trim()
  .toLowerCase()
  .transform(s => s.split(','))
  .transform(arr => arr.map(s => s.trim()))
  .transform(arr => arr.filter(s => s.length > 0));

const result = schema.parse('  Apple, Banana,  , Orange  ');
```

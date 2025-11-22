# Transformation Patterns Reference

Common transformation patterns and async transformations.



## Overwrite vs Transform

### Transform (Additive)

Adds to the data:

```typescript
const schema = z.object({
  firstName: z.string(),
  lastName: z.string()
}).transform(data => ({
  ...data,
  fullName: `${data.firstName} ${data.lastName}`
}));
```

**Output has all fields:**
```typescript
{
  firstName: 'John',
  lastName: 'Doe',
  fullName: 'John Doe'
}
```

### Overwrite (Destructive)

Replaces the data:

```typescript
const schema = z.object({
  firstName: z.string(),
  lastName: z.string()
}).overwrite(data => ({
  fullName: `${data.firstName} ${data.lastName}`
}));
```

**Output has only new fields:**
```typescript
{
  fullName: 'John Doe'
}
```

**When to use:**
- Transform: Keep original data + add computed fields
- Overwrite: Replace with completely new shape

## Async Transformations

### Basic Async Transform

```typescript
const schema = z.string().transform(async (email) => {
  const user = await fetchUser(email);
  return user;
});

const result = await schema.parseAsync('user@example.com');
```

### Async Refinement

```typescript
const emailSchema = z.email().refine(
  async (email) => {
    const exists = await checkEmailExists(email);
    return !exists;
  },
  { error: "Email already exists" }
);

const result = await emailSchema.safeParseAsync('user@example.com');
```

### Async Codec

```typescript
const userCodec = z.codec({
  decode: z.string().transform(async (id) => {
    return await fetchUser(id);
  }),
  encode: z.object({ id: z.string() }).transform(user => user.id)
});

const user = await userCodec.parseAsync('user-123');
```

## Common Patterns

### Slug Generation

```typescript
const slugSchema = z.string()
  .trim()
  .toLowerCase()
  .transform(s => s.replace(/\s+/g, '-'))
  .transform(s => s.replace(/[^a-z0-9-]/g, ''))
  .transform(s => s.replace(/-+/g, '-'))
  .transform(s => s.replace(/^-|-$/g, ''));

const slug = slugSchema.parse('Hello World! 123');
```

**Output:** `'hello-world-123'`

### Phone Number Normalization

```typescript
const phoneSchema = z.string()
  .transform(s => s.replace(/\D/g, ''))
  .regex(/^\d{10}$/, { error: "Must be 10 digits" })
  .transform(s => `(${s.slice(0,3)}) ${s.slice(3,6)}-${s.slice(6)}`);

const phone = phoneSchema.parse('123-456-7890');
```

**Output:** `'(123) 456-7890'`

### Price Parsing

```typescript
const priceSchema = z.string()
  .transform(s => s.replace(/[$,]/g, ''))
  .transform(s => parseFloat(s))
  .refine(n => !isNaN(n), { error: "Invalid price" })
  .refine(n => n >= 0, { error: "Price must be positive" });

const price = priceSchema.parse('$1,234.56');
```

**Output:** `1234.56`

### Tag Parsing

```typescript
const tagsSchema = z.string()
  .transform(s => s.split(','))
  .transform(arr => arr.map(tag => tag.trim().toLowerCase()))
  .transform(arr => arr.filter(tag => tag.length > 0))
  .transform(arr => [...new Set(arr)]);

const tags = tagsSchema.parse('JavaScript, TypeScript, javascript, React');
```

**Output:** `['javascript', 'typescript', 'react']`

### Date Range Parsing

```typescript
const dateRangeSchema = z.string()
  .regex(/^\d{4}-\d{2}-\d{2} to \d{4}-\d{2}-\d{2}$/)
  .transform(s => s.split(' to '))
  .transform(arr => ({
    start: new Date(arr[0]),
    end: new Date(arr[1])
  }))
  .refine(
    range => range.start <= range.end,
    { error: "Start date must be before end date" }
  );

const range = dateRangeSchema.parse('2024-01-01 to 2024-12-31');
```

## Best Practices

### 1. Transform Before Validation

```typescript
z.string().trim().min(1)      // ✅ Trim then validate
z.string().min(1).trim()      // ❌ Validate then trim
```

### 2. Use Built-In Methods

```typescript
z.string().trim().toLowerCase()              // ✅ Built-in
z.string().transform(s => s.trim().toLowerCase())  // ❌ Manual
```

### 3. Keep Transformations Pure

```typescript
const schema = z.string().transform(s => s.toUpperCase());  // ✅ Pure

let count = 0;
const schema = z.string().transform(s => {
  count++;  // ❌ Side effect
  return s.toUpperCase();
});
```

### 4. Use Codecs for Serialization

```typescript
const dateCodec = z.codec({
  decode: z.iso.datetime().transform(s => new Date(s)),
  encode: z.date().transform(d => d.toISOString())
});  // ✅ Bidirectional

const dateSchema = z.string().transform(s => new Date(s));  // ❌ One-way
```

### 5. Type-Safe Transformations

```typescript
const schema = z.string().transform(s => parseInt(s));

type Output = z.output<typeof schema>;  // ✅ Type-safe

const result: Output = schema.parse('42');
```

### 6. Handle Edge Cases

```typescript
const schema = z.string()
  .transform(s => s.split(','))
  .transform(arr => arr.map(s => s.trim()))
  .transform(arr => arr.filter(s => s.length > 0));  // ✅ Handle empty

const result = schema.parse('a, b,  , c');
```

## Migration from v3

### String Transformations (New in v4)

**Before (manual):**
```typescript
const trimmed = input.trim();
const validated = z.string().parse(trimmed);
```

**After (declarative):**
```typescript
const validated = z.string().trim().parse(input);
```

### Codecs (New in v4)

**Before (one-way):**
```typescript
const schema = z.string().transform(s => new Date(s));
```

**After (bidirectional):**
```typescript
const codec = z.codec({
  decode: z.iso.datetime().transform(s => new Date(s)),
  encode: z.date().transform(d => d.toISOString())
});
```

## Performance Considerations

### Transformation Cost

Transformations add runtime overhead:

```typescript
z.string()                  // Fastest
z.string().trim()           // Fast (built-in)
z.string().transform(...)   // Slower (custom)
```

**Optimize:**
- Use built-in methods when possible
- Keep transformations simple
- Avoid async unless necessary

### Caching Transformed Results

```typescript
const cache = new Map<string, number>();

const schema = z.string().transform(s => {
  if (cache.has(s)) return cache.get(s)!;

  const result = expensiveOperation(s);
  cache.set(s, result);
  return result;
});
```

## References

- v4 Features: `@zod-4/skills/VALIDATION-string-formats/SKILL.md`
- Error handling: `@zod-4/skills/ERRORS-customization/SKILL.md`
- Performance: `@zod-4/skills/PERFORMANCE-optimization/SKILL.md`
- Testing: `@zod-4/skills/testing-zod-schemas/SKILL.md`
- Comprehensive docs: `@zod-4/knowledge/zod-4-comprehensive.md`

## Success Criteria

- ✅ Using built-in string transformations
- ✅ Transform before validation
- ✅ Pure transformation functions
- ✅ Type-safe with z.input/z.output
- ✅ Codecs for bidirectional transforms
- ✅ Proper transformation order
- ✅ Edge cases handled
- ✅ Performance optimized

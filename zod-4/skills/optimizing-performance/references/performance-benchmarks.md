# Performance Benchmarks and Real-World Patterns

This document contains benchmarking code and real-world optimization patterns for Zod v4.

## Performance Monitoring

### Measure Validation Time

```typescript
const schema = z.object({
  email: z.email(),
  name: z.string()
});

const start = performance.now();
const result = schema.safeParse(data);
const duration = performance.now() - start;

console.log(`Validation took ${duration}ms`);
```

### Benchmark Different Approaches

```typescript
const iterations = 10000;

console.time('parse');
for (let i = 0; i < iterations; i++) {
  try {
    schema.parse(data);
  } catch {}
}
console.timeEnd('parse');

console.time('safeParse');
for (let i = 0; i < iterations; i++) {
  schema.safeParse(data);
}
console.timeEnd('safeParse');
```

### Profile with DevTools

```typescript
console.profile('Zod Validation');
const result = schema.safeParse(largeDataset);
console.profileEnd('Zod Validation');
```

## Real-World Optimizations

### API Request Validation

```typescript
const requestSchema = z.object({
  user: z.object({
    id: z.string(),
    email: z.email().trim().toLowerCase()
  }),
  items: z.array(z.object({
    id: z.string(),
    quantity: z.number().min(1)
  }))
}).passthrough();

app.post('/orders', (req, res) => {
  const result = requestSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ error: result.error });
  }

  processOrder(result.data);
});
```

**Optimizations:**
- SafeParse for error handling
- Passthrough (don't strip extra fields)
- Bulk array validation
- Schema at module level

### Form Validation

```typescript
const formSchema = z.object({
  email: z.email().trim().toLowerCase(),
  username: z.string().trim().min(3),
  terms: z.stringbool()
});

function validateForm(formData: FormData) {
  return formSchema.safeParse({
    email: formData.get('email'),
    username: formData.get('username'),
    terms: formData.get('terms')
  });
}
```

**Optimizations:**
- SafeParse (errors expected)
- String transformations (trim, toLowerCase)
- StringBool for checkbox values

## Back to Main Guide

See [SKILL.md](../SKILL.md) for the main performance optimization guide.

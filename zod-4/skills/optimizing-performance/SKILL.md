---
name: optimizing-performance
description: Optimize Zod validation performance with safeParse, bulk array validation, schema reuse, and passthrough patterns
---

# Optimizing Zod Performance

## Purpose

Guide to performance optimization patterns in Zod v4, leveraging improved parsing speed, reduced bundle size, and efficient validation strategies.

## Zod v4 Performance Improvements

Zod v4 introduced major performance gains:

- **100x reduction** in TypeScript instantiations (faster compilation)
- **14x faster** string parsing (runtime performance)
- **7x faster** bulk array validation
- **57% smaller** bundle size
- **Faster** discriminated union parsing

These improvements are automatic when using v4.

## Core Optimizations

### 1. SafeParse vs Parse

**SafeParse is 20-30% faster** for invalid data:

```typescript
const result = schema.safeParse(data);
if (!result.success) {
  console.error(result.error);
  return;
}
return result.data;
```

**Why faster:**
- No exception throwing overhead
- No stack unwinding
- Predictable control flow
- Better JIT optimization

**When to use parse:** Internal data that should always be valid (errors are bugs).

### 2. Schema Reuse

Define schemas at module level, not inside functions:

```typescript
const userSchema = z.object({
  email: z.email(),
  name: z.string()
});

function validateUser(data: unknown) {
  return userSchema.parse(data);
}
```

**Performance improvement:** 2-5x faster for repeated validations

### 3. Bulk Array Validation

Use `z.array()` instead of looping:

```typescript
const arraySchema = z.array(itemSchema);
const result = arraySchema.safeParse(items);
```

**7x faster** in Zod v4 than item-by-item validation.

### 4. Discriminated Unions

Use discriminator field for O(1) lookup:

```typescript
const eventSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('click'), x: z.number(), y: z.number() }),
  z.object({ type: z.literal('keypress'), key: z.string() })
]);
```

**Much faster** than regular unions which try each schema sequentially.

### 5. String Format Functions (v4)

Use top-level functions for **14x faster** parsing:

```typescript
z.email()          // ✅ v4 optimized
z.string().email() // ❌ v3 deprecated
```

All v4 string formats are optimized: `z.email()`, `z.uuid()`, `z.url()`, `z.iso.datetime()`, etc.

### 6. Passthrough Mode

Skip property stripping when not needed:

```typescript
const schema = z.object({
  id: z.string(),
  name: z.string()
}).passthrough();
```

**10-20% faster** than strict mode which strips unknown keys.

**Use strict for:** Security-sensitive data, API responses
**Use passthrough for:** Performance-critical paths, partial validation

## Advanced Optimizations

### Refinement Order

Place fast refinements first:

```typescript
const schema = z.string()
  .refine(val => val.length > 5)        // Fast sync
  .refine(val => /[A-Z]/.test(val))     // Slower sync
  .refine(async val => checkDB(val));   // Async last
```

### Schema Composition

Use `extend` instead of `merge` (more performant):

```typescript
const combined = schemaA.extend(schemaB.shape);  // ✅
const combined = schemaA.merge(schemaB);         // ❌
```

### Pick/Omit for Subsets

```typescript
const loginSchema = userSchema.pick({
  email: true,
  password: true
});
```

Faster than redefining the schema.

## Bundle Size

### Tree Shaking

Zod v4 is fully tree-shakeable. Just import and use:

```typescript
import { z } from 'zod';
```

### Zod Mini

For extreme size constraints:

```bash
npm install zod-mini
```

**Trade-offs:** Smaller bundle (~2KB vs ~14KB), fewer features, same API for basics.

## Best Practices Summary

```typescript
schema.safeParse(data)                    // ✅ 20-30% faster
z.array(schema).parse(items)              // ✅ 7x faster bulk validation
z.discriminatedUnion('type', [...])       // ✅ O(1) lookup
z.email()                                 // ✅ 14x faster v4 format
z.object({...}).passthrough()             // ✅ 10-20% faster
const schema = z.object({...})            // ✅ Module level, reusable
.refine(fast).refine(slow).refine(async)  // ✅ Fast first
schemaA.extend(schemaB.shape)             // ✅ Faster than merge
```

## References

- v4 Features: Use the validating-string-formats skill from the zod-4 plugin
- Error handling: Use the customizing-errors skill from the zod-4 plugin
- Testing: Use the testing-zod-schemas skill from the zod-4 plugin

**Cross-Plugin References:**

- If analyzing schema complexity, use the reviewing-complexity skill for identifying optimization opportunities

## Success Criteria

- ✅ Using safeParse instead of parse + try/catch
- ✅ Schemas defined at module level
- ✅ Bulk array validation for collections
- ✅ Discriminated unions where applicable
- ✅ v4 string format functions (14x faster)
- ✅ Passthrough when stripping not needed
- ✅ Refinements ordered by speed
- ✅ Performance monitoring in place

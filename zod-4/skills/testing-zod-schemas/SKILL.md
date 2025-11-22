---
name: testing-zod-schemas
description: Test Zod schemas comprehensively with unit tests, integration tests, and type tests for validation logic
---

# Testing Zod Schemas

## Purpose

Comprehensive guide to testing Zod v4 schemas, including validation logic, error messages, transformations, and type inference.

## Unit Testing Schemas

### Basic Validation Tests

```typescript
import { z } from 'zod';
import { describe, it, expect } from 'vitest';

const userSchema = z.object({
  email: z.email().trim().toLowerCase(),
  age: z.number().min(18),
  username: z.string().trim().min(3)
});

describe('userSchema', () => {
  it('validates correct user data', () => {
    const result = userSchema.safeParse({
      email: 'user@example.com',
      age: 25,
      username: 'john'
    });

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.email).toBe('user@example.com');
    }
  });

  it('rejects invalid email', () => {
    const result = userSchema.safeParse({
      email: 'not-an-email',
      age: 25,
      username: 'john'
    });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].path).toEqual(['email']);
    }
  });
});
```

### Testing Transformations

```typescript
describe('email transformation', () => {
  const emailSchema = z.email().trim().toLowerCase();

  it('trims whitespace and converts to lowercase', () => {
    const result = emailSchema.safeParse('  USER@EXAMPLE.COM  ');

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data).toBe('user@example.com');
    }
  });
});
```

### Testing Error Messages

```typescript
describe('custom error messages', () => {
  const schema = z.object({
    email: z.email({ error: "Please enter a valid email address" }),
    password: z.string().min(8, {
      error: "Password must be at least 8 characters"
    })
  });

  it('shows custom email error', () => {
    const result = schema.safeParse({
      email: 'invalid',
      password: 'password123'
    });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe(
        "Please enter a valid email address"
      );
    }
  });
});
```

### Testing Refinements

```typescript
describe('password refinements', () => {
  const passwordSchema = z.string()
    .min(8)
    .refine(
      (password) => /[A-Z]/.test(password),
      { error: "Must contain uppercase letter" }
    )
    .refine(
      (password) => /[0-9]/.test(password),
      { error: "Must contain number" }
    );

  it('accepts valid password', () => {
    const result = passwordSchema.safeParse('Password123');
    expect(result.success).toBe(true);
  });

  it('rejects password without uppercase', () => {
    const result = passwordSchema.safeParse('password123');

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe(
        "Must contain uppercase letter"
      );
    }
  });
});
```

### Testing Async Refinements

```typescript
describe('async validation', () => {
  const emailSchema = z.email().refine(
    async (email) => {
      const exists = await checkEmailExists(email);
      return !exists;
    },
    { error: "Email already exists" }
  );

  it('accepts unique email', async () => {
    const result = await emailSchema.safeParseAsync('new@example.com');
    expect(result.success).toBe(true);
  });

  it('rejects existing email', async () => {
    const result = await emailSchema.safeParseAsync('existing@example.com');

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe("Email already exists");
    }
  });
});
```

## Testing Complex Schemas

### Nested Objects

```typescript
describe('nested schema', () => {
  const addressSchema = z.object({
    street: z.string().trim().min(1),
    city: z.string().trim().min(1),
    zip: z.string().trim().regex(/^\d{5}$/)
  });

  const userSchema = z.object({
    name: z.string().trim().min(1),
    address: addressSchema
  });

  it('shows nested error path', () => {
    const result = userSchema.safeParse({
      name: 'John',
      address: { street: '123 Main St', city: 'Boston', zip: 'invalid' }
    });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].path).toEqual(['address', 'zip']);
    }
  });
});
```

### Arrays

```typescript
describe('array schema', () => {
  const tagsSchema = z.array(
    z.string().trim().min(1)
  ).min(1, { error: "At least one tag required" });

  it('shows item-specific errors', () => {
    const result = tagsSchema.safeParse(['valid', '']);

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].path).toEqual([1]);
    }
  });
});
```

### Discriminated Unions

```typescript
describe('discriminated union', () => {
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

  it('validates click event', () => {
    const result = eventSchema.safeParse({
      type: 'click',
      x: 100,
      y: 200
    });

    expect(result.success).toBe(true);
  });
});
```

## Type Testing

### Type Inference

```typescript
import { expectTypeOf } from 'vitest';

const userSchema = z.object({
  email: z.email(),
  age: z.number(),
  name: z.string()
});

type User = z.infer<typeof userSchema>;

describe('type inference', () => {
  it('infers correct types', () => {
    expectTypeOf<User>().toEqualTypeOf<{
      email: string;
      age: number;
      name: string;
    }>();
  });
});
```

### Transform Types

```typescript
const schema = z.string().transform(s => parseInt(s));

type Input = z.input<typeof schema>;
type Output = z.output<typeof schema>;

describe('transform types', () => {
  it('has correct input/output types', () => {
    expectTypeOf<Input>().toEqualTypeOf<string>();
    expectTypeOf<Output>().toEqualTypeOf<number>();
  });
});
```

## Best Practices

### 1. Test Both Success and Failure

```typescript
it('validates correct data');      // ✅
it('rejects invalid data');        // ✅
```

### 2. Test Transformations

```typescript
it('trims whitespace');            // ✅
it('converts to lowercase');       // ✅
```

### 3. Verify Error Messages

```typescript
expect(error.message).toBe("Custom error");  // ✅
```

### 4. Test Edge Cases

```typescript
it('handles empty string');        // ✅
it('handles very long string');    // ✅
it('handles special characters');  // ✅
```

### 5. Use SafeParse in Tests

```typescript
const result = schema.safeParse(data);  // ✅
try { schema.parse(data) }              // ❌
```

### 6. Test Type Inference

```typescript
expectTypeOf<User>().toEqualTypeOf<ExpectedType>();  // ✅
```

## Test Coverage

Aim for:
- **100% branch coverage** for validation logic
- **100% path coverage** for refinements
- **Edge cases** tested thoroughly
- **Error messages** verified
- **Transformations** validated

## Detailed Examples

For complete implementation examples including integration testing, performance testing, and coverage strategies, see:

**[Testing Patterns Reference](./references/testing-patterns.md)**

## References

- v4 Features: `@zod-4/skills/VALIDATION-string-formats/SKILL.md`
- Error handling: `@zod-4/skills/ERRORS-customization/SKILL.md`
- Transformations: `@zod-4/skills/TRANSFORMATION-string-methods/SKILL.md`
- Performance: `@zod-4/skills/PERFORMANCE-optimization/SKILL.md`
- Comprehensive docs: `@zod-4/knowledge/zod-4-comprehensive.md`

## Success Criteria

- ✅ 100% branch coverage for validation logic
- ✅ Success and failure paths tested
- ✅ Transformations verified
- ✅ Error messages validated
- ✅ Edge cases covered
- ✅ Type inference tested
- ✅ Integration tests pass
- ✅ Performance benchmarks meet targets

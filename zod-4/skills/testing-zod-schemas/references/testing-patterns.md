# Testing Patterns Reference

**For Vitest test structure, describe/it blocks, vi.fn() mocking, and async testing, see `vitest-4/skills/writing-vitest-tests`**

Integration testing examples and performance testing patterns for Zod schemas.

## Integration Testing

### Form Submission with Zod Validation

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';

const loginSchema = z.object({
  email: z.email({ error: 'Invalid email address' }),
  password: z.string().min(8)
});

const LoginForm = () => {
  const onSubmit = (data) => {
    const result = loginSchema.safeParse(data);
    if (!result.success) {
      displayErrors(result.error);
    }
  };
};

const emailInput = screen.getByLabelText('Email');
const submitButton = screen.getByRole('button', { name: 'Login' });

fireEvent.change(emailInput, { target: { value: 'invalid' } });
fireEvent.click(submitButton);

await waitFor(() => {
  expect(screen.getByText('Invalid email address')).toBeInTheDocument();
});
```

### API Endpoint with Zod Validation

```typescript
import request from 'supertest';
import { app } from '../server';

const userSchema = z.object({
  email: z.email().trim().toLowerCase(),
  name: z.string().trim().min(1)
});

app.post('/users', (req, res) => {
  const result = userSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ error: result.error });
  }
  res.status(201).json(result.data);
});

const response = await request(app)
  .post('/users')
  .send({
    email: 'USER@EXAMPLE.COM',
    name: 'John Doe'
  });

expect(response.status).toBe(201);
expect(response.body.email).toBe('user@example.com');
```

## Type Testing

### Type Inference

```typescript
import { z } from 'zod';
import { expectTypeOf } from 'vitest';

const userSchema = z.object({
  email: z.email(),
  age: z.number(),
  name: z.string()
});

type User = z.infer<typeof userSchema>;

expectTypeOf<User>().toEqualTypeOf<{
  email: string;
  age: number;
  name: string;
}>();
```

### Transform Types

```typescript
const schema = z.string().transform(s => parseInt(s));

type Input = z.input<typeof schema>;
type Output = z.output<typeof schema>;

expectTypeOf<Input>().toEqualTypeOf<string>();
expectTypeOf<Output>().toEqualTypeOf<number>();
```

### Branded Types

```typescript
const userId = z.string().brand<'UserId'>();
const productId = z.string().brand<'ProductId'>();

type UserId = z.infer<typeof userId>;
type ProductId = z.infer<typeof productId>;

expectTypeOf<UserId>().not.toEqualTypeOf<ProductId>();
```

## Performance Testing

### Benchmark Validation Speed

```typescript
const schema = z.object({
  email: z.email(),
  name: z.string()
});

const items = Array(10000).fill({
  email: 'user@example.com',
  name: 'John'
});

const start = performance.now();

for (const item of items) {
  schema.parse(item);
}

const duration = performance.now() - start;
expect(duration).toBeLessThan(100);
```

### Compare Parse vs SafeParse

```typescript
const schema = z.string();
const iterations = 10000;

const start = performance.now();
for (let i = 0; i < iterations; i++) {
  try {
    schema.parse('valid');
  } catch {}
}
const parseDuration = performance.now() - start;

const start2 = performance.now();
for (let i = 0; i < iterations; i++) {
  schema.safeParse('valid');
}
const safeParseDuration = performance.now() - start2;

console.log(`parse: ${parseDuration}ms`);
console.log(`safeParse: ${safeParseDuration}ms`);
```

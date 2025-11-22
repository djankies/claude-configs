# Testing Patterns Reference

Integration testing examples and performance testing patterns.


## Integration Testing

### Form Submission

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect } from 'vitest';

describe('LoginForm', () => {
  it('validates email on submit', async () => {
    render(<LoginForm />);

    const emailInput = screen.getByLabelText('Email');
    const submitButton = screen.getByRole('button', { name: 'Login' });

    fireEvent.change(emailInput, { target: { value: 'invalid' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('Invalid email address')).toBeInTheDocument();
    });
  });

  it('submits with valid data', async () => {
    const onSubmit = vi.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    const emailInput = screen.getByLabelText('Email');
    const passwordInput = screen.getByLabelText('Password');
    const submitButton = screen.getByRole('button', { name: 'Login' });

    fireEvent.change(emailInput, { target: { value: 'user@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        email: 'user@example.com',
        password: 'password123'
      });
    });
  });
});
```

### API Endpoint

```typescript
import request from 'supertest';
import { app } from '../server';

describe('POST /users', () => {
  it('creates user with valid data', async () => {
    const response = await request(app)
      .post('/users')
      .send({
        email: 'user@example.com',
        name: 'John Doe'
      });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('id');
    expect(response.body.email).toBe('user@example.com');
  });

  it('returns 400 for invalid email', async () => {
    const response = await request(app)
      .post('/users')
      .send({
        email: 'invalid',
        name: 'John Doe'
      });

    expect(response.status).toBe(400);
    expect(response.body.error).toBeDefined();
  });

  it('transforms email to lowercase', async () => {
    const response = await request(app)
      .post('/users')
      .send({
        email: 'USER@EXAMPLE.COM',
        name: 'John Doe'
      });

    expect(response.status).toBe(201);
    expect(response.body.email).toBe('user@example.com');
  });
});
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
  it('has correct input type', () => {
    expectTypeOf<Input>().toEqualTypeOf<string>();
  });

  it('has correct output type', () => {
    expectTypeOf<Output>().toEqualTypeOf<number>();
  });
});
```

### Branded Types

```typescript
const userId = z.string().brand<'UserId'>();
const productId = z.string().brand<'ProductId'>();

type UserId = z.infer<typeof userId>;
type ProductId = z.infer<typeof productId>;

describe('branded types', () => {
  it('creates distinct types', () => {
    expectTypeOf<UserId>().not.toEqualTypeOf<ProductId>();
  });
});
```

## Performance Testing

### Benchmark Validation Speed

```typescript
import { describe, it, expect } from 'vitest';

describe('validation performance', () => {
  const schema = z.object({
    email: z.email(),
    name: z.string()
  });

  it('validates 10000 items in under 100ms', () => {
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
  });
});
```

### Compare Parse vs SafeParse

```typescript
describe('parse vs safeParse', () => {
  const schema = z.string();
  const iterations = 10000;

  it('benchmarks parse', () => {
    const start = performance.now();

    for (let i = 0; i < iterations; i++) {
      try {
        schema.parse('valid');
      } catch {}
    }

    const parseDuration = performance.now() - start;
    console.log(`parse: ${parseDuration}ms`);
  });

  it('benchmarks safeParse', () => {
    const start = performance.now();

    for (let i = 0; i < iterations; i++) {
      schema.safeParse('valid');
    }

    const safeParseDuration = performance.now() - start;
    console.log(`safeParse: ${safeParseDuration}ms`);
  });
## Performance Testing

### Benchmark Validation Speed

```typescript
import { describe, it, expect } from 'vitest';

describe('validation performance', () => {
  const schema = z.object({
    email: z.email(),
    name: z.string()
  });

  it('validates 10000 items in under 100ms', () => {
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
  });
});
```

### Compare Parse vs SafeParse

```typescript
describe('parse vs safeParse', () => {
  const schema = z.string();
  const iterations = 10000;

  it('benchmarks parse', () => {
    const start = performance.now();

    for (let i = 0; i < iterations; i++) {
      try {
        schema.parse('valid');
      } catch {}
    }

    const parseDuration = performance.now() - start;
    console.log(`parse: ${parseDuration}ms`);
  });

  it('benchmarks safeParse', () => {
    const start = performance.now();

    for (let i = 0; i < iterations; i++) {
      schema.safeParse('valid');
    }

    const safeParseDuration = performance.now() - start;
    console.log(`safeParse: ${safeParseDuration}ms`);
  });
});
```


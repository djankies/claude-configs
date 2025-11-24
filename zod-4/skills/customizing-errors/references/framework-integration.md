# Framework Integration Examples

This document contains detailed framework integration examples for Zod error handling.

## React Forms

```typescript
import { z } from 'zod';
import { useState } from 'react';

const loginSchema = z.object({
  email: z.email({ error: "Invalid email address" }).trim().toLowerCase(),
  password: z.string({ error: "Password required" }).min(8, {
    error: "Password must be at least 8 characters"
  })
});

function LoginForm() {
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);

    const result = loginSchema.safeParse({
      email: formData.get('email'),
      password: formData.get('password')
    });

    if (!result.success) {
      const fieldErrors = result.error.flatten().fieldErrors;
      setErrors({
        email: fieldErrors.email?.[0] ?? '',
        password: fieldErrors.password?.[0] ?? ''
      });
      return;
    }

    setErrors({});
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="email" />
      {errors.email && <span>{errors.email}</span>}

      <input name="password" type="password" />
      {errors.password && <span>{errors.password}</span>}

      <button type="submit">Login</button>
    </form>
  );
}
```

## React Hook Form

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const formSchema = z.object({
  email: z.email(),
  password: z.string().min(8)
});

type FormData = z.infer<typeof formSchema>;

function Form() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(formSchema)
  });

  const onSubmit = (data: FormData) => {
    console.log(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}

      <input {...register('password')} type="password" />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit">Submit</button>
    </form>
  );
}
```

## Next.js Server Actions

```typescript
'use server';

import { z } from 'zod';

const createUserSchema = z.object({
  name: z.string().trim().min(1, { error: "Name required" }),
  email: z.email({ error: "Invalid email" }).trim().toLowerCase()
});

export async function createUser(formData: FormData) {
  const result = createUserSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email')
  });

  if (!result.success) {
    return {
      success: false,
      errors: result.error.flatten().fieldErrors
    };
  }

  await db.users.create({ data: result.data });

  return { success: true };
}
```

## Express API

```typescript
import express from 'express';
import { z } from 'zod';

const app = express();

const userSchema = z.object({
  email: z.email(),
  name: z.string().trim().min(1)
});

app.post('/users', (req, res) => {
  const result = userSchema.safeParse(req.body);

  if (!result.success) {
    return res.status(400).json({
      error: 'Validation failed',
      details: result.error.flatten().fieldErrors
    });
  }

  const user = createUser(result.data);
  res.json(user);
});
```

## Back to Main Guide

See [SKILL.md](../SKILL.md) for the main error handling guide.

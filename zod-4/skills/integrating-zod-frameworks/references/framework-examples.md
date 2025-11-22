## React Hook Form

### Installation

```bash
npm install react-hook-form @hookform/resolvers zod
```

### Basic Integration

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const formSchema = z.object({
  email: z.email({ error: "Invalid email address" }).trim().toLowerCase(),
  password: z.string({ error: "Password required" }).min(8, {
    error: "Password must be at least 8 characters"
  }),
  age: z.number({ error: "Age must be a number" }).min(18, {
    error: "Must be 18 or older"
  })
});

type FormData = z.infer<typeof formSchema>;

function RegistrationForm() {
  const {
    register,
    handleSubmit,
    formState: { errors }
  } = useForm<FormData>({
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

      <input {...register('age', { valueAsNumber: true })} type="number" />
      {errors.age && <span>{errors.age.message}</span>}

      <button type="submit">Register</button>
    </form>
  );
}
```

### Advanced Patterns

**Default values:**
```typescript
const { register, handleSubmit } = useForm<FormData>({
  resolver: zodResolver(formSchema),
  defaultValues: {
    email: '',
    password: '',
    age: 0
  }
});
```

**Conditional validation:**
```typescript
const formSchema = z.object({
  accountType: z.enum(['personal', 'business']),
  businessName: z.string().optional()
}).refine(
  (data) => {
    if (data.accountType === 'business') {
      return !!data.businessName;
    }
    return true;
  },
  {
    error: "Business name required for business accounts",
    path: ['businessName']
  }
);
```

**Array fields:**
```typescript
const schema = z.object({
  tags: z.array(z.string().trim().min(1)).min(1, {
    error: "At least one tag required"
  })
});

function Form() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema)
  });

  return (
    <form>
      <input {...register('tags.0')} />
      <input {...register('tags.1')} />
      {errors.tags && <span>{errors.tags.message}</span>}
    </form>
  );
}
```

## Next.js Server Actions

### Form Validation

```typescript
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';

const createPostSchema = z.object({
  title: z.string({ error: "Title required" }).trim().min(1),
  content: z.string({ error: "Content required" }).trim().min(10, {
    error: "Content must be at least 10 characters"
  }),
  published: z.stringbool()
});

export async function createPost(formData: FormData) {
  const result = createPostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
    published: formData.get('published')
  });

  if (!result.success) {
    return {
      success: false,
      errors: result.error.flatten().fieldErrors
    };
  }

  const post = await db.posts.create({
    data: result.data
  });

  revalidatePath('/posts');

  return {
    success: true,
    data: post
  };
}
```

### Client Component

```typescript
'use client';

import { useFormState, useFormStatus } from 'react-dom';
import { createPost } from './actions';

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Creating...' : 'Create Post'}
    </button>
  );
}

export function CreatePostForm() {
  const [state, formAction] = useFormState(createPost, null);

  return (
    <form action={formAction}>
      <input name="title" />
      {state?.errors?.title && <span>{state.errors.title[0]}</span>}

      <textarea name="content" />
      {state?.errors?.content && <span>{state.errors.content[0]}</span>}

      <input type="checkbox" name="published" value="true" />
      {state?.errors?.published && <span>{state.errors.published[0]}</span>}

      <SubmitButton />
    </form>
  );
}
```

### API Routes

```typescript
import { z } from 'zod';
import { NextRequest, NextResponse } from 'next/server';

const userSchema = z.object({
  email: z.email().trim().toLowerCase(),
  name: z.string().trim().min(1)
});

export async function POST(request: NextRequest) {
  const body = await request.json();

  const result = userSchema.safeParse(body);

  if (!result.success) {
    return NextResponse.json(
      { error: result.error.flatten().fieldErrors },
      { status: 400 }
    );
  }

  const user = await createUser(result.data);

  return NextResponse.json(user);
}
```

## Express

### Middleware Validation

```typescript
import express from 'express';
import { z } from 'zod';

const app = express();
app.use(express.json());

function validate<T extends z.ZodTypeAny>(schema: T) {
  return (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: result.error.flatten().fieldErrors
      });
    }

    req.body = result.data;
    next();
  };
}

const createUserSchema = z.object({
  email: z.email().trim().toLowerCase(),
  password: z.string().min(8),
  name: z.string().trim().min(1)
});

app.post('/users', validate(createUserSchema), async (req, res) => {
  const user = await createUser(req.body);
  res.json(user);
});
```

### Query Parameter Validation

```typescript
const querySchema = z.object({
  page: z.string().transform(s => parseInt(s)).pipe(z.number().min(1)),
  limit: z.string().transform(s => parseInt(s)).pipe(z.number().min(1).max(100)),
  sort: z.enum(['asc', 'desc']).optional()
});

app.get('/users', (req, res) => {
  const result = querySchema.safeParse(req.query);

  if (!result.success) {
    return res.status(400).json({ error: result.error });
  }

  const users = await getUsers(result.data);
  res.json(users);
});
```

## tRPC

### Router with Zod Input

```typescript
import { z } from 'zod';
import { initTRPC } from '@trpc/server';

const t = initTRPC.create();

const createUserInput = z.object({
  email: z.email().trim().toLowerCase(),
  name: z.string().trim().min(1),
  age: z.number().min(18)
});

export const appRouter = t.router({
  createUser: t.procedure
    .input(createUserInput)
    .mutation(async ({ input }) => {
      const user = await db.users.create({ data: input });
      return user;
    }),

  getUser: t.procedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input }) => {
      const user = await db.users.findUnique({
        where: { id: input.id }
      });
      return user;
    })
});

export type AppRouter = typeof appRouter;
```

### Client Usage

```typescript
import { createTRPCProxyClient, httpBatchLink } from '@trpc/client';
import type { AppRouter } from './server';

const client = createTRPCProxyClient<AppRouter>({
  links: [
    httpBatchLink({
      url: 'http://localhost:3000/trpc',
    }),
  ],
});

const user = await client.createUser.mutate({
  email: 'user@example.com',
  name: 'John Doe',
  age: 25
});
```

## GraphQL (with Pothos)

### Schema Definition

```typescript
import { z } from 'zod';
import SchemaBuilder from '@pothos/core';
import ValidationPlugin from '@pothos/plugin-validation';

const builder = new SchemaBuilder({
  plugins: [ValidationPlugin],
  validationOptions: {
    validationError: (zodError) => zodError
  }
});

const CreateUserInput = builder.inputType('CreateUserInput', {
  validate: {
    schema: z.object({
      email: z.email().trim().toLowerCase(),
      name: z.string().trim().min(1)
    })
  },
  fields: (t) => ({
    email: t.string({ required: true }),
    name: t.string({ required: true })
  })
});

builder.mutationType({
  fields: (t) => ({
    createUser: t.field({
      type: User,
      args: {
        input: t.arg({ type: CreateUserInput, required: true })
      },
      resolve: async (parent, { input }) => {
        return await createUser(input);
      }
    })
  })
});
```

## Prisma Integration

### Schema Validation

```typescript
import { z } from 'zod';
import { Prisma } from '@prisma/client';

const userCreateSchema = z.object({
  email: z.email().trim().toLowerCase(),
  name: z.string().trim().min(1),
  age: z.number().min(18).optional()
}) satisfies z.ZodType<Prisma.UserCreateInput>;

async function createUser(data: unknown) {
  const validated = userCreateSchema.parse(data);
  return await prisma.user.create({ data: validated });
}
```

### Generate Zod Schemas from Prisma

```bash
npm install zod-prisma-types
```

```prisma
generator zod {
  provider = "zod-prisma-types"
}

model User {
  id    String @id @default(cuid())
  email String @unique
  name  String
}
```

Generates Zod schemas automatically from Prisma models.

## React Query

### Mutation with Validation

```typescript
import { useMutation } from '@tanstack/react-query';
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.email().trim().toLowerCase(),
  name: z.string().trim().min(1)
});

type CreateUserInput = z.infer<typeof createUserSchema>;

async function createUser(input: CreateUserInput) {
  const validated = createUserSchema.parse(input);

  const response = await fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(validated)
  });

  return response.json();
}

function useCreateUser() {
  return useMutation({
    mutationFn: createUser
  });
}
```

## Fastify

### Plugin for Validation

```typescript
import Fastify from 'fastify';
import { z } from 'zod';

const fastify = Fastify();

const createUserSchema = z.object({
  email: z.email().trim().toLowerCase(),
  name: z.string().trim().min(1)
});

fastify.post('/users', {
  schema: {
    body: {
      type: 'object',
      required: ['email', 'name'],
      properties: {
        email: { type: 'string' },
        name: { type: 'string' }
      }
    }
  },
  preHandler: async (request, reply) => {
    const result = createUserSchema.safeParse(request.body);

    if (!result.success) {
      reply.status(400).send({
        error: result.error.flatten().fieldErrors
      });
      return;
    }

    request.body = result.data;
  }
}, async (request, reply) => {
  const user = await createUser(request.body);
  return user;
});
```


---
name: securing-server-actions
description: Teach server action authentication and security patterns in Next.js 16. Use when implementing server actions, form handlers, or mutations that need authentication.
allowed-tools: Read, Write, Edit, Glob, Grep, TodoWrite
version: 1.0.0
---

# Server Actions Security

Secure server actions with authentication, authorization, and validation.

## Authentication Pattern

Every server action must verify the session before processing:

```typescript
'use server'

import { verifySession } from '@/lib/dal'
import { z } from 'zod'

const updateProfileSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email()
})

export async function updateProfile(formData: FormData) {
  const session = await verifySession()
  if (!session) {
    return { error: 'Unauthorized' }
  }

  const validatedFields = updateProfileSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email')
  })

  if (!validatedFields.success) {
    return {
      error: 'Validation failed',
      fields: validatedFields.error.flatten().fieldErrors
    }
  }

  const { name, email } = validatedFields.data
  await db.user.update({
    where: { id: session.userId },
    data: { name, email }
  })

  return { success: true }
}
```

## Authorization Checks

Verify user permissions beyond authentication:

```typescript
'use server'

import { verifySession } from '@/lib/dal'
import { z } from 'zod'

const deletePostSchema = z.object({
  postId: z.string().uuid()
})

export async function deletePost(formData: FormData) {
  const session = await verifySession()
  if (!session) {
    return { error: 'Unauthorized' }
  }

  const validatedFields = deletePostSchema.safeParse({
    postId: formData.get('postId')
  })

  if (!validatedFields.success) {
    return { error: 'Invalid post ID' }
  }

  const post = await db.post.findUnique({
    where: { id: validatedFields.data.postId }
  })

  if (!post) {
    return { error: 'Post not found' }
  }

  if (post.authorId !== session.userId && session.role !== 'admin') {
    return { error: 'Forbidden: You cannot delete this post' }
  }

  await db.post.delete({
    where: { id: validatedFields.data.postId }
  })

  return { success: true }
}
```

## Multi-Layer Security

Implement defense in depth with multiple security layers:

```typescript
'use server'

import { verifySession } from '@/lib/dal'
import { z } from 'zod'
import { rateLimit } from '@/lib/rate-limit'

const transferFundsSchema = z.object({
  toUserId: z.string().uuid(),
  amount: z.number().positive().max(10000)
})

export async function transferFunds(formData: FormData) {
  const session = await verifySession()
  if (!session) {
    return { error: 'Unauthorized' }
  }

  const rateLimitResult = await rateLimit(session.userId, 'transfer', {
    max: 5,
    window: '1h'
  })

  if (!rateLimitResult.success) {
    return {
      error: 'Rate limit exceeded',
      retryAfter: rateLimitResult.retryAfter
    }
  }

  const validatedFields = transferFundsSchema.safeParse({
    toUserId: formData.get('toUserId'),
    amount: Number(formData.get('amount'))
  })

  if (!validatedFields.success) {
    return {
      error: 'Validation failed',
      fields: validatedFields.error.flatten().fieldErrors
    }
  }

  const { toUserId, amount } = validatedFields.data

  if (toUserId === session.userId) {
    return { error: 'Cannot transfer to yourself' }
  }

  const balance = await db.account.findUnique({
    where: { userId: session.userId },
    select: { balance: true }
  })

  if (!balance || balance.balance < amount) {
    return { error: 'Insufficient funds' }
  }

  await db.$transaction([
    db.account.update({
      where: { userId: session.userId },
      data: { balance: { decrement: amount } }
    }),
    db.account.update({
      where: { userId: toUserId },
      data: { balance: { increment: amount } }
    })
  ])

  return { success: true }
}
```

## Validation Patterns

For comprehensive Zod validation patterns and runtime type checking, see @typescript/VALIDATION-runtime-checks.

Structure validation schemas for reusability:

```typescript
'use server'

import { verifySession } from '@/lib/dal'
import { z } from 'zod'

const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(50000),
  tags: z.array(z.string()).max(5).optional(),
  published: z.boolean().default(false)
})

type CreatePostInput = z.infer<typeof createPostSchema>

export async function createPost(formData: FormData) {
  const session = await verifySession()
  if (!session) {
    return { error: 'Unauthorized' }
  }

  const tags = formData.getAll('tags').filter(Boolean) as string[]

  const validatedFields = createPostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
    tags: tags.length > 0 ? tags : undefined,
    published: formData.get('published') === 'true'
  })

  if (!validatedFields.success) {
    return {
      error: 'Validation failed',
      fields: validatedFields.error.flatten().fieldErrors
    }
  }

  const post = await createPostInDb(session.userId, validatedFields.data)

  return { success: true, postId: post.id }
}

async function createPostInDb(userId: string, data: CreatePostInput) {
  return db.post.create({
    data: {
      ...data,
      authorId: userId
    }
  })
}
```

## Security Checklist

Every server action must implement:

1. **Authentication**: Call `verifySession()` first
2. **Authorization**: Verify user permissions for the operation
3. **Validation**: Parse and validate all inputs with Zod
4. **Rate Limiting**: Protect sensitive operations
5. **Error Handling**: Return safe error messages without leaking data

## Integration with Forms

For comprehensive form state management patterns and action state handling, see @react-19/HOOKS-use-action-state.

Use with React 19's useActionState hook for form state management:

```typescript
'use client'

import { useActionState } from 'react'
import { updateProfile } from './actions'

export function ProfileForm() {
  const [state, action, isPending] = useActionState(updateProfile, null)

  return (
    <form action={action}>
      <input name="name" required />
      {state?.fields?.name && <span>{state.fields.name[0]}</span>}

      <input name="email" type="email" required />
      {state?.fields?.email && <span>{state.fields.email[0]}</span>}

      {state?.error && <div>{state.error}</div>}

      <button disabled={isPending}>
        {isPending ? 'Saving...' : 'Save'}
      </button>
    </form>
  )
}
```

## Common Vulnerabilities

Avoid these security mistakes:

```typescript
export async function badAction(formData: FormData) {
  const postId = formData.get('postId') as string

  await db.post.delete({ where: { id: postId } })

  return { success: true }
}
```

Problems:
- No authentication check
- No authorization check
- No input validation
- No error handling

Correct implementation:

```typescript
'use server'

import { verifySession } from '@/lib/dal'
import { z } from 'zod'

const deletePostSchema = z.object({
  postId: z.string().uuid()
})

export async function deletePost(formData: FormData) {
  const session = await verifySession()
  if (!session) {
    return { error: 'Unauthorized' }
  }

  const validatedFields = deletePostSchema.safeParse({
    postId: formData.get('postId')
  })

  if (!validatedFields.success) {
    return { error: 'Invalid input' }
  }

  const post = await db.post.findUnique({
    where: { id: validatedFields.data.postId }
  })

  if (!post) {
    return { error: 'Post not found' }
  }

  if (post.authorId !== session.userId) {
    return { error: 'Forbidden' }
  }

  await db.post.delete({
    where: { id: validatedFields.data.postId }
  })

  return { success: true }
}
```

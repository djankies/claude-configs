# Type Safety Guide

## Inferred Types

TypeScript infers exact return types based on selection:

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  select: {
    name: true,
    email: true,
    posts: {
      select: {
        title: true,
      },
    },
  },
})
```

Inferred type:
```typescript
{
  name: string
  email: string
  posts: {
    title: string
  }[]
} | null
```

## Reusable Selection Objects

Create reusable selection objects:

```typescript
const userBasicSelect = {
  id: true,
  name: true,
  email: true,
} as const

const users = await prisma.user.findMany({
  select: userBasicSelect,
})
```

## Composition Patterns

Build complex selections from smaller pieces:

```typescript
const authorSelect = {
  id: true,
  name: true,
  email: true,
} as const

const postSelect = {
  id: true,
  title: true,
  author: {
    select: authorSelect,
  },
} as const

const posts = await prisma.post.findMany({
  select: postSelect,
})
```

## Type Extraction

Extract types from selection objects:

```typescript
import { Prisma } from '@prisma/client'

const postWithAuthor = Prisma.validator<Prisma.PostDefaultArgs>()({
  select: {
    id: true,
    title: true,
    author: {
      select: {
        id: true,
        name: true,
      },
    },
  },
})

type PostWithAuthor = Prisma.PostGetPayload<typeof postWithAuthor>
```

## Benefits

- **Type safety:** Compiler catches field typos
- **Refactoring:** Changes propagate through types
- **Reusability:** Share selection patterns
- **Documentation:** Types serve as inline docs

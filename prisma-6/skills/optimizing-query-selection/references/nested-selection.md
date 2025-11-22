# Nested Selection Patterns

## Deep Relation Hierarchies

Select fields deep in relation hierarchies:

```typescript
const posts = await prisma.post.findMany({
  select: {
    title: true,
    author: {
      select: {
        name: true,
        profile: {
          select: {
            avatar: true,
          },
        },
      },
    },
    comments: {
      select: {
        content: true,
        author: {
          select: {
            name: true,
          },
        },
      },
      take: 5,
      orderBy: {
        createdAt: 'desc',
      },
    },
  },
})
```

## Combining Select with Filtering

Optimize both data transfer and query performance:

```typescript
const recentPosts = await prisma.post.findMany({
  where: {
    published: true,
    createdAt: {
      gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    },
  },
  select: {
    id: true,
    title: true,
    excerpt: true,
    createdAt: true,
    author: {
      select: {
        id: true,
        name: true,
      },
    },
    _count: {
      select: {
        comments: true,
        likes: true,
      },
    },
  },
  orderBy: {
    createdAt: 'desc',
  },
  take: 10,
})
```

## Key Principles

- Nest selections to match data shape requirements
- Use `take` on nested relations to prevent over-fetching
- Combine `orderBy` with nested relations for sorted results
- Use `_count` for relation counts instead of loading all records

# API Optimization Patterns

## API Endpoint Optimization

```typescript
export async function GET(request: Request) {
  const posts = await prisma.post.findMany({
    where: { published: true },
    select: {
      id: true,
      title: true,
      slug: true,
      excerpt: true,
      publishedAt: true,
      author: {
        select: {
          name: true,
          avatar: true,
        },
      },
      _count: {
        select: {
          comments: true,
        },
      },
    },
    orderBy: {
      publishedAt: 'desc',
    },
    take: 20,
  })

  return Response.json(posts)
}
```

## List vs Detail Views

### List View: Minimal Fields

```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    email: true,
    role: true,
    _count: {
      select: {
        posts: true,
      },
    },
  },
})
```

### Detail View: More Complete Data

```typescript
const user = await prisma.user.findUnique({
  where: { id },
  select: {
    id: true,
    name: true,
    email: true,
    role: true,
    bio: true,
    avatar: true,
    createdAt: true,
    posts: {
      select: {
        id: true,
        title: true,
        publishedAt: true,
        _count: {
          select: {
            comments: true,
          },
        },
      },
      orderBy: {
        publishedAt: 'desc',
      },
      take: 10,
    },
    _count: {
      select: {
        posts: true,
        comments: true,
        followers: true,
      },
    },
  },
})
```

## Pagination with Select

```typescript
async function getPaginatedPosts(page: number, pageSize: number) {
  const [posts, total] = await Promise.all([
    prisma.post.findMany({
      select: {
        id: true,
        title: true,
        excerpt: true,
        author: {
          select: {
            name: true,
          },
        },
      },
      skip: page * pageSize,
      take: pageSize,
      orderBy: {
        createdAt: 'desc',
      },
    }),
    prisma.post.count(),
  ])

  return {
    posts,
    pagination: {
      page,
      pageSize,
      total,
      pages: Math.ceil(total / pageSize),
    },
  }
}
```

## Key Patterns

- **List views:** Minimize fields, use `_count` for relations
- **Detail views:** Include necessary relations with limits
- **API responses:** Always use `select` to control shape
- **Pagination:** Combine `select` with `take`/`skip`

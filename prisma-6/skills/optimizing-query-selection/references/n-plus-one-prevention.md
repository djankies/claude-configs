# N+1 Prevention Guide

## Anti-Patterns

### Over-fetching

**Problem:**
```typescript
const user = await prisma.user.findUnique({
  where: { id },
  include: {
    posts: {
      include: {
        comments: {
          include: {
            author: true,
          },
        },
      },
    },
  },
})
```

**Issue:** Fetches thousands of records, massive data transfer

**Fix:** Use select with limits

```typescript
const user = await prisma.user.findUnique({
  where: { id },
  select: {
    id: true,
    name: true,
    posts: {
      select: {
        id: true,
        title: true,
        _count: {
          select: {
            comments: true,
          },
        },
      },
      take: 10,
      orderBy: {
        createdAt: 'desc',
      },
    },
  },
})
```

### Inconsistent Selection

**Problem:**
```typescript
const posts = await prisma.post.findMany({
  include: {
    author: true,
  },
})
```

**Issue:** Full author object when only name needed

**Fix:** Select specific fields

```typescript
const posts = await prisma.post.findMany({
  select: {
    id: true,
    title: true,
    author: {
      select: {
        name: true,
      },
    },
  },
})
```

### Selecting Then Filtering

**Problem:**
```typescript
const users = await prisma.user.findMany()
const activeUsers = users.filter(u => u.status === 'active')
```

**Issue:** Fetches all users, filters in application

**Fix:** Filter in database

```typescript
const activeUsers = await prisma.user.findMany({
  where: { status: 'active' },
  select: {
    id: true,
    name: true,
    email: true,
  },
})
```

## Prevention Strategies

1. **Always load relations upfront** - Never query in loops
2. **Use select with relations** - Don't fetch unnecessary fields
3. **Add take limits** - Prevent accidental bulk loads
4. **Use _count** - Don't load relations just to count
5. **Test with realistic data** - N+1 only shows at scale

# Cache Invalidation Patterns

## Event-Based Invalidation

**Invalidate immediately when data changes:**

```typescript
async function createPost(data: { title: string; content: string; authorId: string }) {
  const post = await prisma.post.create({ data })

  await Promise.all([
    redis.del(`posts:author:${data.authorId}`),
    redis.del('posts:recent'),
    redis.del('posts:popular'),
  ])

  return post
}
```

**Use when:** Data must be consistent, cache staleness unacceptable.

## Time-Based Expiration

**Let TTL handle invalidation:**

```typescript
async function getRecentPosts() {
  const cached = await redis.get('posts:recent')
  if (cached) return JSON.parse(cached)

  const posts = await prisma.post.findMany({
    orderBy: { createdAt: 'desc' },
    take: 10,
  })

  await redis.setex('posts:recent', 300, JSON.stringify(posts))
  return posts
}
```

**Use when:** Staleness acceptable for TTL duration, mutations infrequent.

## Hybrid Strategy

**Combine TTL with event-based invalidation:**

```typescript
async function updatePost(postId: string, data: { title?: string }) {
  const post = await prisma.post.update({
    where: { id: postId },
    data,
  })

  await redis.del(`post:${postId}`)

  return post
}

async function getPost(postId: string) {
  const cached = await redis.get(`post:${postId}`)
  if (cached) return JSON.parse(cached)

  const post = await prisma.post.findUnique({
    where: { id: postId },
  })

  if (post) {
    await redis.setex(`post:${postId}`, 600, JSON.stringify(post))
  }

  return post
}
```

**Use when:** Mutations trigger immediate invalidation, TTL provides safety net for missed invalidations.

## Conditional Workflows

**If data changes frequently (multiple times per minute):**

1. Avoid caching or use very short TTL (5-30 seconds)
2. Consider real-time updates instead of caching
3. Use event-based invalidation for consistency

**If data changes rarely (hours/days between updates):**

1. Use longer TTL (5-60 minutes)
2. Implement event-based invalidation on mutations
3. Consider cache warming on startup

**If data has read/write ratio > 10:1:**

1. Strong cache candidate
2. Implement cache-aside pattern
3. Use background cache warming for popular data

**If data has read/write ratio < 3:1:**

1. Weak cache candidate
2. Consider query optimization instead
3. Cache only if database is bottleneck

**If data must be consistent:**

1. Use short TTL with event-based invalidation
2. Consider cache-through or write-behind patterns
3. Add cache versioning for atomic updates

# Advanced Caching Examples

## Bulk Invalidation

**Invalidate multiple related keys efficiently:**

```typescript
async function invalidateUserCache(userId: string) {
  const patterns = [
    `user:${userId}`,
    `user_profile:${userId}`,
    `user_settings:${userId}`,
    `posts:author:${userId}`,
    `comments:author:${userId}`,
  ]

  await redis.del(...patterns)
}

async function invalidatePostCache(postId: string) {
  const post = await prisma.post.findUnique({
    where: { id: postId },
    select: { authorId: true },
  })

  if (!post) return

  const keys = await redis.keys(`posts:*`)

  await Promise.all([
    redis.del(`post:${postId}`),
    redis.del(`posts:author:${post.authorId}`),
    keys.length > 0 ? redis.del(...keys) : Promise.resolve(),
  ])
}
```

**Pattern:** Collect all related keys and invalidate in a single operation to maintain consistency.

## Cache Warming

**Pre-populate cache with frequently accessed data:**

```typescript
async function warmCache() {
  const popularPosts = await prisma.post.findMany({
    where: { published: true },
    orderBy: { views: 'desc' },
    take: 20,
  })

  await Promise.all(
    popularPosts.map(post =>
      redis.setex(
        `post:${post.id}`,
        300,
        JSON.stringify(post)
      )
    )
  )

  const activeUsers = await prisma.user.findMany({
    where: { lastActiveAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } },
    take: 50,
  })

  await Promise.all(
    activeUsers.map(user =>
      redis.setex(
        `user:${user.id}`,
        600,
        JSON.stringify(user)
      )
    )
  )
}
```

**Pattern:** Pre-populate cache on application startup or scheduled intervals for predictably popular data.

## Graceful Fallback

**Handle Redis failures without breaking application:**

```typescript
async function getCachedData<T>(
  key: string,
  fetchFn: () => Promise<T>
): Promise<T> {
  try {
    const cached = await redis.get(key)
    if (cached) {
      return JSON.parse(cached)
    }
  } catch (err) {
    console.error('Redis error, falling back to database:', err)
  }

  const data = await fetchFn()

  try {
    await redis.setex(key, 300, JSON.stringify(data))
  } catch (err) {
    console.error('Failed to cache data:', err)
  }

  return data
}

async function getUserProfile(userId: string) {
  return getCachedData(
    `user_profile:${userId}`,
    () => prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    })
  )
}
```

**Pattern:** Wrap all Redis operations in try/catch, always fallback to database on error.

## Advanced TTL Strategy

**Multi-tier caching with different TTL per tier:**

```typescript
const CACHE_TIERS = {
  hot: 60,
  warm: 300,
  cold: 1800,
}

interface CacheOptions {
  tier: keyof typeof CACHE_TIERS
  keyPrefix: string
}

async function tieredCache<T>(
  identifier: string,
  options: CacheOptions,
  fetchFn: () => Promise<T>
): Promise<T> {
  const cacheKey = `${options.keyPrefix}:${identifier}`
  const ttl = CACHE_TIERS[options.tier]

  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }

  const data = await fetchFn()
  await redis.setex(cacheKey, ttl, JSON.stringify(data))

  return data
}

async function getTrendingPosts() {
  return tieredCache(
    'trending',
    { tier: 'hot', keyPrefix: 'posts' },
    () => prisma.post.findMany({
      where: { published: true },
      orderBy: { views: 'desc' },
      take: 10,
    })
  )
}

async function getArchivedPosts() {
  return tieredCache(
    'archived',
    { tier: 'cold', keyPrefix: 'posts' },
    () => prisma.post.findMany({
      where: { archived: true },
      orderBy: { archivedAt: 'desc' },
      take: 20,
    })
  )
}
```

**Pattern:** Classify data into tiers based on access patterns, assign appropriate TTL per tier.

# Common Pitfalls

## Pitfall 1: Infinite TTL

**Problem:** Setting cache values without TTL leads to stale data and memory growth.

**Solution:** Always use `setex()` or `set()` with `EX` option. Never use `set()` alone.

```typescript
await redis.setex(key, 300, value)
```

## Pitfall 2: Cache Key Inconsistency

**Problem:** Query parameter order affects cache key, causing cache misses.

**Solution:** Sort object keys before hashing or use deterministic key generation.

```typescript
function generateKey(obj: Record<string, unknown>) {
  const sorted = Object.keys(obj).sort().reduce((acc, key) => {
    acc[key] = obj[key]
    return acc
  }, {} as Record<string, unknown>)
  return JSON.stringify(sorted)
}
```

## Pitfall 3: Missing Invalidation Paths

**Problem:** Cache invalidated on direct updates but not on related mutations.

**Solution:** Map all mutation paths and ensure comprehensive invalidation.

```typescript
async function deleteUser(userId: string) {
  await prisma.user.delete({ where: { id: userId } })

  await Promise.all([
    redis.del(`user:${userId}`),
    redis.del(`posts:author:${userId}`),
    redis.del(`comments:author:${userId}`),
  ])
}
```

## Pitfall 4: Caching Pagination Without Page Number

**Problem:** Different pages cached with same key, returning wrong results.

**Solution:** Include skip/take or cursor in cache key.

```typescript
const cacheKey = `posts:skip:${skip}:take:${take}`
```

## Pitfall 5: No Redis Fallback

**Problem:** Application crashes when Redis unavailable.

**Solution:** Wrap Redis operations in try/catch, fallback to database.

```typescript
async function getCachedData(key: string, fetchFn: () => Promise<unknown>) {
  try {
    const cached = await redis.get(key)
    if (cached) return JSON.parse(cached)
  } catch (err) {
    console.error('Redis error, falling back to database:', err)
  }

  return fetchFn()
}
```

## Pitfall 6: Caching Sensitive Data

**Problem:** Storing passwords, tokens, or sensitive credentials in cache.

**Solution:** Never cache authentication tokens, passwords, or PII without encryption.

```typescript
async function getCachedUser(userId: string) {
  const cacheKey = `user:${userId}`

  const cached = await redis.get(cacheKey)
  if (cached) return JSON.parse(cached)

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      name: true,
      role: true,
    },
  })

  if (user) {
    await redis.setex(cacheKey, 300, JSON.stringify(user))
  }

  return user
}
```

## Pitfall 7: Pattern Matching in Hot Paths

**Problem:** Using `redis.keys('pattern:*')` in high-traffic endpoints causes performance degradation.

**Solution:** Use Redis SCAN for pattern matching or maintain explicit key sets.

```typescript
async function invalidatePostCacheSafe(postId: string) {
  const cursor = '0'
  const pattern = 'posts:*'
  const keysToDelete: string[] = []

  let currentCursor = cursor
  do {
    const [nextCursor, keys] = await redis.scan(
      currentCursor,
      'MATCH',
      pattern,
      'COUNT',
      100
    )
    keysToDelete.push(...keys)
    currentCursor = nextCursor
  } while (currentCursor !== '0')

  if (keysToDelete.length > 0) {
    await redis.del(...keysToDelete)
  }

  await redis.del(`post:${postId}`)
}
```

## Pitfall 8: Serialization Issues

**Problem:** Storing Prisma model instances directly without serialization.

**Solution:** Always use JSON.stringify for caching, JSON.parse for retrieval.

```typescript
const user = await prisma.user.findUnique({ where: { id: userId } })

await redis.setex(
  `user:${userId}`,
  300,
  JSON.stringify(user)
)

const cached = await redis.get(`user:${userId}`)
if (cached) {
  const user = JSON.parse(cached)
  return user
}
```

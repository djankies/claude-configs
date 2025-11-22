---
name: implementing-query-caching
description: Implement query result caching with Redis and proper invalidation strategies for Prisma 6. Use when optimizing frequently accessed data, improving read-heavy application performance, or reducing database load through caching.
allowed-tools: Read, Write, Edit
version: 1.0.0
---

# Query Result Caching with Redis

This skill teaches how to implement efficient query result caching for Prisma 6 applications using Redis, including cache key generation, invalidation strategies, and TTL management.

---

<role>
This skill teaches Claude how to implement query result caching with Redis for Prisma 6 applications, following best practices for cache key generation, invalidation, TTL strategies, and determining when caching provides value.
</role>

<when-to-activate>
This skill activates when:

- User mentions caching, Redis, performance optimization, or slow queries
- Working with read-heavy applications or frequently accessed data
- Request involves reducing database load or improving response times
- Implementing cache invalidation or cache warming strategies
- Optimizing Prisma queries with caching layers
</when-to-activate>

<overview>
Query result caching with Redis reduces database load and improves response times for read-heavy operations. However, caching adds complexity through cache invalidation, consistency challenges, and infrastructure requirements.

Key capabilities:

1. Redis integration with Prisma queries
2. Consistent cache key generation patterns
3. Cache invalidation on mutations
4. TTL strategies (time-based vs event-based)
5. Identifying when caching provides value
</overview>

<workflow>
## Standard Workflow

**Phase 1: Identify Cache Candidates**

1. Analyze query patterns to find read-heavy operations
2. Identify data with acceptable staleness tolerance
3. Measure query performance without caching (baseline)
4. Estimate cache hit rate and performance improvement

**Phase 2: Implement Cache Layer**

1. Set up Redis client with connection pooling
2. Create cache wrapper around Prisma queries
3. Implement consistent cache key generation
4. Add cache read with fallback to database

**Phase 3: Implement Invalidation**

1. Identify mutations that affect cached data
2. Add cache invalidation to update/delete operations
3. Handle bulk operations and cascading invalidation
4. Test invalidation across different scenarios

**Phase 4: Configure TTL Strategy**

1. Determine appropriate TTL for each data type
2. Implement time-based expiration
3. Add event-based invalidation for critical data
4. Monitor cache hit rates and adjust
</workflow>

<decision-tree>
## When to Cache

### Strong Cache Candidates

**Read-heavy data (read/write ratio > 10:1):**
- User profiles
- Product catalogs
- Configuration data
- Popular content lists

**Expensive queries:**
- Aggregations across large datasets
- Multi-join queries
- Complex filtering with multiple conditions
- Computed/derived values

**High-frequency access:**
- Homepage data
- Navigation menus
- Popular search results
- Trending content

### Weak Cache Candidates

**Write-heavy data (read/write ratio < 3:1):**
- Real-time analytics
- User activity logs
- Chat messages
- Live updates

**Frequently changing data:**
- Stock prices
- Inventory counts
- Auction bids
- Live sports scores

**User-specific data:**
- Shopping carts
- Draft content
- Personalized recommendations
- Session data

**Small result sets with fast queries:**
- Single record lookups by primary key
- Simple queries with database indexes
- Data already in database cache

### Cache Strategy Decision Tree

```
Is read/write ratio > 10:1?
├─ Yes: Strong cache candidate
│  └─ Can data be stale for 1+ minutes?
│     ├─ Yes: Use long TTL (5-60 min) + event invalidation
│     └─ No: Use short TTL (10-60 sec) + aggressive invalidation
│
└─ No: Is read/write ratio > 3:1?
   ├─ Yes: Moderate cache candidate
   │  └─ Is query expensive (> 100ms)?
   │     ├─ Yes: Cache with short TTL (30-120 sec)
   │     └─ No: Skip caching, optimize query instead
   │
   └─ No: Skip caching
      └─ Consider query optimization, database indexes, or connection pooling
```
</decision-tree>

<examples>
## Basic Examples

### Example 1: Cache Wrapper

**Cache-aside pattern with automatic fallback:**

```typescript
import { PrismaClient } from '@prisma/client'
import { Redis } from 'ioredis'

const prisma = new PrismaClient()
const redis = new Redis({
  host: process.env.REDIS_HOST,
  port: parseInt(process.env.REDIS_PORT || '6379'),
  maxRetriesPerRequest: 3,
})

async function getCachedUser(userId: string) {
  const cacheKey = `user:${userId}`

  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, email: true, name: true, role: true },
  })

  if (user) {
    await redis.setex(cacheKey, 300, JSON.stringify(user))
  }

  return user
}
```

### Example 2: Cache Key Generation

**Consistent key generation for complex queries:**

```typescript
import crypto from 'crypto'

function generateCacheKey(
  entity: string,
  query: Record<string, unknown>
): string {
  const sortedQuery = Object.keys(query)
    .sort()
    .reduce((acc, key) => {
      acc[key] = query[key]
      return acc
    }, {} as Record<string, unknown>)

  const queryHash = crypto
    .createHash('sha256')
    .update(JSON.stringify(sortedQuery))
    .digest('hex')
    .slice(0, 16)

  return `${entity}:${queryHash}`
}

async function getCachedPosts(filters: {
  authorId?: string
  published?: boolean
  tags?: string[]
}) {
  const cacheKey = generateCacheKey('posts', filters)

  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }

  const posts = await prisma.post.findMany({
    where: filters,
    select: { id: true, title: true, createdAt: true },
  })

  await redis.setex(cacheKey, 120, JSON.stringify(posts))
  return posts
}
```

### Example 3: Cache Invalidation

**Invalidate related cache entries when data changes:**

```typescript
async function updatePost(postId: string, data: { title?: string; content?: string }) {
  const post = await prisma.post.update({
    where: { id: postId },
    data,
  })

  await Promise.all([
    redis.del(`post:${postId}`),
    redis.del(`posts:author:${post.authorId}`),
    redis.keys('posts:*').then(keys => {
      if (keys.length > 0) return redis.del(...keys)
    }),
  ])

  return post
}
```

**Warning:** Using `redis.keys()` with pattern matching can be slow with many keys. Consider using Redis SCAN or maintaining key sets for invalidation.

### Example 4: TTL Strategies

**Different TTL strategies for different data types:**

```typescript
const TTL_STRATEGIES = {
  user_profile: 600,
  user_settings: 300,
  posts_list: 120,
  post_detail: 180,
  popular_posts: 60,
  real_time_stats: 10,
}

async function cacheWithTTL<T>(
  key: string,
  ttlType: keyof typeof TTL_STRATEGIES,
  fetchFn: () => Promise<T>
): Promise<T> {
  const cached = await redis.get(key)
  if (cached) {
    return JSON.parse(cached)
  }

  const data = await fetchFn()
  const ttl = TTL_STRATEGIES[ttlType]

  await redis.setex(key, ttl, JSON.stringify(data))
  return data
}
```
</examples>

<constraints>
## Constraints and Guidelines

**MUST:**

- Use cache-aside pattern (not cache-through) for Prisma queries
- Implement consistent cache key generation (no random/timestamp components)
- Invalidate cache on all mutations affecting cached data
- Handle Redis connection failures gracefully (fallback to database)
- Use JSON.parse/stringify for serialization (consistent with Prisma types)
- Set TTL on all cached values (no infinite TTL)
- Test cache invalidation thoroughly

**SHOULD:**

- Use Redis connection pooling (ioredis library)
- Separate cache logic from business logic (wrapper functions)
- Monitor cache hit rates and adjust TTL accordingly
- Use shorter TTL for frequently changing data
- Implement cache warming for predictably popular data
- Document cache key patterns and invalidation rules
- Consider using Redis SCAN instead of KEYS for pattern matching

**NEVER:**

- Cache authentication tokens or sensitive credentials
- Use infinite TTL (always set expiration)
- Invalidate cache by pattern matching in hot paths (slow with many keys)
- Cache Prisma queries with skip/take without including pagination in key
- Assume cache is always available (always have database fallback)
- Store Prisma model instances directly (serialize to JSON first)
- Use cache for write-heavy data (read/write ratio < 3:1)
</constraints>

<validation>
## Validation

After implementing caching:

1. **Cache Hit Rate:**

   - Monitor cache hit rate > 60% for effective caching
   - If hit rate < 40%, reconsider cache strategy or TTL
   - Log cache hits/misses during development

2. **Invalidation Testing:**

   - Test all mutation paths invalidate correct keys
   - Verify cascading invalidation for related entities
   - Check bulk operations invalidate list caches
   - Ensure no stale data after mutations

3. **Performance Improvement:**

   - Measure query latency with and without cache
   - Target > 50% latency reduction for cached queries
   - Monitor P95/P99 latency improvements
   - Verify caching doesn't increase memory pressure

4. **Redis Health:**
   - Monitor Redis connection pool utilization
   - Check Redis memory usage (set maxmemory-policy)
   - Alert on Redis connection failures
   - Test application behavior when Redis is down
</validation>

---

## References

For additional implementation details and patterns, see:

- [Redis Configuration](./references/redis-configuration.md) - Connection setup, serverless considerations
- [Invalidation Patterns](./references/invalidation-patterns.md) - Event-based, time-based, hybrid strategies
- [Advanced Examples](./references/advanced-examples.md) - Bulk invalidation, cache warming
- [Common Pitfalls](./references/common-pitfalls.md) - Infinite TTL, key inconsistency, missing invalidation

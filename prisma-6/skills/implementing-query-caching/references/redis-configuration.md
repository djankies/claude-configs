# Redis Configuration

## Connection Setup

**ioredis client with connection pooling:**

```typescript
import { Redis } from 'ioredis'

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD,
  db: parseInt(process.env.REDIS_DB || '0'),
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000)
    return delay
  },
  lazyConnect: true,
})

redis.on('error', (err) => {
  console.error('Redis connection error:', err)
})

redis.on('connect', () => {
  console.log('Redis connected')
})

export default redis
```

## Serverless Considerations

**Redis in serverless environments (Vercel, Lambda):**

- Use Redis connection pooling (ioredis handles this)
- Consider Upstash Redis (serverless-optimized)
- Set `lazyConnect: true` to avoid connection on module load
- Handle cold starts gracefully (fallback to database)
- Monitor connection count to avoid exhaustion

**Upstash example:**

```typescript
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
})
```

Upstash uses HTTP REST API, avoiding connection pooling issues in serverless.

## Cache Implementation Checklist

When implementing caching:

**Setup:**
- [ ] Redis client configured with connection pooling
- [ ] Error handling for Redis connection failures
- [ ] Fallback to database when Redis unavailable
- [ ] Environment variables for Redis configuration

**Cache Keys:**
- [ ] Consistent key naming convention (entity:identifier)
- [ ] Hash complex query parameters for deterministic keys
- [ ] Namespace keys by entity type
- [ ] Document key patterns

**Caching Logic:**
- [ ] Cache-aside pattern (read from cache, fallback to DB)
- [ ] Serialize/deserialize with JSON.parse/stringify
- [ ] Handle null/undefined results appropriately
- [ ] Log cache hits/misses for monitoring

**Invalidation:**
- [ ] Invalidate on create/update/delete mutations
- [ ] Handle cascading invalidation for related entities
- [ ] Consider bulk invalidation for list queries
- [ ] Test invalidation across all mutation paths

**TTL Configuration:**
- [ ] Define TTL for each data type
- [ ] Shorter TTL for frequently changing data
- [ ] Longer TTL for static/rarely changing data
- [ ] Document TTL choices and rationale

**Monitoring:**
- [ ] Track cache hit rate
- [ ] Monitor cache memory usage
- [ ] Log invalidation events
- [ ] Alert on Redis connection failures

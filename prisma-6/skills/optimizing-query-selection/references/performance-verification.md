# Performance Verification

## Verification Checklist

After optimization, verify improvements:

1. **Data Size:** Check response payload size
2. **Query Time:** Measure database query duration
3. **Query Count:** Ensure single query instead of N+1
4. **Memory Usage:** Monitor application memory

## Enable Query Logging

```typescript
const prisma = new PrismaClient({
  log: [
    { emit: 'event', level: 'query' },
  ],
})

prisma.$on('query', (e) => {
  console.log('Query: ' + e.query)
  console.log('Duration: ' + e.duration + 'ms')
})
```

## Performance Testing

```typescript
async function testQueryPerformance() {
  console.time('Unoptimized')
  await prisma.user.findMany({
    include: { posts: true }
  })
  console.timeEnd('Unoptimized')

  console.time('Optimized')
  await prisma.user.findMany({
    select: {
      id: true,
      name: true,
      _count: { select: { posts: true } }
    }
  })
  console.timeEnd('Optimized')
}
```

## Payload Size Comparison

```typescript
async function comparePayloadSize() {
  const full = await prisma.post.findMany()
  const optimized = await prisma.post.findMany({
    select: {
      id: true,
      title: true,
      excerpt: true,
    }
  })

  console.log('Full payload:', JSON.stringify(full).length, 'bytes')
  console.log('Optimized payload:', JSON.stringify(optimized).length, 'bytes')
  console.log('Reduction:',
    Math.round((1 - JSON.stringify(optimized).length / JSON.stringify(full).length) * 100),
    '%'
  )
}
```

## Index Verification

Check that indexes exist for queried fields:

```sql
-- PostgreSQL
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'Post';

-- MySQL
SHOW INDEXES FROM Post;
```

## Production Monitoring

Monitor in production:

1. **APM tools:** Track query performance over time
2. **Database metrics:** Monitor slow query log
3. **API response times:** Measure endpoint latency
4. **Memory usage:** Track application memory consumption

## Expected Improvements

After optimization:

- **Query count:** Reduced to 1-2 queries (from N+1)
- **Response size:** 60-90% smaller payload
- **Query time:** Similar or faster
- **Memory usage:** 50-80% lower

# Cache Invalidation Patterns

## Event-Based: Invalidate on Data Changes

Use when: consistency critical, staleness unacceptable.

```typescript
async function createPost(data: { title: string; content: string; authorId: string }) {
  const post = await prisma.post.create({ data });

  await Promise.all([
    redis.del(`posts:author:${data.authorId}`),
    redis.del('posts:recent'),
    redis.del('posts:popular'),
  ]);

  return post;
}
```

## Time-Based: TTL-Driven Expiration

Use when: staleness acceptable for TTL duration, mutations infrequent.

```typescript
async function getRecentPosts() {
  const cached = await redis.get('posts:recent');
  if (cached) return JSON.parse(cached);

  const posts = await prisma.post.findMany({
    orderBy: { createdAt: 'desc' },
    take: 10,
  });

  await redis.setex('posts:recent', 300, JSON.stringify(posts));
  return posts;
}
```

## Hybrid: TTL + Event-Based Invalidation

Use when: mutations trigger immediate invalidation, TTL provides safety net.

```typescript
async function updatePost(postId: string, data: { title?: string }) {
  const post = await prisma.post.update({
    where: { id: postId },
    data,
  });
  await redis.del(`post:${postId}`);
  return post;
}

async function getPost(postId: string) {
  const cached = await redis.get(`post:${postId}`);
  if (cached) return JSON.parse(cached);

  const post = await prisma.post.findUnique({
    where: { id: postId },
  });
  if (post) await redis.setex(`post:${postId}`, 600, JSON.stringify(post));
  return post;
}
```

## Strategy Selection by Data Characteristics

| Characteristic            | Approach                                                                                                     |
| ------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Changes >1/min            | Avoid caching or use 5-30s TTL; consider real-time updates; event-based invalidation for consistency         |
| Changes rare (hours/days) | Use 5-60min TTL; event-based invalidation on mutations; warm cache on startup                                |
| Read/write ratio >10:1    | Strong cache candidate; cache-aside pattern; warm popular data in background                                 |
| Read/write ratio <3:1     | Weak candidate; optimize queries instead; cache only if DB bottlenecked                                      |
| Consistency required      | Short TTL + event-based invalidation; cache-through/write-behind patterns; add versioning for atomic updates |

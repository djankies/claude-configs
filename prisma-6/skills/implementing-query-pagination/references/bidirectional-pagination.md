# Bidirectional Pagination

Support both forward and backward navigation in cursor-based pagination.

## Pattern

```typescript
async function getBidirectionalPosts(
  cursor?: string,
  direction: 'forward' | 'backward' = 'forward',
  pageSize: number = 20
) {
  const posts = await prisma.post.findMany({
    take: direction === 'forward' ? pageSize : -pageSize,
    skip: cursor ? 1 : 0,
    cursor: cursor ? { id: cursor } : undefined,
    orderBy: { id: 'asc' },
  });

  const data = direction === 'backward' ? posts.reverse() : posts;

  return {
    data,
    nextCursor: data.length === pageSize ? data[data.length - 1].id : null,
    prevCursor: data.length > 0 ? data[0].id : null,
  };
}
```

## Key Points

- Use negative `take` value for backward pagination
- Reverse results when paginating backward
- Return both `nextCursor` and `prevCursor` for navigation
- Maintain consistent ordering across directions

# Handling Data Changes During Pagination

## The Problem

**Offset Pagination Issue:** Duplicates or missing records when data changes between page loads.

### Example Scenario

1. User loads page 1 (posts 1-20)
2. New post is inserted at position 1
3. User loads page 2 (posts 21-40)
4. **Post 21 appears on both pages** (was post 20, now post 21)

### Why It Happens

Offset pagination uses absolute positions:
- Page 1: Records at positions 0-19
- Page 2: Records at positions 20-39

When a record is inserted:
- Page 1 positions: 0-19 (includes new record at position 0)
- Page 2 positions: 20-39 (old position 20 is now position 21)
- **Position 20 was seen on page 1, appears again on page 2**

## Cursor Pagination Solution

Cursor pagination is immune to this problem:

```typescript
const posts = await prisma.post.findMany({
  take: 20,
  skip: cursor ? 1 : 0,
  cursor: cursor ? { id: cursor } : undefined,
  orderBy: { createdAt: 'desc' },
});
```

**Why it works:**
- Uses record identity (cursor), not position
- Always starts from the last seen record
- New records appear in correct position
- No duplicates or gaps

## Mitigation for Offset Pagination

If you must use offset pagination:

### Strategy 1: Accept the Limitation
Document behavior for admin tools where occasional duplicates are acceptable.

### Strategy 2: Timestamp Filtering
Create stable snapshots using timestamp filtering:

```typescript
const snapshotTime = new Date();

async function getPage(page: number) {
  return await prisma.post.findMany({
    where: {
      createdAt: { lte: snapshotTime },
    },
    skip: page * pageSize,
    take: pageSize,
    orderBy: { createdAt: 'desc' },
  });
}
```

**Limitations:**
- Doesn't show new records during pagination session
- User must refresh to see new data

### Strategy 3: Switch to Cursor

The best solution is to redesign using cursor pagination.

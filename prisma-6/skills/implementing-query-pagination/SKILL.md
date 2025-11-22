---
name: implementing-query-pagination
description: Implement efficient pagination using cursor-based or offset strategies for Prisma queries. Use when paginating large datasets (100k+ records), building APIs with page navigation, or when users mention pagination, infinite scroll, or page-based listings.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
version: 1.0.0
---

# QUERIES-pagination: Efficient Pagination Strategies

This skill teaches correct pagination patterns in Prisma 6, focusing on when to use cursor vs offset pagination and their performance implications on large datasets.

---

<role>
This skill teaches Claude how to implement efficient pagination in Prisma 6 using cursor-based or offset-based strategies, with clear guidance on when to use each approach based on dataset size, use case, and performance requirements.
</role>

<when-to-activate>
This skill activates when:
- User mentions "pagination", "page", "infinite scroll", or "load more"
- Building APIs with page navigation or list endpoints
- Working with large datasets (100k+ records)
- Implementing table views with page controls
- Optimizing slow list queries
</when-to-activate>

<overview>
Pagination in Prisma requires choosing between two fundamentally different approaches:

**Cursor-based pagination** (recommended for most cases):
- Stable performance regardless of dataset size
- Efficient for infinite scroll and "load more" patterns
- Handles real-time data changes gracefully
- Requires unique, sequential ordering field

**Offset-based pagination** (use sparingly):
- Simple to implement for small datasets
- Supports jumping to arbitrary pages
- Degrades significantly on large datasets (100k+ records)
- Prone to duplicate/missing items when data changes

Key principle: **Use cursor pagination by default. Only use offset for small, static datasets where arbitrary page access is required.**
</overview>

<workflow>
## Standard Pagination Workflow

**Phase 1: Determine Pagination Strategy**

1. Assess dataset size expectations:
   - Under 10k records: Either approach works
   - 10k-100k records: Cursor preferred
   - Over 100k records: Cursor required

2. Assess access pattern:
   - Sequential access (feed, timeline): **Cursor**
   - Arbitrary page jumps (admin table): **Offset** (if small dataset)
   - Infinite scroll: **Cursor**
   - Traditional page controls: **Cursor** with page size

3. Assess data volatility:
   - Frequent inserts/deletes: **Cursor** (stable)
   - Static data: Either approach

**Phase 2: Implement Chosen Strategy**

For cursor pagination:
1. Choose unique ordering field (id, createdAt + id)
2. Implement take + cursor + skip pattern
3. Return cursor for next page
4. Handle edge cases (first page, last page)

For offset pagination:
1. Implement take + skip pattern
2. Calculate total pages if needed
3. Validate page number bounds
4. Document performance limitations

**Phase 3: Optimize and Validate**

1. Add appropriate indexes for ordering field
2. Test with realistic dataset size
3. Measure query performance
4. Document pagination metadata in API response
</workflow>

<decision-matrix>
## Pagination Strategy Decision Matrix

| Criterion | Cursor | Offset | Winner |
|-----------|--------|--------|--------|
| Dataset size > 100k | Stable O(n) | Degrades O(skip + n) | **Cursor** |
| Infinite scroll | Natural fit | Poor fit | **Cursor** |
| Page controls (1,2,3...) | Requires workaround | Natural fit | Offset |
| Jump to arbitrary page | Not supported | Supported | Offset |
| Real-time data | No duplicates | Duplicates/gaps | **Cursor** |
| Total count needed | Extra query | Same query | Offset |
| Implementation complexity | Medium | Low | Offset |
| Mobile app feed | Natural fit | Poor fit | **Cursor** |
| Admin table (small data) | Overkill | Simple | Offset |
| Search results | Good | Acceptable | **Cursor** |

**Recommendation hierarchy:**

1. **Default to cursor pagination** for all user-facing lists
2. **Use offset only for:**
   - Small admin tables (< 10k records)
   - Cases where total count and page jumping are required
   - Internal tools where performance is acceptable
3. **Never use offset for:**
   - User-facing feeds or timelines
   - Datasets > 100k records
   - Mobile infinite scroll
   - Real-time data
</decision-matrix>

<cursor-pagination>
## Cursor-Based Pagination (Recommended)

Cursor pagination uses a pointer to a specific record as the starting point for the next page.

### Basic Pattern

```typescript
async function getPosts(cursor?: string, pageSize: number = 20) {
  const posts = await prisma.post.findMany({
    take: pageSize,
    skip: cursor ? 1 : 0,
    cursor: cursor ? { id: cursor } : undefined,
    orderBy: { id: 'asc' },
  });

  return {
    data: posts,
    nextCursor: posts.length === pageSize ? posts[posts.length - 1].id : null,
  };
}
```

### Composite Cursor for Non-Unique Fields

When ordering by non-unique fields (createdAt, score), combine with unique field:

```typescript
async function getPostsByDate(
  cursor?: { createdAt: Date; id: string },
  pageSize: number = 20
) {
  const posts = await prisma.post.findMany({
    take: pageSize,
    skip: cursor ? 1 : 0,
    cursor: cursor ? { createdAt_id: cursor } : undefined,
    orderBy: [
      { createdAt: 'desc' },
      { id: 'asc' }
    ],
  });

  const lastPost = posts[posts.length - 1];
  const nextCursor = posts.length === pageSize
    ? { createdAt: lastPost.createdAt, id: lastPost.id }
    : null;

  return {
    data: posts,
    nextCursor,
  };
}
```

**Schema requirement for composite cursor:**

```prisma
model Post {
  id        String   @id @default(cuid())
  createdAt DateTime @default(now())

  @@index([createdAt, id])
}
```

### Performance Characteristics

**Query time complexity:**
- First page: O(n) where n = pageSize
- Subsequent pages: O(n) where n = pageSize
- **Independent of total dataset size**

**Index requirement:**
- Index on ordering field(s) is critical
- Without index: Full table scan (O(total records))

**Memory usage:**
- Constant: Only loads pageSize records

**When data changes:**
- No duplicate records across pages
- No missing records across pages
- New records appear in correct position
</cursor-pagination>

<offset-pagination>
## Offset-Based Pagination (Use Sparingly)

Offset pagination uses a numeric offset to skip records.

### Basic Pattern

```typescript
async function getPostsPaged(page: number = 1, pageSize: number = 20) {
  const skip = (page - 1) * pageSize;

  const [posts, total] = await Promise.all([
    prisma.post.findMany({
      skip,
      take: pageSize,
      orderBy: { createdAt: 'desc' },
    }),
    prisma.post.count(),
  ]);

  return {
    data: posts,
    pagination: {
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
      totalRecords: total,
    },
  };
}
```

### Performance Degradation

**Query time complexity:**
- Page 1: O(pageSize)
- Page 100: O(100 * pageSize)
- **Linear degradation with page number**

**Real-world performance example:**

Dataset: 1 million records, pageSize: 20

- Page 1 (skip 0): ~5ms
- Page 1000 (skip 20,000): ~150ms
- Page 10000 (skip 200,000): ~1,500ms
- Page 50000 (skip 1,000,000): ~7,500ms

**Why it degrades:**
Database must scan and discard skipped rows even with indexes.

### When Offset Is Acceptable

Use offset pagination only when ALL of these are true:

1. Dataset is small (< 10k records) OR deeply paginated pages are rare
2. Users need arbitrary page access (jump to page 42)
3. Total count is required for UI
4. Data changes infrequently

**Common use cases:**
- Admin tables with filters (small result sets)
- Search results (users rarely go past page 5)
- Static archives or reports
</offset-pagination>

<validation>
## Validation

After implementing pagination:

1. **Index Verification:**
   - Check schema has index on ordering field(s)
   - For cursor: Index on cursor field (e.g., `@@index([createdAt, id])`)
   - For offset: Index on ordering field
   - Run: `npx prisma format` and verify indexes exist

2. **Performance Testing:**
   ```typescript
   async function testPaginationPerformance() {
     console.time('First page');
     await getPosts(undefined, 20);
     console.timeEnd('First page');

     console.time('Page 100');
     await getPosts(undefined, 20, 100);
     console.timeEnd('Page 100');
   }
   ```
   - Cursor: Both should be similar (~5-50ms)
   - Offset: Page 100 should be within acceptable limits for your use case

3. **Edge Case Testing:**
   - First page (no cursor/offset)
   - Last page (fewer than pageSize results)
   - Empty results (no data)
   - Invalid cursor/page number
   - Concurrent data modifications

4. **API Contract Validation:**
   - Response includes pagination metadata
   - nextCursor is null when no more pages
   - hasMore boolean is accurate
   - Page numbers are validated (> 0)
</validation>

<constraints>
## Constraints and Guidelines

**MUST:**
- Add index on cursor field(s) for cursor pagination
- Validate limit/pageSize to prevent abuse (max 100)
- Handle empty results gracefully
- Return pagination metadata (nextCursor, hasMore, etc.)
- Use consistent ordering across pages
- Include unique field in composite cursors

**SHOULD:**
- Default to cursor pagination unless specific offset requirement
- Limit offset pagination to datasets < 100k records
- Document pagination strategy in API docs
- Test with realistic dataset sizes
- Consider caching total count for offset pagination

**NEVER:**
- Use offset pagination for datasets > 100k records
- Use offset for infinite scroll patterns
- Omit indexes on pagination ordering fields
- Allow unlimited pageSize
- Use non-unique fields as sole cursor
- Modify ordering between page requests
</constraints>

---

## References

For detailed implementation examples and edge cases, see:

- [Bidirectional Pagination](./references/bidirectional-pagination.md) - Forward/backward navigation patterns
- [Complete API Examples](./references/api-implementation-examples.md) - Full endpoint implementations with filtering
- [Performance Benchmarks](./references/performance-comparison.md) - Detailed performance data and optimization guidance
- [Common Mistakes](./references/common-mistakes.md) - Anti-patterns and how to fix them
- [Data Change Handling](./references/data-change-handling.md) - Managing duplicates and gaps when data changes

---
name: optimizing-query-performance
description: Optimize queries with indexes, batching, and efficient Prisma operations. Use when experiencing slow queries or optimizing production performance.
allowed-tools: Read, Write, Edit, Bash
version: 1.0.0
---

# Query Optimization for Prisma 6

This skill teaches optimizing Prisma queries through strategic indexing, efficient batching, and query monitoring for production performance.

---

<role>
This skill teaches Claude how to identify and resolve Prisma query performance issues through index strategy, batch operations, query analysis, and monitoring.
</role>

<when-to-activate>
This skill activates when:

- User mentions slow queries, performance issues, or query optimization
- Working with large datasets (10k+ records)
- Request involves batch operations, bulk inserts, or data migrations
- Analyzing query logs or debugging N+1 problems
- Optimizing production database performance
</when-to-activate>

<overview>
Query optimization in Prisma requires understanding index strategy, efficient batch operations, and query monitoring. This skill prevents common performance anti-patterns found in production applications.

Key capabilities:

1. Strategic index placement with @@index and @@unique
2. Efficient batch operations with createMany and transactions
3. Query log analysis and slow query identification
4. Field selection optimization and N+1 prevention
</overview>

<workflow>
## Standard Workflow

**Phase 1: Identify Performance Issues**

1. Enable query logging to identify slow queries
2. Analyze query patterns and execution times
3. Identify missing indexes, N+1 problems, or inefficient batching

**Phase 2: Apply Optimizations**

1. Add indexes for frequently filtered/sorted fields
2. Replace loops with batch operations (createMany, updateMany)
3. Select only needed fields with select/include
4. Use cursor pagination for large datasets

**Phase 3: Validate Performance**

1. Measure query execution time before/after
2. Verify index usage with EXPLAIN ANALYZE
3. Monitor connection pool usage under load
</workflow>

## Quick Reference

**Index Strategy:**

| Scenario | Index Type | Example |
|----------|-----------|---------|
| Single field filter | `@@index([field])` | `@@index([status])` |
| Multiple field filter | `@@index([field1, field2])` | `@@index([userId, status])` |
| Sort + filter | `@@index([filterField, sortField])` | `@@index([status, createdAt])` |

**Batch Operations:**

| Operation | Slow (Loop) | Fast (Batch) |
|-----------|-------------|--------------|
| Insert | `for...await create()` | `createMany()` |
| Update | `for...await update()` | `updateMany()` |
| Delete | `for...await delete()` | `deleteMany()` |

**Performance Gains:**
- Index on common queries: 10-100x improvement
- Batch operations: 50-100x faster for 1000+ records
- Cursor pagination: Constant time vs O(n) for offset

<constraints>
## Constraints and Guidelines

**MUST:**

- Add indexes for fields used in WHERE, ORDER BY, or foreign keys with frequent queries
- Use createMany for bulk inserts (100+ records)
- Use cursor pagination for datasets with deep pagination
- Select only needed fields when fetching large result sets
- Monitor query duration in production

**SHOULD:**

- Test index performance with production data volumes
- Chunk very large batches (100k+ records) into smaller batches
- Use `@@index([field1, field2])` for queries filtering by both fields
- Remove unused indexes (check with database query stats)

**NEVER:**

- Add indexes without measuring actual query performance
- Use offset pagination beyond page 100 on large tables
- Fetch all fields when only needing a few
- Loop with individual creates/updates when batch operations exist
- Ignore slow query warnings in production logs
</constraints>

<validation>
## Validation

After applying optimizations:

1. **Measure Performance:**

   ```typescript
   const start = Date.now()
   const result = await prisma.user.findMany({ ... })
   console.log(`Query took ${Date.now() - start}ms`)
   ```

   Expected: 50-90% improvement for indexed queries, 50-100x for batch operations

2. **Verify Index Usage:**

   Run EXPLAIN ANALYZE and confirm "Index Scan" instead of "Seq Scan"

3. **Monitor Production:**

   Track P95/P99 query latency after deployment
   Expected: Reduced slow query frequency

4. **Check Write Performance:**

   If writes become slow, consider removing rarely-used indexes
   Expected: Insert/update time increases 10-30% per index
</validation>

## References

For detailed optimization techniques and examples:

- **Index Strategy Guide**: See `references/index-strategy.md` for comprehensive indexing patterns and trade-offs
- **Batch Operations Guide**: See `references/batch-operations.md` for efficient bulk operations and chunking strategies
- **Query Monitoring Guide**: See `references/query-monitoring.md` for logging setup and slow query analysis
- **Field Selection Guide**: See `references/field-selection.md` for select vs include patterns and N+1 prevention
- **Optimization Examples**: See `references/optimization-examples.md` for real-world performance improvements

For framework-specific optimization:
- **Next.js Integration**: Consult Next.js plugin for App Router-specific query patterns
- **Serverless Optimization**: See CLIENT-serverless-config skill for connection pooling strategies

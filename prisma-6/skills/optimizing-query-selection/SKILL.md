---
name: optimizing-query-selection
description: Optimize queries by selecting only required fields and avoiding N+1 problems. Use when writing queries with relations or large result sets.
allowed-tools: Read, Write, Edit
version: 1.0.0
---

# Query Select Optimization

This skill guides optimization of Prisma 6 queries through strategic field selection and relation loading to avoid N+1 problems and reduce data transfer.

---

<role>
This skill teaches Claude how to optimize Prisma 6 queries by selecting only required fields and properly loading relations to prevent N+1 query problems while minimizing data transfer and memory usage.
</role>

<when-to-activate>
This skill activates when:
- Writing queries that fetch user-facing data
- Loading models with relations
- Building API endpoints or GraphQL resolvers
- Optimizing slow queries
- Reducing database load and network transfer
- Working with large result sets
</when-to-activate>

<overview>
Query optimization in Prisma centers on two key practices:

1. **Select only required fields** - Reduce bandwidth, memory, and serialization overhead
2. **Prevent N+1 queries** - Load relations efficiently in a single query

These practices work together to create performant, scalable queries that minimize database load and response times.
</overview>

<workflow>
## Optimization Workflow

**Phase 1: Identify Requirements**

1. Determine which fields are needed for the use case
2. Identify relations that must be loaded
3. Check if relation counts are needed (use `_count`)
4. Assess whether full models or specific fields suffice

**Phase 2: Choose Selection Strategy**

- **Include:** Quick prototyping, need most model fields
- **Select:** Production code, API responses, performance-critical

**Phase 3: Implement Selection**

1. Use `select` for precise field control
2. Include relations with nested `select`
3. Use `_count` for relation counts instead of loading all records
4. Add `take` limits on relations to prevent over-fetching

**Phase 4: Add Indexes**

1. Index fields used in `where` clauses
2. Index fields used in `orderBy`
3. Create composite indexes for filtered relations

**Phase 5: Validate**

1. Enable query logging to verify single query
2. Test with realistic data volumes
3. Measure response payload size
4. Monitor query duration
</workflow>

<core-principles>
## Core Principles

### 1. Select Only Required Fields

**Problem:** Fetching entire models wastes bandwidth and memory

```typescript
const users = await prisma.user.findMany()
```

**Solution:** Use `select` to fetch only needed fields

```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true,
  },
})
```

**Performance Impact:**
- Reduces data transfer by 60-90% for models with many fields
- Faster JSON serialization
- Lower memory usage
- Excludes sensitive fields by default

### 2. Include vs Select

**Include:** Adds relations to full model

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: true,
    profile: true,
  },
})
```

**Select:** Precise control over all fields

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  select: {
    id: true,
    email: true,
    posts: {
      select: {
        id: true,
        title: true,
        published: true,
      },
    },
    profile: {
      select: {
        bio: true,
        avatar: true,
      },
    },
  },
})
```

**When to Use:**
- `include`: Quick prototyping, need most fields
- `select`: Production code, API responses, performance-critical paths

### 3. Preventing N+1 Queries

**N+1 Problem:** Separate query for each relation

```typescript
const posts = await prisma.post.findMany()

for (const post of posts) {
  const author = await prisma.user.findUnique({
    where: { id: post.authorId },
  })
}
```

**Solution:** Use `include` or `select` with relations

```typescript
const posts = await prisma.post.findMany({
  include: {
    author: true,
  },
})
```

**Better:** Select only needed author fields

```typescript
const posts = await prisma.post.findMany({
  select: {
    id: true,
    title: true,
    content: true,
    author: {
      select: {
        id: true,
        name: true,
        email: true,
      },
    },
  },
})
```

### 4. Relation Counting

**Problem:** Loading all relations just to count them

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: true,
  },
})

const postCount = user.posts.length
```

**Solution:** Use `_count` for efficient aggregation

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  select: {
    id: true,
    name: true,
    _count: {
      select: {
        posts: true,
        comments: true,
      },
    },
  },
})
```

**Result:**
```typescript
{
  id: 1,
  name: "Alice",
  _count: {
    posts: 42,
    comments: 128
  }
}
```
</core-principles>

<quick-reference>
## Quick Reference

### Optimized Query Pattern

```typescript
const optimized = await prisma.model.findMany({
  where: {},
  select: {
    field1: true,
    field2: true,
    relation: {
      select: {
        field: true,
      },
      take: 10,
    },
    _count: {
      select: {
        relation: true,
      },
    },
  },
  orderBy: { field: 'desc' },
  take: 20,
  skip: 0,
})
```

### Key Takeaways

- Default to `select` for all production queries
- Use `include` only for prototyping
- Always use `_count` for counting relations
- Combine selection with filtering and pagination
- Prevent N+1 by loading relations upfront
- Select minimal fields for list views, more for detail views
</quick-reference>

<constraints>
## Constraints and Guidelines

**MUST:**
- Use `select` for all API responses
- Load relations in same query (prevent N+1)
- Use `_count` for relation counts
- Add indexes for filtered/ordered fields
- Test with realistic data volumes

**SHOULD:**
- Limit relation results with `take`
- Create reusable selection objects
- Enable query logging during development
- Measure performance improvements
- Document selection patterns

**NEVER:**
- Use `include` in production without field selection
- Load relations in loops (N+1)
- Fetch full models when only counts needed
- Over-fetch nested relations
- Skip indexes on commonly queried fields
</constraints>

---

## References

For detailed patterns and examples, see:

- [Nested Selection Patterns](./references/nested-selection.md) - Deep relation hierarchies and complex selections
- [API Optimization Patterns](./references/api-optimization.md) - List vs detail views, pagination with select
- [N+1 Prevention Guide](./references/n-plus-one-prevention.md) - Detailed anti-patterns and solutions
- [Type Safety Guide](./references/type-safety.md) - TypeScript types and reusable selection objects
- [Performance Verification](./references/performance-verification.md) - Testing and validation techniques

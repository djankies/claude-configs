# Common Pagination Mistakes

## Mistake 1: Using non-unique cursor

**Problem:**
```typescript
cursor: cursor ? { createdAt: cursor } : undefined,
```

Multiple records can have the same `createdAt` value, causing skipped or duplicate records.

**Fix:** Use composite cursor with unique field:

```typescript
cursor: cursor ? { createdAt_id: cursor } : undefined,
orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
```

## Mistake 2: Missing skip: 1 with cursor

**Problem:**
```typescript
findMany({
  cursor: { id: cursor },
  take: 20,
})
```

The cursor record itself is included in results, causing duplicate on next page.

**Fix:** Skip cursor record itself:

```typescript
findMany({
  cursor: { id: cursor },
  skip: 1,
  take: 20,
})
```

## Mistake 3: Offset pagination on large datasets

**Problem:**
```typescript
findMany({
  skip: page * 1000,
  take: 1000,
})
```

Performance degrades linearly with page number on large datasets.

**Fix:** Use cursor pagination:

```typescript
findMany({
  cursor: cursor ? { id: cursor } : undefined,
  skip: cursor ? 1 : 0,
  take: 1000,
})
```

## Mistake 4: Missing index on cursor field

**Problem:**
Schema without index causes full table scans:

```prisma
model Post {
  id        String   @id
  createdAt DateTime @default(now())
}
```

**Fix:** Add appropriate index:

```prisma
model Post {
  id        String   @id
  createdAt DateTime @default(now())

  @@index([createdAt, id])
}
```

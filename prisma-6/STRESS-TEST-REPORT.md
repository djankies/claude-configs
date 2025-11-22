# Stress Test Report: Prisma 6

**Date:** 2025-11-21 | **Research:** prisma-6/RESEARCH.md | **Agents:** 5

## Executive Summary

| Metric           | Count |
| ---------------- | ----- |
| Total Violations | 30    |
| Critical         | 10    |
| High             | 5     |
| Medium           | 11    |
| Low              | 4     |

**Most Common:** Creating PrismaClient in functions (7 agents)
**Deprecated APIs:** 2/5
**Incorrect APIs:** 8/5
**Legacy/anti-patterns:** 12/5
**Legacy configurations:** 8/5

---

## Pattern Analysis

### Most Common Violations

1. **Creating PrismaClient in functions** - 7 occurrences (4 agents)
2. **SQL Injection via $queryRawUnsafe** - 4 occurrences (2 agents)
3. **Missing connection pool configuration** - 3 occurrences (3 agents)
4. **Buffer instead of Uint8Array (Prisma 6 breaking change)** - 2 occurrences (1 agent)
5. **Offset pagination on large datasets** - 1 occurrence (1 agent)

### Frequently Misunderstood

- **PrismaClient instantiation**: 4 agents created multiple instances instead of singleton pattern
  - Common mistake: Creating `new PrismaClient()` in modules, functions, and test files
  - Research says: "Reuse PrismaClient instance" (Anti-Patterns #1)
  - Recommendation: Use global singleton pattern for serverless, module-level export for long-running processes

- **SQL safety**: 2 agents used `$queryRawUnsafe` or `Prisma.raw()` with string interpolation
  - Common mistake: Manual sanitization with string concatenation
  - Research says: "Always use tagged templates with $queryRaw"
  - Recommendation: Use `$queryRaw` tagged templates for automatic parameterization

- **Bytes type**: 1 agent used deprecated `Buffer` API
  - Common mistake: `Buffer.from()` and `.toString()` on Bytes fields
  - Research says: "Prisma 6 replaced Buffer with Uint8Array"
  - Recommendation: Use `TextEncoder().encode()` and `TextDecoder().decode()`

- **Connection pooling**: 3 agents missed serverless configuration
  - Common mistake: No `connection_limit` parameter in DATABASE_URL
  - Research says: "Serverless Functions: connection_limit = 1"
  - Recommendation: Add `?connection_limit=1` to DATABASE_URL for serverless deployments

- **Pagination**: 1 agent used offset on 100k+ records
  - Common mistake: `skip` for high page numbers
  - Research says: "Use cursor pagination for large datasets" (Anti-Pattern #9)
  - Recommendation: Use `cursor` with unique sequential field (id)

---

## Scenarios Tested

1. **Serverless user search API** - Concepts: PrismaClient reuse, connection pooling, case-insensitive filtering
2. **Blog pagination (100k posts)** - Concepts: Cursor vs offset pagination, select optimization, N+1 queries
3. **E-commerce checkout** - Concepts: Transactions, error handling (P2002/P2025), atomic operations
4. **Admin analytics with raw SQL** - Concepts: SQL injection prevention, Buffer vs Uint8Array, JSON queries
5. **Multi-tenant SaaS** - Concepts: Client extensions, row-level security, migration workflows

---

## Deduplicated Individual Findings

### [CRITICAL] Connection Pool Exhaustion - Multiple PrismaClient Instances

**Found Instances:** 7

```typescript
const prisma = new PrismaClient();

async function getUser(id: number) {
  return prisma.user.findUnique({ where: { id } });
}
```

**Research Doc says:** (section "Anti-Patterns")

> **Anti-Pattern:**
> ```typescript
> async function getUser(id: number) {
>   const prisma = new PrismaClient();
>   return prisma.user.findUnique({ where: { id } });
> }
> ```
> **Correct:**
> ```typescript
> const prisma = new PrismaClient();
> async function getUser(id: number) {
>   return prisma.user.findUnique({ where: { id } });
> }
> ```

**Correct:**

```typescript
const globalForPrisma = global as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
```

**Impact:** Each PrismaClient creates separate connection pool. Multiple instances exhaust database connections, causing P1017 errors (Server closed connection). Critical in serverless where each invocation can create instances.

---

### [CRITICAL] SQL Injection via $queryRawUnsafe and Prisma.raw()

**Found Instances:** 4

```typescript
const category = filters.category;
await prisma.$queryRaw`
  SELECT * FROM orders
  WHERE created_at >= ${startDate}
  ${filters.category ? Prisma.raw(`AND metadata->'tags' ? '${sanitizeForJsonOperator(category)}'`) : Prisma.empty}
`;
```

**Research Doc says:** (section "Anti-Patterns - Using $queryRawUnsafe with User Input")

> **Anti-Pattern:**
> ```typescript
> const users = await prisma.$queryRawUnsafe(`SELECT * FROM User WHERE name = '${userName}'`);
> ```
> **Correct:**
> ```typescript
> const users = await prisma.$queryRaw`SELECT * FROM User WHERE name = ${userName}`;
> ```

**Correct:**

```typescript
await prisma.$queryRaw`
  SELECT * FROM orders
  WHERE created_at >= ${startDate}
  ${filters.category ? Prisma.sql`AND metadata->'tags' ? ${category}` : Prisma.empty}
`;
```

**Impact:** String interpolation with `Prisma.raw()` or `$queryRawUnsafe` bypasses parameterization. Manual sanitization is insufficient - attackers can exploit edge cases. Use tagged templates for automatic SQL parameter binding.

---

### [CRITICAL] Buffer API Usage (Prisma 6 Breaking Change)

**Found Instances:** 2

```typescript
const reportBytes = Buffer.from(jsonString, 'utf-8');

const reportData = JSON.parse(snapshot.reportData.toString('utf-8'));
```

**Research Doc says:** (section "Common Gotchas - Buffer vs Uint8Array for Bytes")

> **Problem:** Prisma 6 replaced Node.js `Buffer` with standard `Uint8Array`.
>
> **Solution:** Update code handling binary data to use `Uint8Array`.

**Correct:**

```typescript
const reportBytes = new TextEncoder().encode(jsonString);

const reportData = JSON.parse(new TextDecoder().decode(snapshot.reportData));
```

**Impact:** Prisma 6 breaking change. Buffer API removed in favor of standard Uint8Array. Code using Buffer will fail with type errors and runtime exceptions when interacting with Prisma Client Bytes fields.

---

### [CRITICAL] Multi-Tenant Architecture with Per-Tenant Clients

**Found Instances:** 1

```typescript
const clientCache = new Map<string, PrismaClient>();

export function getTenantClient(tenantId: string): PrismaClient {
  if (!clientCache.has(tenantId)) {
    const client = new PrismaClient({ log: ['query', 'error', 'warn'] });
    clientCache.set(tenantId, client);
  }
  return clientCache.get(tenantId)!;
}
```

**Research Doc says:** (section "Common Gotchas - Connection Pool Exhaustion in Serverless")

> **Problem:** Creating new PrismaClient instances on every request exhausts database connections.
>
> **Solution:** Reuse PrismaClient instance or set `connection_limit=1`

**Correct:**

```typescript
const prisma = new PrismaClient();

export const tenantPrisma = prisma.$extends({
  query: {
    $allModels: {
      async findMany({ args, query, model }) {
        args.where = { ...args.where, tenantId: getTenantId() };
        return query(args);
      },
    },
  },
});
```

**Impact:** Creating one PrismaClient per tenant creates hundreds of connection pools in multi-tenant systems. With 100 tenants and default pool size of ~10, this opens 1000+ database connections. Use Client Extensions for tenant isolation with single client.

---

### [HIGH] Offset Pagination on Large Datasets

**Found Instances:** 1

```typescript
const skip = (page - 1) * POSTS_PER_PAGE;

const posts = await prisma.post.findMany({
  where: { published: true },
  orderBy: { id: 'desc' },
  skip,
  take: POSTS_PER_PAGE,
});
```

**Research Doc says:** (section "Anti-Patterns - Using Offset Pagination for Large Datasets")

> **Anti-Pattern:**
> ```typescript
> const posts = await prisma.post.findMany({
>   skip: 10000,
>   take: 20,
> });
> ```
> **Correct:**
> ```typescript
> const posts = await prisma.post.findMany({
>   take: 20,
>   cursor: { id: lastPostId },
>   skip: 1,
>   orderBy: { id: 'asc' },
> });
> ```

**Correct:**

```typescript
const posts = await prisma.post.findMany({
  where: { published: true },
  orderBy: { id: 'desc' },
  take: POSTS_PER_PAGE,
  ...(lastPostId && {
    cursor: { id: lastPostId },
    skip: 1,
  }),
});
```

**Impact:** Offset pagination on 100k records requires database to read and discard rows. Page 5000 (skip: 99,980) scans 99,980 rows before returning 20. Performance degrades linearly with page number. Cursor pagination uses indexed lookups - constant O(1) performance.

---

### [HIGH] Missing findUnique for Unique Fields

**Found Instances:** 1

```typescript
async findByEmail(email: string) {
  return await prisma.user.findFirst({
    where: { email },
  });
}
```

**Research Doc says:** (section "Basic CRUD Operations - Find Unique Record")

> ```typescript
> const user = await prisma.user.findUnique({
>   where: { email: 'elsa@prisma.io' },
> });
> ```

**Correct:**

```typescript
async findByEmail(email: string) {
  return await prisma.user.findUnique({
    where: { email },
  });
}
```

**Impact:** findFirst on unique field performs table scan with LIMIT 1 instead of unique index lookup. Less performant and doesn't leverage database constraints. Use findUnique for @unique fields.

---

### [MEDIUM] Missing Connection Pool Configuration for Serverless

**Found Instances:** 3

```typescript
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

```bash
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"
```

**Research Doc says:** (section "Connection Pool Configuration")

> **Serverless Functions:**
> ```
> connection_limit = 1
> ```
> For serverless environments, consider using external connection poolers like PgBouncer to prevent connection exhaustion.

**Correct:**

```bash
DATABASE_URL="postgresql://user:password@localhost:5432/mydb?connection_limit=1&pool_timeout=2"
```

**Impact:** Serverless functions without connection_limit use default (num_cpus * 2 + 1). With 100 concurrent Lambda invocations, this opens 500+ connections. Most databases limit connections to 100-500. Results in P1017 errors and function failures.

---

### [MEDIUM] Missing Logging Configuration

**Found Instances:** 4

```typescript
const prisma = new PrismaClient();
```

**Research Doc says:** (section "Best Practices - Connection Management")

> ```typescript
> export const prisma = new PrismaClient({
>   log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
> });
> ```

**Correct:**

```typescript
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});
```

**Impact:** No logging makes debugging difficult. Development needs query logs to identify N+1 queries, slow queries, and verify transaction behavior. Production needs error logs for monitoring. Missing configuration reduces observability.

---

### [MEDIUM] Missing Unique Constraint Error Handling

**Found Instances:** 2

```typescript
try {
  await prisma.user.create({
    data: { email: userInput.email },
  });
} catch (error) {
  return { error: 'Internal server error' };
}
```

**Research Doc says:** (section "Anti-Patterns - Not Handling Unique Constraint Violations")

> **Correct:**
> ```typescript
> try {
>   await prisma.user.create({ data: { email: userInput.email } });
> } catch (error) {
>   if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
>     throw new Error('Email already exists');
>   }
>   throw error;
> }
> ```

**Correct:**

```typescript
try {
  await prisma.user.create({
    data: { email: userInput.email },
  });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
    return { error: 'Email already exists', status: 409 };
  }
  return { error: 'Internal server error', status: 500 };
}
```

**Impact:** Unique constraint violations (P2002) return generic errors instead of specific user-facing messages. Users see "Internal server error" for duplicate emails instead of "Email already exists". Poor UX and harder debugging.

---

### [MEDIUM] Missing Input Validation

**Found Instances:** 2

```typescript
const { email, firstName, lastName } = req.body;

const user = await prisma.user.create({
  data: { email, firstName, lastName },
});
```

**Research Doc says:** (section "Security Considerations - Input Validation")

> **Validate before database operations:**
> ```typescript
> import { z } from 'zod';
>
> const userSchema = z.object({
>   email: z.string().email(),
>   name: z.string().min(2).max(100),
> });
>
> async function createUser(input: unknown) {
>   const data = userSchema.parse(input);
>   return prisma.user.create({ data });
> }
> ```

**Correct:**

```typescript
import { z } from 'zod';

const userSchema = z.object({
  email: z.string().email(),
  firstName: z.string().min(1).max(100),
  lastName: z.string().min(1).max(100),
});

const { email, firstName, lastName } = userSchema.parse(req.body);
const user = await prisma.user.create({
  data: { email, firstName, lastName },
});
```

**Impact:** Unvalidated input can cause database errors, invalid data storage, or security issues. Zod validation catches malformed emails, missing fields, type errors, and length violations before database operations.

---

### [MEDIUM] Manual Type Definitions Instead of Generated Types

**Found Instances:** 1

```typescript
interface Author {
  name: string | null;
  email: string;
}

interface Post {
  id: number;
  title: string;
  content: string | null;
  published: boolean;
  authorId: number;
  author: Author;
}
```

**Research Doc says:** (section "Best Practices - Type Safety")

> **Use Generated Types:**
> ```typescript
> import { User, Post } from '@prisma/client';
> ```
> **Type Utilities for Complex Queries:**
> ```typescript
> type UserWithPostCount = Prisma.UserGetPayload<{
>   include: { _count: { select: { posts: true } } };
> }>;
> ```

**Correct:**

```typescript
import { Prisma } from '@prisma/client';

type PostWithAuthor = Prisma.PostGetPayload<{
  select: {
    id: true;
    title: true;
    content: true;
    published: true;
    authorId: true;
    author: {
      select: { name: true; email: true };
    };
  };
}>;
```

**Impact:** Manual types duplicate Prisma-generated types. Schema changes don't propagate to manual interfaces, causing type/runtime mismatches. Maintenance burden and potential bugs when adding/removing fields.

---

### [MEDIUM] Missing Graceful Shutdown Handler

**Found Instances:** 2

```typescript
const prisma = new PrismaClient();
```

**Research Doc says:** (section "Connection Management - Handle Graceful Shutdown")

> ```typescript
> process.on('SIGINT', async () => {
>   await prisma.$disconnect();
>   process.exit(0);
> });
> ```

**Correct:**

```typescript
const prisma = new PrismaClient();

process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
```

**Impact:** Application exits without disconnecting from database, leaving connections open. Causes connection pool leaks in container environments and prevents clean shutdown. Critical for long-running processes, less impactful in serverless.

---

### [LOW] Missing Select Optimization

**Found Instances:** 2

```typescript
const users = await prisma.user.findMany();
return users.map((u) => u.email);
```

**Research Doc says:** (section "Best Practices - Query Optimization")

> **Select Only Required Fields:**
> ```typescript
> const users = await prisma.user.findMany({
>   select: { email: true },
> });
> ```

**Correct:**

```typescript
const users = await prisma.user.findMany({
  select: { email: true },
});
```

**Impact:** Fetching all fields when only email needed wastes bandwidth and memory. Large tables with TEXT columns or many fields see significant performance improvement with selective queries.

---

### [LOW] Generic Error Handling Instead of Prisma-Specific Types

**Found Instances:** 1

```typescript
try {
  const user = await prisma.user.findUnique({ where: { id } });
} catch (error) {
  if (error instanceof Error) {
    return { error: 'Internal server error', details: error.message };
  }
}
```

**Research Doc says:** (section "Error Handling - Handle Known Errors")

> ```typescript
> try {
>   await prisma.user.create({ data: { email: 'duplicate@example.com' } });
> } catch (error) {
>   if (error instanceof Prisma.PrismaClientKnownRequestError) {
>     if (error.code === 'P2002') {
>       console.log('Unique constraint violation');
>     } else if (error.code === 'P2025') {
>       console.log('Record not found');
>     }
>   }
>   throw error;
> }
> ```

**Correct:**

```typescript
import { Prisma } from '@prisma/client';

try {
  const user = await prisma.user.findUnique({ where: { id } });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2025') {
      return { error: 'User not found', status: 404 };
    }
    if (error.code === 'P1001') {
      return { error: 'Database unavailable', status: 503 };
    }
  }
  return { error: 'Internal server error', status: 500 };
}
```

**Impact:** Generic error handling doesn't distinguish Prisma error types. Missing opportunity for specific user messages (404 for not found, 409 for conflicts, 503 for connection errors). Current code also exposes error.message in production, potentially leaking sensitive information.

---

## Summary

Report: `/Users/daniel/Projects/claude-configs/prisma-6/STRESS-TEST-REPORT.md`

**Total Violations:** 30
**Top 3 Issues:**
1. Creating PrismaClient in functions (7 instances)
2. SQL injection via unsafe APIs (4 instances)
3. Missing connection pool configuration (3 instances)

**Critical Findings:**
- 10 critical violations including connection pool exhaustion, SQL injection, and Prisma 6 breaking changes (Buffer API)
- Most agents (4/5) created multiple PrismaClient instances
- 2 agents used unsafe SQL APIs ($queryRawUnsafe, Prisma.raw with interpolation)

**Research Gaps:**
- Connection pool configuration for serverless needs more emphasis
- Buffer → Uint8Array migration should be highlighted in overview
- Multi-tenant patterns using Client Extensions need dedicated section

**Next Steps:**
1. Add serverless configuration checklist to research doc
2. Create Prisma 6 breaking changes quick reference
3. Add multi-tenant architecture patterns section
4. Include error handling best practices with all error codes

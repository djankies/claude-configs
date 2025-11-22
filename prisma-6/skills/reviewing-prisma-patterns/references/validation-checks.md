# Validation Checks

Complete validation patterns for all 7 critical issue categories in Prisma code review.

---

## 1. SQL Injection Detection (CRITICAL - P0)

**Pattern:** Unsafe raw SQL usage

**Detection Command:**
```bash
grep -rn "\$queryRawUnsafe\|Prisma\.raw" --include="*.ts" --include="*.js" .
```

**Red flags:**
- `$queryRawUnsafe` with string concatenation
- `Prisma.raw()` with template literals (non-tagged)
- Dynamic table/column names via string interpolation
- Filter conditions with user input interpolation

**Example violations:**

```typescript
const users = await prisma.$queryRawUnsafe(
  `SELECT * FROM users WHERE email = '${email}'`
);

const posts = await prisma.$queryRaw(
  Prisma.raw(`SELECT * FROM posts WHERE title LIKE '%${search}%'`)
);
```

**Remediation:**

Use `$queryRaw` tagged template for automatic parameterization:

```typescript
const users = await prisma.$queryRaw`
  SELECT * FROM users WHERE email = ${email}
`;

const posts = await prisma.$queryRaw`
  SELECT * FROM posts WHERE title LIKE ${'%' + search + '%'}
`;
```

Use Prisma.sql for composition:

```typescript
import { Prisma } from '@prisma/client'

const emailFilter = Prisma.sql`email = ${email}`
const users = await prisma.$queryRaw`
  SELECT * FROM users WHERE ${emailFilter}
`
```

**Impact:** CRITICAL - SQL injection enables arbitrary database access, data exfiltration, deletion

**Reference:** @prisma-6/SECURITY-sql-injection

---

## 2. Multiple PrismaClient Instances (CRITICAL - P0)

**Pattern:** Multiple client instantiation

**Detection Command:**
```bash
grep -rn "new PrismaClient()" --include="*.ts" --include="*.js" . | wc -l
```

**Red flags:**
- Count > 1 across codebase
- Function-scoped client creation
- Missing global singleton pattern
- Test files creating separate instances

**Example violations:**

```typescript
export function getUser(id: string) {
  const prisma = new PrismaClient();
  return prisma.user.findUnique({ where: { id } });
}

export function getPost(id: string) {
  const prisma = new PrismaClient();
  return prisma.post.findUnique({ where: { id } });
}
```

**Remediation:**

Create global singleton:

```typescript
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

Import singleton everywhere:

```typescript
import { prisma } from '@/lib/prisma'

export function getUser(id: string) {
  return prisma.user.findUnique({ where: { id } });
}
```

**Impact:** CRITICAL - Connection pool exhaustion, P1017 errors, production outages

**Reference:** @prisma-6/CLIENT-singleton-pattern

---

## 3. Missing Serverless Configuration (HIGH - P1)

**Pattern:** Serverless deployment without connection limits

**Detection:**

1. Check for serverless context:
```bash
test -f vercel.json || test -d app/ || grep -q "lambda" package.json
```

2. Check for connection_limit:
```bash
grep -rn "connection_limit=1" --include="*.env*" --include="schema.prisma" .
```

**Red flags:**
- Serverless deployment detected (Vercel, Lambda, Cloudflare Workers)
- No `connection_limit=1` in DATABASE_URL
- No PgBouncer configuration
- Default pool_timeout settings

**Example violation:**

```
DATABASE_URL="postgresql://user:pass@host:5432/db"
```

**Remediation:**

Add connection_limit to DATABASE_URL:

```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=10"
```

For Next.js on Vercel:

```typescript
export const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL + '?connection_limit=1'
    }
  }
})
```

**Impact:** HIGH - Production database connection exhaustion under load

**Reference:** @prisma-6/CLIENT-serverless-config

---

## 4. Deprecated Buffer API (HIGH - P1)

**Pattern:** Prisma 6 breaking change - Buffer on Bytes fields

**Detection Command:**
```bash
grep -rn "Buffer\.from\|\.toString()" --include="*.ts" --include="*.js" . | grep -i "bytes\|binary"
```

**Red flags:**
- `Buffer.from()` used with Bytes fields
- `.toString()` called on Bytes field results
- Missing Uint8Array conversion
- Missing TextEncoder/TextDecoder

**Example violations:**

```typescript
const user = await prisma.user.create({
  data: {
    avatar: Buffer.from(base64Data, 'base64')
  }
});

const avatarString = user.avatar.toString('base64');
```

**Remediation:**

Use Uint8Array instead of Buffer:

```typescript
const base64ToUint8Array = (base64: string) => {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
};

const user = await prisma.user.create({
  data: {
    avatar: base64ToUint8Array(base64Data)
  }
});
```

Use TextEncoder/TextDecoder:

```typescript
const encoder = new TextEncoder();
const decoder = new TextDecoder();

const user = await prisma.user.create({
  data: {
    content: encoder.encode('Hello')
  }
});

const text = decoder.decode(user.content);
```

**Impact:** HIGH - Type errors, runtime failures after Prisma 6 upgrade

**Reference:** @prisma-6/MIGRATIONS-v6-upgrade

---

## 5. Generic Error Handling (MEDIUM - P2)

**Pattern:** Missing Prisma error code handling

**Detection Command:**
```bash
grep -rn "catch.*error" --include="*.ts" --include="*.js" . | grep -L "P2002\|P2025\|PrismaClientKnownRequestError"
```

**Red flags:**
- Generic `catch (error)` without P-code checking
- No differentiation between error types
- Exposing raw Prisma errors to clients
- Missing unique constraint handling (P2002)
- Missing not found handling (P2025)

**Example violation:**

```typescript
try {
  await prisma.user.create({ data });
} catch (error) {
  throw new Error('Database error');
}
```

**Remediation:**

Check error.code for specific P-codes:

```typescript
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/library'

try {
  await prisma.user.create({ data })
} catch (error) {
  if (error instanceof PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      throw new Error('User with this email already exists')
    }
    if (error.code === 'P2025') {
      throw new Error('Record not found')
    }
  }
  throw new Error('Unexpected error')
}
```

**Impact:** MEDIUM - Poor user experience, unclear error messages, potential info leakage

**Reference:** @prisma-6/TRANSACTIONS-error-handling, @prisma-6/SECURITY-error-exposure

---

## 6. Missing Input Validation (MEDIUM - P2)

**Pattern:** No validation before database operations

**Detection Command:**
```bash
grep -rn "prisma\.\w+\.(create\|update\|upsert)" --include="*.ts" --include="*.js" . | grep -L "parse\|validate\|schema"
```

**Red flags:**
- Direct database operations with external input
- No Zod/Yup/Joi schema validation
- Type assertions without runtime checks
- Missing email/phone/URL validation

**Example violation:**

```typescript
export async function createUser(data: any) {
  return prisma.user.create({ data });
}
```

**Remediation:**

Add Zod schema validation:

```typescript
import { z } from 'zod'

const userSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  age: z.number().int().positive().optional()
})

export async function createUser(data: unknown) {
  const validated = userSchema.parse(data)
  return prisma.user.create({ data: validated })
}
```

**Impact:** MEDIUM - Type mismatches, invalid data in database, runtime errors

**Reference:** @prisma-6/SECURITY-input-validation

---

## 7. Inefficient Queries (LOW - P3)

**Pattern:** Performance anti-patterns

**Detection Commands:**
```bash
grep -rn "\.skip\|\.take" --include="*.ts" --include="*.js" .
grep -rn "prisma\.\w+\.findMany()" --include="*.ts" --include="*.js" . | grep -v "select\|include"
```

**Red flags:**
- Offset pagination (skip/take) on large datasets (> 10k records)
- Missing `select` for partial queries
- N+1 queries (findMany in loops without include)
- Missing indexes for frequent queries

**Example violations:**

Offset pagination on large dataset:
```typescript
const users = await prisma.user.findMany({
  skip: page * 100,
  take: 100
});
```

Missing select optimization:
```typescript
const users = await prisma.user.findMany();
```

N+1 query:
```typescript
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({
    where: { authorId: user.id }
  });
}
```

**Remediation:**

Use cursor-based pagination:
```typescript
const users = await prisma.user.findMany({
  take: 100,
  cursor: lastId ? { id: lastId } : undefined,
  orderBy: { id: 'asc' }
});
```

Add select for partial queries:
```typescript
const users = await prisma.user.findMany({
  select: { id: true, email: true, name: true }
});
```

Fix N+1 with include:
```typescript
const users = await prisma.user.findMany({
  include: { posts: true }
});
```

**Impact:** LOW - Slow queries, high database load, poor performance at scale

**Reference:** @prisma-6/QUERIES-pagination, @prisma-6/QUERIES-select-optimization

---

## Summary Table

| Check | Severity | Detection | Common Fix | Skill Reference |
|-------|----------|-----------|------------|-----------------|
| SQL Injection | P0 | `$queryRawUnsafe` | Use `$queryRaw` tagged template | SECURITY-sql-injection |
| Multiple Clients | P0 | Count `new PrismaClient()` | Global singleton pattern | CLIENT-singleton-pattern |
| Serverless Config | P1 | Missing `connection_limit` | Add `?connection_limit=1` | CLIENT-serverless-config |
| Buffer API | P1 | `Buffer.from` with Bytes | Use Uint8Array | MIGRATIONS-v6-upgrade |
| Error Handling | P2 | Generic catch | Check P-codes (P2002, P2025) | TRANSACTIONS-error-handling |
| Input Validation | P2 | No validation before DB | Add Zod schema | SECURITY-input-validation |
| Query Efficiency | P3 | skip/take, no select | Cursor pagination, select | QUERIES-pagination |

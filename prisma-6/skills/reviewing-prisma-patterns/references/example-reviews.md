# Example Reviews

Complete code review examples showing typical findings and recommendations.

---

## Example 1: E-commerce API (Next.js)

**Context:** Next.js 14 App Router with Prisma, deployed to Vercel

**Project Structure:**
```
app/
├── api/
│   ├── products/route.ts
│   ├── users/route.ts
│   └── search/route.ts
├── lib/
│   └── db.ts
└── .env
```

**Findings:**

```
Prisma Code Review - E-commerce API
Generated: 2025-11-21
Files Reviewed: 15

CRITICAL Issues (P0): 2
HIGH Issues (P1): 1
MEDIUM Issues (P2): 3
LOW Issues (P3): 2

Overall Assessment: CRITICAL ISSUES - Do not deploy

---

[P0] Multiple PrismaClient Instances
Files:
  - app/api/products/route.ts:8
  - app/api/users/route.ts:12
  - lib/db.ts:5
Count: 3 instances found

Code (app/api/products/route.ts:8):
```typescript
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

export async function GET() {
  const products = await prisma.product.findMany()
  return Response.json(products)
}
```

Impact: CRITICAL - Connection pool exhaustion under load
- Each API route creates separate connection pool
- Vercel scales to 100+ concurrent functions
- 3 routes × 100 instances × 10 connections = 3000 connections!
- Database will reject connections (P1017)

Fix: Create global singleton in lib/db.ts, import everywhere

Remediation Steps:
1. Create lib/prisma.ts with global singleton pattern
2. Replace all `new PrismaClient()` with imports
3. Verify with grep (should find only 1 instance)

Reference: @prisma-6/CLIENT-singleton-pattern

---

[P0] SQL Injection Vulnerability
File: app/api/search/route.ts:23

Code:
```typescript
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const query = searchParams.get('q')

  const products = await prisma.$queryRawUnsafe(
    `SELECT * FROM products WHERE name LIKE '%${query}%'`
  )

  return Response.json(products)
}
```

Impact: CRITICAL - Enables SQL injection attacks
- User controls `query` parameter
- Direct string interpolation allows injection
- Attacker can execute arbitrary SQL

Example attack:
```
/api/search?q=%27;%20DROP%20TABLE%20products;--
```

Fix: Use $queryRaw tagged template with automatic parameterization

Remediation:
```typescript
const products = await prisma.$queryRaw`
  SELECT * FROM products WHERE name LIKE ${'%' + query + '%'}
`
```

Reference: @prisma-6/SECURITY-sql-injection

---

[P1] Missing Serverless Configuration
File: .env

Current:
```
DATABASE_URL="postgresql://user:pass@host:5432/db"
```

Impact: HIGH - Connection exhaustion in Vercel deployment
- Default pool_size = 10 connections per instance
- Vercel can scale to 100+ instances
- 100 instances × 10 connections = 1000 connections
- Most databases have 100-200 connection limit

Fix: Add ?connection_limit=1 to DATABASE_URL

Remediation:
```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=10"
```

Why this works:
- Each Vercel function instance gets 1 connection
- 100 instances × 1 connection = 100 connections (sustainable)
- pool_timeout=10 prevents hanging on exhaustion

Reference: @prisma-6/CLIENT-serverless-config

---

[P2] Missing Input Validation
Files: app/api/users/route.ts, app/api/products/route.ts

Code (app/api/users/route.ts):
```typescript
export async function POST(request: Request) {
  const data = await request.json()
  const user = await prisma.user.create({ data })
  return Response.json(user)
}
```

Impact: MEDIUM - Invalid data can reach database
- No validation of email format
- No validation of required fields
- Type mismatches cause runtime errors

Fix: Add Zod validation schemas before Prisma operations

Remediation:
```typescript
import { z } from 'zod'

const userSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
})

export async function POST(request: Request) {
  const data = await request.json()
  const validated = userSchema.parse(data)
  const user = await prisma.user.create({ data: validated })
  return Response.json(user)
}
```

Reference: @prisma-6/SECURITY-input-validation

---

[P3] Inefficient Pagination
File: app/api/products/route.ts:15

Code:
```typescript
const page = parseInt(searchParams.get('page') ?? '0')
const products = await prisma.product.findMany({
  skip: page * 100,
  take: 100
})
```

Impact: LOW - Slow queries on large datasets
- Product table has 50k+ records
- Offset pagination degrades with page number
- Page 500 skips 50k records (slow!)

Fix: Use cursor-based pagination with id cursor

Remediation:
```typescript
const cursor = searchParams.get('cursor')
const products = await prisma.product.findMany({
  take: 100,
  cursor: cursor ? { id: cursor } : undefined,
  orderBy: { id: 'asc' }
})

const nextCursor = products.length === 100
  ? products[99].id
  : null
```

Reference: @prisma-6/QUERIES-pagination

---

RECOMMENDATION: Fix P0 issues immediately before any deployment. P1 issues will cause production failures under load.

Priority Actions:
1. Implement global singleton pattern (blocking)
2. Fix SQL injection in search endpoint (blocking)
3. Add connection_limit to DATABASE_URL (high priority)
4. Add Zod validation to API routes (recommended)
5. Optimize pagination for products (nice to have)
```

---

## Example 2: Internal Dashboard (Express)

**Context:** Express API with PostgreSQL, traditional server deployment

**Project Structure:**
```
src/
├── controllers/
│   ├── users.ts
│   └── reports.ts
├── db.ts
└── index.ts
```

**Findings:**

```
Prisma Code Review - Internal Dashboard
Generated: 2025-11-21
Files Reviewed: 8

CRITICAL Issues (P0): 0
HIGH Issues (P1): 0
MEDIUM Issues (P2): 1
LOW Issues (P3): 3

Overall Assessment: GOOD - Minor improvements recommended

---

[P2] Generic Error Handling
File: src/controllers/users.ts:45-52

Code:
```typescript
async function createUser(req: Request, res: Response) {
  try {
    const user = await prisma.user.create({
      data: req.body
    })
    res.json(user)
  } catch (error) {
    res.status(500).json({ error: 'Database error' })
  }
}
```

Impact: MEDIUM - P2002/P2025 not handled specifically
- User gets generic "Database error" for all failures
- Duplicate email returns 500 instead of 409
- Poor developer experience debugging issues

Fix: Check error.code for P2002 (unique), P2025 (not found)

Remediation:
```typescript
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/library'

async function createUser(req: Request, res: Response) {
  try {
    const user = await prisma.user.create({
      data: req.body
    })
    res.json(user)
  } catch (error) {
    if (error instanceof PrismaClientKnownRequestError) {
      if (error.code === 'P2002') {
        return res.status(409).json({
          error: 'User with this email already exists'
        })
      }
    }
    res.status(500).json({ error: 'Unexpected error' })
  }
}
```

Reference: @prisma-6/TRANSACTIONS-error-handling

---

[P3] Inefficient Pagination
File: src/controllers/reports.ts:78

Code:
```typescript
const reports = await prisma.report.findMany({
  skip: page * 100,
  take: 100,
  orderBy: { createdAt: 'desc' }
})
```

Context:
- Reports table has 50k+ records
- Used in admin dashboard for audit logs
- Page 500 requires scanning 50k records

Impact: LOW - Slow queries on large datasets
- Query time increases with page number
- Database performs full table scan
- Admin dashboard feels sluggish

Fix: Use cursor-based pagination with id cursor

Remediation:
```typescript
const reports = await prisma.report.findMany({
  take: 100,
  cursor: lastId ? { id: lastId } : undefined,
  orderBy: { createdAt: 'desc' }
})
```

Reference: @prisma-6/QUERIES-pagination

---

[P3] Missing Select Optimization
Files: 8 files with findMany() lacking select

Examples:
- src/controllers/users.ts:23
- src/controllers/reports.ts:45
- src/controllers/analytics.ts:67

Code pattern:
```typescript
const users = await prisma.user.findMany()
```

Impact: LOW - Fetching unnecessary fields
- Returns all columns including large text fields
- Increases response payload size
- Wastes database bandwidth

Fix: Add select: { id, name, email } to queries

Remediation:
```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true,
    role: true
  }
})
```

Reference: @prisma-6/QUERIES-select-optimization

---

[P3] Missing Select in List Endpoints
File: src/controllers/users.ts:88

Code:
```typescript
const users = await prisma.user.findMany({
  include: { posts: true }
})
```

Impact: LOW - Over-fetching related data
- Returns ALL posts for each user
- User with 1000 posts = huge payload
- Should paginate posts separately

Fix: Limit included records or use separate query

Remediation:
```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true,
    _count: {
      select: { posts: true }
    }
  }
})
```

Reference: @prisma-6/QUERIES-select-optimization

---

ASSESSMENT: Code quality is good. No critical issues found.

Recommended Improvements:
1. Improve error handling with P-code checks (user experience)
2. Optimize pagination for reports table (performance)
3. Add select clauses to list endpoints (efficiency)

These improvements are optional but will enhance code quality and performance.
```

---

## Summary

**E-commerce API:**
- High-risk serverless deployment with critical security/stability issues
- Must fix P0 issues before deployment
- Typical of AI-generated code without production hardening

**Internal Dashboard:**
- Low-risk traditional server deployment with minor optimizations
- No blocking issues
- Good baseline quality with room for improvement

Both examples demonstrate the importance of systematic code review before production deployment.

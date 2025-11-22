---
name: configuring-serverless-clients
description: Configure PrismaClient for serverless environments (Next.js, Lambda, Vercel) with connection_limit=1 and global singleton. Use when deploying to serverless platforms, working with Next.js App Router, AWS Lambda, or Vercel functions.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Serverless PrismaClient Configuration

This skill teaches proper PrismaClient configuration for serverless environments to prevent connection pool exhaustion.

---

<role>
This skill teaches Claude how to configure PrismaClient for serverless platforms (Next.js, AWS Lambda, Vercel) using connection pooling limits and global singleton patterns to prevent database connection exhaustion.
</role>

<when-to-activate>
This skill activates when:

- Deploying to Next.js (App Router or Pages Router)
- Working with AWS Lambda functions
- Deploying to Vercel or similar serverless platforms
- User mentions serverless, Lambda, Vercel, or edge functions
- Encountering P1017 errors (connection pool exhausted)
- Working with files in app/, pages/api/, or lambda/ directories
</when-to-activate>

<overview>
Serverless environments create a unique challenge for database connections:

**The Problem:**
- Each Lambda instance creates its own connection pool
- Default pool size (unlimited) × instances = exhausted database connections
- Example: 10 concurrent Lambda instances × 10 connections = 100 connections

**The Solution:**
- Set `connection_limit=1` in DATABASE_URL
- Use global singleton pattern to reuse client across invocations
- Consider PgBouncer for high-concurrency scenarios

**Stress Test Context:**
3/5 agents deployed to serverless without connection limits, causing production P1017 failures.
</overview>

<workflow>
## Standard Workflow

**Phase 1: Environment Configuration**

1. Add `connection_limit=1` to DATABASE_URL in .env
2. Add `pool_timeout=20` for connection wait behavior
3. For Vercel: Configure environment variables in dashboard

**Phase 2: Client Singleton Implementation**

1. Create global PrismaClient instance
2. Use Next.js 13+ pattern for App Router
3. Use traditional pattern for Pages Router or plain Lambda

**Phase 3: Validation**

1. Verify no multiple `new PrismaClient()` calls
2. Test with concurrent requests
3. Monitor connection count in production
</workflow>

<conditional-workflows>
## Decision Points

**If using Next.js 13+ App Router:**

1. Create `lib/prisma.ts` with Next.js global pattern
2. Use `globalThis` to persist client across hot reloads
3. Import from single location throughout app

**If using Next.js Pages Router or API Routes:**

1. Create `lib/prisma.ts` with traditional global pattern
2. Use `global.prisma` to reuse instance
3. Import in API routes and getServerSideProps

**If using AWS Lambda (standalone):**

1. Create client outside handler function
2. Set `connection_limit=1` in DATABASE_URL
3. Don't call `$disconnect()` in handler (reuse connections)

**If experiencing connection issues despite limits:**

1. Consider PgBouncer connection pooler
2. Use transaction mode for short queries
3. Set higher `connection_limit` with pooler (e.g., 5-10)
</conditional-workflows>

<examples>
## Examples

### Example 1: Next.js 13+ App Router Pattern

**File: `lib/prisma.ts`**

```typescript
import { PrismaClient } from '@prisma/client'

const prismaClientSingleton = () => {
  return new PrismaClient()
}

declare const globalThis: {
  prismaGlobal: ReturnType<typeof prismaClientSingleton>;
} & typeof global;

const prisma = globalThis.prismaGlobal ?? prismaClientSingleton()

export default prisma

if (process.env.NODE_ENV !== 'production') globalThis.prismaGlobal = prisma
```

**Environment Variables (`.env`):**

```bash
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=20"
```

**Usage in Server Action:**

```typescript
import prisma from '@/lib/prisma'

export async function createUser(formData: FormData) {
  'use server'

  const user = await prisma.user.create({
    data: {
      email: formData.get('email') as string,
      name: formData.get('name') as string
    }
  })

  return user
}
```

### Example 2: Next.js Pages Router Pattern

**File: `lib/prisma.ts`**

```typescript
import { PrismaClient } from '@prisma/client'

declare global {
  var prisma: PrismaClient | undefined
}

const prisma = global.prisma || new PrismaClient()

if (process.env.NODE_ENV !== 'production') global.prisma = prisma

export default prisma
```

**Usage in API Route:**

```typescript
import type { NextApiRequest, NextApiResponse } from 'next'
import prisma from '@/lib/prisma'

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method === 'POST') {
    const user = await prisma.user.create({
      data: req.body
    })
    return res.json(user)
  }
}
```

### Example 3: AWS Lambda Standalone

**File: `handler.ts`**

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export const handler = async (event: any) => {
  const users = await prisma.user.findMany({
    where: {
      active: true
    }
  })

  return {
    statusCode: 200,
    body: JSON.stringify(users)
  }
}
```

**Environment Variables (Serverless Framework `serverless.yml`):**

```yaml
provider:
  name: aws
  runtime: nodejs20.x
  environment:
    DATABASE_URL: ${env:DATABASE_URL}

functions:
  getUsers:
    handler: handler.handler
    events:
      - http:
          path: users
          method: get
```

**`.env` (for deployment):**

```bash
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=20"
```

### Example 4: With PgBouncer Connection Pooler

**When to use:**
- High concurrency (>50 concurrent requests)
- Multiple serverless functions
- Connection limit still causing issues

**Environment Variables:**

```bash
DATABASE_URL="postgresql://user:pass@pgbouncer-host:6543/db?connection_limit=10&pool_timeout=20"

DIRECT_URL="postgresql://user:pass@direct-host:5432/db"
```

**Prisma Schema (`schema.prisma`):**

```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}
```

**Note:**
- `DATABASE_URL` points to PgBouncer (for queries)
- `DIRECT_URL` points to database (for migrations)
- Can increase `connection_limit` to 5-10 with pooler
</examples>

<progressive-disclosure>
## Reference Files

For detailed information on specific topics:

- **Next.js Integration**: See `references/nextjs-patterns.md` for App Router, Pages Router, and middleware patterns
- **Lambda Optimization**: See `references/lambda-patterns.md` for cold start optimization and connection reuse
- **PgBouncer Setup**: See `references/pgbouncer-guide.md` for connection pooler configuration
</progressive-disclosure>

<constraints>
## Constraints and Guidelines

**MUST:**

- Set `connection_limit=1` in DATABASE_URL for serverless deployments
- Use global singleton pattern (never `new PrismaClient()` in functions)
- Create single `lib/prisma.ts` file imported throughout app
- Add `pool_timeout` to control connection wait behavior

**SHOULD:**

- Use PgBouncer for high-concurrency applications (>50 concurrent)
- Monitor connection count in production database
- Set connection limit via URL parameter, not PrismaClient constructor
- Reuse Lambda container connections (don't disconnect in handler)

**NEVER:**

- Create `new PrismaClient()` inside API routes, Server Actions, or Lambda handlers
- Use default connection pool size in serverless environments
- Call `prisma.$disconnect()` in serverless handlers (prevents reuse)
- Deploy to production without connection limits
- Use separate PrismaClient instances across files
</constraints>

<validation>
## Validation

After implementing serverless configuration:

1. **Environment Variable Check:**

   - Verify DATABASE_URL contains `connection_limit=1`
   - Verify `pool_timeout` is set (recommended: 20)
   - For Vercel: Check dashboard environment variables

2. **Singleton Pattern Check:**

   - Search codebase for `new PrismaClient()`
   - Should appear exactly once in `lib/prisma.ts`
   - All other files should import from `lib/prisma`

3. **Concurrent Request Test:**

   - Deploy to staging environment
   - Send 10+ concurrent requests
   - Monitor database connections (should not exceed 10-15)
   - Watch for P1017 errors

4. **Production Monitoring:**
   - Set up connection count alerts
   - Monitor for "Connection pool timeout" errors
   - Track Lambda cold starts and connection behavior
</validation>

---

## Common Mistakes

### Mistake 1: Connection Limit in Constructor

**Wrong:**

```typescript
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
})
```

**Right:**

```bash
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1"
```

Connection limit must be in URL, not constructor.

### Mistake 2: Multiple Instances

**Wrong:**

```typescript
export async function getUser(id: string) {
  const prisma = new PrismaClient()
  const user = await prisma.user.findUnique({ where: { id } })
  return user
}
```

**Right:**

```typescript
import prisma from '@/lib/prisma'

export async function getUser(id: string) {
  const user = await prisma.user.findUnique({ where: { id } })
  return user
}
```

### Mistake 3: Disconnecting in Handler

**Wrong (Lambda):**

```typescript
export const handler = async (event: any) => {
  const users = await prisma.user.findMany()
  await prisma.$disconnect()
  return { statusCode: 200, body: JSON.stringify(users) }
}
```

**Right:**

```typescript
export const handler = async (event: any) => {
  const users = await prisma.user.findMany()
  return { statusCode: 200, body: JSON.stringify(users) }
}
```

Lambda containers reuse connections. Don't disconnect.

### Mistake 4: Missing Global Declaration

**Wrong:**

```typescript
const prisma = global.prisma || new PrismaClient()
```

TypeScript error: Property 'prisma' does not exist on type 'typeof globalThis'

**Right:**

```typescript
declare global {
  var prisma: PrismaClient | undefined
}

const prisma = global.prisma || new PrismaClient()
```

---

## Platform-Specific Notes

### Vercel

- Set environment variables in Vercel dashboard
- Automatic environment variable encryption
- Connection pooling shared across function invocations in same region
- Consider Vercel Postgres for built-in connection pooling

### AWS Lambda

- Container reuse varies by traffic pattern
- Cold starts create new PrismaClient instances
- Consider provisioned concurrency for consistent performance
- Use Lambda layers for Prisma binary optimization

### Cloudflare Workers

- Different constraints due to V8 isolates (not Node.js)
- Use Prisma Data Proxy or D1 database
- Standard Prisma Client not supported

### Railway / Render

- Traditional serverless platforms
- Apply same connection_limit=1 pattern
- Built-in connection pooling may be available
- Check platform documentation for pooling options

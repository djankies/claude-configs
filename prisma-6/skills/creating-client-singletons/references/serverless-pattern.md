# Serverless Pattern

Serverless environments require special handling due to cold starts, connection pooling, and function lifecycle constraints.

## Next.js App Router (Vercel)

**File: `lib/prisma.ts`**

```typescript
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
})

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

**Environment Configuration (.env):**

```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=10"
```

**Why connection_limit=1:**

- Each serverless function instance gets ONE connection
- Multiple function instances = multiple connections
- Prevents pool exhaustion with many concurrent requests
- Vercel scales to hundreds of instances automatically

**Usage in Server Components:**

```typescript
import { prisma } from '@/lib/prisma'

export default async function UsersPage() {
  const users = await prisma.user.findMany()
  return <UserList users={users} />
}
```

**Usage in Server Actions:**

```typescript
'use server'

import { prisma } from '@/lib/prisma'

export async function createUser(formData: FormData) {
  const email = formData.get('email') as string

  return await prisma.user.create({
    data: { email }
  })
}
```

**Usage in Route Handlers:**

```typescript
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  const users = await prisma.user.findMany()
  return NextResponse.json(users)
}
```

**Key Points:**

- Never create PrismaClient in component files
- Import singleton from `lib/prisma.ts`
- Global pattern survives hot reload
- Connection limit prevents pool exhaustion

---

## AWS Lambda

**File: `lib/db.ts`**

```typescript
import { PrismaClient } from '@prisma/client'

let prisma: PrismaClient

if (!global.prisma) {
  global.prisma = new PrismaClient({
    log: ['error', 'warn']
  })
}

prisma = global.prisma

export default prisma
```

**Lambda Handler:**

```typescript
import prisma from './lib/db'

export async function handler(event: any) {
  const users = await prisma.user.findMany()

  return {
    statusCode: 200,
    body: JSON.stringify(users)
  }
}
```

**Environment Variables (Lambda):**

```
DATABASE_URL=postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=10&connect_timeout=10
```

**Lambda-Specific Considerations:**

- Lambda reuses container for warm starts
- Global singleton survives across invocations
- First invocation creates client (cold start)
- Subsequent invocations reuse client (warm starts)
- No need to disconnect (Lambda freezes container)

---

## Connection Pool Calculation for Serverless

**Formula:**

```
max_connections = (max_concurrent_functions * connection_limit) + buffer
```

**Example (Vercel):**

- Max concurrent functions: 100
- Connection limit per function: 1
- Buffer: 10

**Result:** Need 110 database connections

**Recommended DATABASE_URL for Vercel:**

```
postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=10
```

**Why pool_timeout=10:**

- Prevents long waits for connections
- Fails fast if pool exhausted
- User gets error instead of timeout

---

## Anti-Pattern: Multiple Files Creating Clients

**WRONG - Each file creates its own:**

**`app/api/users/route.ts`:**

```typescript
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

export async function GET() {
  return Response.json(await prisma.user.findMany())
}
```

**`app/api/posts/route.ts`:**

```typescript
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

export async function GET() {
  return Response.json(await prisma.post.findMany())
}
```

**Problems in Serverless:**

- Each route = separate client = separate pool
- 2 routes × 50 function instances × 10 connections = 1000 connections!
- Database exhausted under load
- P1017 errors inevitable

**Fix - Central singleton:**

**`lib/prisma.ts`:**

```typescript
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

**`app/api/users/route.ts`:**

```typescript
import { prisma } from '@/lib/prisma'

export async function GET() {
  return Response.json(await prisma.user.findMany())
}
```

**`app/api/posts/route.ts`:**

```typescript
import { prisma } from '@/lib/prisma'

export async function GET() {
  return Response.json(await prisma.post.findMany())
}
```

**Result:**

- 50 function instances × 1 connection = 50 connections
- Sustainable and scalable
- No P1017 errors

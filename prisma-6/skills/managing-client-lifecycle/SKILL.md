---
name: managing-client-lifecycle
description: Manage PrismaClient lifecycle with graceful shutdown, proper disconnect timing, and logging configuration. Use when setting up application shutdown handlers, configuring logging for development or production, or implementing proper connection cleanup in Node.js servers, serverless functions, or test suites.
allowed-tools: Read, Write, Edit
version: 1.0.0
---

# PrismaClient Lifecycle Management

This skill teaches proper PrismaClient lifecycle patterns including graceful shutdown, disconnect timing, and logging configuration.

---

<role>
This skill teaches Claude how to implement proper PrismaClient lifecycle management following Prisma 6 best practices for connection cleanup and logging.
</role>

<when-to-activate>
This skill activates when:
- Setting up shutdown handlers (SIGINT, SIGTERM)
- Configuring PrismaClient logging
- Implementing connection cleanup in servers or serverless
- Writing test teardown logic
- User mentions "shutdown", "disconnect", "cleanup", "logging", or "graceful exit"
</when-to-activate>

<overview>
PrismaClient maintains a connection pool to the database. Proper lifecycle management ensures:
- Connections close cleanly on application shutdown
- No hanging connections exhaust database resources
- Logging provides useful development/production visibility
- Tests clean up properly without connection leaks

Key capabilities:
1. Graceful shutdown handlers for Node.js servers
2. Proper $disconnect() timing in serverless and tests
3. Development vs production logging configuration
4. Framework-specific cleanup patterns
</overview>

<workflow>
## Standard Workflow

**Phase 1: Identify Application Type**
1. Determine if long-running server, serverless function, or test suite
2. Identify framework (Express, Fastify, Next.js, etc.)
3. Check existing shutdown handling

**Phase 2: Implement Lifecycle Hooks**
1. Add graceful shutdown listeners (SIGINT, SIGTERM) for servers
2. Add $disconnect() in serverless function cleanup
3. Configure logging based on environment
4. Add test teardown hooks if needed

**Phase 3: Verify Cleanup**
1. Test shutdown behavior (Ctrl+C in development)
2. Check for connection leaks in tests
3. Verify logging output matches expectations
</workflow>

<conditional-workflows>
## Decision Points

**If Long-Running Server (Express, Fastify, custom HTTP):**
1. Add SIGINT and SIGTERM handlers
2. Call prisma.$disconnect() in handlers
3. Close server gracefully before process exit
4. See Express.js shutdown example below

**If Serverless Function (AWS Lambda, Vercel, Cloudflare Workers):**
1. Use global singleton pattern (see CLIENT-serverless-config)
2. Do NOT disconnect in function handler
3. Let serverless platform manage connection lifecycle
4. Exception: AWS Lambda with RDS Proxy may benefit from explicit disconnect

**If Test Suite (Jest, Vitest, Mocha):**
1. Call $disconnect() in afterAll() or global teardown
2. Share single PrismaClient instance across tests
3. Clean up database state, not connections, between tests
4. See test teardown pattern below

**If Next.js Application:**
1. Next.js handles cleanup automatically in dev mode
2. No explicit disconnect needed for App Router/Pages Router
3. Serverless functions follow serverless pattern above
4. See Next.js-specific notes below
</conditional-workflows>

<examples>
## Examples

### Example 1: Express.js Shutdown Handler

**Implementation:**

```typescript
import express from 'express'
import { prisma } from './lib/prisma'

const app = express()
const server = app.listen(3000)

async function gracefulShutdown(signal: string) {
  console.log(`Received ${signal}, closing server gracefully...`)

  server.close(async () => {
    console.log('HTTP server closed')

    await prisma.$disconnect()
    console.log('Database connections closed')

    process.exit(0)
  })

  setTimeout(() => {
    console.error('Forcing shutdown after timeout')
    process.exit(1)
  }, 10000)
}

process.on('SIGINT', () => gracefulShutdown('SIGINT'))
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
```

**Pattern Breakdown:**
1. SIGINT (Ctrl+C) and SIGTERM (kill) both trigger shutdown
2. HTTP server closes first (stops accepting new requests)
3. PrismaClient disconnects after server closes
4. 10-second timeout forces exit if cleanup hangs
5. Proper ordering prevents connection leaks

### Example 2: Fastify with Hooks

**Implementation:**

```typescript
import Fastify from 'fastify'
import { prisma } from './lib/prisma'

const fastify = Fastify()

fastify.addHook('onClose', async (instance) => {
  await prisma.$disconnect()
})

const start = async () => {
  try {
    await fastify.listen({ port: 3000 })
  } catch (err) {
    fastify.log.error(err)
    await prisma.$disconnect()
    process.exit(1)
  }
}

start()
```

**Pattern Breakdown:**
1. Fastify's onClose hook handles cleanup
2. Fastify triggers hook on SIGINT/SIGTERM automatically
3. Error path also disconnects before exit
4. Framework handles ordering and timing

### Example 3: Test Suite Teardown (Jest)

**Implementation:**

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

afterAll(async () => {
  await prisma.$disconnect()
})

describe('User operations', () => {
  beforeEach(async () => {
    await prisma.user.deleteMany()
  })

  test('creates user', async () => {
    const user = await prisma.user.create({
      data: { email: 'test@example.com', name: 'Test' }
    })

    expect(user.email).toBe('test@example.com')
  })
})
```

**Pattern Breakdown:**
1. Single PrismaClient instance shared across all tests
2. afterAll() disconnects after entire suite completes
3. beforeEach() cleans database state, NOT connections
4. Prevents "jest did not exit" warnings

### Example 4: Global Test Setup (Vitest)

**File: `tests/setup.ts`**

```typescript
import { PrismaClient } from '@prisma/client'
import { afterAll, beforeAll } from 'vitest'

export const prisma = new PrismaClient()

beforeAll(async () => {
  await prisma.$connect()
})

afterAll(async () => {
  await prisma.$disconnect()
})
```

**File: `vitest.config.ts`**

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    setupFiles: ['./tests/setup.ts'],
  },
})
```

**Pattern Breakdown:**
1. Global setup file creates singleton
2. Explicit $connect() ensures connection before tests
3. Single $disconnect() in global teardown
4. All test files import from setup

### Example 5: AWS Lambda Handler (Not Recommended)

**When Disconnect Might Be Needed:**

```typescript
import { APIGatewayProxyHandler } from 'aws-lambda'
import { prisma } from './lib/prisma'

export const handler: APIGatewayProxyHandler = async (event) => {
  try {
    const users = await prisma.user.findMany()

    return {
      statusCode: 200,
      body: JSON.stringify(users),
    }
  } catch (error) {
    console.error(error)
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' }),
    }
  } finally {
    if (process.env.PRISMA_DISCONNECT === 'true') {
      await prisma.$disconnect()
    }
  }
}
```

**Important Notes:**
- Default: Do NOT disconnect in Lambda handlers
- Disconnect breaks warm starts (connection setup every invocation)
- Only disconnect if using RDS Proxy with specific requirements
- Connection pooling handled by CLIENT-serverless-config patterns
- Most serverless platforms benefit from persistent connections

### Example 6: Next.js Server Component (No Disconnect)

**Implementation:**

```typescript
import { prisma } from '@/lib/prisma'

export default async function UsersPage() {
  const users = await prisma.user.findMany()

  return (
    <div>
      {users.map(user => (
        <div key={user.id}>{user.name}</div>
      ))}
    </div>
  )
}
```

**Pattern Breakdown:**
1. No disconnect call needed
2. Next.js manages PrismaClient lifecycle
3. Development: Hot reload handles cleanup
4. Production: Process lifecycle manages connections
5. Serverless deployment: See CLIENT-serverless-config

</examples>

<logging>
## Logging Configuration

**Development Logging:**

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
})
```

**Outputs:**
- Every SQL query with parameters
- Connection events
- Warnings and errors
- Useful for debugging query performance

**Production Logging:**

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient({
  log: ['warn', 'error'],
})
```

**Outputs:**
- Only warnings and errors
- Reduces log volume
- Better performance (no query logging overhead)

**Environment-Based Configuration:**

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'production'
    ? ['warn', 'error']
    : ['query', 'info', 'warn', 'error'],
})
```

**Custom Log Handling:**

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient({
  log: [
    { emit: 'event', level: 'query' },
    { emit: 'event', level: 'error' },
    { emit: 'stdout', level: 'warn' },
  ],
})

prisma.$on('query', (e) => {
  console.log('Query: ' + e.query)
  console.log('Duration: ' + e.duration + 'ms')
})

prisma.$on('error', (e) => {
  console.error('Prisma Error:', e)
})
```

**Log Levels:**
- `query`: SQL queries and execution time
- `info`: General informational messages
- `warn`: Warnings (deprecated features, performance issues)
- `error`: Errors and exceptions

</logging>

<constraints>
## Constraints and Guidelines

**MUST:**
- Call $disconnect() in server shutdown handlers (SIGINT, SIGTERM)
- Call $disconnect() in test teardown (afterAll, global teardown)
- Use environment-based logging (verbose in dev, minimal in prod)
- Wait for $disconnect() to complete (await) before process.exit()

**SHOULD:**
- Add timeout to force exit if shutdown hangs (10 seconds typical)
- Close HTTP server before disconnecting database
- Use framework-provided hooks when available (Fastify onClose, NestJS onModuleDestroy)
- Log shutdown progress for debugging

**NEVER:**
- Disconnect in serverless function handlers (breaks warm starts)
- Disconnect between test cases (only in afterAll)
- Forget await on $disconnect() (leads to hanging connections)
- Exit process before $disconnect() completes
</constraints>

<validation>
## Validation

**Test Shutdown Behavior:**

1. **Manual Testing:**
   - Start server: `npm run dev`
   - Press Ctrl+C
   - Expected: "Database connections closed" log appears
   - Expected: Process exits cleanly (no hanging)

2. **Test Suite:**
   - Run tests: `npm test`
   - Expected: No "jest did not exit" or "vitest did not exit" warnings
   - Expected: All tests pass without connection errors

3. **Connection Leak Detection:**
   - Run tests multiple times: `for i in {1..10}; do npm test; done`
   - Expected: No "Too many connections" errors
   - Expected: Consistent test execution time

**Verify Logging:**

1. **Development:**
   - Set NODE_ENV=development
   - Start application
   - Expected: Query logs appear in console
   - Perform database operation
   - Expected: See SQL query and execution time

2. **Production:**
   - Set NODE_ENV=production
   - Start application
   - Expected: Only warn/error logs appear
   - Perform database operation
   - Expected: No query logs (silent success)

</validation>

---

## Framework-Specific Notes

**Express.js:**
- Use `server.close()` before `$disconnect()`
- Handle both SIGINT and SIGTERM
- Add timeout to force exit

**Fastify:**
- Use `onClose` hook for automatic cleanup
- Framework handles signal listeners
- Simpler than manual shutdown handlers

**NestJS:**
- Implement `onModuleDestroy` lifecycle hook
- Use `@nestjs/terminus` for health checks
- Automatic cleanup in module system

**Next.js:**
- Development: No explicit disconnect needed
- Production: Depends on deployment (see CLIENT-serverless-config)
- Server Actions: No disconnect in action functions
- API Routes: Follow serverless pattern

**Serverless (Lambda, Vercel, Cloudflare):**
- Default: Do NOT disconnect in handlers
- Exception: RDS Proxy with specific configuration
- See CLIENT-serverless-config for connection management

**Test Frameworks:**
- Jest: Use `afterAll()` in test files or global teardown
- Vitest: Use global `setupFiles` for singleton management
- Mocha: Use `after()` hook in root suite
- Playwright: Use `globalTeardown` for E2E tests

---

## Common Issues

**Issue: "jest did not exit" warning**
- Cause: Missing $disconnect() in afterAll()
- Solution: Add afterAll hook with await prisma.$disconnect()

**Issue: "Too many connections" in tests**
- Cause: Creating new PrismaClient in each test file
- Solution: Use global singleton pattern (see Example 4)

**Issue: Process hangs on shutdown**
- Cause: Forgot await on $disconnect()
- Solution: Always await prisma.$disconnect()

**Issue: Serverless cold starts very slow**
- Cause: Disconnecting in handler breaks warm starts
- Solution: Remove $disconnect() from handler (see Example 5)

**Issue: Connection pool exhausted after shutdown**
- Cause: $disconnect() called before server.close()
- Solution: Close server first, then disconnect database

---

## Related Skills

- **CLIENT-singleton-pattern**: Ensuring single PrismaClient instance
- **CLIENT-serverless-config**: Serverless-specific connection management
- **PERFORMANCE-connection-pooling**: Optimizing connection pool size

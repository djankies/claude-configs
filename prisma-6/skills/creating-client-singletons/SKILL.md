---
name: creating-client-singletons
description: Prevent multiple PrismaClient instances that exhaust connection pools causing P1017 errors. Use when creating PrismaClient, exporting database clients, setting up Prisma in new files, or encountering connection pool errors. Critical for serverless environments.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
version: 1.0.0
---

# PrismaClient Singleton Pattern

This skill teaches the global singleton pattern to prevent multiple PrismaClient instances from exhausting database connection pools.

---

<role>
This skill teaches Claude how to properly instantiate and export PrismaClient using the global singleton pattern to prevent connection pool exhaustion, P1017 errors, and serverless deployment failures.
</role>

<when-to-activate>
This skill activates when:

- Creating new PrismaClient instances
- Setting up database clients in new files
- Exporting Prisma for use across modules
- Encountering P1017 connection pool errors
- Working with serverless environments (Next.js, Lambda, Vercel)
- Reviewing code that uses @prisma/client
</when-to-activate>

<overview>
## The Problem

Creating multiple `new PrismaClient()` instances is the #1 violation in Prisma usage. Each instance creates a separate database connection pool, leading to:

- **Connection pool exhaustion**: Database refuses new connections (P1017)
- **Performance degradation**: Too many idle connections
- **Serverless failures**: Each Lambda/function instance × pool size = disaster
- **Memory waste**: Multiple client instances in memory

**Critical Impact:** 80% of AI agents in stress testing created multiple instances, causing production failures.

## The Solution

Use a **global singleton pattern** with module-level export:

1. Check if PrismaClient already exists globally
2. Create new instance only if none exists
3. Export the singleton for reuse across modules
4. Never create instances inside functions or classes

Key capabilities:

1. Module-level singleton for Node.js applications
2. Global singleton for serverless/hot-reload environments
3. Test file patterns with proper cleanup
4. Connection pool configuration
</overview>

<workflow>
## Standard Workflow

**Phase 1: Assess Current Setup**

1. Search for existing PrismaClient instantiation
   - Use Grep: `@prisma/client` imports
   - Look for `new PrismaClient()` calls
   - Check for existing client exports

2. Identify environment type
   - Development with hot reload (Next.js, Vite)
   - Production serverless (Vercel, Lambda)
   - Traditional Node.js server
   - Test environment

**Phase 2: Implement Singleton Pattern**

1. Choose appropriate pattern based on environment
   - Global singleton for hot-reload/serverless
   - Module-level for traditional servers
   - Mock pattern for tests

2. Create or update client export file
   - Typically `lib/db.ts` or `lib/prisma.ts`
   - Use global check before instantiation
   - Export singleton instance

3. Update all imports to use singleton
   - Replace direct `new PrismaClient()` calls
   - Import from singleton module
   - Remove duplicate instantiations

**Phase 3: Validation**

1. Verify single instance across codebase
   - Grep for `new PrismaClient()` occurrences
   - Should only appear once (in singleton module)
   - All other files import the singleton

2. Test in development
   - Hot reload should reuse connection
   - No P1017 errors in logs
   - Check connection count in database

3. Test in production/serverless
   - Deploy and monitor connections
   - Verify pool configuration applied
   - Check for P1017 in production logs
</workflow>

<examples>
## Example 1: Correct Module-Level Singleton

**File: `lib/db.ts`**

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export default prisma
```

**Usage in other files:**

```typescript
import prisma from '@/lib/db'

async function getUsers() {
  return await prisma.user.findMany()
}
```

**Why this works:**

- Module loads once in Node.js
- Single instance shared across all imports
- Simple and effective for traditional servers

---

## Example 2: Global Singleton (Next.js/Hot Reload)

**File: `lib/prisma.ts`**

```typescript
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

**Why this works:**

- `globalThis` survives hot module reload
- Development: reuses client across reloads
- Production: clean instance per deployment
- Prevents "too many clients" during development

---

## Example 3: Anti-Pattern - Function-Scoped Creation

**WRONG - Creates new instance per call:**

```typescript
async function getUsers() {
  const prisma = new PrismaClient()
  const users = await prisma.user.findMany()
  await prisma.$disconnect()
  return users
}
```

**Problems:**

- New connection pool every function call
- Connection overhead kills performance
- Pool never warms up
- Will exhaust connections under load

**Fix:**

```typescript
import prisma from '@/lib/db'

async function getUsers() {
  return await prisma.user.findMany()
}
```
</examples>

<progressive-disclosure>
## Reference Files

For detailed information on specific patterns:

- **Serverless Pattern**: See `references/serverless-pattern.md` for Next.js App Router, Vercel, and AWS Lambda configurations
- **Test Pattern**: See `references/test-pattern.md` for test file setup, mocking, and isolation strategies
- **Common Scenarios**: See `references/common-scenarios.md` for converting codebases, handling P1017 errors, and configuration

Load references only when working with serverless environments, writing tests, or troubleshooting specific issues.
</progressive-disclosure>

<constraints>
## Constraints and Guidelines

**MUST:**

- Create PrismaClient instance exactly once in codebase
- Export singleton from centralized module (e.g., `lib/db.ts`)
- Use global singleton pattern in hot-reload environments
- Import singleton in all files needing database access
- Never call `new PrismaClient()` inside functions or classes

**SHOULD:**

- Place client in `lib/db.ts`, `lib/prisma.ts`, or `src/db.ts`
- Configure logging in singleton creation
- Set connection pool size based on deployment
- Use TypeScript for type safety
- Document connection configuration

**NEVER:**

- Create PrismaClient in route handlers
- Create PrismaClient in API endpoints
- Create PrismaClient in service functions
- Create PrismaClient in test files (import singleton instead)
- Create PrismaClient in utility functions
- Create multiple instances "just to be safe"
- Disconnect and reconnect repeatedly
</constraints>

<validation>
## Validation

After implementing singleton pattern:

1. **Search for Multiple Instances:**

   - Run: `grep -r "new PrismaClient()" --include="*.ts" --include="*.js"`
   - Expected: Should appear exactly once (in singleton file)
   - If multiple: consolidate to single singleton

2. **Verify Import Pattern:**

   - Run: `grep -r "from '@prisma/client'" --include="*.ts" --include="*.js"`
   - Expected: Most imports should be from your singleton module
   - Only singleton file imports from '@prisma/client'

3. **Check Connection Pool:**

   - Development: Monitor database connections while hot reloading
   - Expected: Connection count stays constant (not growing)
   - If growing: Global singleton pattern not working

4. **Production Deployment:**
   - Monitor for P1017 errors in logs
   - Expected: Zero connection pool errors
   - If errors occur: Check serverless configuration (connection_limit)

5. **Test Isolation:**
   - Run test suite
   - Expected: Tests pass, no connection errors
   - If failing: Ensure tests import singleton, not creating new clients
</validation>

<output-format>
## Standard Client Export

**For TypeScript projects:**

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

**For JavaScript projects:**

```javascript
const { PrismaClient } = require('@prisma/client')

const globalForPrisma = globalThis

const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
})

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma

module.exports = prisma
```

</output-format>

---

## Quick Reference

**Checklist for new Prisma setup:**

- [ ] Create `lib/db.ts` or `lib/prisma.ts`
- [ ] Use global singleton pattern (hot reload environments)
- [ ] Export single instance
- [ ] Configure logging based on NODE_ENV
- [ ] Set connection_limit for serverless
- [ ] Import singleton in all files
- [ ] Never create PrismaClient elsewhere
- [ ] Validate with grep (one instance only)
- [ ] Test hot reload behavior
- [ ] Monitor production connections

**Red flags indicating problems:**

- Multiple `new PrismaClient()` in grep results
- P1017 errors in logs
- Growing connection count during development
- Different files importing from '@prisma/client'
- PrismaClient creation inside functions
- Test files creating their own clients

**When you see these, implement the singleton pattern immediately.**

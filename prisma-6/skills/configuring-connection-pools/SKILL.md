---
name: configuring-connection-pools
description: Configure connection pool sizing for optimal performance. Use when configuring DATABASE_URL or deploying to production.
allowed-tools: Read, Write, Edit
---

# Connection Pooling Performance

Configure Prisma Client connection pools for optimal performance and resource utilization.

## Pool Sizing Formula

**Standard environments:**
```
connection_limit = (number_of_physical_cpus × 2) + 1
```

**Calculation examples:**
- 4 CPU machine: `4 × 2 + 1 = 9 connections`
- 8 CPU machine: `8 × 2 + 1 = 17 connections`
- 16 CPU machine: `16 × 2 + 1 = 33 connections`

**Configure in DATABASE_URL:**
```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=9&pool_timeout=20"
```

**Configure in schema.prisma:**
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["metrics"]
}
```

## Serverless Environments

**Rule: Always use connection_limit=1 per function instance**

Serverless platforms scale horizontally by creating many function instances. Each instance should use a single connection to avoid exhausting database connection limits.

**AWS Lambda / Vercel / Netlify:**
```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=0&connect_timeout=10"
```

**Why connection_limit=1:**
- Functions are short-lived and stateless
- Platform creates many concurrent instances
- Total connections = instances × connection_limit
- Example: 100 Lambda instances × 1 = 100 DB connections (manageable)
- Anti-pattern: 100 instances × 10 = 1000 connections (exhausted)

**Additional serverless optimizations:**
```
pool_timeout=0          # Don't wait for connections
connect_timeout=10      # Timeout connecting to DB
pgbouncer=true          # Use PgBouncer transaction mode
```

## PgBouncer for High Concurrency

**When to use an external connection pooler:**
- More than 100 application instances
- Serverless with unpredictable scaling
- Multiple applications sharing one database
- Database connection limit exhaustion
- P1017 errors occurring frequently

**PgBouncer configuration:**
```ini
[databases]
mydb = host=postgres.internal port=5432 dbname=production

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
reserve_pool_size = 5
reserve_pool_timeout = 3
```

**Prisma with PgBouncer:**
```
DATABASE_URL="postgresql://user:pass@pgbouncer:6432/db?pgbouncer=true&connection_limit=10"
```

**Transaction mode requirements:**
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

**Avoid in transaction mode:**
- Prepared statements (disabled with `pgbouncer=true`)
- SET variables that persist across queries
- LISTEN/NOTIFY
- Advisory locks
- Temporary tables

## Bottleneck Identification

**P1017: Connection pool timeout**
```
Error: P1017
Can't reach database server at `localhost:5432`
Please make sure your database server is running at `localhost:5432`.
```

**Causes:**
- Connection limit too low
- Slow queries holding connections
- Missing connection cleanup
- Database at max_connections limit

**Diagnosis:**
```typescript
import { Prisma } from '@prisma/client'

const prisma = new Prisma.PrismaClient({
  log: [
    { emit: 'event', level: 'query' },
  ],
})

prisma.$on('query', (e) => {
  console.log('Query duration:', e.duration)
})

const metrics = await prisma.$metrics.json()
console.log('Pool metrics:', metrics)
```

**Check pool status:**
```sql
SELECT
  count(*) as connections,
  state,
  wait_event_type,
  wait_event
FROM pg_stat_activity
WHERE datname = 'your_database'
GROUP BY state, wait_event_type, wait_event;
```

**Check max connections:**
```sql
SHOW max_connections;
SELECT count(*) FROM pg_stat_activity;
```

## Pool Configuration Parameters

**connection_limit:**
- Default: `num_physical_cpus × 2 + 1`
- Serverless: `1`
- With PgBouncer: `10-20`

**pool_timeout:**
- Time to wait for available connection (seconds)
- Default: `10`
- Serverless: `0` (fail fast)
- Standard: `20-30` (wait for connections)

**connect_timeout:**
- Time to wait for initial connection (seconds)
- Default: `5`
- Recommended: `10`
- Network issues: `15-30`

**Complete configuration:**
```
postgresql://user:pass@host:5432/db?connection_limit=9&pool_timeout=20&connect_timeout=10&socket_timeout=0&statement_cache_size=100
```

## Production Deployment Checklist

**Before deploying:**
- [ ] Calculate connection_limit based on CPU count or instance count
- [ ] Configure pool_timeout appropriately for your environment
- [ ] Enable query logging to identify slow queries
- [ ] Monitor P1017 errors in application logs
- [ ] Set up database connection monitoring
- [ ] Configure PgBouncer if using serverless or high concurrency
- [ ] Test under expected load with realistic connection counts
- [ ] Document pool settings in deployment runbook

**Environment-specific settings:**

Traditional servers:
```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=17&pool_timeout=20"
```

Containers with PgBouncer:
```
DATABASE_URL="postgresql://user:pass@pgbouncer:6432/db?pgbouncer=true&connection_limit=10"
```

Serverless functions:
```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1&pool_timeout=0"
```

## Common Mistakes

**Mistake: Using default connection limit in serverless**
```typescript
const prisma = new PrismaClient()
```
Problem: Each Lambda instance uses ~10 connections, exhausting database with 50+ concurrent functions.

**Solution:**
```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=1"
```

**Mistake: Pool timeout too high in serverless**
```
?connection_limit=1&pool_timeout=30
```
Problem: Functions wait 30s for connections, hitting function timeout.

**Solution:**
```
?connection_limit=1&pool_timeout=0
```

**Mistake: Not using PgBouncer with high concurrency**
Direct connections with 200+ application instances = connection exhaustion.

**Solution:** Deploy PgBouncer with transaction pooling.

**Mistake: Setting connection_limit higher than database max_connections**
```
DATABASE_URL="?connection_limit=200"
```
Database max_connections: 100

**Solution:** Use PgBouncer or reduce connection_limit to stay under database limit.

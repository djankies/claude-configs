# Prisma 6 Research

## Overview

- **Version**: 6.x (Current stable: 6.19.0 as of November 2025)
- **Purpose in Project**: Next-generation ORM for Node.js and TypeScript with type-safe database access
- **Official Documentation**: https://www.prisma.io/docs
- **GitHub Repository**: https://github.com/prisma/prisma
- **Last Updated**: November 19, 2025

## Installation

### Basic Installation

```bash
npm install @prisma/client@6
npm install -D prisma@6
```

### Initialize New Project

```bash
npx prisma init --db
```

This command creates:

- `prisma/schema.prisma` file
- `.env` file with DATABASE_URL

## Core Concepts

### Prisma Architecture

Prisma consists of three main components:

1. **Prisma Schema**: Declarative configuration defining data sources, generators, and data models
2. **Prisma Client**: Auto-generated, type-safe database client for TypeScript/JavaScript
3. **Prisma Migrate**: Database migration system for version control of schema changes

### Schema Structure

The Prisma Schema contains three essential parts:

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  posts     Post[]
  createdAt DateTime @default(now())
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
}
```

## Configuration

### Database Connection

Configure connection string in `.env`:

```bash
DATABASE_URL="postgresql://user:password@localhost:5432/mydb?schema=public"
```

### Connection Pool Configuration

Connection pool size defaults to: `num_physical_cpus * 2 + 1`

Configure using URL parameters:

```bash
postgresql://user:pass@localhost/db?connection_limit=5&pool_timeout=2
```

**Connection Pool Settings:**

- `connection_limit`: Maximum number of connections (default: varies by driver)
- `pool_timeout`: Maximum wait time in seconds for available connection (default: 10)

**Recommended Settings by Environment:**

**Long-Running Processes:**

```
connection_limit = (num_physical_cpus * 2 + 1) / number_of_app_instances
```

**Serverless Functions:**

```
connection_limit = 1
```

For serverless environments, consider using external connection poolers like PgBouncer to prevent connection exhaustion.

### Logging Configuration

**Stdout Logging:**

```typescript
const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
});
```

**Event-Based Logging:**

```typescript
const prisma = new PrismaClient({
  log: [
    { emit: 'event', level: 'query' },
    { emit: 'stdout', level: 'error' },
    { emit: 'stdout', level: 'info' },
    { emit: 'stdout', level: 'warn' },
  ],
});

prisma.$on('query', (e) => {
  console.log('Query: ' + e.query);
  console.log('Params: ' + e.params);
  console.log('Duration: ' + e.duration + 'ms');
});
```

## Usage Patterns

### Basic CRUD Operations

**Create Single Record:**

```typescript
const user = await prisma.user.create({
  data: {
    email: 'elsa@prisma.io',
    name: 'Elsa Prisma',
  },
});
```

**Create Multiple Records:**

```typescript
const users = await prisma.user.createMany({
  data: [
    { name: 'Bob', email: 'bob@prisma.io' },
    { name: 'Yewande', email: 'yewande@prisma.io' },
  ],
  skipDuplicates: true,
});
```

**Create and Return Multiple (v5.14.0+):**

```typescript
const users = await prisma.user.createManyAndReturn({
  data: [
    { name: 'Alice', email: 'alice@prisma.io' },
    { name: 'Bob', email: 'bob@prisma.io' },
  ],
});
```

**Find Unique Record:**

```typescript
const user = await prisma.user.findUnique({
  where: { email: 'elsa@prisma.io' },
});
```

**Find Many with Filtering:**

```typescript
const users = await prisma.user.findMany({
  where: {
    email: { endsWith: 'prisma.io' },
  },
});
```

**Find First Matching:**

```typescript
const user = await prisma.user.findFirst({
  where: {
    posts: { some: { likes: { gt: 100 } } },
  },
  orderBy: { id: 'desc' },
});
```

**Update Single Record:**

```typescript
const updateUser = await prisma.user.update({
  where: { email: 'viola@prisma.io' },
  data: { name: 'Viola the Magnificent' },
});
```

**Update Multiple Records:**

```typescript
const updateUsers = await prisma.user.updateMany({
  where: { email: { contains: 'prisma.io' } },
  data: { role: 'ADMIN' },
});
```

**Upsert (Update or Create):**

```typescript
const upsertUser = await prisma.user.upsert({
  where: { email: 'viola@prisma.io' },
  update: { name: 'Viola the Magnificent' },
  create: {
    email: 'viola@prisma.io',
    name: 'Viola the Magnificent',
  },
});
```

**Atomic Number Operations:**

```typescript
const updatePosts = await prisma.post.updateMany({
  data: {
    views: { increment: 1 },
    likes: { increment: 1 },
  },
});
```

**Delete Single Record:**

```typescript
const deleteUser = await prisma.user.delete({
  where: { email: 'bert@prisma.io' },
});
```

**Delete Multiple Records:**

```typescript
const deleteUsers = await prisma.user.deleteMany({
  where: {
    email: { contains: 'prisma.io' },
  },
});
```

### Advanced Filtering and Sorting

**String Operators:**

```typescript
const users = await prisma.user.findMany({
  where: {
    email: {
      startsWith: 'alice',
      endsWith: '@prisma.io',
      contains: 'test',
    },
  },
});
```

**Case-Insensitive Filtering (PostgreSQL/MongoDB):**

```typescript
const users = await prisma.user.findMany({
  where: {
    email: {
      contains: 'prisma',
      mode: 'insensitive',
    },
  },
});
```

**Relational Filtering:**

```typescript
const users = await prisma.user.findMany({
  where: {
    posts: {
      some: { published: true },
    },
  },
});
```

**Combining Conditions with NOT and OR:**

```typescript
const users = await prisma.user.findMany({
  where: {
    OR: [{ email: { contains: 'prisma.io' } }, { name: { startsWith: 'A' } }],
    NOT: {
      role: 'ADMIN',
    },
  },
});
```

**Null Checks:**

```typescript
const posts = await prisma.post.findMany({
  where: {
    content: { not: null },
  },
});
```

**Multi-Field Sorting:**

```typescript
const users = await prisma.user.findMany({
  orderBy: [{ role: 'desc' }, { name: 'asc' }],
});
```

**Sort by Relation Count:**

```typescript
const users = await prisma.user.findMany({
  orderBy: {
    posts: { _count: 'desc' },
  },
});
```

**Null Sorting (v4.16.0+):**

```typescript
const posts = await prisma.post.findMany({
  orderBy: {
    updatedAt: { sort: 'asc', nulls: 'last' },
  },
});
```

### Pagination Patterns

**Offset Pagination:**

```typescript
const pageSize = 10;
const page = 2;

const users = await prisma.user.findMany({
  skip: (page - 1) * pageSize,
  take: pageSize,
});
```

**Cursor-Based Pagination:**

```typescript
const posts = await prisma.post.findMany({
  take: 10,
  cursor: {
    id: lastPostId,
  },
  skip: 1,
  orderBy: {
    id: 'asc',
  },
});
```

### Relations

**One-to-Many Relation:**

```prisma
model User {
  id    Int    @id @default(autoincrement())
  posts Post[]
}

model Post {
  id       Int  @id @default(autoincrement())
  author   User @relation(fields: [authorId], references: [id])
  authorId Int
}
```

**One-to-One Relation:**

```prisma
model User {
  id      Int      @id @default(autoincrement())
  profile Profile?
}

model Profile {
  id     Int  @id @default(autoincrement())
  user   User @relation(fields: [userId], references: [id])
  userId Int  @unique
}
```

**Implicit Many-to-Many Relation:**

```prisma
model Post {
  id         Int        @id @default(autoincrement())
  categories Category[]
}

model Category {
  id    Int    @id @default(autoincrement())
  posts Post[]
}
```

**Explicit Many-to-Many Relation:**

```prisma
model Post {
  id         Int                 @id @default(autoincrement())
  categories CategoriesOnPosts[]
}

model Category {
  id    Int                 @id @default(autoincrement())
  posts CategoriesOnPosts[]
}

model CategoriesOnPosts {
  post       Post     @relation(fields: [postId], references: [id])
  postId     Int
  category   Category @relation(fields: [categoryId], references: [id])
  categoryId Int
  assignedAt DateTime @default(now())

  @@id([postId, categoryId])
}
```

**Disambiguating Multiple Relations:**

```prisma
model User {
  id           Int    @id @default(autoincrement())
  writtenPosts Post[] @relation("WrittenPosts")
  pinnedPost   Post?  @relation("PinnedPost")
}

model Post {
  id           Int   @id @default(autoincrement())
  author       User  @relation("WrittenPosts", fields: [authorId], references: [id])
  authorId     Int
  pinnedBy     User? @relation("PinnedPost", fields: [pinnedById], references: [id])
  pinnedById   Int?  @unique
}
```

### Nested Writes

**Create with Related Records:**

```typescript
const user = await prisma.user.create({
  data: {
    email: 'alice@prisma.io',
    posts: {
      create: [
        { title: 'First Post', content: 'Content 1' },
        { title: 'Second Post', content: 'Content 2' },
      ],
    },
  },
});
```

**Update with Nested Updates:**

```typescript
const user = await prisma.user.update({
  where: { id: 1 },
  data: {
    posts: {
      update: {
        where: { id: 10 },
        data: { published: true },
      },
    },
  },
});
```

**Connect Existing Records:**

```typescript
const post = await prisma.post.create({
  data: {
    title: 'New Post',
    author: {
      connect: { id: 5 },
    },
  },
});
```

### Select and Include

**Select Specific Fields:**

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  select: {
    id: true,
    email: true,
    name: true,
  },
});
```

**Include Relations:**

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: true,
  },
});
```

**Nested Select/Include:**

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: {
    posts: {
      where: { published: true },
      select: {
        title: true,
        content: true,
      },
    },
  },
});
```

### Type-Safe Partial Types

**Using Prisma.validator and GetPayload:**

```typescript
import { Prisma } from '@prisma/client';

const userWithPosts = Prisma.validator<Prisma.UserDefaultArgs>()({
  include: { posts: true },
});

type UserWithPosts = Prisma.UserGetPayload<typeof userWithPosts>;

const userPersonalData = Prisma.validator<Prisma.UserDefaultArgs>()({
  select: { email: true, name: true },
});

type UserPersonalData = Prisma.UserGetPayload<typeof userPersonalData>;
```

**Direct Type Helper Usage:**

```typescript
type UserWithPosts = Prisma.UserGetPayload<{
  include: { posts: true };
}>;
```

### Transactions

**Sequential Operations:**

```typescript
const [posts, totalCount] = await prisma.$transaction([
  prisma.post.findMany({ where: { title: { contains: 'prisma' } } }),
  prisma.post.count(),
]);
```

**Interactive Transactions:**

```typescript
await prisma.$transaction(async (tx) => {
  const sender = await tx.account.update({
    data: { balance: { decrement: amount } },
    where: { email: from },
  });

  if (sender.balance < 0) {
    throw new Error('Insufficient funds');
  }

  return await tx.account.update({
    data: { balance: { increment: amount } },
    where: { email: to },
  });
});
```

**Transaction with Timeout and Isolation:**

```typescript
await prisma.$transaction(
  async (tx) => {
    // transaction operations
  },
  {
    maxWait: 5000,
    timeout: 10000,
    isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
  }
);
```

**Bulk Operations (Auto-Transactional):**

```typescript
const createMany = await prisma.user.createMany({
  data: [{ email: 'user1@example.com' }, { email: 'user2@example.com' }],
});
```

### Raw SQL Queries

**Safe Query with Tagged Template:**

```typescript
const email = 'user@prisma.io';
const users = await prisma.$queryRaw`
  SELECT * FROM User WHERE email = ${email}
`;
```

**Safe Execute (Returns Count):**

```typescript
const result = await prisma.$executeRaw`
  UPDATE User SET active = true WHERE email = ${email}
`;
console.log(`Updated ${result} records`);
```

**Unsafe Variant (Use with Caution):**

```typescript
const tableName = 'User';
const users = await prisma.$queryRawUnsafe(`SELECT * FROM ${tableName} WHERE active = true`);
```

### JSON Field Operations

**Query JSON Fields:**

```typescript
const users = await prisma.user.findMany({
  where: {
    metadata: {
      path: ['settings', 'theme'],
      equals: 'dark',
    },
  },
});
```

**String Contains in JSON:**

```typescript
const users = await prisma.user.findMany({
  where: {
    metadata: {
      path: ['name'],
      string_contains: 'john',
    },
  },
});
```

**Handling NULL in JSON:**

```typescript
import { Prisma } from '@prisma/client';

const user = await prisma.user.create({
  data: {
    email: 'user@example.com',
    metadata: {
      setting: Prisma.JsonNull,
    },
  },
});
```

### Client Extensions

**Result Extension (Computed Fields):**

```typescript
const prisma = new PrismaClient().$extends({
  result: {
    user: {
      fullName: {
        needs: { firstName: true, lastName: true },
        compute(user) {
          return `${user.firstName} ${user.lastName}`;
        },
      },
    },
  },
});

const user = await prisma.user.findFirst({
  select: {
    fullName: true,
  },
});
```

**Model Extension (Custom Methods):**

```typescript
const prisma = new PrismaClient().$extends({
  model: {
    user: {
      async findByEmail(email: string) {
        return this.findUnique({ where: { email } });
      },
    },
  },
});

const user = await prisma.user.findByEmail('test@example.com');
```

**Client Extension (Client-Level Methods):**

```typescript
const prisma = new PrismaClient().$extends({
  client: {
    async healthCheck() {
      await this.$queryRaw`SELECT 1`;
      return 'OK';
    },
  },
});

const status = await prisma.healthCheck();
```

## Prisma Migrate Workflows

### Development Environment

**Create and Apply Migration:**

```bash
npx prisma migrate dev --name add-user-role
```

This command:

1. Reruns existing migrations in shadow database
2. Detects schema drift
3. Generates new migration SQL
4. Applies migration to database
5. Regenerates Prisma Client

**Create Migration Without Applying:**

```bash
npx prisma migrate dev --create-only
```

Edit the generated SQL file, then run:

```bash
npx prisma migrate dev
```

**Reset Database:**

```bash
npx prisma migrate reset
```

This drops the database, recreates it, applies all migrations, and runs seed scripts.

**Prototype Without Migrations (db push):**

```bash
npx prisma db push
```

Use during initial prototyping when you don't need migration history.

### Production Environment

**Apply Pending Migrations:**

```bash
npx prisma migrate deploy
```

This command:

1. Compares applied migrations against history
2. Applies pending migrations only
3. Does NOT reset, detect drift, or generate artifacts

**Recommended CI/CD Integration:**

```yaml
jobs:
  deploy:
    steps:
      - name: Apply Migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### Migration Best Practices

1. Store migrations in version control (Git)
2. Use `migrate dev` in development only
3. Use `migrate deploy` in production/CI/CD
4. Never run `migrate reset` in production
5. Review generated SQL before committing
6. Use consistent database providers across environments
7. Squash migrations during feature branch development if needed

## Best Practices

### Schema Design

**Use Descriptive Model Names:**

```prisma
model UserAccount {
  id Int @id @default(autoincrement())
}
```

**Leverage Enums for Fixed Sets:**

```prisma
enum Role {
  USER
  ADMIN
  MODERATOR
}

model User {
  id   Int  @id @default(autoincrement())
  role Role @default(USER)
}
```

**Use Native Database Types for Precision:**

```prisma
model Product {
  id          Int      @id @default(autoincrement())
  name        String   @db.VarChar(255)
  description String   @db.Text
  price       Decimal  @db.Decimal(10, 2)
  createdAt   DateTime @db.Timestamptz(6)
}
```

**Add Indexes for Query Performance:**

```prisma
model Post {
  id        Int      @id @default(autoincrement())
  title     String
  published Boolean
  authorId  Int

  @@index([published, authorId])
  @@index([title])
}
```

**Use Unique Constraints:**

```prisma
model User {
  id       Int    @id @default(autoincrement())
  email    String @unique
  username String

  @@unique([username, email])
}
```

### Query Optimization

**Select Only Required Fields:**

```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
  },
});
```

**Use Cursor Pagination for Large Datasets:**

```typescript
const posts = await prisma.post.findMany({
  take: 100,
  cursor: { id: lastId },
  orderBy: { id: 'asc' },
});
```

**Batch Read Operations:**

```typescript
const userIds = [1, 2, 3, 4, 5];
const users = await prisma.user.findMany({
  where: {
    id: { in: userIds },
  },
});
```

**Avoid N+1 Queries with Include:**

```typescript
const users = await prisma.user.findMany({
  include: {
    posts: true,
  },
});
```

### Connection Management

**Reuse Prisma Client Instance:**

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export default prisma;
```

**Handle Graceful Shutdown:**

```typescript
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
```

**For Serverless (e.g., Next.js):**

```typescript
import { PrismaClient } from '@prisma/client';

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

### Error Handling

**Handle Known Errors:**

```typescript
import { Prisma } from '@prisma/client';

try {
  await prisma.user.create({
    data: { email: 'duplicate@example.com' },
  });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      console.log('Unique constraint violation');
    } else if (error.code === 'P2025') {
      console.log('Record not found');
    }
  }
  throw error;
}
```

**Common Error Codes:**

- `P2002`: Unique constraint violation
- `P2025`: Record not found
- `P2003`: Foreign key constraint violation
- `P2014`: Invalid ID
- `P1001`: Connection refused
- `P1008`: Operations timed out

**Use findUniqueOrThrow for Required Records:**

```typescript
const user = await prisma.user.findUniqueOrThrow({
  where: { id: userId },
});
```

### Type Safety

**Use Generated Types:**

```typescript
import { User, Post } from '@prisma/client';

function processUser(user: User) {
  console.log(user.email);
}
```

**Type Utilities for Complex Queries:**

```typescript
type UserWithPostCount = Prisma.UserGetPayload<{
  include: {
    _count: {
      select: { posts: true };
    };
  };
}>;
```

**Enforce Input Types:**

```typescript
async function createUser(data: Prisma.UserCreateInput) {
  return prisma.user.create({ data });
}
```

### Security

**Use Environment Variables:**

```bash
DATABASE_URL="postgresql://user:password@localhost:5432/db"
```

**Never expose connection string in code**

**Validate Input Before Queries:**

```typescript
import { z } from 'zod';

const emailSchema = z.string().email();

async function findUserByEmail(email: string) {
  const validEmail = emailSchema.parse(email);
  return prisma.user.findUnique({
    where: { email: validEmail },
  });
}
```

**Prefer $queryRaw over $queryRawUnsafe:**

```typescript
const email = userInput;
const users = await prisma.$queryRaw`
  SELECT * FROM User WHERE email = ${email}
`;
```

**Implement Row-Level Security with Extensions:**

```typescript
function createContextClient(userId: number) {
  return new PrismaClient().$extends({
    query: {
      post: {
        async findMany({ args, query }) {
          args.where = { ...args.where, authorId: userId };
          return query(args);
        },
      },
    },
  });
}
```

## Common Gotchas

### 1. Connection Pool Exhaustion in Serverless

**Problem:** Creating new PrismaClient instances on every request exhausts database connections.

**Solution:** Reuse PrismaClient instance or set `connection_limit=1`

```typescript
export const prisma = globalForPrisma.prisma ?? new PrismaClient();
```

### 2. Foreign Key Constraint Violations

**Problem:** Cannot delete records with related data.

**Solution:** Use cascading deletes or delete related records first.

```prisma
model Post {
  author   User @relation(fields: [authorId], references: [id], onDelete: Cascade)
  authorId Int
}
```

### 3. Missing Migration After Schema Changes

**Problem:** Schema changes not reflected in database.

**Solution:** Always run `npx prisma migrate dev` or `npx prisma db push` after schema changes.

### 4. Schema Drift in Production

**Problem:** Manual database changes create drift between schema and database.

**Solution:** Always use migrations for database changes. Never modify production database manually.

### 5. N+1 Query Problem

**Problem:** Fetching relations in loops creates many queries.

**Solution:** Use `include` to fetch relations eagerly.

```typescript
const users = await prisma.user.findMany({
  include: { posts: true },
});
```

### 6. Case-Sensitive Filtering

**Problem:** String filters are case-sensitive by default.

**Solution:** Use `mode: 'insensitive'` (PostgreSQL/MongoDB only).

```typescript
where: {
  email: {
    contains: 'test',
    mode: 'insensitive',
  },
}
```

### 7. Cannot Use Select and Include Together

**Problem:** Attempting to use both `select` and `include` in same query fails.

**Solution:** Use only one. Prefer `select` with nested includes.

```typescript
select: {
  id: true,
  email: true,
  posts: {
    select: {
      title: true,
    },
  },
}
```

### 8. Implicit Many-to-Many Primary Key Change in v6

**Problem:** Upgrading to Prisma 6 changes unique indexes to primary keys for PostgreSQL implicit m-n relations.

**Solution:** Run dedicated migration immediately after upgrade:

```bash
npx prisma migrate dev --name upgrade-to-v6
```

### 9. Buffer vs Uint8Array for Bytes

**Problem:** Prisma 6 replaced Node.js `Buffer` with standard `Uint8Array`.

**Solution:** Update code handling binary data to use `Uint8Array`.

### 10. Using Different Databases in Dev/Prod

**Problem:** SQLite in development, PostgreSQL in production causes feature mismatches.

**Solution:** Use same database provider across all environments, or use Docker for local PostgreSQL.

### 11. NotFoundError Removed in v6

**Problem:** `NotFoundError` no longer exists.

**Solution:** Catch `PrismaClientKnownRequestError` with code `P2025`.

```typescript
try {
  await prisma.user.findUniqueOrThrow({ where: { id: 1 } });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') {
    console.log('User not found');
  }
}
```

### 12. Reserved Keywords as Model Names

**Problem:** Using `async`, `await`, or `using` as model names fails in v6.

**Solution:** Rename models to avoid reserved keywords.

### 13. Special Characters in LIKE Operators

**Problem:** Underscore `_` and percent `%` have special meaning in `startsWith`, `contains`, `endsWith`.

**Solution:** Escape special characters: `startsWith: '\\_test'`

### 14. Cursor Pagination Requires Unique Field

**Problem:** Cursor pagination without unique field produces inconsistent results.

**Solution:** Always use unique, sequential field (e.g., `id`) as cursor and in `orderBy`.

### 15. Transaction Isolation Level Differences

**Problem:** Default isolation levels vary by database (PostgreSQL: `ReadCommitted`, MySQL: `RepeatableRead`).

**Solution:** Explicitly set `isolationLevel` for critical transactions.

## Anti-Patterns

### 1. Creating PrismaClient in Every Function

**Anti-Pattern:**

```typescript
async function getUser(id: number) {
  const prisma = new PrismaClient();
  return prisma.user.findUnique({ where: { id } });
}
```

**Correct:**

```typescript
const prisma = new PrismaClient();

async function getUser(id: number) {
  return prisma.user.findUnique({ where: { id } });
}
```

### 2. Not Handling Unique Constraint Violations

**Anti-Pattern:**

```typescript
await prisma.user.create({
  data: { email: userInput.email },
});
```

**Correct:**

```typescript
try {
  await prisma.user.create({
    data: { email: userInput.email },
  });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
    throw new Error('Email already exists');
  }
  throw error;
}
```

### 3. Using $queryRawUnsafe with User Input

**Anti-Pattern:**

```typescript
const users = await prisma.$queryRawUnsafe(`SELECT * FROM User WHERE name = '${userName}'`);
```

**Correct:**

```typescript
const users = await prisma.$queryRaw`
  SELECT * FROM User WHERE name = ${userName}
`;
```

### 4. Fetching All Fields When Only Few Needed

**Anti-Pattern:**

```typescript
const users = await prisma.user.findMany();
return users.map((u) => u.email);
```

**Correct:**

```typescript
const users = await prisma.user.findMany({
  select: { email: true },
});
```

### 5. Manual Transaction Management Instead of Nested Writes

**Anti-Pattern:**

```typescript
const user = await prisma.user.create({
  data: { email: 'test@example.com' },
});

await prisma.post.create({
  data: {
    title: 'Post',
    authorId: user.id,
  },
});
```

**Correct:**

```typescript
const user = await prisma.user.create({
  data: {
    email: 'test@example.com',
    posts: {
      create: { title: 'Post' },
    },
  },
});
```

### 6. Not Using Migrations in Production

**Anti-Pattern:**

```bash
npx prisma db push
```

**Correct:**

```bash
npx prisma migrate deploy
```

### 7. Performing Multiple Queries Instead of Batch Operations

**Anti-Pattern:**

```typescript
for (const email of emails) {
  await prisma.user.create({
    data: { email },
  });
}
```

**Correct:**

```typescript
await prisma.user.createMany({
  data: emails.map((email) => ({ email })),
});
```

### 8. Not Setting Connection Limits for Serverless

**Anti-Pattern:**

```
DATABASE_URL="postgresql://user:pass@host/db"
```

**Correct:**

```
DATABASE_URL="postgresql://user:pass@host/db?connection_limit=1"
```

### 9. Using Offset Pagination for Large Datasets

**Anti-Pattern:**

```typescript
const posts = await prisma.post.findMany({
  skip: 10000,
  take: 20,
});
```

**Correct:**

```typescript
const posts = await prisma.post.findMany({
  take: 20,
  cursor: { id: lastPostId },
  skip: 1,
  orderBy: { id: 'asc' },
});
```

### 10. Ignoring Type Safety

**Anti-Pattern:**

```typescript
const user: any = await prisma.user.findUnique({ where: { id: 1 } });
```

**Correct:**

```typescript
const user = await prisma.user.findUnique({ where: { id: 1 } });
```

## Error Handling

### Error Types

Prisma Client throws different error types based on the error:

- `PrismaClientKnownRequestError`: Errors with specific error codes
- `PrismaClientUnknownRequestError`: Unknown database errors
- `PrismaClientRustPanicError`: Rust panic errors
- `PrismaClientInitializationError`: Failed to initialize client
- `PrismaClientValidationError`: Invalid query arguments

### Common Error Codes

| Code  | Description                      | Common Cause                       |
| ----- | -------------------------------- | ---------------------------------- |
| P2002 | Unique constraint violation      | Duplicate key                      |
| P2025 | Record not found                 | findUniqueOrThrow/findFirstOrThrow |
| P2003 | Foreign key constraint violation | Invalid relation reference         |
| P2014 | Invalid ID                       | Wrong ID format                    |
| P1001 | Connection refused               | Database unreachable               |
| P1008 | Operations timed out             | Query too slow                     |
| P1017 | Server closed connection         | Connection pool exhausted          |

### Centralized Error Handler

```typescript
import { Prisma } from '@prisma/client';

export function handlePrismaError(error: unknown): never {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    switch (error.code) {
      case 'P2002':
        throw new Error('Duplicate entry');
      case 'P2025':
        throw new Error('Record not found');
      case 'P2003':
        throw new Error('Invalid reference');
      default:
        throw new Error(`Database error: ${error.code}`);
    }
  }

  if (error instanceof Prisma.PrismaClientValidationError) {
    throw new Error('Invalid query parameters');
  }

  throw error;
}
```

**Usage:**

```typescript
try {
  await prisma.user.create({ data: { email: 'test@example.com' } });
} catch (error) {
  handlePrismaError(error);
}
```

## Security Considerations

### 1. SQL Injection Prevention

**Always use tagged templates with $queryRaw:**

```typescript
const safe = await prisma.$queryRaw`SELECT * FROM User WHERE email = ${email}`;
```

**Avoid $queryRawUnsafe with user input:**

```typescript
const unsafe = await prisma.$queryRawUnsafe(`SELECT * FROM ${table}`);
```

### 2. Connection String Security

**Never commit connection strings:**

```bash
DATABASE_URL="postgresql://user:password@host/db"
```

**Use environment variables:**

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

### 3. Input Validation

**Validate before database operations:**

```typescript
import { z } from 'zod';

const userSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2).max(100),
});

async function createUser(input: unknown) {
  const data = userSchema.parse(input);
  return prisma.user.create({ data });
}
```

### 4. Row-Level Security

**Implement with Client Extensions:**

```typescript
function createUserContext(userId: number) {
  return new PrismaClient().$extends({
    query: {
      $allModels: {
        async findMany({ args, query, model }) {
          if (model === 'Post') {
            args.where = { ...args.where, authorId: userId };
          }
          return query(args);
        },
      },
    },
  });
}
```

### 5. Sensitive Data Handling

**Exclude sensitive fields in select:**

```typescript
const user = await prisma.user.findUnique({
  where: { id: 1 },
  select: {
    id: true,
    email: true,
  },
});
```

**Use computed fields for derived data:**

```typescript
const prisma = new PrismaClient().$extends({
  result: {
    user: {
      emailDomain: {
        needs: { email: true },
        compute(user) {
          return user.email.split('@')[1];
        },
      },
    },
  },
});
```

## Performance Tips

### 1. Use Connection Pooling

Configure appropriate pool size based on environment:

```
postgresql://user:pass@host/db?connection_limit=10&pool_timeout=5
```

### 2. Enable Query Logging in Development

```typescript
const prisma = new PrismaClient({
  log: ['query'],
});
```

Analyze slow queries and add indexes.

### 3. Use Indexes Strategically

```prisma
model Post {
  id        Int      @id
  title     String
  published Boolean
  authorId  Int

  @@index([published, authorId])
}
```

### 4. Batch Operations

```typescript
await prisma.user.createMany({
  data: users,
  skipDuplicates: true,
});
```

### 5. Select Only Required Fields

```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
  },
});
```

### 6. Use Cursor Pagination for Large Datasets

```typescript
const posts = await prisma.post.findMany({
  take: 100,
  cursor: { id: lastId },
  orderBy: { id: 'asc' },
});
```

### 7. Leverage Caching

```typescript
import { Redis } from 'ioredis';

const redis = new Redis();

async function getCachedUser(id: number) {
  const cached = await redis.get(`user:${id}`);
  if (cached) return JSON.parse(cached);

  const user = await prisma.user.findUnique({ where: { id } });
  await redis.setex(`user:${id}`, 3600, JSON.stringify(user));
  return user;
}
```

### 8. Use Read Replicas for Heavy Read Workloads

```typescript
const readPrisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_READ_URL,
    },
  },
});

const writePrisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_WRITE_URL,
    },
  },
});
```

### 9. Monitor Query Performance

```typescript
prisma.$on('query', (e) => {
  if (e.duration > 1000) {
    console.warn(`Slow query (${e.duration}ms): ${e.query}`);
  }
});
```

### 10. Use Prisma Accelerate for Global Distribution

Prisma Accelerate provides:

- Global database caching
- Connection pooling
- Query acceleration

## Version-Specific Notes

### Prisma 6.0.0 Breaking Changes

**Node.js Version Requirements:**

- Minimum Node.js 18.18.0 or higher
- Node.js 20.9.0 or higher supported
- Node.js 22.11.0 or higher supported
- No support for versions 16, 17, 19, or 21

**TypeScript Requirement:**

- Minimum TypeScript 5.1.0

**PostgreSQL Implicit Many-to-Many:**

- Unique indexes changed to primary keys
- Run migration immediately after upgrade: `npx prisma migrate dev --name upgrade-to-v6`

**Bytes Type Change:**

- `Buffer` replaced with `Uint8Array`
- Update code handling binary data

**Error Handling:**

- `NotFoundError` removed
- Use `PrismaClientKnownRequestError` with code `P2025`

**Full-Text Search (PostgreSQL):**

- Change preview feature from `fullTextSearch` to `fullTextSearchPostgres`

**Reserved Keywords:**

- Model names cannot use `async`, `await`, or `using`

### Features Promoted to General Availability in v6

**Full-Text Search (MySQL):**

```prisma
model Post {
  id      Int    @id
  title   String
  content String

  @@fulltext([title, content])
}
```

**Full-Text Indexing:**

```typescript
const posts = await prisma.post.findMany({
  where: {
    title: { search: 'prisma' },
  },
});
```

### Prisma 6.6.0+ Features

**ESM Support:**
New `prisma-client` generator for ESM-first applications

**Cloudflare D1 and Turso Support:**
Early Access support for migrations

**MCP Server:**
Manage databases directly in AI tools

### Prisma 6.16.0+ Features

**Migration to Pure JavaScript:**
Prisma ORM can now run without Rust engine in production

**Flexible Generator:**
New ESM-first `prisma-client` generator is production-ready

## Code Examples

### Complete CRUD Application

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const user = await prisma.user.create({
    data: {
      email: 'alice@prisma.io',
      name: 'Alice',
      posts: {
        create: [
          { title: 'Hello World', published: true },
          { title: 'Draft Post', published: false },
        ],
      },
    },
  });
  console.log('Created user:', user);

  const allUsers = await prisma.user.findMany({
    include: {
      posts: true,
    },
  });
  console.log('All users:', allUsers);

  const updatedUser = await prisma.user.update({
    where: { email: 'alice@prisma.io' },
    data: { name: 'Alice Updated' },
  });
  console.log('Updated user:', updatedUser);

  const deletedUser = await prisma.user.delete({
    where: { email: 'alice@prisma.io' },
  });
  console.log('Deleted user:', deletedUser);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

### Advanced Filtering Example

```typescript
const results = await prisma.post.findMany({
  where: {
    OR: [
      {
        title: { contains: 'prisma', mode: 'insensitive' },
      },
      {
        content: { contains: 'database' },
      },
    ],
    AND: {
      published: true,
      author: {
        email: { endsWith: '@prisma.io' },
      },
    },
    NOT: {
      viewCount: { lt: 10 },
    },
  },
  orderBy: [{ published: 'desc' }, { createdAt: 'desc' }],
  take: 20,
  skip: 0,
});
```

### Transaction with Rollback Example

```typescript
try {
  await prisma.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: { email: 'test@example.com', name: 'Test' },
    });

    const post = await tx.post.create({
      data: {
        title: 'Test Post',
        authorId: user.id,
      },
    });

    if (!post.title.includes('required')) {
      throw new Error('Title validation failed');
    }

    return { user, post };
  });
} catch (error) {
  console.log('Transaction rolled back:', error);
}
```

### Middleware for Logging Example

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

prisma.$use(async (params, next) => {
  const before = Date.now();
  const result = await next(params);
  const after = Date.now();

  console.log(`Query ${params.model}.${params.action} took ${after - before}ms`);

  return result;
});
```

### Type-Safe API Example

```typescript
import { Prisma } from '@prisma/client';

const userWithPosts = Prisma.validator<Prisma.UserDefaultArgs>()({
  include: { posts: true },
});

type UserWithPosts = Prisma.UserGetPayload<typeof userWithPosts>;

async function processUserWithPosts(user: UserWithPosts) {
  console.log(`User ${user.name} has ${user.posts.length} posts`);
}

const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: { posts: true },
});

if (user) {
  processUserWithPosts(user);
}
```

## References

### Official Documentation

- Main Documentation: https://www.prisma.io/docs
- Prisma Schema Reference: https://www.prisma.io/docs/orm/reference/prisma-schema-reference
- Prisma Client API Reference: https://www.prisma.io/docs/orm/reference/prisma-client-reference
- Upgrade Guide to v6: https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-6

### Key Resources

- GitHub Repository: https://github.com/prisma/prisma
- Release Notes: https://github.com/prisma/prisma/releases
- Changelog: https://www.prisma.io/changelog
- Data Guide: https://www.prisma.io/dataguide
- Community Discord: https://pris.ly/discord

### Advanced Topics

- Connection Pooling: https://www.prisma.io/docs/orm/prisma-client/setup-and-configuration/databases-connections/connection-pool
- Client Extensions: https://www.prisma.io/docs/orm/prisma-client/client-extensions
- Transactions: https://www.prisma.io/docs/orm/prisma-client/queries/transactions
- Raw SQL: https://www.prisma.io/docs/orm/prisma-client/using-raw-sql/raw-queries
- Type Safety: https://www.prisma.io/docs/orm/prisma-client/type-safety
- Migrations: https://www.prisma.io/docs/orm/prisma-migrate/workflows/development-and-production

### Blog Posts

- Announcing Prisma 6.19.0: https://www.prisma.io/blog/announcing-prisma-6-19-0
- ESM Support, D1 Migrations: https://www.prisma.io/blog/prisma-orm-6-6-0-esm-support-d1-migrations-and-prisma-mcp-server

### Community Resources

- Stack Overflow: https://stackoverflow.com/questions/tagged/prisma
- GitHub Discussions: https://github.com/prisma/prisma/discussions
- Client Extensions Examples: https://github.com/prisma/prisma-client-extensions

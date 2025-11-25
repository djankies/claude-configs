# Drizzle ORM Research

## Overview

- **Version**: 0.44.7 (latest as of November 2025)
- **Drizzle Kit Version**: 0.31.7 (latest companion CLI tool)
- **Purpose in Project**: TypeScript ORM with SQL-like syntax and excellent type safety
- **Official Documentation**: https://orm.drizzle.team/
- **GitHub Repository**: https://github.com/drizzle-team/drizzle-orm
- **Last Updated**: November 19, 2025

## What is Drizzle ORM?

Drizzle is a **headless ORM library** (not a data framework) designed to integrate into projects without imposing architectural constraints. The philosophy is expressed as: _"a good friend who's there for you when necessary and doesn't bother when you need some space."_

### Key Differentiators

**1. SQL-First Approach**

- Embraces SQL rather than abstracting from it
- Query syntax mirrors SQL fundamentals
- Minimal learning curve for developers familiar with SQL

**2. Zero Dependencies**

- Only 7.4kb minified+gzipped
- Tree-shakeable
- Serverless-ready by design

**3. Dual Query APIs**

- SQL-like query builder for direct SQL control
- Relational query API for complex data fetching
- Guarantee: **Drizzle always outputs exactly 1 SQL query** (eliminates N+1 problems)

**4. Broad Database Support**

- PostgreSQL (Native, Neon, Vercel Postgres, Supabase, Xata, PGLite, Nile)
- MySQL (MySQL, PlanetScale, TiDB, SingleStore)
- SQLite (Turso, SQLite Cloud, Cloudflare D1, Bun SQLite, Expo, OP SQLite)

**5. Runtime Compatibility**

- NodeJS, Bun, Deno
- Cloudflare Workers, Supabase functions
- Any Edge runtime
- Browsers

## Installation

### Basic Installation

**PostgreSQL with node-postgres:**

```bash
npm i drizzle-orm pg
npm i -D drizzle-kit @types/pg
```

**PostgreSQL with postgres.js:**

```bash
npm i drizzle-orm postgres
npm i -D drizzle-kit
```

**MySQL with mysql2:**

```bash
npm i drizzle-orm mysql2
npm i -D drizzle-kit
```

**SQLite:**

```bash
npm i drizzle-orm better-sqlite3
npm i -D drizzle-kit @types/better-sqlite3
```

### Version Requirements

- **Drizzle ORM**: v0.36.0+ (for drizzle-zod integration)
- **Zod**: v3.25.1+ (if using validation)

## Core Concepts

### 1. Schema-First Design

TypeScript-defined schemas serve as the single source of truth. Drizzle generates migrations automatically from schema changes.

### 2. Type Safety

Complete end-to-end TypeScript type inference from schema to queries to results.

### 3. Thin Layer Over SQL

Drizzle is designed to be a minimal abstraction with near-zero overhead. Prepared statements can make it faster than native drivers.

### 4. Dialect-Specific Design

Native support for each database through industry-standard drivers ensures compatibility without abstraction penalties.

## Configuration

### Basic Configuration File

Create `drizzle.config.ts` in your project root:

```typescript
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/schema.ts',
  out: './drizzle',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
```

### Configuration Options

| Option          | Type                                                              | Description                                         |
| --------------- | ----------------------------------------------------------------- | --------------------------------------------------- |
| `dialect`       | `"postgresql" \| "mysql" \| "sqlite" \| "turso" \| "singlestore"` | Database type (required)                            |
| `schema`        | `string \| string[]`                                              | Path or glob pattern to schema files (required)     |
| `out`           | `string`                                                          | Migration output directory (default: `"./drizzle"`) |
| `dbCredentials` | `object`                                                          | Database connection credentials                     |
| `migrations`    | `object`                                                          | Migration naming and filtering options              |
| `introspect`    | `object`                                                          | Schema introspection settings                       |

### Multiple Environment Setup

Create separate config files for different environments:

```bash
npx drizzle-kit push --config=drizzle-prod.config.ts
npx drizzle-kit generate --config=drizzle-dev.config.ts
```

### Schema File Organization

Drizzle supports flexible schema layouts:

**Single file:**

```typescript
export default defineConfig({
  schema: './src/schema.ts',
});
```

**Multiple files (glob pattern):**

```typescript
export default defineConfig({
  schema: './src/**/schema.ts',
});
```

**Directory:**

```typescript
export default defineConfig({
  schema: './src/schema',
});
```

## Database Connection

### Connection URL Format

```
postgresql://username:password@hostname:port/database
             └──────┘   └───────┘ └────────┘   └────┘
```

### PostgreSQL Connection

**Basic connection:**

```typescript
import { drizzle } from 'drizzle-orm/node-postgres';

const db = drizzle(process.env.DATABASE_URL);
```

**With explicit pool:**

```typescript
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

const db = drizzle({ client: pool });
```

**Serverless (Neon HTTP):**

```typescript
import { drizzle } from 'drizzle-orm/neon-http';

const db = drizzle(process.env.DATABASE_URL);
```

**Serverless (Vercel Postgres):**

```typescript
import { drizzle } from 'drizzle-orm/vercel-postgres';
import { sql } from '@vercel/postgres';

const db = drizzle({ client: sql });
```

### MySQL Connection

```typescript
import { drizzle } from 'drizzle-orm/mysql2';

const db = drizzle(process.env.DATABASE_URL);
```

### SQLite Connection

**File-based:**

```typescript
import { drizzle } from 'drizzle-orm/bun-sqlite';

const db = drizzle('./sqlite.db');
```

**In-memory:**

```typescript
const db = drizzle();
```

### Connection Pooling Best Practices

**PostgreSQL pool configuration:**

```typescript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

**Supabase with connection pooling:**
When using Supabase with "Transaction" pool mode, disable prepared statements:

```typescript
const db = drizzle({
  client: pool,
  prepare: false,
});
```

### Environment Variables

Store connection strings in `.env`:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
```

### Accessing the Native Client

```typescript
const pool = db.$client;
```

### Camel/Snake Case Mapping

Automatic case conversion during initialization:

```typescript
const db = drizzle({
  connection: process.env.DATABASE_URL,
  casing: 'snake_case',
});
```

This automatically converts `camelCase` TypeScript properties to `snake_case` in SQL.

## Schema Definition

### Table Declaration

Tables require dialect-specific imports:

**PostgreSQL:**

```typescript
import { pgTable, integer, varchar } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: integer().primaryKey(),
  firstName: varchar('first_name', { length: 256 }),
});
```

**MySQL:**

```typescript
import { mysqlTable, int, varchar } from 'drizzle-orm/mysql-core';

export const users = mysqlTable('users', {
  id: int().primaryKey(),
  firstName: varchar('first_name', { length: 256 }),
});
```

**SQLite:**

```typescript
import { sqliteTable, integer, text } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: integer().primaryKey(),
  firstName: text('first_name'),
});
```

### Column Types (PostgreSQL)

**Numeric Types:**

```typescript
import {
  integer,
  smallint,
  bigint,
  serial,
  numeric,
  real,
  doublePrecision,
} from 'drizzle-orm/pg-core';

export const products = pgTable('products', {
  id: serial().primaryKey(),
  quantity: integer(),
  smallAmount: smallint(),
  largeAmount: bigint({ mode: 'number' }),
  price: numeric({ precision: 10, scale: 2 }),
  weight: real(),
  volume: doublePrecision(),
});
```

**Text Types:**

```typescript
import { text, varchar, char } from 'drizzle-orm/pg-core';

export const posts = pgTable('posts', {
  content: text(),
  title: varchar({ length: 256 }),
  code: char({ length: 10 }),
});
```

**Boolean:**

```typescript
import { boolean } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  isActive: boolean().default(true),
});
```

**Date/Time Types:**

```typescript
import { timestamp, date, time, interval } from 'drizzle-orm/pg-core';

export const events = pgTable('events', {
  createdAt: timestamp({ mode: 'date', precision: 3, withTimezone: true }).defaultNow(),
  eventDate: date({ mode: 'date' }),
  eventTime: time({ precision: 6, withTimezone: false }),
  duration: interval({ fields: 'day to second', precision: 3 }),
});
```

**JSON Types:**

```typescript
import { json, jsonb } from 'drizzle-orm/pg-core';

interface Settings {
  theme: string;
  notifications: boolean;
}

export const users = pgTable('users', {
  settings: json().$type<Settings>(),
  preferences: jsonb().$type<Settings>(),
});
```

**Geometric Types:**

```typescript
import { point, line } from 'drizzle-orm/pg-core';

export const locations = pgTable('locations', {
  coordinates: point({ mode: 'xy' }),
  boundary: line({ mode: 'abc' }),
});
```

**Enum Type:**

```typescript
import { pgEnum } from 'drizzle-orm/pg-core';

export const statusEnum = pgEnum('status', ['pending', 'active', 'inactive']);

export const users = pgTable('users', {
  status: statusEnum().default('pending'),
});
```

### Column Modifiers

**Default Values:**

```typescript
id: serial().default(42),
name: varchar().default('Anonymous'),
createdAt: timestamp().defaultNow(),
uuid: uuid().defaultRandom(),
customId: varchar().$defaultFn(() => generateUniqueString(16)),
```

**Constraints:**

```typescript
id: serial().primaryKey(),
email: varchar().notNull().unique(),
age: integer().check(sql`${age} > 18`),
```

**Runtime Defaults:**

```typescript
updatedAt: timestamp().$defaultFn(() => new Date()),
```

**On Update:**

```typescript
updatedAt: timestamp().$onUpdateFn(() => new Date()),
```

**Type Customization:**

```typescript
data: jsonb().$type<CustomType>(),
```

### Identity Columns (PostgreSQL - Recommended)

PostgreSQL now recommends identity columns over serial types:

```typescript
import { integer } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: integer().generatedAlwaysAsIdentity({
    startWith: 1,
    increment: 1,
    minValue: 1,
    maxValue: 1000000,
    cache: 10,
  }),
});
```

### Indexes and Constraints

**Table-level indexes:**

```typescript
export const posts = pgTable(
  'posts',
  {
    id: serial().primaryKey(),
    slug: varchar(),
    title: varchar(),
    ownerId: integer().references(() => users.id),
  },
  (table) => [
    uniqueIndex('slug_idx').on(table.slug),
    index('title_idx').on(table.title),
    index('owner_title_idx').on(table.ownerId, table.title),
  ]
);
```

**Advanced index options (v0.31.0+):**

```typescript
(table) => [
  index('name_idx').on(table.name.asc()).nullsFirst().concurrently().with({ fillfactor: '70' }),
];
```

**Unique constraints:**

```typescript
email: varchar().unique(),
  (table) => [
    unique().on(table.email, table.username),
    unique('custom_name').on(table.id, table.name),
  ];
```

**Check constraints:**

```typescript
(table) => [check('age_check', sql`${table.age} > 21`)];
```

**Primary keys:**

```typescript
id: serial().primaryKey(),
  (table) => ({
    pk: primaryKey({ columns: [table.userId, table.groupId] }),
  });
```

**Foreign keys:**

```typescript
authorId: integer().references(() => users.id),

authorId: integer().references(() => users.id, {
  onDelete: 'cascade',
  onUpdate: 'cascade',
}),

(table) => ({
  fk: foreignKey({
    columns: [table.authorId],
    foreignColumns: [users.id],
  }).onDelete('cascade'),
})
```

### Reusable Column Patterns

```typescript
const timestamps = {
  updatedAt: timestamp().$onUpdateFn(() => new Date()),
  createdAt: timestamp().defaultNow().notNull(),
  deletedAt: timestamp(),
};

export const users = pgTable('users', {
  id: serial().primaryKey(),
  name: varchar(),
  ...timestamps,
});

export const posts = pgTable('posts', {
  id: serial().primaryKey(),
  title: varchar(),
  ...timestamps,
});
```

### PostgreSQL Schemas

```typescript
import { pgSchema } from 'drizzle-orm/pg-core';

export const customSchema = pgSchema('custom');

export const users = customSchema.table('users', {
  id: serial().primaryKey(),
  name: varchar(),
});
```

## Relations

Relations operate at the **application level** (not database level) and are completely optional.

### Defining Relations

```typescript
import { relations } from 'drizzle-orm';

export const usersRelations = relations(users, ({ one, many }) => ({
  posts: many(posts),
  profile: one(profile),
}));
```

### One-to-One Relations

**Pattern 1: Foreign key in related table**

```typescript
export const usersRelations = relations(users, ({ one }) => ({
  profileInfo: one(profileInfo),
}));

export const profileInfoRelations = relations(profileInfo, ({ one }) => ({
  user: one(users, {
    fields: [profileInfo.userId],
    references: [users.id],
  }),
}));
```

**Pattern 2: Foreign key in parent table**

```typescript
export const usersRelations = relations(users, ({ one }) => ({
  invitee: one(users, {
    fields: [users.invitedBy],
    references: [users.id],
  }),
}));
```

### One-to-Many Relations

```typescript
export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}));

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id],
  }),
}));
```

### Many-to-Many Relations

Requires a junction table:

```typescript
export const usersToGroups = pgTable('users_to_groups', {
  userId: integer().references(() => users.id),
  groupId: integer().references(() => groups.id),
});

export const usersRelations = relations(users, ({ many }) => ({
  usersToGroups: many(usersToGroups),
}));

export const usersToGroupsRelations = relations(usersToGroups, ({ one }) => ({
  group: one(groups, {
    fields: [usersToGroups.groupId],
    references: [groups.id],
  }),
  user: one(users, {
    fields: [usersToGroups.userId],
    references: [users.id],
  }),
}));

export const groupsRelations = relations(groups, ({ many }) => ({
  usersToGroups: many(usersToGroups),
}));
```

### Disambiguating Relations

When multiple relations exist between the same tables:

```typescript
export const usersRelations = relations(users, ({ many }) => ({
  authoredPosts: many(posts, { relationName: 'author' }),
  reviewedPosts: many(posts, { relationName: 'reviewer' }),
}));

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id],
    relationName: 'author',
  }),
  reviewer: one(users, {
    fields: [posts.reviewerId],
    references: [users.id],
    relationName: 'reviewer',
  }),
}));
```

### Foreign Key Actions

```typescript
export const posts = pgTable('posts', {
  id: serial().primaryKey(),
  authorId: integer()
    .references(() => users.id, {
      onDelete: 'cascade',
      onUpdate: 'cascade',
    })
    .notNull(),
});
```

Available actions:

- `'cascade'` - Automatically remove/update dependent rows
- `'no action'` - Prevent deletion/update of referenced rows (default)
- `'restrict'` - Similar to no action
- `'set null'` - Set foreign key to NULL
- `'set default'` - Set to default column value

### Relations vs Foreign Keys

**Relations:**

- Application-level abstractions
- Don't affect database schema
- Don't enforce constraints
- Used for querying related data

**Foreign Keys:**

- Database-level constraints
- Validated during insert/update/delete
- Prevent constraint violations
- Maintain referential integrity

They work independently - you can use either or both together.

## Query Patterns

### Basic SELECT

```typescript
const result = await db.select().from(users);
```

### Partial Selection

```typescript
const result = await db
  .select({
    id: users.id,
    name: users.name,
  })
  .from(users);
```

### Filtering

```typescript
import { eq, lt, gte, ne, and, or } from 'drizzle-orm';

await db.select().from(users).where(eq(users.id, 42));
await db.select().from(users).where(lt(users.age, 30));
await db
  .select()
  .from(users)
  .where(and(eq(users.isActive, true), gte(users.age, 18)));
```

### Distinct

```typescript
await db.selectDistinct().from(users).orderBy(users.id);
```

### Pagination

```typescript
await db.select().from(users).limit(10).offset(20);
```

### Ordering

```typescript
import { asc, desc } from 'drizzle-orm';

await db.select().from(users).orderBy(asc(users.name), desc(users.createdAt));
```

### Aggregations

```typescript
import { count, sum, avg, max, min, sql } from 'drizzle-orm';

await db
  .select({
    count: count(),
  })
  .from(users);

await db
  .select({
    avgAge: avg(users.age),
  })
  .from(users);

await db
  .select({
    age: users.age,
    count: count(),
  })
  .from(users)
  .groupBy(users.age);
```

### Count Utility

```typescript
const total = await db.$count(users);
const active = await db.$count(users, eq(users.isActive, true));
```

### Joins

```typescript
import { eq } from 'drizzle-orm';

await db.select().from(posts).leftJoin(users, eq(posts.authorId, users.id));

await db
  .select({
    post: posts,
    author: users,
  })
  .from(posts)
  .innerJoin(users, eq(posts.authorId, users.id));
```

### Subqueries

```typescript
const sq = db.select().from(users).where(eq(users.id, 42)).as('sq');

const result = await db.select().from(sq);
```

### WITH Clause (CTE)

```typescript
const sq = db.$with('sq').as(db.select().from(users).where(eq(users.id, 42)));

const result = await db.with(sq).select().from(sq);
```

### Basic INSERT

```typescript
await db.insert(users).values({
  name: 'John',
  email: 'john@example.com',
});
```

### Batch INSERT

```typescript
await db.insert(users).values([
  { name: 'John', email: 'john@example.com' },
  { name: 'Jane', email: 'jane@example.com' },
]);
```

### INSERT with Returning (PostgreSQL/SQLite)

```typescript
const result = await db.insert(users).values({ name: 'John' }).returning();

const ids = await db.insert(users).values({ name: 'John' }).returning({ id: users.id });
```

### INSERT with Returning ID (MySQL)

```typescript
const result = await db
  .insert(users)
  .values([{ name: 'John' }, { name: 'Jane' }])
  .$returningId();
```

### On Conflict (PostgreSQL/SQLite)

**Do Nothing:**

```typescript
await db.insert(users).values({ id: 1, name: 'John' }).onConflictDoNothing({ target: users.id });
```

**Do Update:**

```typescript
await db
  .insert(users)
  .values({ id: 1, name: 'John' })
  .onConflictDoUpdate({
    target: users.id,
    set: { name: 'John Updated' },
  });
```

### On Duplicate Key Update (MySQL)

```typescript
await db
  .insert(users)
  .values({ id: 1, name: 'John' })
  .onDuplicateKeyUpdate({
    set: { name: 'John Updated' },
  });
```

### INSERT from SELECT

```typescript
await db.insert(employees).select(
  db
    .select({
      name: users.name,
      role: sql`'employee'`,
    })
    .from(users)
    .where(eq(users.department, 'engineering'))
);
```

### Basic UPDATE

```typescript
await db.update(users).set({ name: 'Mr. Dan' }).where(eq(users.name, 'Dan'));
```

### UPDATE with SQL Expressions

```typescript
await db
  .update(users)
  .set({
    updatedAt: sql`NOW()`,
    loginCount: sql`${users.loginCount} + 1`,
  })
  .where(eq(users.id, 42));
```

### UPDATE with Limit

```typescript
await db.update(users).set({ verified: true }).limit(10);
```

### UPDATE with Order By

```typescript
await db.update(users).set({ verified: true }).orderBy(desc(users.createdAt)).limit(5);
```

### UPDATE with Returning (PostgreSQL/SQLite)

```typescript
const updated = await db
  .update(users)
  .set({ name: 'John Updated' })
  .where(eq(users.id, 1))
  .returning();
```

### UPDATE FROM

```typescript
await db
  .update(users)
  .set({ cityId: cities.id })
  .from(cities)
  .where(and(eq(cities.name, 'Seattle'), eq(users.name, 'John')));
```

### Basic DELETE

```typescript
await db.delete(users).where(eq(users.id, 1));
```

### DELETE All (use with caution)

```typescript
await db.delete(users);
```

### DELETE with Limit

```typescript
await db.delete(users).where(eq(users.isActive, false)).limit(100);
```

### DELETE with Order By

```typescript
await db.delete(users).where(eq(users.isActive, false)).orderBy(desc(users.createdAt)).limit(10);
```

### DELETE with Returning (PostgreSQL/SQLite)

```typescript
const deleted = await db.delete(users).where(eq(users.id, 1)).returning();
```

## Relational Query Builder

The relational query API simplifies fetching nested data with a single SQL query.

### Initialization

```typescript
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from './schema';

const db = drizzle({
  client: pool,
  schema,
});
```

### Basic Queries

```typescript
const users = await db.query.users.findMany();
const user = await db.query.users.findFirst();
```

### Including Relations

```typescript
const posts = await db.query.posts.findMany({
  with: {
    comments: true,
  },
});
```

### Nested Relations

```typescript
const users = await db.query.users.findMany({
  with: {
    posts: {
      with: {
        comments: true,
      },
    },
  },
});
```

### Partial Field Selection

```typescript
const posts = await db.query.posts.findMany({
  columns: {
    id: true,
    title: true,
  },
  with: {
    author: {
      columns: {
        id: true,
        name: true,
      },
    },
  },
});
```

### Filtering

```typescript
import { eq, gt } from 'drizzle-orm';

await db.query.posts.findMany({
  where: eq(posts.published, true),
  with: {
    comments: {
      where: (comments, { gt }) => gt(comments.likes, 10),
    },
  },
});
```

### Pagination

```typescript
await db.query.users.findMany({
  limit: 10,
  offset: 20,
  with: {
    posts: {
      limit: 5,
    },
  },
});
```

### Order By

```typescript
await db.query.posts.findMany({
  orderBy: (posts, { desc }) => [desc(posts.createdAt)],
  with: {
    comments: {
      orderBy: (comments, { asc }) => [asc(comments.createdAt)],
    },
  },
});
```

### Custom Fields with Extras

```typescript
await db.query.users.findMany({
  extras: {
    fullName: sql`concat(${users.firstName}, ' ', ${users.lastName})`.as('full_name'),
  },
});
```

### Prepared Statements (Relational)

```typescript
const prepared = db.query.users
  .findMany({
    where: (users, { eq }) => eq(users.id, placeholder('id')),
    with: { posts: true },
  })
  .prepare();

const result = await prepared.execute({ id: 1 });
```

### PlanetScale Mode (No Lateral Join)

For PlanetScale MySQL which lacks lateral join support:

```typescript
const db = drizzle({
  client: connection,
  schema,
  mode: 'planetscale',
});
```

## Transactions

### Basic Transaction

```typescript
await db.transaction(async (tx) => {
  await tx.insert(users).values({ name: 'John' });
  await tx.insert(posts).values({
    authorId: 1,
    title: 'First Post',
  });
});
```

### Transaction with Rollback

```typescript
await db.transaction(async (tx) => {
  const [account] = await tx
    .select({ balance: accounts.balance })
    .from(accounts)
    .where(eq(users.name, 'Dan'));

  if (account.balance < 100) {
    tx.rollback();
  }

  await tx
    .update(accounts)
    .set({ balance: sql`${accounts.balance} - 100` })
    .where(eq(users.name, 'Dan'));
});
```

### Transaction Return Values

```typescript
const newBalance = await db.transaction(async (tx) => {
  await tx
    .update(accounts)
    .set({ balance: sql`${accounts.balance} + 100` })
    .where(eq(users.name, 'Dan'));

  const [account] = await tx
    .select({ balance: accounts.balance })
    .from(accounts)
    .where(eq(users.name, 'Dan'));

  return account.balance;
});
```

### Nested Transactions (Savepoints)

```typescript
await db.transaction(async (tx) => {
  await tx.insert(users).values({ name: 'John' });

  await tx.transaction(async (tx2) => {
    await tx2.insert(posts).values({ title: 'Nested' });
  });
});
```

### Transaction Isolation Levels

**PostgreSQL:**

```typescript
await db.transaction(
  async (tx) => {
    // transaction logic
  },
  {
    isolationLevel: 'serializable',
    accessMode: 'read only',
    deferrable: true,
  }
);
```

Options:

- `isolationLevel`: `'read uncommitted' | 'read committed' | 'repeatable read' | 'serializable'`
- `accessMode`: `'read only' | 'read write'`
- `deferrable`: `true | false`

**MySQL/SingleStore:**

```typescript
await db.transaction(
  async (tx) => {
    // transaction logic
  },
  {
    isolationLevel: 'repeatable read',
    withConsistentSnapshot: true,
  }
);
```

**SQLite:**

```typescript
await db.transaction(
  async (tx) => {
    // transaction logic
  },
  {
    behavior: 'immediate',
  }
);
```

Options: `'deferred' | 'immediate' | 'exclusive'`

### Relational Queries in Transactions

```typescript
await db.transaction(async (tx) => {
  const users = await tx.query.users.findMany({
    with: { posts: true },
  });
});
```

## Batch Operations

Batch operations execute multiple SQL statements in a single database call, reducing network round trips.

### Supported Drivers

- LibSQL (Turso)
- Neon
- D1 (Cloudflare)

### Basic Batch

```typescript
const results = await db.batch([
  db.insert(users).values({ name: 'John' }),
  db.select().from(users),
  db.update(users).set({ name: 'Jane' }).where(eq(users.id, 1)),
]);
```

### Batch with Returning

```typescript
const [insertResult, selectResult] = await db.batch([
  db.insert(users).values({ name: 'John' }).returning(),
  db.select().from(users),
]);
```

### Batch Transaction Behavior

All statements in a batch execute in an implicit transaction. If any statement fails, the entire batch rolls back with no changes applied.

## Prepared Statements

Prepared statements compile SQL once and execute multiple times for extreme performance.

### Basic Prepared Statement

```typescript
const prepared = db.select().from(users).prepare('get_all_users');

const result1 = await prepared.execute();
const result2 = await prepared.execute();
```

### With Placeholders

```typescript
const prepared = db
  .select()
  .from(users)
  .where(eq(users.id, sql.placeholder('id')))
  .prepare('get_user_by_id');

await prepared.execute({ id: 10 });
await prepared.execute({ id: 20 });
```

### Complex Placeholders

```typescript
const prepared = db
  .select()
  .from(users)
  .where(sql`lower(${users.name}) like ${sql.placeholder('pattern')}`)
  .prepare('search_users');

await prepared.execute({ pattern: '%john%' });
```

### Prepared INSERT

```typescript
const prepared = db
  .insert(users)
  .values({
    name: sql.placeholder('name'),
    email: sql.placeholder('email'),
  })
  .prepare('insert_user');

await prepared.execute({
  name: 'John',
  email: 'john@example.com',
});
```

### Performance Benefits

- SQL concatenation happens once on Drizzle side
- Database driver reuses precompiled binary SQL
- Extreme performance gains on large SQL queries
- Can make Drizzle faster than native drivers

### Current Limitations

Prepared statements created outside of a transaction cannot be correctly utilized within a transaction (may be resolved in future versions).

## Migrations with Drizzle Kit

### CLI Commands

| Command    | Function                                                |
| ---------- | ------------------------------------------------------- |
| `generate` | Creates SQL migration files from schema changes         |
| `migrate`  | Applies generated migrations to database                |
| `push`     | Directly pushes schema to database (no migration files) |
| `pull`     | Introspects database and generates Drizzle schema       |
| `studio`   | Launches Drizzle Studio GUI                             |
| `check`    | Detects collision issues in migrations                  |
| `up`       | Upgrades snapshots from older versions                  |

### Generate Migrations

```bash
npx drizzle-kit generate
```

**With custom name:**

```bash
npx drizzle-kit generate --name=add_users_table
```

**Custom empty migration:**

```bash
npx drizzle-kit generate --custom
```

### Apply Migrations

**Using drizzle-kit:**

```bash
npx drizzle-kit migrate
```

**Using Drizzle ORM:**

```typescript
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import { drizzle } from 'drizzle-orm/node-postgres';

const db = drizzle(process.env.DATABASE_URL);

await migrate(db, { migrationsFolder: './drizzle' });
```

### Push Schema (Rapid Prototyping)

```bash
npx drizzle-kit push
```

Push directly syncs schema changes to database without generating migration files. Best for:

- Rapid prototyping
- Development environments
- Teams that prefer database-first workflows

### Pull Schema (Introspection)

```bash
npx drizzle-kit pull
```

Introspects existing database and generates Drizzle schema files. Useful for:

- Migrating to Drizzle from another ORM
- Connecting to existing databases
- Database-first development

### Studio (Database GUI)

```bash
npx drizzle-kit studio
```

Launches Drizzle Studio at `local.drizzle.studio` for visual database management.

### Migration Workflow Approaches

**Migration-First (Recommended for Production):**

1. Change schema files
2. Run `drizzle-kit generate`
3. Review generated SQL
4. Run `drizzle-kit migrate` or use programmatic migration

**Push-First (Rapid Prototyping):**

1. Change schema files
2. Run `drizzle-kit push`
3. Schema changes applied immediately

## Drizzle Studio

Drizzle Studio is a database GUI tool for browsing and managing data.

### Features

- Browse, add, delete, and update data based on schema
- Support for PostgreSQL, MySQL, SQLite databases
- Explicit null and empty string values
- Boolean, number, bigint support
- JSON objects and arrays
- Advanced query execution
- Schema visualization
- Real-time database monitoring

### Launching Studio

**Local:**

```bash
npx drizzle-kit studio
```

**Custom host/port:**

```bash
npx drizzle-kit studio --host 0.0.0.0 --port 3333
```

### Deployment Options

- **Local**: Via `drizzle-kit studio` command
- **Chrome Extension**: For PlanetScale, Cloudflare D1, Vercel Postgres
- **Drizzle Studio Gateway**: Self-hosted deployment

### Benefits

- Lightweight and web-based
- Clean, modern UI
- Fast query execution
- Open-source
- Minimal setup required

## Validation with drizzle-zod

Drizzle-zod generates Zod validation schemas from Drizzle tables for runtime validation.

### Installation

```bash
npm i drizzle-zod
```

**Requirements:**

- Drizzle ORM v0.36.0+
- Zod v3.25.1+

### Select Schema

Validates data returned from database:

```typescript
import { createSelectSchema } from 'drizzle-zod';

const userSelectSchema = createSelectSchema(users);

const validated = userSelectSchema.parse(result);
```

### Insert Schema

Validates data before insertion (primary keys optional):

```typescript
import { createInsertSchema } from 'drizzle-zod';

const userInsertSchema = createInsertSchema(users);

const validated = userInsertSchema.parse({
  name: 'John',
  email: 'john@example.com',
});

await db.insert(users).values(validated);
```

### Update Schema

Validates partial updates (all fields optional):

```typescript
import { createUpdateSchema } from 'drizzle-zod';

const userUpdateSchema = createUpdateSchema(users);

const validated = userUpdateSchema.parse({
  email: 'newemail@example.com',
});

await db.update(users).set(validated).where(eq(users.id, 1));
```

### Refinements

Extend or overwrite field validation:

```typescript
import { createInsertSchema } from 'drizzle-zod';
import { z } from 'zod';

const userInsertSchema = createInsertSchema(users, {
  name: (schema) => schema.max(50),
  email: (schema) => schema.email(),
  age: z.number().min(18).max(120),
});
```

### Factory Functions

For custom Zod instances or coercion:

```typescript
import { createSchemaFactory } from 'drizzle-zod';
import { z } from 'zod';

const { createInsertSchema } = createSchemaFactory({
  zodInstance: z,
  coerce: { date: true },
});

const schema = createInsertSchema(users);
```

### Type Mapping

Drizzle types automatically map to Zod equivalents:

- `boolean` → `z.boolean()`
- `timestamp` / `date` → `z.date()`
- `text` / `varchar` → `z.string()` (with length constraints)
- `integer` / `numeric` → `z.number()` (with min/max)
- `bigint` → `z.bigint()`
- `uuid` → `z.string().uuid()`
- `enum` → `z.enum()`
- `json` → `z.union()` for mixed types
- `array` → `z.array()` with dimension limits

## Best Practices

### 1. Schema Design

**Use Identity Columns (PostgreSQL):**

```typescript
id: integer().generatedAlwaysAsIdentity();
```

**Hybrid ID Strategy:**
Combine integer primary keys for performance with public IDs for security:

```typescript
export const users = pgTable('users', {
  id: serial().primaryKey(),
  publicId: varchar().$defaultFn(() => nanoid()),
  name: varchar(),
});
```

**Timestamp Configuration:**

```typescript
createdAt: timestamp({ mode: 'date', precision: 3, withTimezone: true })
  .defaultNow()
  .notNull(),
updatedAt: timestamp({ mode: 'date', precision: 3, withTimezone: true })
  .$onUpdateFn(() => new Date()),
```

Use `mode: 'date'` for 10-15% better performance over `mode: 'string'`.

**Reusable Column Patterns:**

```typescript
const timestamps = {
  createdAt: timestamp({ mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp({ mode: 'date' }).$onUpdateFn(() => new Date()),
};

export const users = pgTable('users', {
  id: serial().primaryKey(),
  ...timestamps,
});
```

### 2. Indexing Strategies

**Always Index Foreign Keys:**

```typescript
export const posts = pgTable(
  'posts',
  {
    authorId: integer().references(() => users.id),
  },
  (table) => [index('author_idx').on(table.authorId)]
);
```

**Composite Indexes (Column Order Matters):**

```typescript
(table) => [index('user_status_idx').on(table.userId, table.status)];
```

**Partial Indexes for Filtered Queries:**

```typescript
(table) => [
  index('active_users_idx')
    .on(table.email)
    .where(sql`${table.isActive} = true`),
];
```

Can provide up to 275x performance improvement for filtered queries.

**Covering Indexes:**

```typescript
(table) => [index('user_lookup_idx').on(table.email).include(table.name, table.createdAt)];
```

### 3. Query Optimization

**Select Only Needed Columns:**

```typescript
const users = await db
  .select({
    id: users.id,
    name: users.name,
  })
  .from(users);
```

**Use Prepared Statements for Frequent Queries:**

```typescript
const getUserById = db
  .select()
  .from(users)
  .where(eq(users.id, sql.placeholder('id')))
  .prepare();

await getUserById.execute({ id: 1 });
```

**Leverage Relational Queries:**

```typescript
const posts = await db.query.posts.findMany({
  columns: { id: true, title: true },
  with: {
    author: {
      columns: { id: true, name: true },
    },
  },
});
```

Generates a single optimized SQL query with no N+1 problems.

### 4. Connection Pooling

**PostgreSQL:**

```typescript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

const db = drizzle({ client: pool });
```

**Serverless (Disable Prepared Statements for Supabase Transaction Mode):**

```typescript
const db = drizzle({
  client: pool,
  prepare: false,
});
```

### 5. Type Safety

**Use drizzle-zod for Runtime Validation:**

```typescript
import { createInsertSchema } from 'drizzle-zod';

const insertUserSchema = createInsertSchema(users, {
  email: (schema) => schema.email(),
  age: (schema) => schema.min(18),
});

const validated = insertUserSchema.parse(formData);
await db.insert(users).values(validated);
```

**Branded Types for Custom Validation:**

```typescript
import { z } from 'zod';

type UserId = z.infer<typeof userIdSchema>;
const userIdSchema = z.string().uuid().brand<'UserId'>();

export const users = pgTable('users', {
  id: uuid().$type<UserId>(),
});
```

### 6. Migrations

**Never Modify Migration History:**

- Don't edit generated migration files manually
- Don't delete old migrations
- Keep snapshots and journals in version control

**Review Generated SQL:**

```bash
npx drizzle-kit generate
cat drizzle/0000_initial.sql
```

**Use Custom Migrations for Unsupported DDL:**

```bash
npx drizzle-kit generate --custom
```

### 7. Error Handling

**Always Include WHERE Clauses in DELETE:**

```typescript
if (!userId) {
  throw new Error('User ID required');
}

await db.delete(users).where(eq(users.id, userId));
```

**Transaction Error Handling:**

```typescript
try {
  await db.transaction(async (tx) => {
    const [user] = await tx.insert(users).values({ email }).returning();

    await tx.insert(profiles).values({ userId: user.id });
  });
} catch (error) {
  console.error('Transaction failed:', error);
  throw error;
}
```

### 8. Security

**Use Parameterized Queries (Built-in):**

Drizzle automatically parameterizes all queries:

```typescript
await db.select().from(users).where(eq(users.id, userInput));
```

Drizzle maps dynamic parameters to database placeholders (`$1`, `?`, etc.) and passes values separately, preventing SQL injection.

**Validate User Input:**

```typescript
import { createInsertSchema } from 'drizzle-zod';

const schema = createInsertSchema(users);
const validated = schema.parse(untrustedInput);
```

**Use Environment Variables for Credentials:**

```env
DATABASE_URL=postgresql://user:pass@host:5432/db
```

## Common Gotchas

### 1. Migration Management

**Problem:** Modifying migration history manually causes drift between schema and database.

**Solution:** Never edit generated migrations. Use `drizzle-kit generate --custom` for manual SQL.

### 2. Missing Foreign Key Indexes

**Problem:** Queries with joins on foreign keys perform sequential scans.

**Solution:** Always index foreign key columns:

```typescript
(table) => [index('fk_idx').on(table.foreignKeyColumn)];
```

### 3. Over-fetching Data

**Problem:** Selecting all columns when only a few are needed.

**Solution:** Use partial selection:

```typescript
const users = await db
  .select({
    id: users.id,
    name: users.name,
  })
  .from(users);
```

### 4. String Mode Timestamps

**Problem:** Using `mode: 'string'` for timestamps reduces performance by 10-15%.

**Solution:** Use `mode: 'date'` unless string formatting is required:

```typescript
createdAt: timestamp({ mode: 'date' });
```

### 5. Undefined vs Null in Updates

**Problem:** Undefined values are ignored in updates, leading to confusion.

**Solution:** Explicitly use `null` to clear values:

```typescript
await db.update(users).set({
  deletedAt: null,
});
```

### 6. Not Understanding `leftJoin()` Behavior

**Problem:** Expecting non-null values from left joins.

**Solution:** Account for nullable results:

```typescript
const result = await db.select().from(posts).leftJoin(users, eq(posts.authorId, users.id));

result.forEach(({ posts, users }) => {
  if (users) {
  }
});
```

### 7. Prepared Statements in Transactions

**Problem:** Prepared statements created outside transactions may not work correctly inside them.

**Solution:** Create prepared statements inside transaction scope or avoid mixing them.

### 8. Connection Pool Exhaustion

**Problem:** Not configuring connection pool limits leads to "too many connections" errors.

**Solution:** Set appropriate pool size:

```typescript
const pool = new Pool({
  max: 20,
  idleTimeoutMillis: 30000,
});
```

### 9. Forgetting WHERE Clause in DELETE

**Problem:** Accidentally deleting all records.

**Solution:** Always include a WHERE clause or add application-level guards:

```typescript
if (!condition) {
  throw new Error('Cannot delete without condition');
}

await db.delete(users).where(condition);
```

### 10. Not Defining Relations for Complex Queries

**Problem:** Manual joins become unwieldy for nested data.

**Solution:** Define relations and use relational query API:

```typescript
const posts = await db.query.posts.findMany({
  with: {
    author: true,
    comments: { with: { author: true } },
  },
});
```

## Anti-Patterns

### 1. Modifying Migration Files

**Anti-pattern:**

```bash
vim drizzle/0001_migration.sql
```

**Correct approach:**

```bash
npx drizzle-kit generate --custom
```

### 2. Not Indexing Foreign Keys

**Anti-pattern:**

```typescript
export const posts = pgTable('posts', {
  authorId: integer().references(() => users.id),
});
```

**Correct approach:**

```typescript
export const posts = pgTable(
  'posts',
  {
    authorId: integer().references(() => users.id),
  },
  (table) => [index('author_idx').on(table.authorId)]
);
```

### 3. Using String Mode for Timestamps

**Anti-pattern:**

```typescript
createdAt: timestamp({ mode: 'string' });
```

**Correct approach:**

```typescript
createdAt: timestamp({ mode: 'date' });
```

### 4. Over-indexing

**Anti-pattern:**

```typescript
(table) => [
  index('idx1').on(table.col1),
  index('idx2').on(table.col2),
  index('idx3').on(table.col3),
  index('idx4').on(table.col4),
  index('idx5').on(table.col5),
];
```

Creates slow write operations.

**Correct approach:**
Index only columns used in WHERE, JOIN, ORDER BY clauses based on actual query patterns.

### 5. Not Using Prepared Statements for Repeated Queries

**Anti-pattern:**

```typescript
for (const id of ids) {
  await db.select().from(users).where(eq(users.id, id));
}
```

**Correct approach:**

```typescript
const prepared = db
  .select()
  .from(users)
  .where(eq(users.id, sql.placeholder('id')))
  .prepare();

for (const id of ids) {
  await prepared.execute({ id });
}
```

### 6. Manually Constructing Raw SQL

**Anti-pattern:**

```typescript
const query = `SELECT * FROM users WHERE id = ${userId}`;
await db.execute(query);
```

SQL injection risk.

**Correct approach:**

```typescript
await db.select().from(users).where(eq(users.id, userId));
```

### 7. Not Using Transactions for Multi-Step Operations

**Anti-pattern:**

```typescript
await db.insert(users).values({ name: 'John' });
await db.insert(profiles).values({ userId: 1 });
```

Partial writes possible if second operation fails.

**Correct approach:**

```typescript
await db.transaction(async (tx) => {
  const [user] = await tx.insert(users).values({ name: 'John' }).returning();

  await tx.insert(profiles).values({ userId: user.id });
});
```

### 8. Ignoring Type Errors

**Anti-pattern:**

```typescript
const result = await db.select().from(users);
```

**Correct approach:**

```typescript
import { InferSelectModel } from 'drizzle-orm';

type User = InferSelectModel<typeof users>;
const result: User[] = await db.select().from(users);
```

### 9. Using Serial Instead of Identity (PostgreSQL)

**Anti-pattern:**

```typescript
id: serial().primaryKey();
```

**Correct approach (PostgreSQL recommendation 2025):**

```typescript
id: integer().generatedAlwaysAsIdentity();
```

### 10. Not Validating User Input

**Anti-pattern:**

```typescript
await db.insert(users).values(req.body);
```

**Correct approach:**

```typescript
import { createInsertSchema } from 'drizzle-zod';

const schema = createInsertSchema(users);
const validated = schema.parse(req.body);
await db.insert(users).values(validated);
```

## Performance Tips

### 1. Use Prepared Statements

Compile SQL once, execute many times:

```typescript
const prepared = db
  .select()
  .from(users)
  .where(eq(users.id, sql.placeholder('id')))
  .prepare();

for (const id of userIds) {
  await prepared.execute({ id });
}
```

### 2. Select Only Required Columns

```typescript
const users = await db
  .select({
    id: users.id,
    name: users.name,
  })
  .from(users);
```

### 3. Use Batch Operations

For supported drivers (LibSQL, Neon, D1):

```typescript
await db.batch([
  db.insert(users).values({ name: 'John' }),
  db.insert(users).values({ name: 'Jane' }),
  db.insert(users).values({ name: 'Bob' }),
]);
```

### 4. Leverage Indexes

```typescript
(table) => [
  index('lookup_idx').on(table.email),
  index('composite_idx').on(table.userId, table.status),
];
```

### 5. Use Connection Pooling

```typescript
const pool = new Pool({
  max: 20,
  idleTimeoutMillis: 30000,
});
```

### 6. Use Date Mode for Timestamps

10-15% faster than string mode:

```typescript
timestamp({ mode: 'date' });
```

### 7. Partial Indexes for Filtered Queries

```typescript
index('active_idx')
  .on(table.status)
  .where(sql`${table.isActive} = true`);
```

### 8. Use Relational Queries

Generates optimized single SQL query:

```typescript
await db.query.posts.findMany({
  with: { author: true, comments: true },
});
```

### 9. Covering Indexes

Avoid table lookups:

```typescript
index('covering_idx').on(table.email).include(table.name, table.status);
```

### 10. Configure Appropriate Fill Factor

For tables with frequent updates:

```typescript
index('idx').on(table.col).with({ fillfactor: '70' });
```

## Code Examples

### Complete CRUD Application

```typescript
import { pgTable, serial, varchar, timestamp, boolean } from 'drizzle-orm/pg-core';
import { drizzle } from 'drizzle-orm/node-postgres';
import { eq } from 'drizzle-orm';
import { Pool } from 'pg';

const users = pgTable('users', {
  id: serial().primaryKey(),
  name: varchar({ length: 255 }).notNull(),
  email: varchar({ length: 255 }).notNull().unique(),
  isActive: boolean().default(true),
  createdAt: timestamp({ mode: 'date' }).defaultNow().notNull(),
  updatedAt: timestamp({ mode: 'date' }).$onUpdateFn(() => new Date()),
});

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
});

const db = drizzle({ client: pool });

async function createUser(name: string, email: string) {
  const [user] = await db.insert(users).values({ name, email }).returning();
  return user;
}

async function getUserById(id: number) {
  const [user] = await db.select().from(users).where(eq(users.id, id));
  return user;
}

async function updateUser(id: number, data: { name?: string; email?: string }) {
  const [updated] = await db.update(users).set(data).where(eq(users.id, id)).returning();
  return updated;
}

async function deleteUser(id: number) {
  await db.delete(users).where(eq(users.id, id));
}

async function listActiveUsers() {
  return db.select().from(users).where(eq(users.isActive, true)).orderBy(users.createdAt);
}
```

### Blog System with Relations

```typescript
import { pgTable, serial, varchar, text, integer, timestamp } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { drizzle } from 'drizzle-orm/node-postgres';

const users = pgTable('users', {
  id: serial().primaryKey(),
  name: varchar({ length: 255 }).notNull(),
  email: varchar({ length: 255 }).notNull().unique(),
  createdAt: timestamp({ mode: 'date' }).defaultNow(),
});

const posts = pgTable(
  'posts',
  {
    id: serial().primaryKey(),
    title: varchar({ length: 255 }).notNull(),
    content: text().notNull(),
    published: boolean().default(false),
    authorId: integer()
      .references(() => users.id)
      .notNull(),
    createdAt: timestamp({ mode: 'date' }).defaultNow(),
  },
  (table) => [index('author_idx').on(table.authorId), index('published_idx').on(table.published)]
);

const comments = pgTable(
  'comments',
  {
    id: serial().primaryKey(),
    content: text().notNull(),
    postId: integer()
      .references(() => posts.id)
      .notNull(),
    authorId: integer()
      .references(() => users.id)
      .notNull(),
    createdAt: timestamp({ mode: 'date' }).defaultNow(),
  },
  (table) => [index('post_idx').on(table.postId), index('author_idx').on(table.authorId)]
);

const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
  comments: many(comments),
}));

const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id],
  }),
  comments: many(comments),
}));

const commentsRelations = relations(comments, ({ one }) => ({
  post: one(posts, {
    fields: [comments.postId],
    references: [posts.id],
  }),
  author: one(users, {
    fields: [comments.authorId],
    references: [users.id],
  }),
}));

const db = drizzle({
  client: pool,
  schema: {
    users,
    posts,
    comments,
    usersRelations,
    postsRelations,
    commentsRelations,
  },
});

async function getPostWithDetails(postId: number) {
  return db.query.posts.findFirst({
    where: (posts, { eq }) => eq(posts.id, postId),
    with: {
      author: {
        columns: { id: true, name: true },
      },
      comments: {
        with: {
          author: {
            columns: { id: true, name: true },
          },
        },
        orderBy: (comments, { desc }) => [desc(comments.createdAt)],
      },
    },
  });
}

async function getPublishedPosts(limit: number = 10) {
  return db.query.posts.findMany({
    where: (posts, { eq }) => eq(posts.published, true),
    orderBy: (posts, { desc }) => [desc(posts.createdAt)],
    limit,
    with: {
      author: {
        columns: { id: true, name: true },
      },
    },
  });
}
```

### E-commerce Schema with Validation

```typescript
import { pgTable, serial, varchar, integer, numeric, timestamp } from 'drizzle-orm/pg-core';
import { createInsertSchema, createSelectSchema } from 'drizzle-zod';
import { z } from 'zod';

const products = pgTable(
  'products',
  {
    id: serial().primaryKey(),
    name: varchar({ length: 255 }).notNull(),
    description: text(),
    price: numeric({ precision: 10, scale: 2 }).notNull(),
    stock: integer().notNull().default(0),
    createdAt: timestamp({ mode: 'date' }).defaultNow(),
    updatedAt: timestamp({ mode: 'date' }).$onUpdateFn(() => new Date()),
  },
  (table) => [index('name_idx').on(table.name)]
);

const orders = pgTable(
  'orders',
  {
    id: serial().primaryKey(),
    userId: integer().notNull(),
    status: varchar({ length: 50 }).notNull().default('pending'),
    total: numeric({ precision: 10, scale: 2 }).notNull(),
    createdAt: timestamp({ mode: 'date' }).defaultNow(),
  },
  (table) => [index('user_idx').on(table.userId), index('status_idx').on(table.status)]
);

const orderItems = pgTable(
  'order_items',
  {
    id: serial().primaryKey(),
    orderId: integer()
      .references(() => orders.id)
      .notNull(),
    productId: integer()
      .references(() => products.id)
      .notNull(),
    quantity: integer().notNull(),
    price: numeric({ precision: 10, scale: 2 }).notNull(),
  },
  (table) => [index('order_idx').on(table.orderId), index('product_idx').on(table.productId)]
);

const insertProductSchema = createInsertSchema(products, {
  name: (schema) => schema.min(1).max(255),
  price: (schema) => schema.positive(),
  stock: (schema) => schema.int().nonnegative(),
});

const insertOrderSchema = createInsertSchema(orders, {
  total: (schema) => schema.positive(),
  status: z.enum(['pending', 'processing', 'shipped', 'delivered', 'cancelled']),
});

async function createOrder(userId: number, items: Array<{ productId: number; quantity: number }>) {
  return db.transaction(async (tx) => {
    let total = 0;

    for (const item of items) {
      const [product] = await tx.select().from(products).where(eq(products.id, item.productId));

      if (!product || product.stock < item.quantity) {
        throw new Error(`Insufficient stock for product ${item.productId}`);
      }

      total += Number(product.price) * item.quantity;

      await tx
        .update(products)
        .set({ stock: product.stock - item.quantity })
        .where(eq(products.id, item.productId));
    }

    const [order] = await tx.insert(orders).values({ userId, total: total.toString() }).returning();

    for (const item of items) {
      const [product] = await tx.select().from(products).where(eq(products.id, item.productId));

      await tx.insert(orderItems).values({
        orderId: order.id,
        productId: item.productId,
        quantity: item.quantity,
        price: product.price,
      });
    }

    return order;
  });
}
```

## Version-Specific Notes

### v0.44.7 (Latest - November 2025)

- Current stable release
- Full TypeScript support
- Zero dependencies
- Tree-shakeable

### v0.32.2 (August 2024)

- Added PostgreSQL sequences
- Identity columns support
- Generated columns for all dialects
- `$returningId()` for MySQL

### v0.31.0 (Breaking Changes)

- PostgreSQL indexes API changes
- Requires drizzle-kit@0.24.0+
- Alignment with PostgreSQL documentation

### v0.30.5

- `$onUpdate` functionality added
- Timestamp handling improvements

### v0.29.0

- Removed support for filtering by nested relations
- Improved query performance

## References

### Official Documentation

- **Main Site**: https://orm.drizzle.team/
- **Getting Started**: https://orm.drizzle.team/docs/get-started
- **Overview**: https://orm.drizzle.team/docs/overview
- **Schema Declaration**: https://orm.drizzle.team/docs/sql-schema-declaration
- **Queries**: https://orm.drizzle.team/docs/select
- **Migrations**: https://orm.drizzle.team/docs/kit-overview
- **Column Types**: https://orm.drizzle.team/docs/column-types/pg

### GitHub

- **Repository**: https://github.com/drizzle-team/drizzle-orm
- **Issues**: https://github.com/drizzle-team/drizzle-orm/issues
- **Releases**: https://github.com/drizzle-team/drizzle-orm/releases

### NPM

- **drizzle-orm**: https://www.npmjs.com/package/drizzle-orm
- **drizzle-kit**: https://www.npmjs.com/package/drizzle-kit
- **drizzle-zod**: https://www.npmjs.com/package/drizzle-zod

### Community Resources

- **PostgreSQL Best Practices Guide (2025)**: https://gist.github.com/productdevbook/7c9ce3bbeb96b3fabc3c7c2aa2abc717
- **Better Stack Guide**: https://betterstack.com/community/guides/scaling-nodejs/drizzle-orm/
- **Supabase Integration**: https://supabase.com/docs/guides/database/drizzle

### Tools

- **Drizzle Studio**: https://orm.drizzle.team/drizzle-studio/overview
- **ESLint Plugin**: For enforcing best practices
- **Drizzle Kit CLI**: Migration and schema management tool

---

**Research Date**: November 19, 2025
**Latest Version**: 0.44.7
**Status**: Production Ready

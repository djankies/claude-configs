---
name: managing-dev-migrations
description: Use migrate dev for versioned migrations and db push for rapid prototyping. Use when developing schema changes locally.
allowed-tools: Read, Write, Edit, Bash
---

# Development Migration Workflow

Guide for choosing and using migration workflows in Prisma 6 during local development.

## Decision Tree

### Use `prisma migrate dev` when:
- Building production-ready features
- Working on a team with shared schema changes
- Need a migration history for rollbacks
- Schema changes should be version controlled
- Deploying to staging/production environments

### Use `prisma db push` when:
- Rapid prototyping and experimentation
- Early stage development with frequent schema changes
- Personal projects without deployment concerns
- Testing schema ideas quickly
- No need for migration history

## migrate dev Workflow

Standard development workflow for versioned migrations:

```bash
npx prisma migrate dev --name add_user_profile
```

This command:
1. Detects schema changes in `schema.prisma`
2. Generates a SQL migration file
3. Applies the migration to your database
4. Regenerates Prisma Client

### Review Before Apply

Use `--create-only` to review generated SQL before applying:

```bash
npx prisma migrate dev --create-only --name add_indexes
```

This generates the migration file without applying it. Review and edit if needed, then apply:

```bash
npx prisma migrate dev
```

## db push Workflow

Fast iteration without migration files:

```bash
npx prisma db push
```

This command:
1. Syncs schema.prisma directly to database
2. No migration files created
3. Regenerates Prisma Client
4. Warning on destructive changes (data loss)

Use for throwaway prototypes or when you plan to recreate migrations later.

## Editing Generated Migrations

### When to Edit

- Add custom indexes with specific options
- Include data migrations alongside schema changes
- Optimize generated SQL for your database
- Add database-specific features not in Prisma schema

### Example: Custom Data Migration

After running `--create-only`:

```sql
-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "role" TEXT NOT NULL DEFAULT 'user',

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- Data migration: Set admin role for specific email
UPDATE "User" SET "role" = 'admin' WHERE "email" = 'admin@example.com';

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
```

Then apply with:

```bash
npx prisma migrate dev
```

## Workflow Examples

### Feature Development Workflow

```bash
npx prisma migrate dev --name add_comments
npx prisma migrate dev --name add_comment_likes
npx prisma migrate dev --name add_comment_moderation
```

Each feature gets its own migration for clear history.

### Prototyping Workflow

```bash
npx prisma db push
npx prisma db push
npx prisma db push
```

Iterate rapidly on schema design. Once stable, create a migration:

```bash
npx prisma migrate dev --name initial_schema
```

### Review and Customize Workflow

```bash
npx prisma migrate dev --create-only --name optimize_queries
```

Edit migration in `prisma/migrations/[timestamp]_optimize_queries/migration.sql`:

```sql
-- Generated schema changes
CREATE INDEX "Post_authorId_createdAt_idx" ON "Post"("authorId", "createdAt" DESC);

-- Custom optimization
CREATE INDEX CONCURRENTLY "Post_title_search_idx" ON "Post" USING GIN(to_tsvector('english', "title"));
```

Apply:

```bash
npx prisma migrate dev
```

## Switching Between Workflows

### From db push to migrate dev

If you used `db push` during prototyping and want to create versioned migrations:

```bash
npx prisma migrate dev --name initial_schema
```

Prisma detects the current state and creates a baseline migration.

### Handling Conflicts

If you have unapplied migrations and used `db push`, reset migration history:

```bash
npx prisma migrate reset
npx prisma migrate dev
```

This drops the database, replays all migrations, and applies new ones.

## Common Patterns

### Daily Development

```bash
npx prisma migrate dev --name descriptive_name
```

One migration per logical change.

### Experimentation Phase

```bash
npx prisma db push
```

Skip migrations until design is stable.

### Pre-commit Review

```bash
npx prisma migrate dev --create-only --name feature_name
```

Review SQL, edit if needed, commit both schema.prisma and migration files.

### Team Collaboration

```bash
git pull
npx prisma migrate dev
```

Apply teammate's migrations from version control.

## Troubleshooting

### Migration Already Applied

If you see "migration already applied", your database is in sync:

```bash
npx prisma migrate dev
```

This is normal when no schema changes exist.

### Drift Detected

If database differs from migration history:

```bash
npx prisma migrate diff --from-migrations ./prisma/migrations --to-schema-datamodel ./prisma/schema.prisma
```

Shows differences. Resolve by resetting or creating new migration.

### Data Loss Warnings

Both commands warn before destructive changes. Review carefully:

```
⚠️  Warning: You are about to drop the column `oldField` on the `User` table, which still contains data.
```

Migrate data before proceeding or cancel and adjust schema.

---
name: deploying-production-migrations
description: Deploy migrations to production safely using migrate deploy in CI/CD. Use when setting up production deployment pipelines.
allowed-tools: Read, Write, Edit, Bash
---

# MIGRATIONS-production

## Overview

Production database migrations require careful orchestration to prevent data loss and downtime. This skill covers safe migration deployment using `prisma migrate deploy` in CI/CD pipelines, handling failures, and implementing rollback strategies.

## Production Migration Commands

### Safe Commands

**prisma migrate deploy**
- Applies pending migrations to production
- Only runs migrations that haven't been applied
- Records migration history in `_prisma_migrations` table
- Does NOT create new migrations
- Does NOT reset the database

```bash
npx prisma migrate deploy
```

### NEVER Use in Production

**prisma migrate dev**
- Creates new migrations
- Can reset the database
- Intended for development only
- DANGER: Will prompt for database reset

**prisma migrate reset**
- Drops and recreates database
- Deletes ALL data
- DANGER: Catastrophic data loss

**prisma db push**
- Pushes schema without migrations
- Bypasses migration history
- No rollback capability
- Can cause data loss

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Generate Prisma Client
        run: npx prisma generate

      - name: Run migrations
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: npx prisma migrate deploy

      - name: Deploy application
        run: npm run deploy
```

### GitLab CI

```yaml
deploy-production:
  stage: deploy
  image: node:20
  only:
    - main
  environment:
    name: production
  before_script:
    - npm ci
    - npx prisma generate
  script:
    - npx prisma migrate deploy
    - npm run deploy
  variables:
    DATABASE_URL: $DATABASE_URL_PRODUCTION
```

### Docker Deployment

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY prisma ./prisma
RUN npx prisma generate

COPY . .

CMD ["sh", "-c", "npx prisma migrate deploy && npm start"]
```

## Handling Failed Migrations

### Migration Failure Detection

Check migration status:

```bash
npx prisma migrate status
```

Output indicates:
- Pending migrations
- Applied migrations
- Failed migrations
- Database schema drift

### Recovery Strategies

**Option 1: Resolve and Retry**

If migration failed due to temporary issue:

```bash
npx prisma migrate resolve --applied <migration_name>
npx prisma migrate deploy
```

**Option 2: Mark as Rolled Back**

If migration was partially applied and manually reverted:

```bash
npx prisma migrate resolve --rolled-back <migration_name>
```

**Option 3: Fix Migration File**

If migration has bugs:

1. DO NOT edit existing migration files
2. Create new migration to fix issues:

```bash
npx prisma migrate dev --name fix_previous_migration
```

3. Deploy the fix:

```bash
npx prisma migrate deploy
```

### Rollback Pattern

Prisma doesn't support automatic rollbacks. Manual rollback:

1. Create down migration:

```sql
-- migrations/20240115000002_rollback_add_status/migration.sql
ALTER TABLE "User" DROP COLUMN "status";
```

2. Apply manually or via new migration:

```bash
npx prisma migrate dev --name rollback_add_status --create-only
```

## Production Deployment Checklist

### Pre-Deployment

- [ ] All migrations tested in staging environment
- [ ] Database backup created
- [ ] Migration rollback plan documented
- [ ] Downtime window scheduled (if needed)
- [ ] Team notified of deployment

### Deployment

- [ ] Application maintenance mode enabled (if needed)
- [ ] Run `npx prisma migrate deploy`
- [ ] Verify migration status
- [ ] Run smoke tests
- [ ] Monitor error logs

### Post-Deployment

- [ ] Verify all migrations applied successfully
- [ ] Check application functionality
- [ ] Monitor database performance
- [ ] Disable maintenance mode
- [ ] Document any issues encountered

## Database Connection Best Practices

### Connection Pooling

Use connection pooling for production:

```env
DATABASE_URL="postgresql://user:password@host:5432/db?connection_limit=10&pool_timeout=20"
```

### Connection URL Security

Never commit DATABASE_URL:

- Use environment variables
- Store in CI/CD secrets
- Use secret management tools (Vault, AWS Secrets Manager)

```bash
export DATABASE_URL="postgresql://..."
npx prisma migrate deploy
```

### Read Replicas

Separate migration connection from application connections:

```env
DATABASE_URL="postgresql://primary:5432/db"
DATABASE_URL_REPLICA="postgresql://replica:5432/db"
```

Migrations always run against primary database.

## Zero-Downtime Migrations

### Expand-Contract Pattern

**Phase 1: Expand** (add new column, keep old)

```sql
ALTER TABLE "User" ADD COLUMN "email_new" TEXT;
```

Deploy application that writes to both columns.

**Phase 2: Migrate Data**

```sql
UPDATE "User" SET "email_new" = "email" WHERE "email_new" IS NULL;
```

**Phase 3: Contract** (remove old column)

```sql
ALTER TABLE "User" DROP COLUMN "email";
ALTER TABLE "User" RENAME COLUMN "email_new" TO "email";
```

### Backwards-Compatible Migrations

Make columns optional first:

```prisma
model User {
  id    Int     @id @default(autoincrement())
  name  String
  email String?
}
```

Then enforce constraints in later migration:

```prisma
model User {
  id    Int     @id @default(autoincrement())
  name  String
  email String  @unique
}
```

## Monitoring and Alerts

### Migration Duration Tracking

```bash
time npx prisma migrate deploy
```

Set alerts for migrations exceeding expected duration.

### Failed Migration Alerts

Configure CI/CD to alert on migration failures:

```yaml
- name: Run migrations
  run: npx prisma migrate deploy
  continue-on-error: false

- name: Alert on failure
  if: failure()
  run: |
    curl -X POST $SLACK_WEBHOOK \
      -d '{"text":"Production migration failed!"}'
```

### Schema Drift Detection

Run in staging before production:

```bash
npx prisma migrate status
```

Fails if schema differs from migrations.

## Common Production Issues

### Issue: Migration Hangs

**Cause:** Long-running query, table locks

**Solution:**
- Identify blocking queries
- Run during low-traffic window
- Use `statement_timeout` in PostgreSQL

```sql
SET statement_timeout = '30s';
```

### Issue: Migration Fails Midway

**Cause:** Constraint violation, data type mismatch

**Solution:**
- Check migration status
- Mark as applied if data is correct
- Create fix migration if needed

### Issue: Out-of-Order Migrations

**Cause:** Multiple developers creating migrations simultaneously

**Solution:**
- Merge conflicts in migration files
- Regenerate migrations if needed
- Use linear migration history

## Shadow Database

Prisma 6 uses shadow database for migration validation:

```env
DATABASE_URL="postgresql://..."
SHADOW_DATABASE_URL="postgresql://...shadow"
```

Not needed for `migrate deploy`, only for `migrate dev`.

## Multi-Environment Strategy

### Development

```bash
npx prisma migrate dev
```

### Staging

```bash
npx prisma migrate deploy
```

Test production deployment process.

### Production

```bash
npx prisma migrate deploy
```

Only apply migrations, never create.

## References

- [Prisma Migrate Deploy Documentation](https://www.prisma.io/docs/orm/prisma-migrate/workflows/deploy)
- [Production Best Practices](https://www.prisma.io/docs/orm/prisma-migrate/workflows/production)
- [Troubleshooting Migrations](https://www.prisma.io/docs/orm/prisma-migrate/workflows/troubleshooting)

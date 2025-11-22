# Prisma 6 Migration Checklist

## Pre-Migration

- [ ] Backup production database
- [ ] Create feature branch for migration
- [ ] Run existing tests to establish baseline
- [ ] Document current Prisma version

## Schema Assessment

- [ ] Search for Bytes fields: `grep "Bytes" prisma/schema.prisma`
- [ ] Search for implicit m-n relations (no explicit join table)
- [ ] Search for reserved keywords: `grep -E "^\s*(async|await|using)\s" prisma/schema.prisma`
- [ ] List all models and relations

## Code Assessment

- [ ] Find Buffer usage: `grep -r "Buffer\\.from\\|Buffer\\.alloc" --include="*.ts"`
- [ ] Find toString on Bytes: `grep -r "\\.toString(" --include="*.ts"`
- [ ] Find NotFoundError: `grep -r "NotFoundError" --include="*.ts"`
- [ ] Document all locations requiring changes

## Update Dependencies

- [ ] Update package.json: `npm install prisma@6 @prisma/client@6`
- [ ] Regenerate client: `npx prisma generate`
- [ ] Verify TypeScript errors appear (expected)

## Schema Migration

- [ ] Rename any reserved keyword fields/models
- [ ] Add `@map()` to maintain database compatibility
- [ ] Run `npx prisma migrate dev --name v6-upgrade`
- [ ] Review generated migration SQL
- [ ] Test migration on development database

## Code Updates: Buffer → Uint8Array

- [ ] Create TextEncoder/TextDecoder instances
- [ ] Replace `Buffer.from(str, 'utf-8')` with `encoder.encode(str)`
- [ ] Replace `buffer.toString('utf-8')` with `decoder.decode(uint8array)`
- [ ] Update type annotations: `Buffer` → `Uint8Array`
- [ ] Handle edge cases (binary data, non-UTF8 encodings)

## Code Updates: NotFoundError → P2025

- [ ] Remove `NotFoundError` imports
- [ ] Replace `error instanceof NotFoundError` with P2025 checks
- [ ] Import `Prisma` from '@prisma/client'
- [ ] Use `Prisma.PrismaClientKnownRequestError` type guard
- [ ] Create helper functions for common error checks

## Testing

- [ ] Run TypeScript compiler: `npx tsc --noEmit`
- [ ] Fix any remaining type errors
- [ ] Run unit tests
- [ ] Run integration tests
- [ ] Test Bytes field operations manually
- [ ] Test not-found error handling
- [ ] Test implicit m-n queries

## Production Deployment

- [ ] Review migration SQL one final time
- [ ] Plan maintenance window if needed
- [ ] Deploy migration: `npx prisma migrate deploy`
- [ ] Deploy application code
- [ ] Monitor error logs for issues
- [ ] Verify Bytes operations work correctly
- [ ] Rollback plan ready if needed

# Prisma 6 Migration Troubleshooting

## Issue: Type error on Bytes field

**Error:**
```
Type 'Buffer' is not assignable to type 'Uint8Array'
```

**Solution:**
Replace Buffer operations with TextEncoder/TextDecoder or use Uint8Array directly.

## Issue: Migration fails with duplicate key

**Error:**
```
ERROR: duplicate key value violates unique constraint "_CategoryToPost_AB_unique"
```

**Solution:**
Implicit m-n tables may have duplicate entries. Clean data before migration:
```sql
DELETE FROM "_CategoryToPost" a USING "_CategoryToPost" b
WHERE a.ctid < b.ctid AND a."A" = b."A" AND a."B" = b."B";
```

## Issue: NotFoundError import fails

**Error:**
```
Module '"@prisma/client"' has no exported member 'NotFoundError'
```

**Solution:**
Remove NotFoundError import, use P2025 error code checking instead.

## Issue: Reserved keyword compilation error

**Error:**
```
'async' is a reserved word
```

**Solution:**
Rename field in schema with `@map()` to preserve database column name.

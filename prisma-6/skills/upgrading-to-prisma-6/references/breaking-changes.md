# Prisma 6 Breaking Changes - Detailed Reference

## 1. Buffer → Uint8Array

**Before (Prisma 5):**
```typescript
const user = await prisma.user.create({
  data: {
    name: 'Alice',
    data: Buffer.from('hello', 'utf-8')
  }
})

const text = user.data.toString('utf-8')
```

**After (Prisma 6):**
```typescript
const encoder = new TextEncoder()
const decoder = new TextDecoder()

const user = await prisma.user.create({
  data: {
    name: 'Alice',
    data: encoder.encode('hello')
  }
})

const text = decoder.decode(user.data)
```

**Type Changes:**
- Schema `Bytes` type now maps to `Uint8Array` instead of `Buffer`
- All database binary data returned as `Uint8Array`
- `Buffer` methods no longer available on Bytes fields

**Migration Steps:**
1. Find all Buffer operations: `grep -r "Buffer.from\|\.toString(" --include="*.ts" --include="*.js"`
2. Replace with TextEncoder/TextDecoder
3. Update type annotations: `Buffer` → `Uint8Array`

## 2. Implicit Many-to-Many Primary Keys

**Before (Prisma 5):**
Implicit m-n join tables had auto-generated integer primary keys.

**After (Prisma 6):**
Implicit m-n join tables use compound primary keys based on foreign keys.

**Example Schema:**
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

**Migration Impact:**
- Prisma generates `_CategoryToPost` join table
- **Prisma 5**: PK was auto-increment `id`
- **Prisma 6**: PK is compound `(A, B)` where A/B are foreign keys

**Migration:**
```sql
ALTER TABLE "_CategoryToPost" DROP CONSTRAINT "_CategoryToPost_pkey";
ALTER TABLE "_CategoryToPost" ADD CONSTRAINT "_CategoryToPost_AB_pkey" PRIMARY KEY ("A", "B");
```

This migration is auto-generated when running `prisma migrate dev` after upgrading.

**Action Required:**
- Run migration in development
- Review generated SQL before production deploy
- No code changes needed (Prisma Client handles internally)

## 3. NotFoundError → P2025 Error Code

**Before (Prisma 5):**
```typescript
import { PrismaClient, NotFoundError } from '@prisma/client'

try {
  const user = await prisma.user.delete({
    where: { id: 999 }
  })
} catch (error) {
  if (error instanceof NotFoundError) {
    console.log('User not found')
  }
}
```

**After (Prisma 6):**
```typescript
import { PrismaClient, Prisma } from '@prisma/client'

try {
  const user = await prisma.user.delete({
    where: { id: 999 }
  })
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2025') {
      console.log('User not found')
    }
  }
}
```

**Type Guard Pattern:**
```typescript
function isNotFoundError(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2025'
  )
}

try {
  const user = await prisma.user.delete({ where: { id: 999 } })
} catch (error) {
  if (isNotFoundError(error)) {
    console.log('User not found')
  }
  throw error
}
```

**Migration Steps:**
1. Find all NotFoundError usage: `grep -r "NotFoundError" --include="*.ts"`
2. Remove NotFoundError imports
3. Replace error class checks with P2025 code checks
4. Use `Prisma.PrismaClientKnownRequestError` type guard

## 4. Reserved Keywords

**Breaking Change:**
The following field/model names are now reserved:
- `async`
- `await`
- `using`

**Before (Prisma 5):**
```prisma
model Task {
  id    Int     @id @default(autoincrement())
  async Boolean
}
```

**After (Prisma 6):**
```prisma
model Task {
  id        Int     @id @default(autoincrement())
  isAsync   Boolean @map("async")
}
```

**Migration Steps:**
1. Find reserved keywords in schema: `grep -E "^\s*(async|await|using)\s" schema.prisma`
2. Rename fields/models with descriptive alternatives
3. Use `@map()` to maintain database column names
4. Update all application code references

**Recommended Renames:**
- `async` → `isAsync`, `asyncMode`, `asynchronous`
- `await` → `awaitStatus`, `pending`, `waitingFor`
- `using` → `inUse`, `isActive`, `usage`

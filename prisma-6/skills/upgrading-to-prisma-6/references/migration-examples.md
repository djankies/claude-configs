# Prisma 6 Migration Examples

## Example 1: Complete Bytes Field Migration

**Schema:**
```prisma
model Document {
  id      Int    @id @default(autoincrement())
  content Bytes
}
```

**Before (Prisma 5):**
```typescript
const doc = await prisma.document.create({
  data: {
    content: Buffer.from('Important document content', 'utf-8')
  }
})

console.log(doc.content.toString('utf-8'))
```

**After (Prisma 6):**
```typescript
const encoder = new TextEncoder()
const decoder = new TextDecoder()

const doc = await prisma.document.create({
  data: {
    content: encoder.encode('Important document content')
  }
})

console.log(decoder.decode(doc.content))
```

**Binary Data (non-text):**
```typescript
const binaryData = new Uint8Array([0x48, 0x65, 0x6c, 0x6c, 0x6f])

const doc = await prisma.document.create({
  data: {
    content: binaryData
  }
})

const retrieved = await prisma.document.findUnique({ where: { id: doc.id } })
console.log(retrieved.content)
```

## Example 2: NotFoundError Migration

**Before (Prisma 5):**
```typescript
import { PrismaClient, NotFoundError } from '@prisma/client'

async function deleteUser(id: number) {
  try {
    const user = await prisma.user.delete({ where: { id } })
    return { success: true, user }
  } catch (error) {
    if (error instanceof NotFoundError) {
      return { success: false, error: 'User not found' }
    }
    throw error
  }
}
```

**After (Prisma 6):**
```typescript
import { PrismaClient, Prisma } from '@prisma/client'

async function deleteUser(id: number) {
  try {
    const user = await prisma.user.delete({ where: { id } })
    return { success: true, user }
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2025') {
        return { success: false, error: 'User not found' }
      }
    }
    throw error
  }
}
```

**Reusable Helper:**
```typescript
import { Prisma } from '@prisma/client'

export function isPrismaNotFoundError(
  error: unknown
): error is Prisma.PrismaClientKnownRequestError {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2025'
  )
}

async function deleteUser(id: number) {
  try {
    const user = await prisma.user.delete({ where: { id } })
    return { success: true, user }
  } catch (error) {
    if (isPrismaNotFoundError(error)) {
      return { success: false, error: 'User not found' }
    }
    throw error
  }
}
```

## Example 3: Reserved Keyword Migration

**Before (Prisma 5):**
```prisma
model Task {
  id    Int     @id @default(autoincrement())
  async Boolean
  await String?
}
```

**After (Prisma 6):**
```prisma
model Task {
  id        Int     @id @default(autoincrement())
  isAsync   Boolean @map("async")
  awaitMsg  String? @map("await")
}
```

**Code Update:**
```typescript

const task = await prisma.task.create({
  data: {
    isAsync: true,
    awaitMsg: 'Waiting for completion'
  }
})

console.log(task.isAsync)
console.log(task.awaitMsg)
```

**Database columns remain unchanged** (`async`, `await`), but TypeScript code uses new names.

## Example 4: Implicit Many-to-Many Migration

**Schema:**
```prisma
model Post {
  id         Int        @id @default(autoincrement())
  title      String
  categories Category[]
}

model Category {
  id    Int    @id @default(autoincrement())
  name  String
  posts Post[]
}
```

**Auto-Generated Migration:**
```sql
ALTER TABLE "_CategoryToPost" DROP CONSTRAINT "_CategoryToPost_pkey";
ALTER TABLE "_CategoryToPost" ADD CONSTRAINT "_CategoryToPost_AB_pkey"
  PRIMARY KEY ("A", "B");
```

**No code changes needed**:
```typescript
const post = await prisma.post.create({
  data: {
    title: 'Hello World',
    categories: {
      connect: [{ id: 1 }, { id: 2 }]
    }
  }
})

const postWithCategories = await prisma.post.findUnique({
  where: { id: post.id },
  include: { categories: true }
})
```

**Migration runs automatically** when you run `npx prisma migrate dev` after upgrading to Prisma 6.

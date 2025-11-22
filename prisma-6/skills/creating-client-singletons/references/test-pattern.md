# Test Pattern

Proper test setup with PrismaClient singleton ensures test isolation and prevents connection exhaustion.

## Test File Setup

**Import singleton, don't create:**

```typescript
import { prisma } from '@/lib/prisma'

describe('User operations', () => {
  beforeEach(async () => {
    await prisma.user.deleteMany()
  })

  it('creates user', async () => {
    const user = await prisma.user.create({
      data: { email: 'test@example.com' }
    })
    expect(user.email).toBe('test@example.com')
  })

  afterAll(async () => {
    await prisma.$disconnect()
  })
})
```

**Key Points:**

- Import singleton, don't create
- Clean state with `deleteMany` or transactions
- Disconnect once at end of suite
- Don't disconnect between tests (kills connection pool)

---

## Test Isolation with Transactions

**Better approach for test isolation:**

```typescript
import { prisma } from '@/lib/prisma'
import { PrismaClient } from '@prisma/client'

describe('User operations', () => {
  let testPrisma: Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use'>

  beforeEach(async () => {
    await prisma.$transaction(async (tx) => {
      testPrisma = tx
      await tx.user.deleteMany()
    })
  })

  it('creates user', async () => {
    const user = await testPrisma.user.create({
      data: { email: 'test@example.com' }
    })
    expect(user.email).toBe('test@example.com')
  })
})
```

**Why this works:**

- Each test runs in transaction
- Automatic rollback after test
- No data leakage between tests
- Faster than deleteMany

---

## Mocking PrismaClient for Unit Tests

**When to mock:**

- Testing business logic without database
- Fast unit tests
- CI/CD pipeline optimization

**File: `__mocks__/prisma.ts`**

```typescript
import { PrismaClient } from '@prisma/client'
import { mockDeep, mockReset, DeepMockProxy } from 'jest-mock-extended'

export const prismaMock = mockDeep<PrismaClient>()

beforeEach(() => {
  mockReset(prismaMock)
})
```

**File: `__tests__/userService.test.ts`**

```typescript
import { prismaMock } from '../__mocks__/prisma'
import { createUser } from '../services/userService'

jest.mock('@/lib/prisma', () => ({
  __esModule: true,
  default: prismaMock,
}))

describe('User Service', () => {
  it('creates user with email', async () => {
    const mockUser = { id: '1', email: 'test@example.com' }

    prismaMock.user.create.mockResolvedValue(mockUser)

    const user = await createUser('test@example.com')

    expect(user.email).toBe('test@example.com')
    expect(prismaMock.user.create).toHaveBeenCalledWith({
      data: { email: 'test@example.com' }
    })
  })
})
```

**Key Points:**

- Mock the singleton module, not PrismaClient
- Reset mocks between tests
- Type-safe mocks with jest-mock-extended
- Fast tests without database

---

## Integration Test Setup

**File: `tests/setup.ts`**

```typescript
import { prisma } from '@/lib/prisma'

beforeAll(async () => {
  await prisma.$connect()
})

afterAll(async () => {
  await prisma.$disconnect()
})

export async function cleanDatabase() {
  const tables = ['User', 'Post', 'Comment']

  for (const table of tables) {
    await prisma[table.toLowerCase()].deleteMany()
  }
}
```

**File: `tests/users.integration.test.ts`**

```typescript
import { prisma } from '@/lib/prisma'
import { cleanDatabase } from './setup'

describe('User Integration Tests', () => {
  beforeEach(async () => {
    await cleanDatabase()
  })

  it('creates and retrieves user', async () => {
    const created = await prisma.user.create({
      data: { email: 'test@example.com' }
    })

    const retrieved = await prisma.user.findUnique({
      where: { id: created.id }
    })

    expect(retrieved?.email).toBe('test@example.com')
  })

  it('handles unique constraint', async () => {
    await prisma.user.create({
      data: { email: 'test@example.com' }
    })

    await expect(
      prisma.user.create({
        data: { email: 'test@example.com' }
      })
    ).rejects.toThrow(/Unique constraint/)
  })
})
```

**Key Points:**

- Shared setup in `tests/setup.ts`
- Clean database between tests
- Test real database behavior
- Catch constraint violations

---

## Anti-Pattern: Creating Client in Tests

**WRONG:**

```typescript
import { PrismaClient } from '@prisma/client'

describe('User tests', () => {
  let prisma: PrismaClient

  beforeEach(() => {
    prisma = new PrismaClient()
  })

  afterEach(async () => {
    await prisma.$disconnect()
  })

  it('creates user', async () => {
    const user = await prisma.user.create({
      data: { email: 'test@example.com' }
    })
    expect(user.email).toBe('test@example.com')
  })
})
```

**Problems:**

- New connection pool every test
- Connect/disconnect overhead
- Connection exhaustion in large suites
- Slow tests

**Fix:**

```typescript
import { prisma } from '@/lib/prisma'

describe('User tests', () => {
  beforeEach(async () => {
    await prisma.user.deleteMany()
  })

  it('creates user', async () => {
    const user = await prisma.user.create({
      data: { email: 'test@example.com' }
    })
    expect(user.email).toBe('test@example.com')
  })
})
```

**Result:**

- Reuses singleton connection
- Fast tests
- No connection exhaustion

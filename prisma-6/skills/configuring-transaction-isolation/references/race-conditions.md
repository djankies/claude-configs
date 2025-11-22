# Preventing Race Conditions

## Lost Update Problem

**Scenario:** Two transactions read the same value, both update it, one overwrites the other.

**Without Isolation:**

```typescript
const product = await prisma.product.findUnique({
  where: { id: productId }
});

await prisma.product.update({
  where: { id: productId },
  data: { stock: product.stock - quantity }
});
```

Transaction A reads stock: 10
Transaction B reads stock: 10
Transaction A writes stock: 5 (10 - 5)
Transaction B writes stock: 8 (10 - 2)
Result: Stock is 8, but should be 3

**With Serializable Isolation:**

```typescript
await prisma.$transaction(
  async (tx) => {
    const product = await tx.product.findUnique({
      where: { id: productId }
    });

    if (product.stock < quantity) {
      throw new Error('Insufficient stock');
    }

    await tx.product.update({
      where: { id: productId },
      data: { stock: { decrement: quantity } }
    });
  },
  {
    isolationLevel: Prisma.TransactionIsolationLevel.Serializable
  }
);
```

One transaction succeeds, the other gets P2034 and retries with fresh data.

## Double-Booking Problem

**Scenario:** Two users try to book the same resource simultaneously.

**Solution:**

```typescript
async function bookSeat(userId: string, seatId: string) {
  try {
    await prisma.$transaction(
      async (tx) => {
        const seat = await tx.seat.findUnique({
          where: { id: seatId }
        });

        if (seat.status !== 'AVAILABLE') {
          throw new Error('Seat no longer available');
        }

        await tx.seat.update({
          where: { id: seatId },
          data: {
            status: 'BOOKED',
            userId,
            bookedAt: new Date()
          }
        });
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable
      }
    );

    return { success: true };
  } catch (error) {
    if (error.code === 'P2034') {
      throw new Error('Seat was just booked by another user');
    }
    throw error;
  }
}
```

## Phantom Read Problem

**Scenario:** Query for rows matching a condition, insert happens, re-query shows different results.

**Example with RepeatableRead:**

```typescript
await prisma.$transaction(
  async (tx) => {
    const activeUsers = await tx.user.findMany({
      where: { status: 'ACTIVE' }
    });

    const count = activeUsers.length;

    await tx.report.create({
      data: {
        type: 'USER_COUNT',
        value: count,
        timestamp: new Date()
      }
    });
  },
  {
    isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead
  }
);
```

RepeatableRead prevents other transactions from changing existing rows, but may still allow new inserts (phantom reads) depending on database implementation.

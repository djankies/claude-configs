# Complete Examples

## Example 1: Banking Transfer

**Input:** Transfer money between accounts with strict consistency.

**Implementation:**

```typescript
import { Prisma } from '@prisma/client';

async function transferMoney(
  fromAccountId: string,
  toAccountId: string,
  amount: number
) {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }

  try {
    const result = await prisma.$transaction(
      async (tx) => {
        const fromAccount = await tx.account.findUnique({
          where: { id: fromAccountId }
        });

        if (!fromAccount) {
          throw new Error('Source account not found');
        }

        if (fromAccount.balance < amount) {
          throw new Error('Insufficient funds');
        }

        const toAccount = await tx.account.findUnique({
          where: { id: toAccountId }
        });

        if (!toAccount) {
          throw new Error('Destination account not found');
        }

        await tx.account.update({
          where: { id: fromAccountId },
          data: { balance: { decrement: amount } }
        });

        await tx.account.update({
          where: { id: toAccountId },
          data: { balance: { increment: amount } }
        });

        const transfer = await tx.transfer.create({
          data: {
            fromAccountId,
            toAccountId,
            amount,
            status: 'COMPLETED',
            completedAt: new Date()
          }
        });

        return transfer;
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        maxWait: 5000,
        timeout: 10000
      }
    );

    return { success: true, transfer: result };

  } catch (error) {
    if (error.code === 'P2034') {
      throw new Error('Transaction conflict - please retry');
    }
    throw error;
  }
}
```

## Example 2: Inventory Reservation

**Input:** Reserve inventory items for an order.

**Implementation:**

```typescript
async function reserveInventory(
  orderId: string,
  items: Array<{ productId: string; quantity: number }>
) {
  const maxRetries = 3;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      await prisma.$transaction(
        async (tx) => {
          for (const item of items) {
            const product = await tx.product.findUnique({
              where: { id: item.productId }
            });

            if (!product) {
              throw new Error(`Product ${item.productId} not found`);
            }

            if (product.stock < item.quantity) {
              throw new Error(
                `Insufficient stock for ${product.name}`
              );
            }

            await tx.product.update({
              where: { id: item.productId },
              data: { stock: { decrement: item.quantity } }
            });

            await tx.reservation.create({
              data: {
                orderId,
                productId: item.productId,
                quantity: item.quantity,
                reservedAt: new Date()
              }
            });
          }
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
          maxWait: 3000,
          timeout: 8000
        }
      );

      return { success: true };

    } catch (error) {
      if (error.code === 'P2034' && attempt < maxRetries - 1) {
        await new Promise(resolve =>
          setTimeout(resolve, Math.pow(2, attempt) * 200)
        );
        continue;
      }

      throw error;
    }
  }

  throw new Error('Reservation failed after retries');
}
```

## Example 3: Seat Booking with Status Check

**Input:** Book a seat with concurrent user protection.

**Implementation:**

```typescript
async function bookSeat(
  userId: string,
  eventId: string,
  seatNumber: string
) {
  try {
    const booking = await prisma.$transaction(
      async (tx) => {
        const seat = await tx.seat.findFirst({
          where: {
            eventId,
            seatNumber
          }
        });

        if (!seat) {
          throw new Error('Seat not found');
        }

        if (seat.status !== 'AVAILABLE') {
          throw new Error('Seat is no longer available');
        }

        await tx.seat.update({
          where: { id: seat.id },
          data: {
            status: 'BOOKED',
            bookedAt: new Date()
          }
        });

        const booking = await tx.booking.create({
          data: {
            userId,
            seatId: seat.id,
            eventId,
            status: 'CONFIRMED',
            bookedAt: new Date()
          }
        });

        return booking;
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable
      }
    );

    return { success: true, booking };

  } catch (error) {
    if (error.code === 'P2034') {
      throw new Error(
        'Seat was just booked by another user - please select another seat'
      );
    }
    throw error;
  }
}
```

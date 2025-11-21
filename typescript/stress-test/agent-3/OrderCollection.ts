import { Collection } from './Collection';
import { Order, ValidationError } from './types';

export class OrderCollection extends Collection<Order> {
  constructor() {
    super('Order');
  }

  findByUserId(userId: string): Order[] {
    return this.filter(order => order.userId === userId);
  }

  findByStatus(status: Order['status']): Order[] {
    return this.filter(order => order.status === status);
  }

  findByProductId(productId: string): Order[] {
    return this.filter(order => order.productIds.includes(productId));
  }

  findPending(): Order[] {
    return this.findByStatus('pending');
  }

  findProcessing(): Order[] {
    return this.findByStatus('processing');
  }

  findShipped(): Order[] {
    return this.findByStatus('shipped');
  }

  findDelivered(): Order[] {
    return this.findByStatus('delivered');
  }

  findCancelled(): Order[] {
    return this.findByStatus('cancelled');
  }

  findByAmountRange(minAmount: number, maxAmount: number): Order[] {
    return this.filter(order => order.totalAmount >= minAmount && order.totalAmount <= maxAmount);
  }

  create(entity: Omit<Order, 'id' | 'createdAt' | 'updatedAt'>, id?: string): Order {
    this.validateOrder(entity);
    return super.create(entity, id);
  }

  update(id: string, updates: Partial<Omit<Order, 'id' | 'createdAt'>>): Order {
    if (updates.totalAmount !== undefined && updates.totalAmount < 0) {
      throw new ValidationError('Total amount cannot be negative');
    }

    if (updates.productIds !== undefined && updates.productIds.length === 0) {
      throw new ValidationError('Order must contain at least one product');
    }

    return super.update(id, updates);
  }

  updateStatus(orderId: string, newStatus: Order['status']): Order {
    const order = this.read(orderId);

    if (order.status === 'cancelled') {
      throw new ValidationError('Cannot update status of cancelled order');
    }

    if (order.status === 'delivered' && newStatus !== 'delivered') {
      throw new ValidationError('Cannot change status of delivered order');
    }

    return this.update(orderId, { status: newStatus });
  }

  markAsProcessing(orderId: string): Order {
    return this.updateStatus(orderId, 'processing');
  }

  markAsShipped(orderId: string): Order {
    return this.updateStatus(orderId, 'shipped');
  }

  markAsDelivered(orderId: string): Order {
    return this.updateStatus(orderId, 'delivered');
  }

  cancelOrder(orderId: string): Order {
    const order = this.read(orderId);

    if (order.status === 'delivered') {
      throw new ValidationError('Cannot cancel delivered order');
    }

    if (order.status === 'shipped') {
      throw new ValidationError('Cannot cancel shipped order');
    }

    return this.update(orderId, { status: 'cancelled' });
  }

  getTotalRevenue(): number {
    return this.filter(order => order.status !== 'cancelled').reduce(
      (total, order) => total + order.totalAmount,
      0
    );
  }

  getRevenueByStatus(status: Order['status']): number {
    return this.findByStatus(status).reduce((total, order) => total + order.totalAmount, 0);
  }

  getUserOrderCount(userId: string): number {
    return this.findByUserId(userId).length;
  }

  getUserTotalSpent(userId: string): number {
    return this.findByUserId(userId)
      .filter(order => order.status !== 'cancelled')
      .reduce((total, order) => total + order.totalAmount, 0);
  }

  getAverageOrderValue(): number {
    const completedOrders = this.filter(order => order.status !== 'cancelled');
    if (completedOrders.length === 0) return 0;

    const total = completedOrders.reduce((sum, order) => sum + order.totalAmount, 0);
    return total / completedOrders.length;
  }

  private validateOrder(entity: Omit<Order, 'id' | 'createdAt' | 'updatedAt'>): void {
    if (!entity.userId || entity.userId.trim().length === 0) {
      throw new ValidationError('User ID is required');
    }

    if (!entity.productIds || entity.productIds.length === 0) {
      throw new ValidationError('Order must contain at least one product');
    }

    if (entity.totalAmount < 0) {
      throw new ValidationError('Total amount cannot be negative');
    }

    if (!entity.shippingAddress || entity.shippingAddress.trim().length === 0) {
      throw new ValidationError('Shipping address is required');
    }
  }
}

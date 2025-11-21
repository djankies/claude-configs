export interface BaseEntity {
  id: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface User extends BaseEntity {
  name: string;
  email: string;
  role: 'admin' | 'user' | 'guest';
}

export interface Product extends BaseEntity {
  name: string;
  description: string;
  price: number;
  stock: number;
  category: string;
}

export interface Order extends BaseEntity {
  userId: string;
  productIds: string[];
  totalAmount: number;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  shippingAddress: string;
}

export type EntityType = User | Product | Order;

export interface FilterCriteria<T> {
  field: keyof T;
  operator: 'eq' | 'neq' | 'gt' | 'lt' | 'gte' | 'lte' | 'contains' | 'in';
  value: any;
}

export interface SearchOptions<T> {
  filters?: FilterCriteria<T>[];
  sortBy?: keyof T;
  sortOrder?: 'asc' | 'desc';
  limit?: number;
  offset?: number;
}

export interface CollectionResult<T> {
  data: T[];
  total: number;
  offset: number;
  limit: number;
}

export class EntityNotFoundError extends Error {
  constructor(id: string, entityType: string) {
    super(`${entityType} with id '${id}' not found`);
    this.name = 'EntityNotFoundError';
  }
}

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class DuplicateEntityError extends Error {
  constructor(id: string, entityType: string) {
    super(`${entityType} with id '${id}' already exists`);
    this.name = 'DuplicateEntityError';
  }
}

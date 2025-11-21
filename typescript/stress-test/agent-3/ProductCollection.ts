import { Collection } from './Collection';
import { Product, ValidationError } from './types';

export class ProductCollection extends Collection<Product> {
  constructor() {
    super('Product');
  }

  findByCategory(category: string): Product[] {
    return this.filter(product => product.category === category);
  }

  findByPriceRange(minPrice: number, maxPrice: number): Product[] {
    return this.filter(product => product.price >= minPrice && product.price <= maxPrice);
  }

  findInStock(): Product[] {
    return this.filter(product => product.stock > 0);
  }

  findOutOfStock(): Product[] {
    return this.filter(product => product.stock === 0);
  }

  findByName(name: string): Product[] {
    return this.filter(product => product.name.toLowerCase().includes(name.toLowerCase()));
  }

  searchByDescription(query: string): Product[] {
    return this.filter(product =>
      product.description.toLowerCase().includes(query.toLowerCase())
    );
  }

  getAllCategories(): string[] {
    const categories = new Set(this.map(product => product.category));
    return Array.from(categories).sort();
  }

  create(entity: Omit<Product, 'id' | 'createdAt' | 'updatedAt'>, id?: string): Product {
    this.validateProduct(entity);
    return super.create(entity, id);
  }

  update(id: string, updates: Partial<Omit<Product, 'id' | 'createdAt'>>): Product {
    if (updates.price !== undefined && updates.price < 0) {
      throw new ValidationError('Price cannot be negative');
    }

    if (updates.stock !== undefined && updates.stock < 0) {
      throw new ValidationError('Stock cannot be negative');
    }

    if (updates.name !== undefined && (!updates.name || updates.name.trim().length === 0)) {
      throw new ValidationError('Product name cannot be empty');
    }

    return super.update(id, updates);
  }

  updateStock(productId: string, quantity: number): Product {
    const product = this.read(productId);
    const newStock = product.stock + quantity;

    if (newStock < 0) {
      throw new ValidationError('Insufficient stock');
    }

    return this.update(productId, { stock: newStock });
  }

  decrementStock(productId: string, quantity: number): Product {
    return this.updateStock(productId, -quantity);
  }

  incrementStock(productId: string, quantity: number): Product {
    return this.updateStock(productId, quantity);
  }

  updatePrice(productId: string, newPrice: number): Product {
    if (newPrice < 0) {
      throw new ValidationError('Price cannot be negative');
    }

    return this.update(productId, { price: newPrice });
  }

  getTotalInventoryValue(): number {
    return this.reduce((total, product) => total + product.price * product.stock, 0);
  }

  getTotalStockCount(): number {
    return this.reduce((total, product) => total + product.stock, 0);
  }

  private validateProduct(entity: Omit<Product, 'id' | 'createdAt' | 'updatedAt'>): void {
    if (!entity.name || entity.name.trim().length === 0) {
      throw new ValidationError('Product name is required');
    }

    if (entity.price < 0) {
      throw new ValidationError('Price cannot be negative');
    }

    if (entity.stock < 0) {
      throw new ValidationError('Stock cannot be negative');
    }

    if (!entity.category || entity.category.trim().length === 0) {
      throw new ValidationError('Category is required');
    }
  }
}

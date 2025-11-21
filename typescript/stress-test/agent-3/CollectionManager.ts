import { Collection } from './Collection';
import { BaseEntity } from './types';

export class CollectionManager {
  private collections: Map<string, Collection<any>>;

  constructor() {
    this.collections = new Map();
  }

  registerCollection<T extends BaseEntity>(name: string): Collection<T> {
    if (this.collections.has(name)) {
      return this.collections.get(name)!;
    }

    const collection = new Collection<T>(name);
    this.collections.set(name, collection);
    return collection;
  }

  getCollection<T extends BaseEntity>(name: string): Collection<T> {
    const collection = this.collections.get(name);

    if (!collection) {
      throw new Error(`Collection '${name}' not found. Please register it first.`);
    }

    return collection;
  }

  hasCollection(name: string): boolean {
    return this.collections.has(name);
  }

  removeCollection(name: string): boolean {
    return this.collections.delete(name);
  }

  clearAll(): void {
    this.collections.forEach(collection => collection.deleteAll());
  }

  getAllCollectionNames(): string[] {
    return Array.from(this.collections.keys());
  }

  getStats(): Record<string, number> {
    const stats: Record<string, number> = {};

    this.collections.forEach((collection, name) => {
      stats[name] = collection.count();
    });

    return stats;
  }

  exportAll(): Record<string, any[]> {
    const data: Record<string, any[]> = {};

    this.collections.forEach((collection, name) => {
      data[name] = collection.toJSON();
    });

    return data;
  }

  importAll(data: Record<string, any[]>): void {
    Object.entries(data).forEach(([name, items]) => {
      const collection = this.collections.get(name);
      if (collection) {
        collection.fromJSON(items);
      }
    });
  }
}

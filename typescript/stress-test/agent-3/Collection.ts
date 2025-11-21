import {
  BaseEntity,
  FilterCriteria,
  SearchOptions,
  CollectionResult,
  EntityNotFoundError,
  ValidationError,
  DuplicateEntityError,
} from './types';

export class Collection<T extends BaseEntity> {
  private items: Map<string, T>;
  private readonly entityName: string;

  constructor(entityName: string) {
    this.items = new Map<string, T>();
    this.entityName = entityName;
  }

  create(entity: Omit<T, 'id' | 'createdAt' | 'updatedAt'>, id?: string): T {
    const entityId = id || this.generateId();

    if (this.items.has(entityId)) {
      throw new DuplicateEntityError(entityId, this.entityName);
    }

    const now = new Date();
    const newEntity = {
      ...entity,
      id: entityId,
      createdAt: now,
      updatedAt: now,
    } as T;

    this.validate(newEntity);
    this.items.set(entityId, newEntity);

    return newEntity;
  }

  read(id: string): T {
    const entity = this.items.get(id);

    if (!entity) {
      throw new EntityNotFoundError(id, this.entityName);
    }

    return { ...entity };
  }

  readOrNull(id: string): T | null {
    const entity = this.items.get(id);
    return entity ? { ...entity } : null;
  }

  update(id: string, updates: Partial<Omit<T, 'id' | 'createdAt'>>): T {
    const entity = this.items.get(id);

    if (!entity) {
      throw new EntityNotFoundError(id, this.entityName);
    }

    const updatedEntity = {
      ...entity,
      ...updates,
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: new Date(),
    } as T;

    this.validate(updatedEntity);
    this.items.set(id, updatedEntity);

    return { ...updatedEntity };
  }

  delete(id: string): T {
    const entity = this.items.get(id);

    if (!entity) {
      throw new EntityNotFoundError(id, this.entityName);
    }

    this.items.delete(id);
    return { ...entity };
  }

  deleteAll(): void {
    this.items.clear();
  }

  exists(id: string): boolean {
    return this.items.has(id);
  }

  count(): number {
    return this.items.size;
  }

  findById(id: string): T | null {
    return this.readOrNull(id);
  }

  findByIds(ids: string[]): T[] {
    return ids
      .map(id => this.items.get(id))
      .filter((item): item is T => item !== undefined)
      .map(item => ({ ...item }));
  }

  findAll(): T[] {
    return Array.from(this.items.values()).map(item => ({ ...item }));
  }

  search(options: SearchOptions<T> = {}): CollectionResult<T> {
    let results = Array.from(this.items.values());

    if (options.filters && options.filters.length > 0) {
      results = results.filter(item => this.matchesFilters(item, options.filters!));
    }

    if (options.sortBy) {
      results = this.sortResults(results, options.sortBy, options.sortOrder || 'asc');
    }

    const total = results.length;
    const offset = options.offset || 0;
    const limit = options.limit || total;

    const paginatedResults = results.slice(offset, offset + limit);

    return {
      data: paginatedResults.map(item => ({ ...item })),
      total,
      offset,
      limit,
    };
  }

  filter(predicate: (entity: T) => boolean): T[] {
    return Array.from(this.items.values())
      .filter(predicate)
      .map(item => ({ ...item }));
  }

  map<R>(mapper: (entity: T) => R): R[] {
    return Array.from(this.items.values()).map(mapper);
  }

  reduce<R>(reducer: (acc: R, entity: T) => R, initialValue: R): R {
    return Array.from(this.items.values()).reduce(reducer, initialValue);
  }

  some(predicate: (entity: T) => boolean): boolean {
    return Array.from(this.items.values()).some(predicate);
  }

  every(predicate: (entity: T) => boolean): boolean {
    return Array.from(this.items.values()).every(predicate);
  }

  private matchesFilters(item: T, filters: FilterCriteria<T>[]): boolean {
    return filters.every(filter => {
      const fieldValue = item[filter.field];
      const filterValue = filter.value;

      switch (filter.operator) {
        case 'eq':
          return fieldValue === filterValue;
        case 'neq':
          return fieldValue !== filterValue;
        case 'gt':
          return fieldValue > filterValue;
        case 'lt':
          return fieldValue < filterValue;
        case 'gte':
          return fieldValue >= filterValue;
        case 'lte':
          return fieldValue <= filterValue;
        case 'contains':
          if (typeof fieldValue === 'string' && typeof filterValue === 'string') {
            return fieldValue.toLowerCase().includes(filterValue.toLowerCase());
          }
          if (Array.isArray(fieldValue)) {
            return fieldValue.includes(filterValue);
          }
          return false;
        case 'in':
          if (Array.isArray(filterValue)) {
            return filterValue.includes(fieldValue);
          }
          return false;
        default:
          return false;
      }
    });
  }

  private sortResults(results: T[], sortBy: keyof T, sortOrder: 'asc' | 'desc'): T[] {
    return results.sort((a, b) => {
      const aVal = a[sortBy];
      const bVal = b[sortBy];

      let comparison = 0;

      if (aVal < bVal) comparison = -1;
      if (aVal > bVal) comparison = 1;

      return sortOrder === 'asc' ? comparison : -comparison;
    });
  }

  private validate(entity: T): void {
    if (!entity.id) {
      throw new ValidationError('Entity must have an id');
    }
  }

  private generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  toJSON(): T[] {
    return this.findAll();
  }

  fromJSON(data: T[]): void {
    this.items.clear();
    data.forEach(item => {
      this.items.set(item.id, item);
    });
  }

  clone(): Collection<T> {
    const newCollection = new Collection<T>(this.entityName);
    this.items.forEach((value, key) => {
      newCollection.items.set(key, { ...value });
    });
    return newCollection;
  }
}

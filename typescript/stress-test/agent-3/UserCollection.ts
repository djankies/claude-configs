import { Collection } from './Collection';
import { User, ValidationError } from './types';

export class UserCollection extends Collection<User> {
  constructor() {
    super('User');
  }

  findByEmail(email: string): User | null {
    return this.filter(user => user.email === email)[0] || null;
  }

  findByRole(role: User['role']): User[] {
    return this.filter(user => user.role === role);
  }

  findByName(name: string): User[] {
    return this.filter(user => user.name.toLowerCase().includes(name.toLowerCase()));
  }

  isEmailTaken(email: string, excludeId?: string): boolean {
    return this.some(user => user.email === email && user.id !== excludeId);
  }

  create(entity: Omit<User, 'id' | 'createdAt' | 'updatedAt'>, id?: string): User {
    if (!this.isValidEmail(entity.email)) {
      throw new ValidationError('Invalid email format');
    }

    if (this.isEmailTaken(entity.email)) {
      throw new ValidationError(`Email '${entity.email}' is already taken`);
    }

    if (!entity.name || entity.name.trim().length === 0) {
      throw new ValidationError('Name is required');
    }

    return super.create(entity, id);
  }

  update(id: string, updates: Partial<Omit<User, 'id' | 'createdAt'>>): User {
    if (updates.email) {
      if (!this.isValidEmail(updates.email)) {
        throw new ValidationError('Invalid email format');
      }

      if (this.isEmailTaken(updates.email, id)) {
        throw new ValidationError(`Email '${updates.email}' is already taken`);
      }
    }

    if (updates.name !== undefined && (!updates.name || updates.name.trim().length === 0)) {
      throw new ValidationError('Name cannot be empty');
    }

    return super.update(id, updates);
  }

  getAdmins(): User[] {
    return this.findByRole('admin');
  }

  promoteToAdmin(userId: string): User {
    return this.update(userId, { role: 'admin' });
  }

  demoteToUser(userId: string): User {
    return this.update(userId, { role: 'user' });
  }

  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
}

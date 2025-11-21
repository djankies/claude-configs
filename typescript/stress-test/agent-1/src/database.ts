import { UserRegistrationData } from './types';

export interface StoredUser extends UserRegistrationData {
  id: string;
  createdAt: Date;
}

export class Database {
  private users: Map<string, StoredUser> = new Map();
  private emailIndex: Map<string, string> = new Map();

  async saveUser(userData: UserRegistrationData): Promise<StoredUser> {
    const normalizedEmail = userData.email.toLowerCase().trim();

    if (this.emailIndex.has(normalizedEmail)) {
      throw new Error('Email already exists');
    }

    const userId = this.generateId();
    const user: StoredUser = {
      id: userId,
      email: normalizedEmail,
      name: userData.name.trim(),
      password: this.hashPassword(userData.password),
      createdAt: new Date()
    };

    this.users.set(userId, user);
    this.emailIndex.set(normalizedEmail, userId);

    return user;
  }

  async findByEmail(email: string): Promise<StoredUser | null> {
    const normalizedEmail = email.toLowerCase().trim();
    const userId = this.emailIndex.get(normalizedEmail);

    if (!userId) {
      return null;
    }

    return this.users.get(userId) || null;
  }

  async findById(id: string): Promise<StoredUser | null> {
    return this.users.get(id) || null;
  }

  private generateId(): string {
    return `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private hashPassword(password: string): string {
    return Buffer.from(password).toString('base64');
  }

  getStats() {
    return {
      totalUsers: this.users.size
    };
  }
}

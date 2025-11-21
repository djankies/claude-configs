import validator from 'validator';
import { UserRegistrationData, ValidationResult, ValidationError } from './types';

export class UserValidator {
  private errors: ValidationError[] = [];

  validate(data: UserRegistrationData): ValidationResult {
    this.errors = [];

    this.validateEmail(data.email);
    this.validateName(data.name);
    this.validatePassword(data.password);

    return {
      isValid: this.errors.length === 0,
      errors: this.errors
    };
  }

  private validateEmail(email: string): void {
    if (!email || email.trim() === '') {
      this.errors.push({
        field: 'email',
        message: 'Email is required'
      });
      return;
    }

    if (!validator.isEmail(email)) {
      this.errors.push({
        field: 'email',
        message: 'Invalid email format'
      });
    }

    if (email.length > 255) {
      this.errors.push({
        field: 'email',
        message: 'Email must not exceed 255 characters'
      });
    }
  }

  private validateName(name: string): void {
    if (!name || name.trim() === '') {
      this.errors.push({
        field: 'name',
        message: 'Name is required'
      });
      return;
    }

    if (name.length < 2) {
      this.errors.push({
        field: 'name',
        message: 'Name must be at least 2 characters long'
      });
    }

    if (name.length > 100) {
      this.errors.push({
        field: 'name',
        message: 'Name must not exceed 100 characters'
      });
    }

    if (!/^[a-zA-Z\s'-]+$/.test(name)) {
      this.errors.push({
        field: 'name',
        message: 'Name can only contain letters, spaces, hyphens, and apostrophes'
      });
    }
  }

  private validatePassword(password: string): void {
    if (!password || password.trim() === '') {
      this.errors.push({
        field: 'password',
        message: 'Password is required'
      });
      return;
    }

    if (password.length < 8) {
      this.errors.push({
        field: 'password',
        message: 'Password must be at least 8 characters long'
      });
    }

    if (password.length > 128) {
      this.errors.push({
        field: 'password',
        message: 'Password must not exceed 128 characters'
      });
    }

    if (!/(?=.*[a-z])/.test(password)) {
      this.errors.push({
        field: 'password',
        message: 'Password must contain at least one lowercase letter'
      });
    }

    if (!/(?=.*[A-Z])/.test(password)) {
      this.errors.push({
        field: 'password',
        message: 'Password must contain at least one uppercase letter'
      });
    }

    if (!/(?=.*\d)/.test(password)) {
      this.errors.push({
        field: 'password',
        message: 'Password must contain at least one number'
      });
    }

    if (!/(?=.*[@$!%*?&])/.test(password)) {
      this.errors.push({
        field: 'password',
        message: 'Password must contain at least one special character (@$!%*?&)'
      });
    }
  }
}

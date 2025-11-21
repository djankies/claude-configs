import type { ValidationError } from './types';

export function validateProfile(data: {
  name: string;
  email: string;
  bio: string;
}): ValidationError[] {
  const errors: ValidationError[] = [];

  if (!data.name || data.name.trim().length === 0) {
    errors.push({ field: 'name', message: 'Name is required' });
  } else if (data.name.length < 2) {
    errors.push({ field: 'name', message: 'Name must be at least 2 characters' });
  } else if (data.name.length > 100) {
    errors.push({ field: 'name', message: 'Name must not exceed 100 characters' });
  }

  if (!data.email || data.email.trim().length === 0) {
    errors.push({ field: 'email', message: 'Email is required' });
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)) {
    errors.push({ field: 'email', message: 'Email must be valid' });
  } else if (data.email.length > 255) {
    errors.push({ field: 'email', message: 'Email must not exceed 255 characters' });
  }

  if (!data.bio || data.bio.trim().length === 0) {
    errors.push({ field: 'bio', message: 'Bio is required' });
  } else if (data.bio.length < 10) {
    errors.push({ field: 'bio', message: 'Bio must be at least 10 characters' });
  } else if (data.bio.length > 500) {
    errors.push({ field: 'bio', message: 'Bio must not exceed 500 characters' });
  }

  return errors;
}

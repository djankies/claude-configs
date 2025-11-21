'use server';

import type { FormState, UserProfile } from './types';
import { validateProfile } from './validation';

const mockDatabase: Map<string, UserProfile> = new Map([
  [
    'user-1',
    {
      id: 'user-1',
      name: 'John Doe',
      email: 'john.doe@example.com',
      bio: 'Software engineer passionate about building great user experiences.',
    },
  ],
]);

export async function getUserProfile(userId: string): Promise<UserProfile | null> {
  await new Promise((resolve) => setTimeout(resolve, 100));

  return mockDatabase.get(userId) || null;
}

export async function updateProfile(
  userId: string,
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  await new Promise((resolve) => setTimeout(resolve, 500));

  const data = {
    name: formData.get('name') as string,
    email: formData.get('email') as string,
    bio: formData.get('bio') as string,
  };

  const errors = validateProfile(data);

  if (errors.length > 0) {
    return {
      errors,
      success: false,
      message: 'Please fix the errors below',
    };
  }

  const existingProfile = mockDatabase.get(userId);

  if (!existingProfile) {
    return {
      errors: [],
      success: false,
      message: 'User not found',
    };
  }

  const updatedProfile: UserProfile = {
    id: userId,
    name: data.name,
    email: data.email,
    bio: data.bio,
  };

  mockDatabase.set(userId, updatedProfile);

  return {
    errors: [],
    success: true,
    message: 'Profile updated successfully!',
  };
}

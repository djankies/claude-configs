import type { UserProfile } from './types';

export async function fetchUserProfile(userId: string): Promise<UserProfile> {
  const response = await fetch(`/api/users/${userId}/profile`);

  if (!response.ok) {
    throw new Error(`Failed to fetch profile: ${response.statusText}`);
  }

  return response.json();
}

export async function updateUserProfile(
  userId: string,
  data: Omit<UserProfile, 'id'>
): Promise<UserProfile> {
  const response = await fetch(`/api/users/${userId}/profile`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to update profile');
  }

  return response.json();
}

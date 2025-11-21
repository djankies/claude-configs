'use server';

interface AuthResult {
  success?: boolean;
  user?: {
    id: string;
    email: string;
    name: string;
  };
  error?: string;
  fieldErrors?: {
    email?: string;
    password?: string;
    name?: string;
  };
}

const mockUsers = new Map<string, { id: string; email: string; name: string; password: string }>();

function validateEmail(email: string): string | undefined {
  if (!email) {
    return 'Email is required';
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return 'Invalid email format';
  }
  return undefined;
}

function validatePassword(password: string): string | undefined {
  if (!password) {
    return 'Password is required';
  }
  if (password.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (!/[A-Z]/.test(password)) {
    return 'Password must contain at least one uppercase letter';
  }
  if (!/[a-z]/.test(password)) {
    return 'Password must contain at least one lowercase letter';
  }
  if (!/[0-9]/.test(password)) {
    return 'Password must contain at least one number';
  }
  return undefined;
}

function validateName(name: string): string | undefined {
  if (!name) {
    return 'Name is required';
  }
  if (name.length < 2) {
    return 'Name must be at least 2 characters';
  }
  return undefined;
}

export async function authenticateUser(
  prevState: AuthResult | null,
  formData: FormData
): Promise<AuthResult> {
  await new Promise(resolve => setTimeout(resolve, 1000));

  const mode = formData.get('mode') as 'login' | 'signup';
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;
  const name = formData.get('name') as string;

  const fieldErrors: AuthResult['fieldErrors'] = {};

  const emailError = validateEmail(email);
  if (emailError) {
    fieldErrors.email = emailError;
  }

  const passwordError = validatePassword(password);
  if (passwordError) {
    fieldErrors.password = passwordError;
  }

  if (mode === 'signup') {
    const nameError = validateName(name);
    if (nameError) {
      fieldErrors.name = nameError;
    }
  }

  if (Object.keys(fieldErrors).length > 0) {
    return { fieldErrors };
  }

  try {
    if (mode === 'signup') {
      if (mockUsers.has(email)) {
        return {
          error: 'An account with this email already exists',
        };
      }

      const userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const user = {
        id: userId,
        email,
        name,
        password,
      };

      mockUsers.set(email, user);

      return {
        success: true,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
        },
      };
    } else {
      const user = mockUsers.get(email);

      if (!user || user.password !== password) {
        return {
          error: 'Invalid email or password',
        };
      }

      return {
        success: true,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
        },
      };
    }
  } catch (error) {
    console.error('Authentication error:', error);
    return {
      error: 'An unexpected error occurred. Please try again.',
    };
  }
}

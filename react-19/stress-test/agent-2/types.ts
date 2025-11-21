export interface UserProfile {
  id: string;
  name: string;
  email: string;
  bio: string;
}

export interface ValidationError {
  field: string;
  message: string;
}

export interface FormState {
  errors: ValidationError[];
  success: boolean;
  message?: string;
}

# Password Strength Validation

## Complete Implementation

```typescript
interface PasswordRequirements {
  minLength: number;
  requireUppercase: boolean;
  requireLowercase: boolean;
  requireNumbers: boolean;
  requireSpecialChars: boolean;
}

const DEFAULT_REQUIREMENTS: PasswordRequirements = {
  minLength: 12,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true
};

function validatePasswordStrength(
  password: string,
  requirements: PasswordRequirements = DEFAULT_REQUIREMENTS
): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (password.length < requirements.minLength) {
    errors.push(`Password must be at least ${requirements.minLength} characters`);
  }

  if (requirements.requireUppercase && !/[A-Z]/.test(password)) {
    errors.push("Password must contain at least one uppercase letter");
  }

  if (requirements.requireLowercase && !/[a-z]/.test(password)) {
    errors.push("Password must contain at least one lowercase letter");
  }

  if (requirements.requireNumbers && !/[0-9]/.test(password)) {
    errors.push("Password must contain at least one number");
  }

  if (requirements.requireSpecialChars && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push("Password must contain at least one special character");
  }

  const commonPasswords = ["password", "12345678", "qwerty", "admin"];
  if (commonPasswords.some(common => password.toLowerCase().includes(common))) {
    errors.push("Password contains common patterns");
  }

  return {
    valid: errors.length === 0,
    errors
  };
}
```

## Best Practices

- Minimum 12 characters (prefer 16+)
- Mix of uppercase, lowercase, numbers, special characters
- Reject common passwords and patterns
- Provide user-friendly feedback
- Consider using zxcvbn for entropy estimation

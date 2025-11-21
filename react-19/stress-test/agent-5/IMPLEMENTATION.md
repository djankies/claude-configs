# Implementation Guide

This guide explains how the authentication modal system works and how to integrate it into your Next.js 15 + React 19 application.

## System Overview

The authentication system consists of several interconnected parts:

1. **AuthContext**: Global state management
2. **Modal Component**: Reusable portal-based modal
3. **AuthModal**: Login/signup form
4. **Server Action**: Authentication logic
5. **Custom Hook**: Bridge between server actions and context

## Flow Diagrams

### User Registration Flow

```
User clicks "Sign Up"
    ↓
Modal opens (useAuth.openModal())
    ↓
User fills form (name, email, password)
    ↓
Form submitted to Server Action
    ↓
Server validates inputs
    ↓
If valid: Create user in database
    ↓
Return user object
    ↓
useAuthAction hook receives response
    ↓
Calls context.login(user)
    ↓
Updates global state
    ↓
Saves to localStorage
    ↓
Modal closes automatically
    ↓
User is logged in across app
```

### User Login Flow

```
User clicks "Sign In"
    ↓
Modal opens with login form
    ↓
User enters email and password
    ↓
Form submitted to Server Action
    ↓
Server validates credentials
    ↓
If valid: Return user object
    ↓
Context updated via useAuthAction
    ↓
localStorage updated
    ↓
Modal closes
    ↓
User authenticated globally
```

## Core Components Explained

### 1. AuthContext Implementation

**Purpose**: Provide global authentication state to all components

**Key Features:**
- Manages user object and authentication status
- Handles theme preference
- Controls modal visibility
- Persists state to localStorage
- Handles hydration properly

**How it works:**

```typescript
// Provider wraps entire app
<AuthProvider>
  <App />
</AuthProvider>

// Any component can access auth state
const { user, isAuthenticated, openModal } = useAuth();
```

**State Persistence:**

```typescript
useEffect(() => {
  // Load from localStorage on mount
  const storedUser = localStorage.getItem('auth_user');
  if (storedUser) setUser(JSON.parse(storedUser));
}, []);

useEffect(() => {
  // Save to localStorage on change
  if (user) {
    localStorage.setItem('auth_user', JSON.stringify(user));
  }
}, [user]);
```

### 2. Modal Component Implementation

**Purpose**: Reusable portal-based modal for any content

**Key Features:**
- Renders outside main DOM tree using portals
- Click outside to close
- Escape key to close
- Body scroll lock
- Smooth animations

**Portal Pattern:**

```typescript
import { createPortal } from 'react-dom';

return createPortal(
  <div className="modal-overlay">
    <div ref={modalRef} className="modal-content">
      {children}
    </div>
  </div>,
  document.body
);
```

**Why portals?**
- Avoids z-index issues
- Works regardless of parent styling
- Easy to style and position
- Better accessibility

### 3. Server Action Implementation

**Purpose**: Handle authentication logic securely on the server

**Key Features:**
- Server-side validation
- Type-safe with TypeScript
- Progressive enhancement
- Works without JavaScript

**Server Action Pattern:**

```typescript
'use server';

export async function authenticateUser(
  prevState: any,
  formData: FormData
): Promise<AuthResult> {
  // Extract and validate
  const email = formData.get('email') as string;

  // Validate
  const errors = validateInputs(email, password);
  if (errors) return { fieldErrors: errors };

  // Authenticate
  const user = await findUser(email, password);

  // Return result
  return { success: true, user };
}
```

**Form Integration:**

```typescript
const [state, formAction, isPending] = useActionState(authenticateUser, null);

<form action={formAction}>
  <input name="email" />
  <button type="submit" disabled={isPending}>
    {isPending ? 'Loading...' : 'Submit'}
  </button>
</form>
```

### 4. Custom Hook Pattern

**Purpose**: Bridge server actions with React context

**Implementation:**

```typescript
export function useAuthAction(state: any) {
  const { login } = useAuth();

  useEffect(() => {
    if (state?.success && state?.user) {
      login(state.user);
    }
  }, [state, login]);

  return state;
}
```

**Usage:**

```typescript
function AuthModal() {
  const [state, formAction, isPending] = useActionState(authenticateUser, null);
  useAuthAction(state);

  return <form action={formAction}>...</form>;
}
```

## Integration Steps

### Step 1: Wrap App with Provider

```typescript
// app/layout.tsx
import { AuthProvider } from '@/context/AuthContext';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <AuthProvider>
          {children}
        </AuthProvider>
      </body>
    </html>
  );
}
```

### Step 2: Add Modal to Layout

```typescript
import { AuthModal } from '@/components/AuthModal';

export default function RootLayout({ children }) {
  return (
    <AuthProvider>
      <AuthModal />
      {children}
    </AuthProvider>
  );
}
```

### Step 3: Use Auth State in Components

```typescript
'use client';
import { useAuth } from '@/context/AuthContext';

export function MyComponent() {
  const { user, isAuthenticated, openModal } = useAuth();

  if (!isAuthenticated) {
    return <button onClick={openModal}>Sign In</button>;
  }

  return <div>Welcome, {user.name}!</div>;
}
```

### Step 4: Create Server Actions

```typescript
// actions/auth.ts
'use server';

export async function authenticateUser(
  prevState: any,
  formData: FormData
) {
  // Your authentication logic
}
```

## Advanced Patterns

### Protected Routes

```typescript
'use client';

export function ProtectedPage() {
  const { isAuthenticated, openModal } = useAuth();

  useEffect(() => {
    if (!isAuthenticated) {
      openModal();
    }
  }, [isAuthenticated, openModal]);

  if (!isAuthenticated) {
    return <div>Please sign in to continue...</div>;
  }

  return <div>Protected content</div>;
}
```

### Conditional Navigation

```typescript
function Navbar() {
  const { isAuthenticated, user, logout } = useAuth();

  return (
    <nav>
      {isAuthenticated ? (
        <>
          <span>Hi, {user.name}</span>
          <button onClick={logout}>Logout</button>
        </>
      ) : (
        <button onClick={openModal}>Sign In</button>
      )}
    </nav>
  );
}
```

### Theme Integration

```typescript
function ThemeToggle() {
  const { theme, toggleTheme } = useAuth();

  return (
    <button onClick={toggleTheme}>
      {theme === 'light' ? '🌙' : '☀️'}
    </button>
  );
}
```

## Best Practices

### 1. Error Handling

Always handle errors gracefully:

```typescript
if (state?.error) {
  return (
    <div className="error">
      {state.error}
    </div>
  );
}

if (state?.fieldErrors?.email) {
  return (
    <span className="field-error">
      {state.fieldErrors.email}
    </span>
  );
}
```

### 2. Loading States

Provide feedback during async operations:

```typescript
<button disabled={isPending}>
  {isPending ? (
    <>
      <Spinner />
      Processing...
    </>
  ) : (
    'Submit'
  )}
</button>
```

### 3. Accessibility

Ensure keyboard navigation and screen reader support:

```typescript
<Modal
  role="dialog"
  aria-modal="true"
  aria-labelledby="modal-title"
>
  <h2 id="modal-title">Sign In</h2>
  <button aria-label="Close modal">×</button>
</Modal>
```

### 4. Type Safety

Use TypeScript for better development experience:

```typescript
interface User {
  id: string;
  email: string;
  name: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  login: (user: User) => void;
  logout: () => void;
}
```

### 5. Hydration Safety

Handle client-only code properly:

```typescript
const [mounted, setMounted] = useState(false);

useEffect(() => {
  setMounted(true);
}, []);

if (!mounted) return null;
```

## Common Patterns

### Auto-open Modal on Protected Route

```typescript
useEffect(() => {
  if (!isAuthenticated && requiresAuth) {
    openModal();
  }
}, [isAuthenticated, requiresAuth, openModal]);
```

### Redirect After Login

```typescript
useEffect(() => {
  if (state?.success) {
    router.push('/dashboard');
  }
}, [state, router]);
```

### Conditional Rendering

```typescript
{isAuthenticated ? (
  <UserProfile user={user} />
) : (
  <GuestWelcome onSignIn={openModal} />
)}
```

## Performance Considerations

### 1. Memoization

Memoize context values:

```typescript
const value = useMemo(
  () => ({
    user,
    isAuthenticated,
    login,
    logout,
  }),
  [user, isAuthenticated]
);
```

### 2. Lazy Loading

Load modal only when needed:

```typescript
const AuthModal = dynamic(() => import('./AuthModal'), {
  ssr: false
});
```

### 3. Debouncing

Debounce validation:

```typescript
const debouncedValidate = useMemo(
  () => debounce(validateEmail, 300),
  []
);
```

## Testing

### Unit Tests

```typescript
describe('AuthContext', () => {
  it('provides auth state to children', () => {
    const { result } = renderHook(() => useAuth(), {
      wrapper: AuthProvider
    });

    expect(result.current.isAuthenticated).toBe(false);
  });
});
```

### Integration Tests

```typescript
test('user can sign up and login', async () => {
  render(<App />);

  await userEvent.click(screen.getByText('Sign In'));
  await userEvent.type(screen.getByLabelText('Email'), 'test@example.com');
  await userEvent.type(screen.getByLabelText('Password'), 'Password123');
  await userEvent.click(screen.getByText('Create Account'));

  expect(screen.getByText('Welcome, Test User')).toBeInTheDocument();
});
```

## Troubleshooting

### Modal Not Opening

Check:
1. Is AuthProvider wrapping the app?
2. Is AuthModal rendered in the tree?
3. Are you using the useAuth hook correctly?
4. Check console for errors

### State Not Persisting

Check:
1. Is localStorage available?
2. Are you in incognito mode?
3. Check browser storage quota
4. Verify hydration logic

### Form Not Submitting

Check:
1. Is the form action set correctly?
2. Are Server Actions enabled?
3. Check network tab for requests
4. Verify formData extraction

## Next Steps

1. Replace mock auth with real backend
2. Add password reset flow
3. Implement email verification
4. Add OAuth providers
5. Set up session management
6. Add 2FA support

## Resources

- [React 19 Documentation](https://react.dev)
- [Next.js 15 Documentation](https://nextjs.org/docs)
- [Server Actions Guide](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
- [Context API](https://react.dev/learn/passing-data-deeply-with-context)

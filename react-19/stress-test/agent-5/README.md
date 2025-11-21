# Authentication Modal System - React 19

A production-ready authentication modal system with global state management for React 19 applications. This implementation demonstrates modern React patterns including Server Actions, `useActionState`, and Context API for cross-application state sharing.

## Features

- **Global Authentication State**: Share user info and login status across the entire application
- **Modal System**: Portal-based modal that can be triggered from any component
- **Server Validation**: Server Actions with comprehensive validation and error handling
- **Theme Persistence**: Dark/light mode shared across the app and persisted in localStorage
- **Client & Server Components**: Works seamlessly with both React component types
- **Production Ready**: Complete error handling, loading states, and accessibility features

## Architecture

### Project Structure

```tree
agent-5/
├── actions/
│   └── auth.ts              # Server action for authentication
├── app/
│   ├── dashboard/
│   │   └── page.tsx         # Protected dashboard page
│   ├── settings/
│   │   └── page.tsx         # Settings with modal triggers
│   ├── layout.tsx           # Root layout with providers
│   └── page.tsx             # Home page
├── components/
│   ├── AuthModal.tsx        # Authentication modal form
│   ├── Modal.tsx            # Reusable portal-based modal
│   └── Navbar.tsx           # Navigation with auth controls
├── context/
│   └── AuthContext.tsx      # Global auth state provider
├── hooks/
│   └── useAuthAction.ts     # Custom hook for auth actions
└── styles/
    └── globals.css          # Global styles and animations
```

### Key Components

#### 1. AuthContext (`context/AuthContext.tsx`)

Global state provider managing:
- User authentication state
- Theme preference (light/dark)
- Modal open/close state
- localStorage persistence
- Hydration handling

```typescript
interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  theme: 'light' | 'dark';
  isModalOpen: boolean;
  login: (user: User) => void;
  logout: () => void;
  toggleTheme: () => void;
  openModal: () => void;
  closeModal: () => void;
}
```

#### 2. Modal Component (`components/Modal.tsx`)

Reusable portal-based modal with:
- Portal rendering to document.body
- Click outside to close
- Escape key to close
- Body scroll lock when open
- Smooth animations
- Dark mode support

#### 3. Server Action (`actions/auth.ts`)

Production-ready authentication with:
- Email format validation
- Password strength requirements (8+ chars, uppercase, lowercase, number)
- Name validation
- Mock user database (Map-based)
- Detailed error messages
- Field-level error reporting

#### 4. Custom Hook (`hooks/useAuthAction.ts`)

Bridges Server Actions with Context API:
- Automatically updates auth state on successful login
- Closes modal after authentication
- Reacts to server action state changes

## Usage

### Opening the Modal

From any component:

```typescript
import { useAuth } from '../context/AuthContext';

function MyComponent() {
  const { openModal } = useAuth();

  return (
    <button onClick={openModal}>
      Sign In
    </button>
  );
}
```

### Accessing Auth State

```typescript
import { useAuth } from '../context/AuthContext';

function MyComponent() {
  const { user, isAuthenticated, theme, toggleTheme } = useAuth();

  return (
    <div>
      {isAuthenticated ? (
        <p>Welcome, {user?.name}!</p>
      ) : (
        <p>Please sign in</p>
      )}
    </div>
  );
}
```

### Protected Routes

```typescript
import { useAuth } from '../context/AuthContext';
import { useEffect } from 'react';

export default function ProtectedPage() {
  const { isAuthenticated, openModal } = useAuth();

  useEffect(() => {
    if (!isAuthenticated) {
      openModal();
    }
  }, [isAuthenticated, openModal]);

  if (!isAuthenticated) {
    return <div>Please sign in...</div>;
  }

  return <div>Protected content</div>;
}
```

## Password Requirements

For security, passwords must:
- Be at least 8 characters long
- Contain at least one uppercase letter
- Contain at least one lowercase letter
- Contain at least one number

## State Persistence

The system persists data in localStorage:
- **User data**: Stored on successful login, removed on logout
- **Theme preference**: Automatically saved and restored
- **Hydration safe**: Properly handles server/client rendering

## Error Handling

### Server-side Validation

All validation happens on the server:
- Email format validation
- Password strength validation
- Name validation (signup only)
- Duplicate email detection

### Error Display

- **Field errors**: Displayed below each input field
- **General errors**: Displayed at the top of the form
- **Loading states**: Disabled inputs and animated spinner during submission

## Accessibility

- ARIA labels and roles
- Keyboard navigation (Escape to close)
- Focus management
- Screen reader friendly error messages
- Proper semantic HTML

## Security Features

1. **Server-side Validation**: Never trust client input
2. **Password Requirements**: Enforced strength requirements
3. **Error Messages**: Generic messages to prevent user enumeration
4. **XSS Protection**: React's built-in escaping
5. **CSRF Protection**: Server Actions include CSRF tokens automatically

## Styling

Built with Tailwind CSS:
- Dark mode support throughout
- Smooth transitions and animations
- Responsive design
- Consistent color scheme
- Custom modal animation

## React 19 Features Used

1. **useActionState**: Server Action integration with form state
2. **Server Actions**: Type-safe server-side mutations
3. **use client/server directives**: Proper component boundaries
4. **Context API**: Global state management
5. **Portal API**: Modal rendering

## Demo Pages

### Home (`/`)
- Feature overview
- Authentication status display
- Modal trigger examples
- Navigation to other pages

### Dashboard (`/dashboard`)
- Protected page with auto-redirect
- User profile display
- Activity tracking
- Statistics cards

### Settings (`/settings`)
- Theme toggle with visual preview
- Account information
- Multiple modal trigger buttons
- System information display

## Testing the System

1. **Sign Up**: Create a new account with email and password
2. **Sign In**: Log in with created credentials
3. **Persistence**: Refresh the page - user stays logged in
4. **Theme**: Toggle theme - preference persists
5. **Modal**: Open from different pages - state is shared
6. **Logout**: Sign out and verify state clears
7. **Validation**: Try invalid inputs to see error handling

## Production Considerations

Before deploying:

1. Replace mock authentication with real backend
2. Add HTTPS for secure transmission
3. Implement proper session management
4. Add rate limiting on auth endpoints
5. Set up monitoring and logging
6. Implement password reset flow
7. Add email verification
8. Consider OAuth providers
9. Add audit logging
10. Implement CAPTCHA for bot protection

## Next Steps

To integrate with a real backend:

1. Replace `actions/auth.ts` mock database with API calls
2. Add JWT or session token management
3. Implement refresh token logic
4. Add backend session validation
5. Set up secure cookie handling
6. Implement proper user database

## License

This is a demonstration project for React 19 authentication patterns.

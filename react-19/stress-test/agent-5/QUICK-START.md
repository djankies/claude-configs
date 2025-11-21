# Quick Start Guide

## Installation

```bash
npm install
npm run dev
```

Visit: `http://localhost:3000`

## Test Credentials

Create any account during signup. Example:
- Name: `John Doe`
- Email: `test@example.com`
- Password: `Password123`

## Key Features to Test

### 1. Authentication Modal

**Open Modal:**
- Click "Sign In" in navbar
- Navigate to `/dashboard` (auto-opens if not logged in)
- Click any modal button in `/settings`

**Sign Up:**
1. Click "Don't have an account? Sign up"
2. Enter name, email, password
3. Click "Create Account"

**Sign In:**
1. Use existing credentials
2. Click "Sign In"

**Password Requirements:**
- Min 8 characters
- 1 uppercase letter
- 1 lowercase letter
- 1 number

### 2. Global State

**Test Persistence:**
1. Login
2. Navigate between pages
3. Refresh browser
4. User stays logged in

**Logout:**
- Click "Sign Out" in navbar
- State clears globally

### 3. Theme Toggle

**Switch Themes:**
- Click moon/sun icon in navbar
- Or use "Toggle Theme" in settings
- Persists across refresh

### 4. Protected Routes

**Test Protection:**
1. Logout
2. Navigate to `/dashboard`
3. Modal opens automatically

## File Locations

### Source Code
```
/actions/auth.ts              - Authentication logic
/context/AuthContext.tsx      - Global state
/components/AuthModal.tsx     - Login form
/components/Modal.tsx         - Reusable modal
/components/Navbar.tsx        - Navigation
```

### Pages
```
/app/page.tsx                 - Home
/app/dashboard/page.tsx       - Dashboard
/app/settings/page.tsx        - Settings
```

### Docs
```
README.md                     - Overview
ARCHITECTURE.md               - Design
IMPLEMENTATION.md             - How to use
TESTING.md                    - Test guide
SECURITY.md                   - Security
DEPLOYMENT.md                 - Deploy guide
```

## Common Tasks

### Use Auth in Component

```typescript
'use client';
import { useAuth } from '../context/AuthContext';

export function MyComponent() {
  const { user, isAuthenticated, openModal } = useAuth();

  if (!isAuthenticated) {
    return <button onClick={openModal}>Sign In</button>;
  }

  return <div>Hello, {user.name}!</div>;
}
```

### Toggle Theme

```typescript
const { theme, toggleTheme } = useAuth();

<button onClick={toggleTheme}>
  {theme === 'light' ? 'Dark' : 'Light'} Mode
</button>
```

### Protect Route

```typescript
const { isAuthenticated, openModal } = useAuth();

useEffect(() => {
  if (!isAuthenticated) {
    openModal();
  }
}, [isAuthenticated, openModal]);
```

## Testing Checklist

- [ ] Sign up new account
- [ ] Sign in with credentials
- [ ] Navigate between pages
- [ ] Refresh browser (state persists)
- [ ] Toggle theme (persists)
- [ ] Open modal from different pages
- [ ] Test invalid inputs
- [ ] Test protected routes
- [ ] Sign out (clears state)

## Troubleshooting

**Modal won't open:**
- Check browser console for errors
- Ensure AuthProvider wraps app
- Verify AuthModal is rendered

**State not persisting:**
- Check localStorage in DevTools
- Clear cache and try again
- Check for private/incognito mode

**Form errors:**
- Check password requirements
- Ensure email is valid format
- Try different credentials

## Project Structure

```tree
agent-5/
├── actions/              # Server logic
├── app/                  # Pages
├── components/           # UI components
├── context/             # Global state
├── hooks/               # Custom hooks
└── styles/              # CSS
```

## Available Scripts

```bash
npm run dev         # Start dev server
npm run build       # Build for production
npm run start       # Start production server
npm run lint        # Run linter
```

## Next Steps

1. Test all features
2. Read full documentation
3. Review code implementation
4. Check security considerations
5. Plan production migration

## Key Endpoints

- `/` - Home page
- `/dashboard` - Protected dashboard
- `/settings` - Settings page

## Support

For detailed information, see:
- **README.md** - Full overview
- **IMPLEMENTATION.md** - Integration guide
- **TESTING.md** - Complete test scenarios
- **SECURITY.md** - Security details

## Production Notes

**WARNING**: This uses mock authentication

Before production:
- Replace mock auth with database
- Add password hashing
- Implement session management
- Enable HTTPS
- Add rate limiting
- Set up monitoring

See **DEPLOYMENT.md** for full details.

# User Profile Editor - Progressive Enhancement

Production-ready user profile editor built with React 19 demonstrating progressive enhancement, server actions, and optimistic updates.

## Features

### Progressive Enhancement
- Works without JavaScript (server-side form submission)
- Enhances with client-side validation when JavaScript loads
- Graceful degradation for all users

### Form Handling
- **useActionState**: Server action integration with pending states
- **useOptimistic**: Immediate UI updates during submission
- **Server Actions**: Type-safe form processing without API routes
- **Dual Validation**: Client-side (instant) and server-side (secure)

### User Experience
- Displays current profile data while editing
- Submit button shows pending state ("Saving...")
- Inline error messages with ARIA attributes
- Character counter for bio field
- Success/error message notifications

### Accessibility
- Semantic HTML form elements
- ARIA labels and roles
- Keyboard navigation support
- Screen reader friendly error messages
- Focus management

### Type Safety
- Full TypeScript coverage
- Shared validation logic between client/server
- Type-safe form data handling
- Strict null checks

## File Structure

```tree
agent-2/
├── types.ts              # TypeScript interfaces
├── validation.ts         # Shared validation logic
├── api.ts               # Client-side API functions
├── actions.ts           # Server actions
├── ProfileEditor.tsx    # Client component with form
├── page.tsx             # Server component page
└── README.md            # Documentation
```

## Usage

### Server Component (page.tsx)
```tsx
import { ProfileEditor } from './ProfileEditor';
import { getUserProfile } from './actions';

export default async function ProfilePage({ params }: PageProps) {
  const profile = await getUserProfile(params.userId);
  return <ProfileEditor userId={params.userId} initialProfile={profile} />;
}
```

### Progressive Enhancement Flow

1. **Without JavaScript**:
   - Form renders with current profile data
   - Native HTML validation
   - Server-side processing via form action
   - Full page reload on submit

2. **With JavaScript**:
   - Hydration enhances form behavior
   - Client-side validation (instant feedback)
   - Optimistic updates (immediate UI response)
   - Server validation (security layer)
   - No page reload

## Implementation Details

### Server Actions
```tsx
'use server';

export async function updateProfile(
  userId: string,
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  const data = {
    name: formData.get('name') as string,
    email: formData.get('email') as string,
    bio: formData.get('bio') as string,
  };

  const errors = validateProfile(data);
  if (errors.length > 0) {
    return { errors, success: false };
  }

  return { errors: [], success: true };
}
```

### Client Component Hooks
```tsx
const [formState, formAction, isPending] = useActionState(
  (prevState, formData) => updateProfile(userId, prevState, formData),
  { errors: [], success: false }
);

const [optimisticProfile, setOptimisticProfile] = useOptimistic(
  initialProfile,
  (state, newProfile) => ({ ...state, ...newProfile })
);
```

### Validation
- **Client**: Instant feedback, prevents unnecessary server calls
- **Server**: Security layer, canonical validation source
- **Shared Logic**: Same validation rules on both sides

### Error Handling
- Field-level errors with specific messages
- Form-level success/error notifications
- ARIA attributes for screen readers
- Visual indicators for invalid fields

## Production Considerations

### Performance
- Server components for initial data fetch
- Client components only where needed
- Optimistic updates reduce perceived latency
- No unnecessary re-renders

### Security
- Server-side validation (never trust client)
- Type-safe form processing
- SQL injection prevention (parameterized queries)
- XSS prevention (React escaping)

### User Experience
- Works for all users (with/without JS)
- Clear feedback on all actions
- Accessible to screen readers
- Mobile-friendly responsive design

### Testing Strategy
1. Test without JavaScript (curl/Postman)
2. Test with JavaScript disabled in browser
3. Test with slow network (throttling)
4. Test validation edge cases
5. Test accessibility (screen reader)

## API Endpoints (Mock)

The implementation uses mock data via server actions. In production, replace with:

```tsx
GET  /api/users/:userId/profile    # Fetch profile
PUT  /api/users/:userId/profile    # Update profile
```

## Validation Rules

- **Name**: Required, 2-100 characters
- **Email**: Required, valid format, max 255 characters
- **Bio**: Required, 10-500 characters

## Browser Support

- Modern browsers (ES2020+)
- Progressive enhancement ensures basic functionality in all browsers
- Graceful degradation for older browsers

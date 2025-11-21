---
name: action-state-patterns
description: Teaches useActionState hook for managing form state with Server Actions in React 19. Use when implementing forms, handling form submissions, tracking pending states, or working with Server Functions.
allowed-tools: Read, Write, Edit, Glob, Grep
version: 1.0.0
---

# useActionState Patterns for Forms

<role>
This skill teaches you how to use React 19's `useActionState` hook for form state management with Server Actions.
</role>

<when-to-activate>
This skill activates when:

- User mentions `useActionState`, form state, or form handling
- Working with Server Actions or Server Functions
- Need to track form pending state or submission status
- Implementing progressive enhancement
- Need form validation with server-side logic
</when-to-activate>

<overview>
`useActionState` is React 19's solution for managing form state based on action results:

1. **Tracks Pending State** - Automatic `isPending` flag during submission
2. **Manages Form State** - Returns current state from action results
3. **Server Action Integration** - Works seamlessly with `'use server'` functions
4. **Progressive Enhancement** - Optional permalink for no-JS submissions

Replaces manual state management for form submissions.
</overview>

<workflow>
## Standard Form with useActionState

**Step 1: Create Server Action**

```javascript
'use server';

export async function submitForm(previousState, formData) {
  const email = formData.get('email');

  if (!email || !email.includes('@')) {
    return { error: 'Invalid email address' };
  }

  await saveToDatabase({ email });
  return { success: true };
}
```

**Step 2: Use in Component with useActionState**

```javascript
'use client';

import { useActionState } from 'react';
import { submitForm } from './actions';

function ContactForm() {
  const [state, formAction, isPending] = useActionState(submitForm, null);

  return (
    <form action={formAction}>
      <input name="email" type="email" required />

      <button type="submit" disabled={isPending}>
        {isPending ? 'Submitting...' : 'Submit'}
      </button>

      {state?.error && <p className="error">{state.error}</p>}
      {state?.success && <p className="success">Submitted!</p>}
    </form>
  );
}
```

</workflow>

<conditional-workflows>
## Decision Points

**If you need progressive enhancement:**

1. Add permalink as third argument to `useActionState`
2. Form submits to URL before JavaScript loads
3. Server handles both JS and no-JS submissions

```javascript
const [state, formAction] = useActionState(
  submitForm,
  null,
  '/api/submit'
);
```

**If you need validation before submission:**

1. Server Action receives previous state
2. Return error object for validation failures
3. Return success object when valid
4. Component renders errors from state

**If you need multi-step forms:**

1. Track step in state
2. Server Action advances step or returns errors
3. Component renders current step based on state
</conditional-workflows>

<progressive-disclosure>
## Reference Files

For detailed information:

- **Server Actions**: See `../../forms/skills/server-actions/SKILL.md`
- **Form Validation**: See `../../forms/skills/form-validation/SKILL.md`
- **Progressive Enhancement**: See `../../../research/react-19-comprehensive.md` (lines 715-722)

Load references when specific patterns are needed.
</progressive-disclosure>

<examples>
## Example 1: Simple Form with Validation

```javascript
'use server';

import { z } from 'zod';

const schema = z.object({
  email: z.string().email(),
  message: z.string().min(10).max(1000),
});

export async function contactAction(previousState, formData) {
  const data = {
    email: formData.get('email'),
    message: formData.get('message'),
  };

  const result = schema.safeParse(data);

  if (!result.success) {
    return { errors: result.error.flatten().fieldErrors };
  }

  try {
    await db.contacts.create({ data: result.data });
    return { success: true };
  } catch (error) {
    return { error: 'Failed to submit contact form' };
  }
}
```

```javascript
'use client';

import { useActionState } from 'react';
import { contactAction } from './actions';

export default function ContactForm() {
  const [state, formAction, isPending] = useActionState(contactAction, null);

  if (state?.success) {
    return <p>Thank you for contacting us!</p>;
  }

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="email">Email</label>
        <input id="email" name="email" type="email" required />
        {state?.errors?.email && (
          <span className="error">{state.errors.email}</span>
        )}
      </div>

      <div>
        <label htmlFor="message">Message</label>
        <textarea id="message" name="message" required />
        {state?.errors?.message && (
          <span className="error">{state.errors.message}</span>
        )}
      </div>

      <button type="submit" disabled={isPending}>
        {isPending ? 'Sending...' : 'Send Message'}
      </button>

      {state?.error && <p className="error">{state.error}</p>}
    </form>
  );
}
```

## Example 2: Multi-Step Form

```javascript
'use server';

export async function multiStepAction(previousState, formData) {
  const step = previousState?.step || 1;

  if (step === 1) {
    const name = formData.get('name');
    if (!name || name.length < 2) {
      return { step: 1, error: 'Name is required' };
    }
    return { step: 2, data: { name } };
  }

  if (step === 2) {
    const email = formData.get('email');
    if (!email?.includes('@')) {
      return { step: 2, error: 'Valid email is required', data: previousState.data };
    }

    await db.users.create({
      data: { ...previousState.data, email },
    });

    return { step: 3, success: true };
  }
}
```

```javascript
'use client';

import { useActionState } from 'react';
import { multiStepAction } from './actions';

export default function MultiStepForm() {
  const [state, formAction, isPending] = useActionState(multiStepAction, { step: 1 });

  if (state.success) {
    return <p>Registration complete!</p>;
  }

  return (
    <form action={formAction}>
      {state.step === 1 && (
        <>
          <h2>Step 1: Name</h2>
          <input name="name" type="text" required />
          {state.error && <p className="error">{state.error}</p>}
        </>
      )}

      {state.step === 2 && (
        <>
          <h2>Step 2: Email</h2>
          <p>Name: {state.data.name}</p>
          <input name="email" type="email" required />
          {state.error && <p className="error">{state.error}</p>}
        </>
      )}

      <button type="submit" disabled={isPending}>
        {isPending ? 'Processing...' : state.step === 2 ? 'Complete' : 'Next'}
      </button>
    </form>
  );
}
```

</examples>

<constraints>
## MUST

- Server Action first parameter MUST be `previousState`
- Server Action second parameter MUST be `formData`
- Return serializable values from Server Actions (no functions, symbols)
- Use `formData.get('fieldName')` to access form values
- Mark functions with `'use server'` directive

## SHOULD

- Validate inputs on server (never trust client)
- Return structured error objects for field-specific errors
- Disable submit button when `isPending` is true
- Show loading indicators during submission
- Use validation libraries (zod, yup) for robust validation

## NEVER

- Trust client-side validation alone
- Return sensitive data in error messages
- Mutate `previousState` directly (return new object)
- Forget to handle errors from async operations
- Skip authentication/authorization checks in Server Actions
</constraints>

<validation>
## After Implementation

1. **Test Form Submission**:
   - Submit valid data → success state
   - Submit invalid data → error state
   - Check `isPending` during submission

2. **Verify Server Action**:
   - Receives `previousState` and `formData` correctly
   - Returns serializable objects
   - Handles errors gracefully

3. **Check Security**:
   - Server validates all inputs
   - Authentication/authorization implemented
   - No sensitive data in error messages

4. **Test Progressive Enhancement** (if used):
   - Disable JavaScript in browser
   - Form still submits to permalink
   - Server handles both JS and no-JS cases
</validation>

---

## Common Patterns

### Pattern 1: Optimistic Updates with useActionState

Combine with `useOptimistic` for immediate UI feedback:

```javascript
const [state, formAction] = useActionState(addTodo, null);
const [optimisticTodos, addOptimisticTodo] = useOptimistic(todos, (state, newTodo) =>
  [...state, newTodo]
);
```

See `../optimistic-updates/SKILL.md` for details.

### Pattern 2: Reset Form on Success

```javascript
const formRef = useRef();

const [state, formAction] = useActionState(async (prev, formData) => {
  const result = await submitForm(prev, formData);
  if (result.success) {
    formRef.current?.reset();
  }
  return result;
}, null);

return <form ref={formRef} action={formAction}>...</form>;
```

For comprehensive useActionState documentation, see: `research/react-19-comprehensive.md` lines 135-180.

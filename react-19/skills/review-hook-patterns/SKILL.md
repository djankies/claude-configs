---
name: review-react-hook-patterns
description: Review React hook usage for React 19 compliance and best practices. Use when reviewing code, checking for deprecated patterns, or validating hook usage.
review: true
allowed-tools: Read, Grep, Glob
version: 1.0.0
---

# Review: React Hook Patterns

<role>
This skill provides comprehensive criteria for reviewing React hook usage in React 19 codebases.
</role>

<when-to-activate>
This skill activates when:

- Code review is requested for React components
- Need to validate hook usage compliance
- Checking for React 19 migration readiness
- Reviewing pull requests with hook changes
</when-to-activate>

<overview>
This review skill checks for:

1. **New React 19 Hooks** - Proper usage of `use()`, `useActionState`, `useOptimistic`
2. **Deprecated Patterns** - Identifies forwardRef, propTypes, defaultProps
3. **Hook Rules** - Verifies dependencies, top-level calls, conditionals
4. **Best Practices** - Checks for common mistakes and anti-patterns
5. **TypeScript Compliance** - Validates types for React 19 patterns

**Review Focus:**
- Correctness over style
- Security issues (especially Server Actions)
- Performance problems (unnecessary re-renders)
- React 19 compliance (deprecated API usage)
</overview>

<workflow>
## Review Process

**Phase 1: Search for Deprecated Patterns**

Use Grep to find deprecated APIs:

```bash
# Search for forwardRef usage
pattern: "forwardRef"
output_mode: "content"

# Search for propTypes (removed in React 19)
pattern: "\.propTypes\s*="
output_mode: "content"

# Search for defaultProps on function components (deprecated)
pattern: "\.defaultProps\s*="
output_mode: "content"
```

**Phase 2: Review Hook Usage**

Check each hook usage for:

1. **use() API**:
   - ✅ Used with Promises or Context
   - ✅ Wrapped in Suspense (for Promises)
   - ✅ Has Error Boundary (for Promises)
   - ❌ NOT called in try-catch
   - ❌ Promises created outside component (stable)

2. **useActionState**:
   - ✅ Server Action receives (previousState, formData)
   - ✅ Returns serializable values
   - ✅ Has error handling
   - ✅ Validates inputs on server
   - ❌ NOT missing authentication checks

3. **useOptimistic**:
   - ✅ Update function is pure
   - ✅ Paired with startTransition
   - ✅ Has visual pending indicator
   - ❌ NOT used for critical operations

4. **Standard Hooks** (useState, useEffect, etc.):
   - ✅ Called at top level (not conditional)
   - ✅ All dependencies included in arrays
   - ✅ Cleanup functions for effects
   - ❌ NOT missing dependencies
   - ❌ NOT directly mutating state

**Phase 3: Check TypeScript Types**

For TypeScript projects:

1. **useRef** requires initial value:
   ```typescript
   // ✅ Correct
   const ref = useRef<HTMLDivElement>(null);

   // ❌ Incorrect (React 19)
   const ref = useRef<HTMLDivElement>();
   ```

2. **Ref as prop** typed correctly:
   ```typescript
   // ✅ Correct
   interface Props {
     ref?: Ref<HTMLButtonElement>;
   }

   // ❌ Incorrect (using forwardRef)
   const Comp = forwardRef<HTMLButtonElement, Props>(...);
   ```

**Phase 4: Identify Anti-Patterns**

Common mistakes to flag:

1. **Array index as key**:
   ```javascript
   // ❌ Bad
   {items.map((item, index) => <div key={index}>{item}</div>)}

   // ✅ Good
   {items.map(item => <div key={item.id}>{item}</div>)}
   ```

2. **Direct state mutation**:
   ```javascript
   // ❌ Bad
   const [items, setItems] = useState([]);
   items.push(newItem);
   setItems(items);

   // ✅ Good
   setItems([...items, newItem]);
   ```

3. **Missing dependencies**:
   ```javascript
   // ❌ Bad
   useEffect(() => {
     fetchData(userId);
   }, []);

   // ✅ Good
   useEffect(() => {
     fetchData(userId);
   }, [userId]);
   ```

4. **Missing cleanup**:
   ```javascript
   // ❌ Bad
   useEffect(() => {
     const timer = setInterval(() => {}, 1000);
   }, []);

   // ✅ Good
   useEffect(() => {
     const timer = setInterval(() => {}, 1000);
     return () => clearInterval(timer);
   }, []);
   ```

</workflow>

<output>
## Review Report Format

Structure your review findings as:

### ✅ Compliant Patterns

- List React 19 patterns used correctly
- Highlight good practices found
- Note proper hook usage

### ⚠️ Warnings (Non-blocking)

- Deprecated APIs still functional but should migrate:
  - `forwardRef` usage (works but deprecated)
  - Manual memoization when React Compiler available
  - Older patterns that have better React 19 alternatives

### ❌ Issues (Must Fix)

- Removed APIs that will break:
  - `propTypes` on function components
  - `defaultProps` on function components
  - String refs
- Security issues:
  - Server Actions without validation
  - Missing authentication checks
  - XSS vulnerabilities
- Hook rule violations:
  - Conditional hook calls
  - Missing dependencies
  - Hooks called outside components

### 📝 Recommendations

- Migration paths for deprecated APIs
- Performance improvements
- Best practice suggestions
- Links to relevant skills for fixes

</output>

<examples>
## Example Review: Form Component

**Code Being Reviewed:**

```javascript
import { useState } from 'react';

function ContactForm() {
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();
    await fetch('/api/contact', {
      method: 'POST',
      body: JSON.stringify({ email, message }),
    });
  }

  return (
    <form onSubmit={handleSubmit}>
      <input value={email} onChange={e => setEmail(e.target.value)} />
      <textarea value={message} onChange={e => setMessage(e.target.value)} />
      <button type="submit">Send</button>
    </form>
  );
}
```

**Review Report:**

### ❌ Issues (Must Fix)

1. **Missing Server Action Pattern**
   - File: `ContactForm.jsx`
   - Issue: Using client-side fetch instead of Server Actions
   - Fix: Migrate to `useActionState` with Server Action
   - Reference: `concerns/hooks/skills/action-state-patterns/SKILL.md`

2. **No Validation**
   - Issue: No email or message validation
   - Security Risk: Can submit invalid or malicious data
   - Fix: Add server-side validation in Server Action

3. **No Loading State**
   - Issue: No feedback during submission
   - UX Problem: User doesn't know if form is processing
   - Fix: Use `isPending` from `useActionState`

4. **No Error Handling**
   - Issue: Failed submissions show no error
   - Fix: Return error state from Server Action

### 📝 Recommendations

**Recommended Implementation:**

```javascript
'use client';

import { useActionState } from 'react';
import { submitContact } from './actions';

function ContactForm() {
  const [state, formAction, isPending] = useActionState(submitContact, null);

  return (
    <form action={formAction}>
      <input name="email" type="email" required />
      <textarea name="message" required />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Sending...' : 'Send'}
      </button>
      {state?.error && <p className="error">{state.error}</p>}
      {state?.success && <p>Message sent!</p>}
    </form>
  );
}
```

**Server Action (`actions.js`):**

```javascript
'use server';

import { z } from 'zod';

const schema = z.object({
  email: z.string().email(),
  message: z.string().min(10),
});

export async function submitContact(previousState, formData) {
  const data = {
    email: formData.get('email'),
    message: formData.get('message'),
  };

  const result = schema.safeParse(data);

  if (!result.success) {
    return { error: 'Invalid input' };
  }

  try {
    await db.contacts.create({ data: result.data });
    return { success: true };
  } catch (error) {
    return { error: 'Failed to send message' };
  }
}
```

## Example Review: forwardRef Component

**Code Being Reviewed:**

```javascript
import { forwardRef } from 'react';

const Button = forwardRef((props, ref) => (
  <button ref={ref} {...props}>
    {props.children}
  </button>
));

Button.displayName = 'Button';
```

**Review Report:**

### ⚠️ Warnings (Non-blocking)

1. **Deprecated forwardRef Usage**
   - File: `Button.jsx`
   - Issue: Using deprecated `forwardRef` API
   - Status: Still functional in React 19 but deprecated
   - Migration: Convert to ref-as-prop pattern
   - Reference: `concerns/hooks/skills/migrating-from-forwardref/SKILL.md`

### 📝 Recommendations

**React 19 Migration:**

```javascript
function Button({ children, ref, ...props }) {
  return (
    <button ref={ref} {...props}>
      {children}
    </button>
  );
}
```

**Benefits:**
- Simpler API (no wrapper function)
- Better TypeScript inference
- Follows React 19 patterns
- Less boilerplate

</examples>

<constraints>
## Review Standards

**MUST Flag:**

- Removed APIs (`propTypes`, `defaultProps` on function components, string refs)
- Hook rule violations (conditional calls, missing dependencies)
- Security issues (unvalidated Server Actions, missing auth)
- Missing Suspense/Error Boundaries for `use()` with Promises

**SHOULD Flag:**

- Deprecated APIs (`forwardRef`)
- Performance issues (unnecessary re-renders, missing memoization when needed)
- Missing TypeScript types for React 19 patterns
- Anti-patterns (array index keys, direct state mutation)

**MAY Suggest:**

- Better patterns available in React 19
- Component architecture improvements
- Code organization enhancements

**NEVER:**

- Enforce personal style preferences
- Require changes that don't improve correctness/security/performance
- Flag patterns that work correctly in React 19
- Demand premature optimization

</constraints>

<validation>
## Review Checklist

Before completing review, verify you checked:

### New React 19 Features
- [ ] `use()` usage with Promises has Suspense + Error Boundary
- [ ] `use()` with Context used appropriately
- [ ] `useActionState` Server Actions validate inputs
- [ ] `useOptimistic` paired with `startTransition`
- [ ] `useFormStatus` called inside form components

### Deprecated Patterns
- [ ] No `forwardRef` (or flagged for migration)
- [ ] No `propTypes` on function components
- [ ] No `defaultProps` on function components
- [ ] No string refs

### Hook Rules
- [ ] All hooks called at top level
- [ ] No conditional hook calls
- [ ] All dependencies included in arrays
- [ ] Cleanup functions present for subscriptions

### TypeScript (if applicable)
- [ ] `useRef` has initial value
- [ ] Ref props typed with `Ref<HTMLElement>`
- [ ] Server Actions have proper types
- [ ] No usage of deprecated type patterns

### Security
- [ ] Server Actions validate all inputs
- [ ] Authentication checks present where needed
- [ ] No XSS vulnerabilities (`dangerouslySetInnerHTML` sanitized)
- [ ] No exposed sensitive data in client code

### Performance
- [ ] No array index as key
- [ ] No direct state mutation
- [ ] No missing dependencies causing stale closures
- [ ] Reasonable component structure (not god components)

</validation>

---

## Quick Reference: Common Issues

| Issue | Search Pattern | Fix Reference |
|-------|---------------|---------------|
| forwardRef usage | `forwardRef` | `migrating-from-forwardref/SKILL.md` |
| propTypes | `\.propTypes\s*=` | Remove (use TypeScript) |
| defaultProps | `\.defaultProps\s*=` | Use ES6 defaults |
| Missing dependencies | Manual review | Add to dependency array |
| Array index keys | `key={.*index}` | Use stable ID |
| Direct mutation | Manual review | Use immutable updates |
| use() without Suspense | Manual review | Add Suspense boundary |
| Server Action no validation | Manual review | Add zod/yup validation |

For comprehensive React 19 patterns and migration guides, see: `research/react-19-comprehensive.md`.

---
name: using-use-hook
description: Teaches when and how to use the new use() API in React 19 for reading Promises and Context conditionally. Use when working with async data fetching, Suspense, or conditional context access.
allowed-tools: Read, Write, Edit, Glob, Grep
version: 1.0.0
---

# Using the `use()` Hook in React 19

<role>
This skill teaches you how to use React 19's new `use()` API for reading values from Promises and Context objects.
</role>

<when-to-activate>
This skill activates when:

- User mentions `use()`, `use hook`, or async data patterns
- Working with Suspense boundaries and data fetching
- Need conditional context access (inside if statements or loops)
- Migrating from `useContext` patterns
</when-to-activate>

<overview>
The `use()` API is new in React 19 and provides capabilities that traditional hooks cannot:

1. **Read Promises** - Suspend component until Promise resolves
2. **Conditional Context** - Access context inside if statements and loops
3. **Works after early returns** - Unlike `useContext`
4. **Integrates with Suspense** - Automatic loading states

Key difference from hooks: `use()` can be called conditionally.
</overview>

<workflow>
## Using `use()` with Promises

**Step 1: Create Promise in Parent Component**

```javascript
import { use, Suspense } from 'react';

function App() {
  const userPromise = fetchUser();

  return (
    <Suspense fallback={<Loading />}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

**Step 2: Read Promise with `use()` in Child**

```javascript
function UserProfile({ userPromise }) {
  const user = use(userPromise);

  return <div>{user.name}</div>;
}
```

## Using `use()` with Context

**Step 1: Create Context**

```javascript
import { createContext } from 'react';

const ThemeContext = createContext('light');
```

**Step 2: Use Conditionally (Not Possible with `useContext`)**

```javascript
function Button({ isPrimary }) {
  let theme;
  if (isPrimary) {
    theme = use(ThemeContext);
  }

  return <button className={theme}>Click me</button>;
}
```

</workflow>

<conditional-workflows>
## Decision Points

**If working with async data:**

1. Pass Promise as prop from parent
2. Use `use(promise)` in child component
3. Wrap in Suspense boundary for loading state
4. Use Error Boundary for error handling

**If working with conditional context:**

1. Replace `useContext` with `use` for flexibility
2. Can now call inside if statements
3. Can call after early returns
4. Can call in loops

**If migrating from `useContext`:**

1. Find `useContext(SomeContext)` calls
2. Replace with `use(SomeContext)`
3. Benefit: Can now use conditionally if needed
</conditional-workflows>

<progressive-disclosure>
## Reference Files

For detailed information:

- **Error Handling**: See `../../../research/react-19-comprehensive.md` (Error Handling Patterns section)
- **Promise Patterns**: See `../../../research/react-19-comprehensive.md` (use API section, lines 241-311)
- **Context Migration**: See `../../../research/react-19-comprehensive.md` (useContext section)

Load references when specific patterns are needed.
</progressive-disclosure>

<examples>
## Example 1: Async Data Fetching

**Input**: "Fetch user data and display it"

**Implementation**:

```javascript
import { use, Suspense } from 'react';

async function fetchUser(id) {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
}

function UserProfile({ userId }) {
  const userPromise = fetchUser(userId);

  return (
    <Suspense fallback={<div>Loading...</div>}>
      <UserData promise={userPromise} />
    </Suspense>
  );
}

function UserData({ promise }) {
  const user = use(promise);
  return <div>{user.name}</div>;
}
```

## Example 2: Conditional Context Access

**Input**: "Only access theme for primary buttons"

**Implementation**:

```javascript
import { use, createContext } from 'react';

const ThemeContext = createContext('light');

function Button({ isPrimary, children }) {
  let className = 'button';

  if (isPrimary) {
    const theme = use(ThemeContext);
    className += ` ${theme}`;
  }

  return <button className={className}>{children}</button>;
}
```

## Example 3: Custom Hook with `use()`

**Input**: "Create reusable user data hook"

**Implementation**:

```javascript
import { use, cache } from 'react';

const getUser = cache(async (id) => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
});

function useUser(userId) {
  if (!userId) {
    return null;
  }

  const userPromise = getUser(userId);
  return use(userPromise);
}

function UserProfile({ userId }) {
  const user = useUser(userId);

  if (!user) {
    return <div>No user selected</div>;
  }

  return <div>{user.name}</div>;
}
```

</examples>

<constraints>
## MUST

- Wrap components using `use(promise)` in Suspense boundary
- Use Error Boundary for error handling (cannot use try-catch)
- Create Promises in parent/Server Components, not in component using `use()`
- Pass Promises as props for stability

## SHOULD

- Use `cache()` wrapper for Promise functions to avoid duplicate requests
- Prefer `async`/`await` in Server Components over `use()`
- Consider conditional logic carefully when using `use()` conditionally

## NEVER

- Call `use()` inside try-catch blocks (use Error Boundaries instead)
- Create new Promises on every render inside component (causes infinite loops)
- Use `use()` outside Component or Hook functions
- Forget Suspense boundary for Promises
</constraints>

<validation>
## After Implementation

1. **Verify Suspense Boundary**:
   - Every `use(promise)` must be wrapped in `<Suspense>`
   - Check for loading fallback

2. **Verify Error Boundary**:
   - Errors from Promises caught by Error Boundary
   - User sees error UI, not blank screen

3. **Check Promise Stability**:
   - Promises created outside component or with `cache()`
   - No new Promise on every render

4. **Test Conditional Logic**:
   - If using `use()` conditionally, test all branches
   - Ensure no hook rule violations
</validation>

---

## Key Differences from Hooks

| Feature | Hooks (`useContext`, etc.) | `use()` API |
|---------|---------------------------|-------------|
| Conditional calls | ❌ Not allowed | ✅ Allowed |
| After early return | ❌ Not allowed | ✅ Allowed |
| Inside loops | ❌ Not allowed | ✅ Allowed |
| Read Promises | ❌ Not supported | ✅ Suspends component |
| Error handling | try-catch | Error Boundary only |

For comprehensive React 19 use() documentation, see: `research/react-19-comprehensive.md` lines 241-311.

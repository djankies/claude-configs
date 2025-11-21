# React 19 Research

## Overview

- **Version**: 19.0.0 (stable release December 5, 2024)
- **Latest Version**: 19.2.0 (released October 1, 2025)
- **Purpose in Project**: JavaScript library for building user interfaces with components
- **Official Documentation**: https://react.dev
- **Last Updated**: November 19, 2025

## Installation

### Standard Installation

```bash
npm install --save-exact react@^19.0.0 react-dom@^19.0.0
```

### TypeScript Projects

```bash
npm install --save-exact react@^19.0.0 react-dom@^19.0.0 @types/react@^19.0.0 @types/react-dom@^19.0.0
```

### Package.json Configuration

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0"
  }
}
```

### Important Notes

- React 19 requires the new JSX transform (introduced in 2020)
- Some third-party libraries may still require React 18, necessitating the `--legacy-peer-deps` flag
- ESM CDNs like esm.sh replace UMD builds

## Core Concepts

### Actions

Actions are async functions used within transitions that automatically manage pending states, errors, and form resets. They represent a new pattern in React 19 for handling asynchronous operations, particularly in forms and data mutations.

**Key characteristics:**

- Execute asynchronously
- Automatically track pending state
- Handle errors without manual try-catch in most cases
- Reset forms on successful submission
- Work seamlessly with Server Components

### Transitions

Transitions mark state updates as non-blocking, allowing the UI to remain responsive during lengthy operations. React 19 adds support for async functions in transitions.

**Key characteristics:**

- Non-blocking UI updates
- Can be interrupted by urgent updates
- Support async/await patterns
- Automatic pending state management

### Server Components

Server Components render ahead of time in an environment separate from the client application, enabling direct database access and API calls without exposing sensitive logic to the client.

**Key characteristics:**

- Render entirely on the server
- Can access databases and APIs directly
- Reduce JavaScript bundle size by 20%-90%
- Support "Full-stack React Architecture"
- Not sent to browsers

### Server Actions

Server Actions are async functions marked with `"use server"` that execute on servers but can be called transparently from Client Components.

**Key characteristics:**

- Execute on the server
- Called directly from Client Components without API routes
- Automatically serialized by React
- Support progressive enhancement
- Work with form submissions

## Configuration

### JSX Transform Requirement

React 19 requires the modern JSX transform. Most projects created after 2020 already have this enabled. Verify your build configuration includes the automatic JSX runtime.

**Babel Configuration:**

```json
{
  "presets": [
    [
      "@babel/preset-react",
      {
        "runtime": "automatic"
      }
    ]
  ]
}
```

### TypeScript Configuration

TypeScript projects require updated type definitions:

```bash
npx types-react-codemod@latest preset-19 ./path-to-app
```

### React Compiler (Optional)

React Compiler is a build-time tool that automatically memoizes code:

- Automatically optimizes component re-rendering
- Eliminates need for manual `useMemo`, `useCallback`, `React.memo` in most cases
- Requires build tooling integration
- Available as a separate package from React 19

## New Hooks in React 19

### useActionState

Manages form state based on action results, particularly useful with Server Functions.

**Syntax:**

```javascript
const [state, formAction, isPending] = useActionState(fn, initialState, permalink?)
```

**Parameters:**

- `fn`: Action function invoked on form submission (receives previous state + form arguments)
- `initialState`: Initial state value (any serializable value)
- `permalink` (optional): URL for progressive enhancement before JavaScript loads

**Return Values:**

1. Current state (initially `initialState`, then action's return value)
2. Form action (wrapped action for `<form action>` prop)
3. `isPending` flag (boolean indicating active transition)

**Usage Example:**

```javascript
import { useActionState } from 'react';

function MyForm() {
  const [state, formAction, isPending] = useActionState(async (previousState, formData) => {
    const error = await updateName(formData.get('name'));
    return error ? { error } : { success: true };
  }, null);

  return (
    <form action={formAction}>
      <input name="name" />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Submitting...' : 'Submit'}
      </button>
      {state?.error && <p>{state.error}</p>}
    </form>
  );
}
```

**Important Note:** The action function receives previous state as the first argument, and form data as the second (different from standard form actions).

### useOptimistic

Enables optimistic UI updates by showing anticipated results immediately during async operations.

**Syntax:**

```javascript
const [optimisticState, addOptimistic] = useOptimistic(state, updateFn);
```

**Parameters:**

- `state`: Baseline value returned when no async action is in progress
- `updateFn(currentState, optimisticValue)`: Pure function that merges current state with optimistic input

**Return Values:**

1. `optimisticState`: Original state during normal operation, optimistic state during pending actions
2. `addOptimistic`: Dispatcher function accepting an optimistic value

**Usage Example:**

```javascript
import { useOptimistic, startTransition } from 'react';

function MessageList({ messages, sendMessage }) {
  const [optimisticMessages, addOptimisticMessage] = useOptimistic(
    messages,
    (state, newMessage) => [...state, { ...newMessage, sending: true }]
  );

  const handleSend = async (text) => {
    const tempId = Date.now();
    addOptimisticMessage({ id: tempId, text });

    startTransition(async () => {
      await sendMessage(text);
    });
  };

  return (
    <ul>
      {optimisticMessages.map((msg) => (
        <li key={msg.id}>
          {msg.text} {msg.sending && <small>(Sending...)</small>}
        </li>
      ))}
    </ul>
  );
}
```

**Best Practices:**

- Keep update function pure (no side effects)
- Pair with `startTransition` for async operations
- Provide visual feedback for pending states
- Ensure update logic matches server response

### use

New rendering API that reads values from Promises or context objects.

**Syntax:**

```javascript
const value = use(resource);
```

**Parameters:**

- `resource`: A Promise or context object

**Return Value:**

- Resolved value from Promise or context value

**Key Capabilities:**

- Works conditionally (inside `if` statements and loops)
- Suspends component until Promise resolves
- Can be called after early returns (unlike `useContext`)
- Integrates with Suspense and Error Boundaries

**Usage Example with Promise:**

```javascript
import { use, Suspense } from 'react';

function UserProfile({ userPromise }) {
  const user = use(userPromise);

  return <div>{user.name}</div>;
}

function App() {
  const userPromise = fetchUser();

  return (
    <Suspense fallback={<div>Loading...</div>}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

**Usage Example with Context:**

```javascript
import { use, createContext } from 'react';

const ThemeContext = createContext('light');

function Button() {
  let theme;
  if (someCondition) {
    theme = use(ThemeContext);
  }

  return <button className={theme}>Click me</button>;
}
```

**Important Caveats:**

- Must be called inside a Component or Hook
- Cannot be called within try-catch blocks (use Error Boundaries)
- In Server Components, prefer `async`/`await` over `use`
- Promises should be created server-side for stability

### useFormStatus

Provides status information about parent form submissions.

**Syntax:**

```javascript
const { pending, data, method, action } = useFormStatus();
```

**Return Values:**

1. `pending` (boolean): Whether parent form is submitting
2. `data` (FormData | null): Form data being submitted
3. `method` (string): HTTP method ('get' or 'post')
4. `action` (function | null): Function passed to form's action prop

**Usage Example:**

```javascript
import { useFormStatus } from 'react-dom';

function SubmitButton() {
  const { pending, data } = useFormStatus();

  return <button disabled={pending}>{pending ? 'Submitting...' : 'Submit'}</button>;
}

function MyForm() {
  return (
    <form action={handleSubmit}>
      <input name="username" />
      <SubmitButton />
    </form>
  );
}
```

**Critical Requirements:**

- Must be called from a component rendered **inside a `<form>` element**
- Only tracks status for parent forms, not sibling or child forms
- Returns `false` for `pending` if not nested within a form

### useTransition (Enhanced in React 19)

Enables non-blocking state updates with async support.

**Syntax:**

```javascript
const [isPending, startTransition] = useTransition();
```

**Return Values:**

1. `isPending` (boolean): Whether a transition is processing
2. `startTransition` (function): Marks state updates as non-blocking

**React 19 Async Support:**

```javascript
const [isPending, startTransition] = useTransition();

startTransition(async () => {
  const data = await fetchData();
  startTransition(() => {
    setState(data);
  });
});
```

**Usage Example:**

```javascript
import { useState, useTransition } from 'react';

function TabContainer() {
  const [isPending, startTransition] = useTransition();
  const [tab, setTab] = useState('home');

  const selectTab = (nextTab) => {
    startTransition(() => {
      setTab(nextTab);
    });
  };

  return (
    <>
      <button onClick={() => selectTab('home')}>Home</button>
      <button onClick={() => selectTab('posts')}>Posts</button>
      {isPending && <Spinner />}
      <TabContent tab={tab} />
    </>
  );
}
```

**Limitations:**

- Cannot control text inputs through transitions
- Cannot use with `setTimeout`
- Transitions are interruptible by urgent updates
- Requires access to state setter functions

### useDeferredValue (Enhanced)

Defers updating non-critical UI sections while prioritizing critical updates.

**React 19 Enhancement:**

- Accepts `initialValue` parameter for better initial render performance

**Syntax:**

```javascript
const deferredValue = useDeferredValue(value, initialValue?)
```

## Standard Hooks Reference

### useState

Adds state variable to component.

**Syntax:**

```javascript
const [state, setState] = useState(initialState);
```

**Key Behaviors:**

- Returns current state and setter function
- State updates are asynchronous
- React batches updates within event handlers
- Requires immutability for objects/arrays
- Uses `Object.is()` for equality comparison

**Updater Function Pattern:**

```javascript
setState((prevState) => prevState + 1);
```

### useEffect

Connects component to external systems.

**Syntax:**

```javascript
useEffect(setup, dependencies?)
```

**Parameters:**

- `setup`: Function containing effect logic, optionally returns cleanup
- `dependencies`: Array of reactive values (optional)

**Dependency Patterns:**

- `[dep1, dep2]`: Runs on mount and when dependencies change
- `[]`: Runs only on mount and unmount
- Omitted: Runs after every render

**Cleanup Example:**

```javascript
useEffect(() => {
  const connection = createConnection();
  connection.connect();
  return () => connection.disconnect();
}, [dependency]);
```

**Common Pitfalls:**

- Double execution in Strict Mode (intentional)
- Infinite loops from state updates in dependencies
- Race conditions in data fetching (use ignore flag)

### useContext

Reads and subscribes to context.

**Syntax:**

```javascript
const value = useContext(Context);
```

**Note:** Consider using the new `use` API for conditional context reading.

### useReducer

Declares state variable with reducer logic.

**Syntax:**

```javascript
const [state, dispatch] = useReducer(reducer, initialArg, init?)
```

**Better for:**

- Complex state logic
- Multiple related state values
- State updates depending on previous state

### useRef

Declares ref for holding any value (commonly DOM nodes).

**Syntax:**

```javascript
const ref = useRef(initialValue);
```

**React 19 Changes:**

- Now requires initial value argument (previously optional)
- All refs are mutable
- Supports cleanup functions when used as ref callbacks

### useMemo

Caches result of expensive calculations.

**Syntax:**

```javascript
const memoizedValue = useMemo(() => computeExpensiveValue(a, b), [a, b]);
```

**React 19 Note:** React Compiler can auto-memoize, reducing need for manual `useMemo`.

### useCallback

Caches function definition.

**Syntax:**

```javascript
const memoizedCallback = useCallback(() => {
  doSomething(a, b);
}, [a, b]);
```

**React 19 Note:** React Compiler can auto-memoize, reducing need for manual `useCallback`.

### useLayoutEffect

Fires before browser repaints (for layout measurements).

**Syntax:**

```javascript
useLayoutEffect(setup, dependencies?)
```

**Use Cases:**

- Measuring layout
- Preventing visual flicker
- DOM mutations before paint

### useId

Associates unique IDs with components.

**Syntax:**

```javascript
const id = useId();
```

**Usage:**

```javascript
function Form() {
  const id = useId();
  return (
    <>
      <label htmlFor={id}>Name:</label>
      <input id={id} type="text" />
    </>
  );
}
```

### useSyncExternalStore

Subscribes components to external state sources.

**Syntax:**

```javascript
const snapshot = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot?)
```

### useImperativeHandle

Customizes refs exposed by components.

**Syntax:**

```javascript
useImperativeHandle(ref, createHandle, dependencies?)
```

### useDebugValue

Customizes React DevTools labels for custom hooks.

**Syntax:**

```javascript
useDebugValue(value, format?)
```

### useInsertionEffect

Fires before React modifies DOM (for dynamic style insertion).

**Syntax:**

```javascript
useInsertionEffect(setup, dependencies?)
```

## Server Functions (Server Components)

Server Functions are async functions executed on the server, marked with `"use server"` directive.

### Defining Server Functions

**Inline in Server Components:**

```javascript
async function ServerComponent() {
  async function myAction() {
    'use server';
    await saveToDatabase();
  }

  return <ClientComponent action={myAction} />;
}
```

**In Separate Files:**

```javascript
'use server';

export async function updateUser(formData) {
  const name = formData.get('name');
  await database.users.update({ name });
  return { success: true };
}
```

**Importing in Client Components:**

```javascript
'use client';

import { updateUser } from './actions';

function UserForm() {
  return (
    <form action={updateUser}>
      <input name="name" />
      <button>Update</button>
    </form>
  );
}
```

### Form Integration

Server Functions work seamlessly with forms:

```javascript
function MyForm() {
  async function handleSubmit(formData) {
    'use server';
    const result = await processForm(formData);
    return result;
  }

  return <form action={handleSubmit}>...</form>;
}
```

**Automatic Features:**

- Forms auto-reset on successful submission
- Works with `useActionState` for pending states
- Progressive enhancement support
- Automatic form replay after hydration

### Progressive Enhancement

Using `useActionState` with a permalink enables form submission before JavaScript loads:

```javascript
const [state, formAction] = useActionState(serverAction, initialState, '/fallback-url');
```

### Security Considerations

- Server Functions automatically serialize to prevent client exposure
- Sensitive logic remains on server
- Framework creates references, not actual function code
- Type safety maintained with `$$typeof: Symbol.for("react.server.reference")`

### Important Framework Note

Server Functions in React 19 are stable, but underlying bundler/framework APIs do not follow semver and may break between React 19.x minor versions.

## React DOM Enhancements

### Document Metadata Support

Components can render `<title>`, `<meta>`, and `<link>` tags directly. React automatically hoists them to `<head>`.

**Example:**

```javascript
function BlogPost({ post }) {
  return (
    <article>
      <title>{post.title}</title>
      <meta name="description" content={post.description} />
      <meta property="og:title" content={post.title} />
      <link rel="author" href={post.authorUrl} />

      <h1>{post.title}</h1>
      <p>{post.content}</p>
    </article>
  );
}
```

**Key Features:**

- Automatic hoisting to `<head>`
- Works with client-only apps, streaming SSR, and Server Components
- No external libraries needed (like react-helmet)

### Stylesheet Management

React 19 introduces built-in stylesheet support with precedence control.

**Example:**

```javascript
function Component() {
  return (
    <div>
      <link rel="stylesheet" href="/styles.css" precedence="default" />
      <p>Content</p>
    </div>
  );
}
```

**Features:**

- `precedence` prop controls insertion order
- Automatic deduplication across components
- Integration with Suspense boundaries
- Manages loading states

### Async Script Support

Async scripts can render anywhere and are automatically deduplicated.

**Example:**

```javascript
function MyComponent() {
  return (
    <div>
      <script async src="/analytics.js" />
      <p>Content</p>
    </div>
  );
}
```

**Features:**

- Automatic deduplication
- Proper SSR prioritization
- Can be placed anywhere in component tree

### Resource Preloading APIs

New functions optimize initial load and navigation:

```javascript
import { prefetchDNS, preconnect, preload, preinit } from 'react-dom';

function App() {
  prefetchDNS('https://api.example.com');
  preconnect('https://cdn.example.com');
  preload('/font.woff2', { as: 'font' });
  preinit('/critical.js', { as: 'script' });

  return <div>App content</div>;
}
```

**Available Functions:**

- `prefetchDNS(href)`: DNS resolution
- `preconnect(href)`: Early connection
- `preload(href, options)`: Resource preloading
- `preinit(href, options)`: Resource initialization

## Major Breaking Changes

### Removed APIs

**React Package:**

- `propTypes` - use TypeScript or type-checking solution
- `defaultProps` for function components - use ES6 default parameters
- Legacy Context (`contextTypes`, `getChildContext`)
- String refs - migrate to ref callbacks
- `React.createFactory`
- `react-test-renderer/shallow`

**React DOM Package:**

- `ReactDOM.render` → use `createRoot`
- `ReactDOM.hydrate` → use `hydrateRoot`
- `unmountComponentAtNode` → use `root.unmount()`
- `ReactDOM.findDOMNode` - use DOM refs
- `react-dom/test-utils` - move `act` to `react`

### New Deprecations

**element.ref:**

- Now access via `element.props.ref`

**react-test-renderer:**

- Migrate to React Testing Library

**forwardRef:**

- Deprecated (still functional in React 19)
- Use ref as prop instead

### Error Handling Redesign

React 19 changes how errors are reported:

- Uncaught errors → `window.reportError`
- Caught errors → `console.error`
- New error callbacks in `createRoot` and `hydrateRoot`:

```javascript
const root = createRoot(container, {
  onCaughtError: (error, errorInfo) => {
    console.error('Caught error:', error);
  },
  onUncaughtError: (error, errorInfo) => {
    console.error('Uncaught error:', error);
  },
});
```

### TypeScript Breaking Changes

**useRef Requires Initial Value:**

```javascript
const ref = useRef < HTMLDivElement > null;
```

**Ref Callback Cleanup:**

```javascript
<div
  ref={(current) => {
    instance = current;
  }}
/>
```

**JSX Namespace:**

- Must be scoped within module declarations

**ReactElement Props:**

- Default to `unknown` instead of `any`

### Suspense Improvements

- Fallbacks render immediately without waiting for sibling trees
- Pre-warm lazy requests afterward

### StrictMode Refinements

- `useMemo` and `useCallback` reuse memoized results across double-renders during development

### UMD Removal

- Use ESM CDNs like esm.sh instead

## Migration Path

### Step-by-Step Upgrade

**1. Upgrade to React 18.3 First:**

```bash
npm install react@18.3 react-dom@18.3
```

This identifies deprecated API usage with warnings.

**2. Run Migration Codemods:**

```bash
npx codemod@latest react/19/migration-recipe
```

This executes five key codemods:

- DOM render replacements
- String ref conversions
- Test utilities updates
- PropTypes removal
- DefaultProps migration

**3. Update TypeScript Types:**

```bash
npx types-react-codemod@latest preset-19 ./path-to-app
```

**4. Install React 19:**

```bash
npm install --save-exact react@^19.0.0 react-dom@^19.0.0
```

**5. Update Tests:**

- Migrate from `react-test-renderer/shallow` to Testing Library
- Move `act` imports from `react-dom/test-utils` to `react`

**6. Manual Fixes:**

- Replace `forwardRef` with ref props
- Update error handling to use new callbacks
- Remove `propTypes` and `defaultProps`

## Ref as Prop (forwardRef Deprecation)

### Before React 19

```javascript
import { forwardRef } from 'react';

const MyButton = forwardRef((props, ref) => (
  <button ref={ref} {...props}>
    {props.children}
  </button>
));
```

### After React 19

```javascript
import { Ref } from 'react';

function MyButton({
  children,
  ref,
  ...props
}: {
  children: React.ReactNode,
  ref?: Ref<HTMLButtonElement>,
}) {
  return (
    <button ref={ref} {...props}>
      {children}
    </button>
  );
}
```

### Ref Cleanup Functions

React 19 supports cleanup in ref callbacks:

```javascript
<div
  ref={(node) => {
    console.log('Connected:', node);

    return () => {
      console.log('Disconnected:', node);
    };
  }}
/>
```

**When Cleanup Runs:**

- Component unmounts
- Ref changes to different element

## Custom Elements (Web Components)

React 19 adds full support for custom elements and passes all Custom Elements Everywhere tests.

### Property vs Attribute Handling

React 19 intelligently determines whether to set properties or attributes:

- Checks if DOM element has corresponding property
- If yes, assigns as property
- If no, treats as HTML attribute
- Boolean attributes added/removed as needed

### Before React 19

```javascript
<web-counter
  ref={(el) => {
    if (el) {
      el.increment = increment;
      el.isDark = isDark;
    }
  }}
/>
```

### After React 19

```javascript
<web-counter
  increment={increment}
  isDark={isDark}
  onIncrementedEvent={() => setClickCount(clickCount + 1)}
/>
```

### Custom Events Support

React 19 supports custom events with the standard "on + EventName" convention:

```javascript
<my-button label="React Button" onButtonClick={handleClick} />
```

### SSR vs CSR Rendering

**Server Side Rendering:**

- Props render as attributes if primitive (string, number, true)
- Non-primitive types (object, symbol, function) or false are omitted

**Client Side Rendering:**

- Props matching Custom Element instance properties assigned as properties
- Others assigned as attributes

## Error Handling Patterns

### Error Boundaries with Suspense

```javascript
import { ErrorBoundary } from 'react-error-boundary';
import { Suspense } from 'react';

function App() {
  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      onError={(error, errorInfo) => logError(error, errorInfo)}>
      <Suspense fallback={<Spinner />}>
        <AsyncComponent />
      </Suspense>
    </ErrorBoundary>
  );
}

function ErrorFallback({ error, resetErrorBoundary }) {
  return (
    <div role="alert">
      <p>Something went wrong:</p>
      <pre>{error.message}</pre>
      <button onClick={resetErrorBoundary}>Try again</button>
    </div>
  );
}
```

### Using `use` API with Error Boundaries

```javascript
import { use, Suspense } from 'react';
import { ErrorBoundary } from 'react-error-boundary';

function UserProfile({ userPromise }) {
  const user = use(userPromise);
  return <div>{user.name}</div>;
}

function App() {
  const userPromise = fetchUser();

  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <Suspense fallback={<Loading />}>
        <UserProfile userPromise={userPromise} />
      </Suspense>
    </ErrorBoundary>
  );
}
```

### Error Handling with Actions

```javascript
function MyForm() {
  const [error, submitAction, isPending] = useActionState(async (previousState, formData) => {
    try {
      await updateData(formData);
      return null;
    } catch (err) {
      return { error: err.message };
    }
  }, null);

  return (
    <form action={submitAction}>
      <input name="field" />
      <button disabled={isPending}>Submit</button>
      {error && <p className="error">{error}</p>}
    </form>
  );
}
```

### Server-Side Error Handling

React uses Suspense boundaries to handle errors on the server:

- If component throws error on server, React doesn't abort
- Finds closest Suspense boundary
- Includes fallback in server HTML
- If also errors on client, throws and displays closest Error Boundary

## Performance Optimization

### React Compiler

The React Compiler is a build-time tool that automatically memoizes code.

**How It Works:**

- Analyzes components during build
- Automatically memoizes values and computations
- Skips unnecessary re-renders
- Stabilizes function references

**Benefits:**

- Eliminates manual `useMemo`, `useCallback`, `React.memo` in most cases
- More comprehensive than `React.memo`
- Simpler, cleaner code
- Automatic optimization

**When Manual Memoization Still Needed:**

- Third-party libraries requiring memoized values
- Extremely expensive calculations React doesn't catch
- Edge cases identified via React Profiler

### Memoization Best Practices

**With React Compiler (React 19):**

- Remove redundant `React.memo`, `useMemo`, `useCallback` where not needed
- Keep components small and focused
- Trust compiler for most optimizations
- Measure with React Profiler to identify exceptions

**Without React Compiler:**

- Use `memo` for components that re-render often with same props
- Only memoize when re-render logic is expensive
- Avoid premature optimization

**General Principles:**

- Keep state local (don't lift unnecessarily)
- Use children prop pattern to prevent wrapper re-renders
- Prefer local state over context for frequently changing values

### Code Splitting Best Practices

```javascript
import { lazy, Suspense } from 'react';

const HeavyComponent = lazy(() => import('./HeavyComponent'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyComponent />
    </Suspense>
  );
}
```

### Resource Preloading for Performance

```javascript
import { preload, preinit } from 'react-dom';

function AppRouter() {
  const handleMouseEnter = () => {
    preload('/heavy-page-data.json', { as: 'fetch' });
    preinit('/heavy-page.js', { as: 'script' });
  };

  return (
    <nav>
      <Link to="/heavy-page" onMouseEnter={handleMouseEnter}>
        Heavy Page
      </Link>
    </nav>
  );
}
```

## Best Practices

### Component Design

**Keep Components Small and Focused:**

```javascript
function UserProfile({ user }) {
  return (
    <>
      <UserAvatar user={user} />
      <UserInfo user={user} />
      <UserActions user={user} />
    </>
  );
}
```

**Use Composition Over Complex Props:**

```javascript
function Card({ children, header, footer }) {
  return (
    <div className="card">
      <div className="header">{header}</div>
      <div className="body">{children}</div>
      <div className="footer">{footer}</div>
    </div>
  );
}
```

### State Management

**Keep State Local:**

```javascript
function TodoList() {
  const [todos, setTodos] = useState([]);

  return (
    <div>
      {todos.map((todo) => (
        <TodoItem key={todo.id} todo={todo} />
      ))}
    </div>
  );
}
```

**Use Reducers for Complex State:**

```javascript
function TodoApp() {
  const [state, dispatch] = useReducer(todoReducer, initialState);

  return (
    <TodoContext.Provider value={{ state, dispatch }}>
      <TodoList />
    </TodoContext.Provider>
  );
}
```

**Avoid Prop Drilling with Context:**

```javascript
const ThemeContext = createContext('light');

function App() {
  return (
    <ThemeContext value="dark">
      <Layout />
    </ThemeContext>
  );
}

function DeepComponent() {
  const theme = use(ThemeContext);
  return <div className={theme}>Content</div>;
}
```

### Server Components Best Practices

**Direct Database Access:**

```javascript
async function UserList() {
  const users = await db.users.findMany();

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

**Separate Server and Client Logic:**

```javascript
async function ProductPage({ id }) {
  const product = await fetchProduct(id);

  return (
    <>
      <ProductDetails product={product} />
      <AddToCartButton productId={id} />
    </>
  );
}
```

### Form Handling

**Use Server Actions:**

```javascript
function ContactForm() {
  async function handleSubmit(formData) {
    'use server';

    const email = formData.get('email');
    const message = formData.get('message');

    await sendEmail({ email, message });
    redirect('/thank-you');
  }

  return (
    <form action={handleSubmit}>
      <input name="email" type="email" required />
      <textarea name="message" required />
      <button type="submit">Send</button>
    </form>
  );
}
```

**Track Form Status:**

```javascript
function ContactForm() {
  const [state, formAction, isPending] = useActionState(submitForm, null);

  return (
    <form action={formAction}>
      <input name="email" type="email" />
      <SubmitButton />
      {state?.error && <p className="error">{state.error}</p>}
      {state?.success && <p className="success">Message sent!</p>}
    </form>
  );
}

function SubmitButton() {
  const { pending } = useFormStatus();
  return <button disabled={pending}>Submit</button>;
}
```

### TypeScript Integration

**Type Component Props:**

```typescript
interface ButtonProps {
  variant: 'primary' | 'secondary';
  onClick: () => void;
  children: React.ReactNode;
  ref?: Ref<HTMLButtonElement>;
}

function Button({ variant, onClick, children, ref }: ButtonProps) {
  return (
    <button ref={ref} className={variant} onClick={onClick}>
      {children}
    </button>
  );
}
```

**Type Hooks:**

```typescript
interface User {
  id: number;
  name: string;
}

const [user, setUser] = useState<User | null>(null);
const [users, setUsers] = useState<User[]>([]);
```

**Type Server Actions:**

```typescript
async function updateUser(formData: FormData): Promise<{ error?: string }> {
  'use server';

  const name = formData.get('name');
  if (typeof name !== 'string') {
    return { error: 'Invalid name' };
  }

  await db.users.update({ name });
  return {};
}
```

## Anti-Patterns to Avoid

### State Management Anti-Patterns

**Never Declare State as Regular Variables:**

```javascript
function Counter() {
  let count = 0;

  return <button onClick={() => count++}>{count}</button>;
}
```

**Never Mutate State Directly:**

```javascript
function TodoList() {
  const [todos, setTodos] = useState([]);

  const addTodo = (text) => {
    todos.push({ id: Date.now(), text });
    setTodos(todos);
  };
}
```

**Always Use Immutable Updates:**

```javascript
function TodoList() {
  const [todos, setTodos] = useState([]);

  const addTodo = (text) => {
    setTodos([...todos, { id: Date.now(), text }]);
  };
}
```

### Key Anti-Patterns

**Never Use Array Index as Key:**

```javascript
function List({ items }) {
  return items.map((item, index) => <div key={index}>{item.name}</div>);
}
```

**Always Use Stable, Unique Keys:**

```javascript
function List({ items }) {
  return items.map((item) => <div key={item.id}>{item.name}</div>);
}
```

### Component Design Anti-Patterns

**Avoid God Components:**

```javascript
function MassiveComponent() {
  return (
    <div>
      <header>...</header>
      <nav>...</nav>
      <main>...</main>
      <aside>...</aside>
      <footer>...</footer>
    </div>
  );
}
```

**Break Into Smaller Components:**

```javascript
function App() {
  return (
    <div>
      <Header />
      <Navigation />
      <MainContent />
      <Sidebar />
      <Footer />
    </div>
  );
}
```

### Hook Anti-Patterns

**Never Omit Dependencies:**

```javascript
useEffect(() => {
  fetchData(userId);
}, []);
```

**Always Include All Dependencies:**

```javascript
useEffect(() => {
  fetchData(userId);
}, [userId]);
```

**Never Call Hooks Conditionally:**

```javascript
function Component({ condition }) {
  if (condition) {
    const [state, setState] = useState(0);
  }
}
```

**Always Call Hooks at Top Level:**

```javascript
function Component({ condition }) {
  const [state, setState] = useState(0);

  if (condition) {
    setState(1);
  }
}
```

### Prop Drilling Anti-Pattern

**Avoid Excessive Prop Drilling:**

```javascript
function App() {
  const [theme, setTheme] = useState('dark');
  return <Layout theme={theme} setTheme={setTheme} />;
}

function Layout({ theme, setTheme }) {
  return <Header theme={theme} setTheme={setTheme} />;
}

function Header({ theme, setTheme }) {
  return <ThemeButton theme={theme} setTheme={setTheme} />;
}
```

**Use Context Instead:**

```javascript
const ThemeContext = createContext('light');

function App() {
  const [theme, setTheme] = useState('dark');
  return (
    <ThemeContext value={{ theme, setTheme }}>
      <Layout />
    </ThemeContext>
  );
}

function ThemeButton() {
  const { theme, setTheme } = use(ThemeContext);
  return <button onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}>Toggle</button>;
}
```

### Context Anti-Patterns

**Don't Overuse Context:**

- Context is not a state management solution
- Don't put all state in context
- Context re-renders all consumers on change

**Split Contexts:**

```javascript
const UserContext = createContext(null);
const ThemeContext = createContext('light');

function App() {
  const [user, setUser] = useState(null);
  const [theme, setTheme] = useState('light');

  return (
    <UserContext value={{ user, setUser }}>
      <ThemeContext value={{ theme, setTheme }}>
        <Layout />
      </ThemeContext>
    </UserContext>
  );
}
```

## Common Gotchas

### Async State Updates

State updates are asynchronous and don't reflect immediately:

```javascript
function Counter() {
  const [count, setCount] = useState(0);

  const handleClick = () => {
    setCount(count + 1);
    console.log(count);
  };
}
```

**Solution - Use Updater Function:**

```javascript
const handleClick = () => {
  setCount((prev) => {
    console.log(prev);
    return prev + 1;
  });
};
```

### Effect Dependencies

Missing dependencies cause stale closures:

```javascript
useEffect(() => {
  const interval = setInterval(() => {
    setCount(count + 1);
  }, 1000);
  return () => clearInterval(interval);
}, []);
```

**Solution - Include Dependencies or Use Updater:**

```javascript
useEffect(() => {
  const interval = setInterval(() => {
    setCount((prev) => prev + 1);
  }, 1000);
  return () => clearInterval(interval);
}, []);
```

### Ref Current Access

Refs aren't reactive:

```javascript
function Component() {
  const ref = useRef(0);

  const increment = () => {
    ref.current++;
    console.log(ref.current);
  };

  return <div>{ref.current}</div>;
}
```

Changing `ref.current` doesn't trigger re-renders. Use state for reactive values.

### Form Action Signatures

Server Actions wrapped with `useActionState` have different signatures:

```javascript
async function myAction(currentState, formData) {
  const value = formData.get('field');
}
```

First parameter is previous state, second is form data.

### Double Renders in Development

Strict Mode intentionally double-renders in development:

- Effects run twice
- Render functions execute twice
- This is intentional to catch bugs
- Only happens in development

### Hydration Mismatches

Server and client HTML must match:

```javascript
function Component() {
  return <div>{typeof window === 'undefined' ? 'server' : 'client'}</div>;
}
```

**Solution - Use useEffect:**

```javascript
function Component() {
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  return <div>{isClient ? 'client' : 'server'}</div>;
}
```

### Server Component Limitations

Server Components cannot:

- Use hooks (useState, useEffect, etc.)
- Access browser APIs
- Handle events
- Use Context (directly)

**Solution - Use Client Components:**

```javascript
'use client';

function InteractiveButton() {
  const [clicked, setClicked] = useState(false);
  return <button onClick={() => setClicked(true)}>Click me</button>;
}
```

## Security Considerations

### XSS Prevention

**React's Default Protection:**
React automatically escapes values in JSX to prevent XSS:

```javascript
const userInput = '<script>alert("xss")</script>';
return <div>{userInput}</div>;
```

This renders as text, not executable code.

### dangerouslySetInnerHTML

**Avoid When Possible:**

```javascript
<div dangerouslySetInnerHTML={{ __html: userContent }} />
```

**Always Sanitize:**

```javascript
import DOMPurify from 'dompurify';

function SafeHTML({ html }) {
  const sanitized = DOMPurify.sanitize(html);
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

**Encapsulate in Component:**

```javascript
function SanitizedHTML({ html }) {
  const clean = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a'],
    ALLOWED_ATTR: ['href'],
  });

  return <div dangerouslySetInnerHTML={{ __html: clean }} />;
}
```

### URL Validation

**Prevent javascript: URLs:**

```javascript
function SafeLink({ href, children }) {
  const url = new URL(href, window.location.origin);
  const allowed = ['http:', 'https:'];

  if (!allowed.includes(url.protocol)) {
    return <span>{children}</span>;
  }

  return <a href={href}>{children}</a>;
}
```

### Content Security Policy

Implement strong CSP headers:

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://trusted-cdn.com; style-src 'self' 'unsafe-inline';
```

### Server Action Security

**Validate All Inputs:**

```javascript
async function updateUser(formData) {
  'use server';

  const name = formData.get('name');

  if (typeof name !== 'string' || name.length < 1 || name.length > 100) {
    throw new Error('Invalid name');
  }

  const sanitizedName = name.trim();
  await db.users.update({ name: sanitizedName });
}
```

**Authenticate Requests:**

```javascript
async function deleteUser(userId) {
  'use server';

  const session = await getSession();
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized');
  }

  await db.users.delete({ id: userId });
}
```

### Environment Variables

**Never Expose Secrets to Client:**

```javascript
const API_KEY = process.env.API_KEY;
```

**Use Public Prefix for Client Variables:**

```javascript
const PUBLIC_API_URL = process.env.NEXT_PUBLIC_API_URL;
```

### Dependency Security

**Keep Dependencies Updated:**

```bash
npm outdated
npm update
npm audit fix
```

**Use Security Linters:**

```bash
npm install --save-dev eslint-plugin-react-security
```

## Code Examples

### Complete Form with Server Actions

```javascript
'use server';

import { redirect } from 'next/navigation';
import { z } from 'zod';

const schema = z.object({
  email: z.string().email(),
  message: z.string().min(10).max(1000),
});

export async function submitContact(previousState, formData) {
  const data = {
    email: formData.get('email'),
    message: formData.get('message'),
  };

  const result = schema.safeParse(data);

  if (!result.success) {
    return { error: result.error.flatten().fieldErrors };
  }

  try {
    await db.contacts.create({ data: result.data });
    redirect('/thank-you');
  } catch (error) {
    return { error: 'Failed to submit form' };
  }
}
```

```javascript
'use client';

import { useActionState } from 'react';
import { useFormStatus } from 'react-dom';
import { submitContact } from './actions';

function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}

export default function ContactForm() {
  const [state, formAction] = useActionState(submitContact, null);

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="email">Email</label>
        <input id="email" name="email" type="email" required />
        {state?.error?.email && <span className="error">{state.error.email}</span>}
      </div>

      <div>
        <label htmlFor="message">Message</label>
        <textarea id="message" name="message" required />
        {state?.error?.message && <span className="error">{state.error.message}</span>}
      </div>

      <SubmitButton />

      {state?.error && typeof state.error === 'string' && <p className="error">{state.error}</p>}
    </form>
  );
}
```

### Optimistic Updates Example

```javascript
'use client';

import { useOptimistic, startTransition } from 'react';
import { addTodo } from './actions';

export default function TodoList({ initialTodos }) {
  const [optimisticTodos, addOptimisticTodo] = useOptimistic(initialTodos, (state, newTodo) => [
    ...state,
    { ...newTodo, id: Date.now(), pending: true },
  ]);

  const handleSubmit = async (formData) => {
    const text = formData.get('text');

    addOptimisticTodo({ text });

    startTransition(async () => {
      await addTodo(text);
    });
  };

  return (
    <div>
      <form action={handleSubmit}>
        <input name="text" required />
        <button type="submit">Add Todo</button>
      </form>

      <ul>
        {optimisticTodos.map((todo) => (
          <li key={todo.id} style={{ opacity: todo.pending ? 0.5 : 1 }}>
            {todo.text}
            {todo.pending && <span> (Saving...)</span>}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### Server Component with Data Fetching

```javascript
import { Suspense } from 'react';

async function UserList() {
  const users = await db.users.findMany({
    orderBy: { createdAt: 'desc' },
    take: 10,
  });

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>
          <UserCard user={user} />
        </li>
      ))}
    </ul>
  );
}

async function UserStats() {
  const stats = await db.users.aggregate({
    _count: true,
    _avg: { age: true },
  });

  return (
    <div>
      <p>Total Users: {stats._count}</p>
      <p>Average Age: {stats._avg.age}</p>
    </div>
  );
}

export default function UsersPage() {
  return (
    <div>
      <h1>Users</h1>

      <Suspense fallback={<div>Loading stats...</div>}>
        <UserStats />
      </Suspense>

      <Suspense fallback={<div>Loading users...</div>}>
        <UserList />
      </Suspense>
    </div>
  );
}
```

### Custom Hook with use API

```javascript
import { use, cache } from 'react';

const getUser = cache(async (id) => {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
});

function useUser(userId) {
  if (!userId) {
    return null;
  }

  const userPromise = getUser(userId);
  return use(userPromise);
}

export default function UserProfile({ userId }) {
  const user = useUser(userId);

  if (!user) {
    return <div>No user selected</div>;
  }

  return (
    <div>
      <h2>{user.name}</h2>
      <p>{user.email}</p>
    </div>
  );
}
```

### Error Boundary Implementation

```javascript
'use client';

import { Component } from 'react';

export class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
    this.props.onError?.(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback?.(this.state.error) || (
          <div>
            <h2>Something went wrong</h2>
            <details>
              <summary>Error details</summary>
              <pre>{this.state.error?.message}</pre>
            </details>
            <button onClick={() => this.setState({ hasError: false })}>Try again</button>
          </div>
        )
      );
    }

    return this.props.children;
  }
}
```

### Streaming SSR with Suspense

```javascript
import { Suspense } from 'react';

async function SlowComponent() {
  await new Promise((resolve) => setTimeout(resolve, 3000));
  return <div>Slow content loaded!</div>;
}

async function FastComponent() {
  await new Promise((resolve) => setTimeout(resolve, 100));
  return <div>Fast content loaded!</div>;
}

export default function StreamingPage() {
  return (
    <div>
      <h1>Streaming SSR Demo</h1>

      <Suspense fallback={<div>Loading fast content...</div>}>
        <FastComponent />
      </Suspense>

      <Suspense fallback={<div>Loading slow content...</div>}>
        <SlowComponent />
      </Suspense>
    </div>
  );
}
```

### Progressive Enhancement Form

```javascript
'use client';

import { useActionState } from 'react';

export default function NewsletterForm() {
  const [state, formAction] = useActionState(
    async (previousState, formData) => {
      const email = formData.get('email');

      const response = await fetch('/api/newsletter', {
        method: 'POST',
        body: JSON.stringify({ email }),
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) {
        return { error: 'Failed to subscribe' };
      }

      return { success: true };
    },
    null,
    '/newsletter/subscribe'
  );

  if (state?.success) {
    return <p>Thank you for subscribing!</p>;
  }

  return (
    <form action={formAction}>
      <input name="email" type="email" placeholder="Enter your email" required />
      <button type="submit">Subscribe</button>
      {state?.error && <p className="error">{state.error}</p>}
    </form>
  );
}
```

## Version-Specific Notes

### React 19.0.0 (December 2024)

- Initial stable release
- All features documented above
- Server Components stable
- Actions and form features stable

### React 19.1.0 (March 2025)

- Minor improvements and bug fixes
- Enhanced error reporting
- Performance optimizations

### React 19.2.0 (October 2025)

- Latest stable version
- Continued refinements
- Additional optimizations

### Breaking Changes from React 18

**Critical:**

- New JSX transform required
- `propTypes` removed
- `defaultProps` removed for function components
- `ReactDOM.render` removed (use `createRoot`)
- `forwardRef` deprecated (use ref as prop)

**TypeScript:**

- `useRef` requires initial value
- Ref callbacks must use block statements
- `ReactElement` props default to `unknown`

**Testing:**

- `react-test-renderer/shallow` removed
- Move `act` from `react-dom/test-utils` to `react`

### Future Deprecations

React team signals these may be deprecated in future versions:

- `forwardRef` (deprecated but functional in 19.x)
- Class component patterns
- Legacy context API

## References

### Official Documentation

- React 19 Release Post: https://react.dev/blog/2024/12/05/react-19
- React 19 Upgrade Guide: https://react.dev/blog/2024/04/25/react-19-upgrade-guide
- React 19.2 Release: https://react.dev/blog/2025/10/01/react-19-2
- API Reference: https://react.dev/reference/react
- Hooks Reference: https://react.dev/reference/react/hooks
- Server Functions: https://react.dev/reference/rsc/server-functions

### Community Resources

- React 19 Best Practices: https://www.telerik.com/blogs/react-design-patterns-best-practices
- React & Next.js 2025 Guide: https://strapi.io/blog/react-and-nextjs-in-2025-modern-best-practices
- React 19 Migration Guide (Codemod): https://docs.codemod.com/guides/migrations/react-18-19
- Custom Elements Everywhere: https://custom-elements-everywhere.com/

### Security Resources

- OWASP XSS Prevention: https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
- React XSS Guide: https://www.stackhawk.com/blog/react-xss-guide-examples-and-prevention/
- DOMPurify Library: https://github.com/cure53/DOMPurify

### Performance Resources

- React Compiler Documentation: https://react.dev/learn/react-compiler
- React Performance Patterns: https://www.telerik.com/blogs/react-design-patterns-best-practices

### Testing Resources

- React Testing Library: https://testing-library.com/react
- Jest Documentation: https://jestjs.io/

---

**Document Generated:** November 19, 2025
**Research Scope:** React 19.0.0 - 19.2.0
**Next Review:** Check for React 19.3+ updates or React 20 announcements

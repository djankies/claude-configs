---
name: server-vs-client-boundaries
description: Teaches when to use Server Components vs Client Components in React 19, including the 'use client' directive and boundary patterns. Use when architecting components, choosing component types, or working with Server Components.
allowed-tools: Read, Write, Edit, Glob, Grep
version: 1.0.0
---

# Server vs Client Component Boundaries

<role>
This skill teaches you how to choose between Server and Client Components and manage the boundaries between them effectively.
</role>

<when-to-activate>
This skill activates when:

- User mentions Server Components, Client Components, or `'use client'`
- Architecting component hierarchy
- Need to access server-only APIs or client-only APIs
- Working with frameworks supporting React Server Components (Next.js, Remix)
- Encountering errors about hooks or browser APIs in Server Components
</when-to-activate>

<overview>
React 19 supports two component types:

**Server Components (default):**
- Render on the server before being sent to client
- Can access databases, file systems, server-only APIs directly
- Cannot use hooks (useState, useEffect, etc.)
- Cannot access browser APIs
- Reduce JavaScript bundle size by 20%-90%
- No `'use client'` directive needed (default)

**Client Components:**
- Render on client (can also pre-render on server for HTML)
- Can use hooks and browser APIs
- Support interactivity (onClick, onChange, etc.)
- Larger JavaScript bundle (sent to browser)
- Require `'use client'` directive at top of file

**Key Decision:**
- If needs interactivity/hooks/browser → Client Component
- If can be static/server-only data → Server Component
</overview>

<workflow>
## Decision Flow

**Step 1: Identify Component Requirements**

Ask these questions:
1. Does it need hooks? → Client Component
2. Does it need event handlers? → Client Component
3. Does it access browser APIs? → Client Component
4. Does it access server APIs/databases directly? → Server Component
5. Is it purely presentational with no interactivity? → Server Component

**Step 2: Place `'use client'` Directive**

Only where needed:

```javascript
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

**Step 3: Compose Server and Client**

Server Components can import Client Components:

```javascript
import { Counter } from './Counter';

async function Page() {
  const data = await db.getData();

  return (
    <div>
      <h1>{data.title}</h1>
      <Counter />
    </div>
  );
}
```

**Step 4: Avoid Common Mistakes**

❌ Client Components cannot import Server Components:

```javascript
'use client';

import ServerComponent from './ServerComponent';

export function ClientComponent() {
  return <ServerComponent />;
}
```

✅ Pass Server Components as children:

```javascript
<ClientWrapper>
  <ServerComponent />
</ClientWrapper>
```

</workflow>

<conditional-workflows>
## Boundary Patterns

**If you need interactivity at leaf nodes:**

```javascript
async function ProductPage({ id }) {
  const product = await db.products.find(id);

  return (
    <>
      <ProductDetails product={product} />
      <AddToCartButton productId={id} />
    </>
  );
}
```

**If you need server data in client component:**

Pass data as props (not import):

```javascript
async function ServerComponent() {
  const data = await fetchData();

  return <ClientComponent data={data} />;
}
```

**If you need to share server logic:**

Use Server Actions:

```javascript
async function ServerComponent() {
  async function serverAction() {
    'use server';
    await db.update(...);
  }

  return <ClientForm action={serverAction} />;
}
```

</conditional-workflows>

<progressive-disclosure>
## Reference Files

For detailed information:

- **Server Components**: See `../../../research/react-19-comprehensive.md` (lines 71-82)
- **Server Actions**: See `../../forms/skills/server-actions/SKILL.md`
- **Component Composition**: See `../component-composition/SKILL.md`

Load references when specific patterns are needed.
</progressive-disclosure>

<examples>
## Example 1: Product Page Architecture

```javascript
import { ProductImage } from './ProductImage';
import { AddToCart } from './AddToCart';
import { Reviews } from './Reviews';

async function ProductPage({ productId }) {
  const product = await db.products.find(productId);
  const reviews = await db.reviews.findByProduct(productId);

  return (
    <main>
      <ProductImage src={product.image} alt={product.name} />

      <section>
        <h1>{product.name}</h1>
        <p>{product.description}</p>
        <p>${product.price}</p>

        <AddToCart productId={productId} />
      </section>

      <Reviews reviews={reviews} />
    </main>
  );
}
```

```javascript
'use client';

import { useState } from 'react';

export function AddToCart({ productId }) {
  const [adding, setAdding] = useState(false);

  async function handleAdd() {
    setAdding(true);
    await fetch('/api/cart', {
      method: 'POST',
      body: JSON.stringify({ productId }),
    });
    setAdding(false);
  }

  return (
    <button onClick={handleAdd} disabled={adding}>
      {adding ? 'Adding...' : 'Add to Cart'}
    </button>
  );
}
```

## Example 2: Dashboard with Real-Time Updates

```javascript
import { DashboardStats } from './DashboardStats';
import { LiveMetrics } from './LiveMetrics';

async function Dashboard() {
  const stats = await db.stats.getLatest();

  return (
    <>
      <DashboardStats stats={stats} />

      <LiveMetrics />
    </>
  );
}
```

```javascript
'use client';

import { useEffect, useState } from 'react';

export function LiveMetrics() {
  const [metrics, setMetrics] = useState(null);

  useEffect(() => {
    const ws = new WebSocket('/api/metrics');

    ws.onmessage = (event) => {
      setMetrics(JSON.parse(event.data));
    };

    return () => ws.close();
  }, []);

  if (!metrics) return <div>Connecting...</div>;

  return <div>Active Users: {metrics.activeUsers}</div>;
}
```

## Example 3: Form with Server Action

```javascript
async function ContactPage() {
  async function submitContact(formData) {
    'use server';

    const email = formData.get('email');
    const message = formData.get('message');

    await db.contacts.create({ email, message });
  }

  return (
    <form action={submitContact}>
      <input name="email" type="email" />
      <textarea name="message" />
      <button type="submit">Send</button>
    </form>
  );
}
```

</examples>

<constraints>
## MUST

- Add `'use client'` directive at top of file for Client Components
- Place `'use client'` before any imports
- Pass data from Server to Client as props (serialize)
- Use Server Actions for server-side logic called from Client

## SHOULD

- Keep most components as Server Components (smaller bundle)
- Push `'use client'` to leaf nodes (smallest boundary)
- Use Server Components for data fetching
- Use Client Components only for interactivity

## NEVER

- Import Server Components into Client Components
- Use hooks in Server Components
- Access browser APIs in Server Components
- Pass non-serializable props (functions, classes, symbols)
- Forget `'use client'` directive (will fail at runtime)

</constraints>

<validation>
## After Implementation

1. **Verify Component Type**:
   - Client Components have `'use client'` at top
   - Server Components have NO directive (default)
   - No hooks/event handlers in Server Components

2. **Check Data Flow**:
   - Server → Client: Props are serializable
   - Client → Server: Use Server Actions
   - No Server Components imported in Client

3. **Test Functionality**:
   - Server Components fetch data correctly
   - Client Components handle interaction
   - No hydration mismatches
   - No runtime errors about hooks/browser APIs

4. **Review Bundle Size**:
   - Only necessary components are Client Components
   - Most components stay on server
   - JavaScript bundle is minimized

</validation>

---

## Quick Reference

| Feature | Server Component | Client Component |
|---------|------------------|------------------|
| Directive | None (default) | `'use client'` |
| Hooks | ❌ No | ✅ Yes |
| Event handlers | ❌ No | ✅ Yes |
| Browser APIs | ❌ No | ✅ Yes |
| Async/await | ✅ Yes (top-level) | ⚠️ Limited |
| Database access | ✅ Yes | ❌ No (use Server Actions) |
| Import Server Components | ✅ Yes | ❌ No (use children) |
| Bundle size | 📦 Zero | 📦 Sent to client |

For comprehensive Server Components documentation, see: `research/react-19-comprehensive.md` lines 71-82, 644-730.

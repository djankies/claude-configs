# Async Request APIs - Migration Patterns

Complete before/after examples for migrating to async request APIs in Next.js 16.

## Table of Contents

- [Page Components](#page-components)
- [Layout Components](#layout-components)
- [Route Handlers](#route-handlers)
- [Server Actions](#server-actions)
- [Middleware Patterns](#middleware-patterns)
- [Authentication Patterns](#authentication-patterns)
- [Complex Scenarios](#complex-scenarios)

---

## Page Components

### Simple Dynamic Route

**Before (Next.js 15):**
```typescript
export default function UserPage({ params }: { params: { id: string } }) {
  return <div>User: {params.id}</div>;
}
```

**After (Next.js 16):**
```typescript
export default async function UserPage({
  params
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params;
  return <div>User: {id}</div>;
}
```

### Page with Search Params

**Before (Next.js 15):**
```typescript
export default function SearchPage({
  searchParams
}: {
  searchParams: { q?: string; sort?: string }
}) {
  const query = searchParams.q || '';
  const sort = searchParams.sort || 'relevance';

  return (
    <div>
      <h1>Search: {query}</h1>
      <p>Sort: {sort}</p>
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
export default async function SearchPage({
  searchParams
}: {
  searchParams: Promise<{ q?: string; sort?: string }>
}) {
  const params = await searchParams;
  const query = params.q || '';
  const sort = params.sort || 'relevance';

  return (
    <div>
      <h1>Search: {query}</h1>
      <p>Sort: {sort}</p>
    </div>
  );
}
```

### Page with Both Params and SearchParams

**Before (Next.js 15):**
```typescript
export default function ProductPage({
  params,
  searchParams
}: {
  params: { id: string };
  searchParams: { variant?: string; size?: string };
}) {
  return (
    <div>
      <h1>Product {params.id}</h1>
      <p>Variant: {searchParams.variant}</p>
      <p>Size: {searchParams.size}</p>
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
export default async function ProductPage({
  params,
  searchParams
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ variant?: string; size?: string }>;
}) {
  const [{ id }, search] = await Promise.all([params, searchParams]);

  return (
    <div>
      <h1>Product {id}</h1>
      <p>Variant: {search.variant}</p>
      <p>Size: {search.size}</p>
    </div>
  );
}
```

### Page with Metadata Generation

**Before (Next.js 15):**
```typescript
import { Metadata } from 'next';

export async function generateMetadata({
  params
}: {
  params: { slug: string }
}): Promise<Metadata> {
  const post = await fetchPost(params.slug);

  return {
    title: post.title,
    description: post.excerpt
  };
}

export default async function BlogPost({ params }: { params: { slug: string } }) {
  const post = await fetchPost(params.slug);

  return (
    <article>
      <h1>{post.title}</h1>
      <div>{post.content}</div>
    </article>
  );
}
```

**After (Next.js 16):**
```typescript
import { Metadata } from 'next';

export async function generateMetadata({
  params
}: {
  params: Promise<{ slug: string }>
}): Promise<Metadata> {
  const { slug } = await params;
  const post = await fetchPost(slug);

  return {
    title: post.title,
    description: post.excerpt
  };
}

export default async function BlogPost({
  params
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params;
  const post = await fetchPost(slug);

  return (
    <article>
      <h1>{post.title}</h1>
      <div>{post.content}</div>
    </article>
  );
}
```

### Multi-Segment Dynamic Route

**Before (Next.js 15):**
```typescript
export default function ProductDetailPage({
  params
}: {
  params: { category: string; subcategory: string; id: string }
}) {
  return (
    <div>
      <nav>
        {params.category} → {params.subcategory}
      </nav>
      <h1>Product {params.id}</h1>
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
export default async function ProductDetailPage({
  params
}: {
  params: Promise<{ category: string; subcategory: string; id: string }>
}) {
  const { category, subcategory, id } = await params;

  return (
    <div>
      <nav>
        {category} → {subcategory}
      </nav>
      <h1>Product {id}</h1>
    </div>
  );
}
```

---

## Layout Components

### Simple Layout with Params

**Before (Next.js 15):**
```typescript
export default function CategoryLayout({
  children,
  params
}: {
  children: React.ReactNode;
  params: { category: string };
}) {
  return (
    <div>
      <aside>Category: {params.category}</aside>
      <main>{children}</main>
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
export default async function CategoryLayout({
  children,
  params
}: {
  children: React.ReactNode;
  params: Promise<{ category: string }>;
}) {
  const { category } = await params;

  return (
    <div>
      <aside>Category: {category}</aside>
      <main>{children}</main>
    </div>
  );
}
```

### Root Layout with Locale

**Before (Next.js 15):**
```typescript
export default function RootLayout({
  children,
  params
}: {
  children: React.ReactNode;
  params: { locale: string };
}) {
  return (
    <html lang={params.locale}>
      <body>{children}</body>
    </html>
  );
}
```

**After (Next.js 16):**
```typescript
export default async function RootLayout({
  children,
  params
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;

  return (
    <html lang={locale}>
      <body>{children}</body>
    </html>
  );
}
```

### Layout with Metadata and Params

**Before (Next.js 15):**
```typescript
import { Metadata } from 'next';

export async function generateMetadata({
  params
}: {
  params: { workspace: string }
}): Promise<Metadata> {
  const workspace = await fetchWorkspace(params.workspace);

  return {
    title: workspace.name
  };
}

export default function WorkspaceLayout({
  children,
  params
}: {
  children: React.ReactNode;
  params: { workspace: string };
}) {
  return (
    <div data-workspace={params.workspace}>
      {children}
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
import { Metadata } from 'next';

export async function generateMetadata({
  params
}: {
  params: Promise<{ workspace: string }>
}): Promise<Metadata> {
  const { workspace } = await params;
  const data = await fetchWorkspace(workspace);

  return {
    title: data.name
  };
}

export default async function WorkspaceLayout({
  children,
  params
}: {
  children: React.ReactNode;
  params: Promise<{ workspace: string }>;
}) {
  const { workspace } = await params;

  return (
    <div data-workspace={workspace}>
      {children}
    </div>
  );
}
```

---

## Route Handlers

### GET with Params

**Before (Next.js 15):**
```typescript
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const user = await fetchUser(params.id);

  return Response.json(user);
}
```

**After (Next.js 16):**
```typescript
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const user = await fetchUser(id);

  return Response.json(user);
}
```

### POST with Headers and Cookies

**Before (Next.js 15):**
```typescript
import { cookies, headers } from 'next/headers';

export async function POST(request: Request) {
  const headersList = headers();
  const authorization = headersList.get('authorization');

  const cookieStore = cookies();
  const sessionId = cookieStore.get('sessionId');

  const body = await request.json();

  return Response.json({ success: true });
}
```

**After (Next.js 16):**
```typescript
import { cookies, headers } from 'next/headers';

export async function POST(request: Request) {
  const [headersList, cookieStore, body] = await Promise.all([
    headers(),
    cookies(),
    request.json()
  ]);

  const authorization = headersList.get('authorization');
  const sessionId = cookieStore.get('sessionId');

  return Response.json({ success: true });
}
```

### PATCH with All Request Data

**Before (Next.js 15):**
```typescript
import { cookies, headers } from 'next/headers';

export async function PATCH(
  request: Request,
  { params }: { params: { id: string } }
) {
  const headersList = headers();
  const contentType = headersList.get('content-type');

  const cookieStore = cookies();
  const token = cookieStore.get('token');

  if (!token) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();

  return Response.json({
    id: params.id,
    updated: body
  });
}
```

**After (Next.js 16):**
```typescript
import { cookies, headers } from 'next/headers';

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const [{ id }, headersList, cookieStore, body] = await Promise.all([
    params,
    headers(),
    cookies(),
    request.json()
  ]);

  const contentType = headersList.get('content-type');
  const token = cookieStore.get('token');

  if (!token) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  return Response.json({
    id,
    updated: body
  });
}
```

### DELETE with Draft Mode

**Before (Next.js 15):**
```typescript
import { draftMode } from 'next/headers';

export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  const { isEnabled } = draftMode();

  if (isEnabled) {
    return Response.json({ error: 'Cannot delete in draft mode' }, { status: 403 });
  }

  await deleteItem(params.id);

  return Response.json({ success: true });
}
```

**After (Next.js 16):**
```typescript
import { draftMode } from 'next/headers';

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const [{ id }, draft] = await Promise.all([params, draftMode()]);

  if (draft.isEnabled) {
    return Response.json({ error: 'Cannot delete in draft mode' }, { status: 403 });
  }

  await deleteItem(id);

  return Response.json({ success: true });
}
```

---

## Server Actions

### Form Action with Cookies

**Before (Next.js 15):**
```typescript
'use server';

import { cookies } from 'next/headers';

export async function updateProfile(formData: FormData) {
  const cookieStore = cookies();
  const userId = cookieStore.get('userId')?.value;

  if (!userId) {
    return { error: 'Not authenticated' };
  }

  const name = formData.get('name');

  return { success: true };
}
```

**After (Next.js 16):**
```typescript
'use server';

import { cookies } from 'next/headers';

export async function updateProfile(formData: FormData) {
  const cookieStore = await cookies();
  const userId = cookieStore.get('userId')?.value;

  if (!userId) {
    return { error: 'Not authenticated' };
  }

  const name = formData.get('name');

  return { success: true };
}
```

### Action with Headers

**Before (Next.js 15):**
```typescript
'use server';

import { headers } from 'next/headers';

export async function submitForm(formData: FormData) {
  const headersList = headers();
  const referer = headersList.get('referer');

  return { success: true, referer };
}
```

**After (Next.js 16):**
```typescript
'use server';

import { headers } from 'next/headers';

export async function submitForm(formData: FormData) {
  const headersList = await headers();
  const referer = headersList.get('referer');

  return { success: true, referer };
}
```

---

## Authentication Patterns

### Session Check

**Before (Next.js 15):**
```typescript
import { cookies } from 'next/headers';

async function getSession() {
  const cookieStore = cookies();
  const sessionToken = cookieStore.get('session')?.value;

  if (!sessionToken) {
    return null;
  }

  return await verifySession(sessionToken);
}

export default async function ProtectedPage() {
  const session = await getSession();

  if (!session) {
    redirect('/login');
  }

  return <div>Welcome, {session.user.name}</div>;
}
```

**After (Next.js 16):**
```typescript
import { cookies } from 'next/headers';

async function getSession() {
  const cookieStore = await cookies();
  const sessionToken = cookieStore.get('session')?.value;

  if (!sessionToken) {
    return null;
  }

  return await verifySession(sessionToken);
}

export default async function ProtectedPage() {
  const session = await getSession();

  if (!session) {
    redirect('/login');
  }

  return <div>Welcome, {session.user.name}</div>;
}
```

### API Route Authentication

**Before (Next.js 15):**
```typescript
import { cookies, headers } from 'next/headers';

async function authenticate() {
  const headersList = headers();
  const authorization = headersList.get('authorization');

  if (authorization) {
    const token = authorization.replace('Bearer ', '');
    return await verifyToken(token);
  }

  const cookieStore = cookies();
  const sessionToken = cookieStore.get('session')?.value;

  if (sessionToken) {
    return await verifySession(sessionToken);
  }

  return null;
}

export async function GET() {
  const user = await authenticate();

  if (!user) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  return Response.json({ user });
}
```

**After (Next.js 16):**
```typescript
import { cookies, headers } from 'next/headers';

async function authenticate() {
  const [headersList, cookieStore] = await Promise.all([
    headers(),
    cookies()
  ]);

  const authorization = headersList.get('authorization');

  if (authorization) {
    const token = authorization.replace('Bearer ', '');
    return await verifyToken(token);
  }

  const sessionToken = cookieStore.get('session')?.value;

  if (sessionToken) {
    return await verifySession(sessionToken);
  }

  return null;
}

export async function GET() {
  const user = await authenticate();

  if (!user) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  return Response.json({ user });
}
```

---

## Complex Scenarios

### E-commerce Product Page

**Before (Next.js 15):**
```typescript
import { cookies, headers } from 'next/headers';
import { Metadata } from 'next';

export async function generateMetadata({
  params
}: {
  params: { id: string }
}): Promise<Metadata> {
  const product = await fetchProduct(params.id);

  return {
    title: product.name,
    description: product.description
  };
}

export default async function ProductPage({
  params,
  searchParams
}: {
  params: { id: string };
  searchParams: { variant?: string };
}) {
  const cookieStore = cookies();
  const currency = cookieStore.get('currency')?.value || 'USD';

  const headersList = headers();
  const userAgent = headersList.get('user-agent');
  const isMobile = /mobile/i.test(userAgent || '');

  const product = await fetchProduct(params.id);
  const selectedVariant = searchParams.variant || product.defaultVariant;

  return (
    <div>
      <h1>{product.name}</h1>
      <p>Price: {formatPrice(product.price, currency)}</p>
      <p>Variant: {selectedVariant}</p>
      {isMobile && <MobileActions />}
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
import { cookies, headers } from 'next/headers';
import { Metadata } from 'next';

export async function generateMetadata({
  params
}: {
  params: Promise<{ id: string }>
}): Promise<Metadata> {
  const { id } = await params;
  const product = await fetchProduct(id);

  return {
    title: product.name,
    description: product.description
  };
}

export default async function ProductPage({
  params,
  searchParams
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ variant?: string }>;
}) {
  const [{ id }, search, cookieStore, headersList] = await Promise.all([
    params,
    searchParams,
    cookies(),
    headers()
  ]);

  const currency = cookieStore.get('currency')?.value || 'USD';
  const userAgent = headersList.get('user-agent');
  const isMobile = /mobile/i.test(userAgent || '');

  const product = await fetchProduct(id);
  const selectedVariant = search.variant || product.defaultVariant;

  return (
    <div>
      <h1>{product.name}</h1>
      <p>Price: {formatPrice(product.price, currency)}</p>
      <p>Variant: {selectedVariant}</p>
      {isMobile && <MobileActions />}
    </div>
  );
}
```

### Dashboard with Permissions

**Before (Next.js 15):**
```typescript
import { cookies, headers } from 'next/headers';
import { redirect } from 'next/navigation';

async function checkPermissions(userId: string, workspaceId: string) {
  const permissions = await fetchPermissions(userId, workspaceId);
  return permissions;
}

export default async function WorkspaceDashboard({
  params
}: {
  params: { workspace: string }
}) {
  const cookieStore = cookies();
  const userId = cookieStore.get('userId')?.value;

  if (!userId) {
    redirect('/login');
  }

  const headersList = headers();
  const timezone = headersList.get('x-timezone') || 'UTC';

  const permissions = await checkPermissions(userId, params.workspace);

  if (!permissions.canView) {
    redirect('/unauthorized');
  }

  return (
    <div>
      <h1>Workspace: {params.workspace}</h1>
      <p>Timezone: {timezone}</p>
      {permissions.canEdit && <EditButton />}
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
import { cookies, headers } from 'next/headers';
import { redirect } from 'next/navigation';

async function checkPermissions(userId: string, workspaceId: string) {
  const permissions = await fetchPermissions(userId, workspaceId);
  return permissions;
}

export default async function WorkspaceDashboard({
  params
}: {
  params: Promise<{ workspace: string }>
}) {
  const [{ workspace }, cookieStore, headersList] = await Promise.all([
    params,
    cookies(),
    headers()
  ]);

  const userId = cookieStore.get('userId')?.value;

  if (!userId) {
    redirect('/login');
  }

  const timezone = headersList.get('x-timezone') || 'UTC';
  const permissions = await checkPermissions(userId, workspace);

  if (!permissions.canView) {
    redirect('/unauthorized');
  }

  return (
    <div>
      <h1>Workspace: {workspace}</h1>
      <p>Timezone: {timezone}</p>
      {permissions.canEdit && <EditButton />}
    </div>
  );
}
```

---

## Type Helpers

### Reusable Type Definitions

```typescript
type AsyncParams<T = Record<string, string>> = Promise<T>;
type AsyncSearchParams = Promise<Record<string, string | string[] | undefined>>;

type PageProps<P = Record<string, string>, S = Record<string, string | string[] | undefined>> = {
  params: AsyncParams<P>;
  searchParams: AsyncSearchParams;
};

type LayoutProps<P = Record<string, string>> = {
  children: React.ReactNode;
  params: AsyncParams<P>;
};

type RouteContext<P = Record<string, string>> = {
  params: AsyncParams<P>;
};

export default async function Page({
  params,
  searchParams
}: PageProps<{ id: string }>) {
  const { id } = await params;
  const search = await searchParams;

  return <div>{id}</div>;
}

export async function GET(
  request: Request,
  context: RouteContext<{ id: string }>
) {
  const { id } = await context.params;
  return Response.json({ id });
}
```

---

## Migration Checklist by Component Type

### For Pages:
- [ ] Add `Promise<>` wrapper to `params` type
- [ ] Add `Promise<>` wrapper to `searchParams` type
- [ ] Make component `async`
- [ ] Add `await` before accessing `params`
- [ ] Add `await` before accessing `searchParams`
- [ ] Use `Promise.all()` for parallel resolution

### For Layouts:
- [ ] Add `Promise<>` wrapper to `params` type
- [ ] Make component `async`
- [ ] Add `await` before accessing `params`

### For Route Handlers:
- [ ] Add `Promise<>` wrapper to context `params` type
- [ ] Add `await` before accessing `params`
- [ ] Add `await` to `cookies()` calls
- [ ] Add `await` to `headers()` calls
- [ ] Add `await` to `draftMode()` calls
- [ ] Use `Promise.all()` for parallel resolution

### For Server Actions:
- [ ] Add `await` to `cookies()` calls
- [ ] Add `await` to `headers()` calls
- [ ] Add `await` to `draftMode()` calls

### For Metadata Functions:
- [ ] Add `Promise<>` wrapper to `params` type
- [ ] Add `await` before accessing `params`

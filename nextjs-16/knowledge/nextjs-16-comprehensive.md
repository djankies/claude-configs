# Next.js 16 Comprehensive Knowledge Base

**Version**: 16.0.0
**Release Date**: October 21, 2025
**Last Updated**: 2025-11-19

This document serves as the single source of truth for Next.js 16 API patterns, breaking changes, and best practices. All skills should reference this document rather than duplicating information.

## Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Installation & Upgrade](#installation--upgrade)
4. [Cache Components](#cache-components)
5. [Async Request APIs](#async-request-apis)
6. [Proxy (Middleware Replacement)](#proxy-middleware-replacement)
7. [Security (CVE-2025-29927 & Data Access Layer)](#security-cve-2025-29927--data-access-layer)
8. [Turbopack](#turbopack)
9. [React 19 Integration](#react-19-integration)
10. [Image Optimization](#image-optimization)
11. [Routing Patterns](#routing-patterns)
12. [Error Handling](#error-handling)
13. [Font Optimization](#font-optimization)
14. [Breaking Changes](#breaking-changes)
15. [Common Gotchas](#common-gotchas)
16. [Anti-Patterns](#anti-patterns)

---

## Overview

Next.js 16 represents a major shift in caching philosophy and introduces several critical breaking changes:

- **Explicit Caching**: All dynamic code executes at request time by default; caching requires the `use cache` directive
- **Turbopack Default**: Turbopack is now the default bundler for development and production
- **Proxy vs Middleware**: `middleware.ts` is deprecated in favor of `proxy.ts`
- **Async Request APIs**: All request APIs (`cookies`, `headers`, `params`, etc.) now require async/await
- **Security First**: Following CVE-2025-29927, authentication must use Data Access Layer pattern instead of middleware

**Official Documentation**: https://nextjs.org/blog/next-16
**Upgrade Guide**: https://nextjs.org/docs/app/guides/upgrading/version-16

---

## System Requirements

| Component | Minimum Version | Notes |
|-----------|----------------|-------|
| Node.js | 20.9.0 (LTS) | Node.js 18 no longer supported |
| TypeScript | 5.1.0 | Required if using TypeScript |
| Chrome/Edge | 111+ | Minimum browser support |
| Firefox | 111+ | Minimum browser support |
| Safari | 16.4+ | Minimum browser support |

---

## Installation & Upgrade

### Automated Upgrade (Recommended)

```bash
npx @next/codemod@canary upgrade latest
```

The codemod handles:
- Turbopack configuration updates
- ESLint CLI migration
- Middleware-to-proxy conversion
- Removal of `unstable_` prefixes
- Experimental PPR config cleanup
- Async request API transformations

### Manual Installation

```bash
npm install next@latest react@latest react-dom@latest
npm install -D @types/react @types/react-dom
```

### New Project

```bash
npx create-next-app@latest
```

---

## Cache Components

### Core Concept

Next.js 16 introduces explicit caching via the `use cache` directive. This replaces the implicit caching of previous versions.

**Key Principles:**
- All dynamic code executes at request time by default
- Caching is opt-in via `use cache`
- Completes the Partial Pre-Rendering (PPR) implementation

### Configuration

Enable cache components in `next.config.ts`:

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  cacheComponents: true,
};

export default nextConfig;
```

### Basic Usage

#### File-level Caching

```typescript
'use cache';

export default async function Page() {
  const data = await fetch('https://api.example.com/data');
  return <div>{data}</div>;
}
```

#### Component-level Caching

```typescript
export async function MyComponent() {
  'use cache';
  return <div>Cached component</div>;
}
```

#### Function-level Caching

```typescript
export async function getData() {
  'use cache';
  const data = await fetch('/api/data');
  return data;
}
```

### Cache Lifecycle Management

#### cacheLife()

Defines cache duration with named profiles:

```typescript
import { cacheLife } from 'next/cache';

export default async function Page() {
  'use cache';
  cacheLife('hours');

  const users = await db.query('SELECT * FROM users');
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

Available profiles:
- `'seconds'`: Short-lived cache
- `'minutes'`: Medium-lived cache
- `'hours'`: Long-lived cache
- `'days'`: Very long-lived cache
- `'weeks'`: Extended cache
- `'max'`: Maximum cache duration

Custom profile:

```typescript
cacheLife({ stale: 60, revalidate: 300, expire: 3600 });
```

#### cacheTag()

Tags cache entries for targeted invalidation:

```typescript
import { cacheTag } from 'next/cache';

export async function getProducts() {
  'use cache';
  cacheTag('products');

  const products = await db.query('SELECT * FROM products');
  return products;
}
```

### Private Caching

For user-specific data that varies by cookies:

```typescript
import { cookies } from 'next/headers';
import { cacheLife, cacheTag } from 'next/cache';

async function getRecommendations(productId: string) {
  'use cache: private';
  cacheTag(`recommendations-${productId}`);
  cacheLife({ stale: 60 });

  const sessionId = (await cookies()).get('session-id')?.value || 'guest';
  return getPersonalizedRecommendations(productId, sessionId);
}
```

### Remote Caching

For streaming content:

```typescript
import { connection } from 'next/server';
import { cacheLife, cacheTag } from 'next/cache';

async function getFeedItems() {
  'use cache: remote';
  cacheTag('feed-items');
  cacheLife({ expire: 120 });

  const response = await fetch('https://api.example.com/feed');
  return response.json();
}
```

### Cache Invalidation APIs

#### updateTag()

Provides read-your-writes semantics for immediate consistency:

```typescript
'use server';

import { updateTag } from 'next/cache';
import { redirect } from 'next/navigation';

export async function createPost(formData: FormData) {
  const post = await db.post.create({
    data: {
      title: formData.get('title'),
      content: formData.get('content'),
    },
  });

  updateTag('posts');
  updateTag(`post-${post.id}`);

  redirect(`/posts/${post.id}`);
}
```

#### refresh()

Refreshes uncached data:

```typescript
'use server';

import { refresh } from 'next/cache';

export async function markNotificationAsRead(notificationId: string) {
  await db.notifications.markAsRead(notificationId);
  refresh();
}
```

#### revalidateTag()

Enhanced with cache life options:

```typescript
'use server';

import { revalidateTag } from 'next/cache';

export async function updateArticle(articleId: string) {
  await db.articles.update(articleId, data);
  revalidateTag(`article-${articleId}`, 'max');
}
```

With expire time:

```typescript
revalidateTag('analytics', { expire: 3600 });
```

### Cache Key Composition

Cache keys automatically include:
- Function arguments
- Closure variables from parent scope

```typescript
async function Component({ userId }: { userId: string }) {
  const getData = async (filter: string) => {
    'use cache';
    return fetch(`/api/users/${userId}/data?filter=${filter}`);
  };

  return getData('active');
}
```

Cache key includes both `userId` (closure) and `filter` (argument).

---

## Async Request APIs

All request APIs are now asynchronous and require `await`.

### Affected APIs

- `cookies()`
- `headers()`
- `draftMode()`
- `params` prop
- `searchParams` prop

### params and searchParams

#### Server Components

```typescript
export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const { slug } = await params;
  const { query } = await searchParams;

  return <div>{slug} - {query}</div>;
}
```

#### Client Components

Use React's `use()` hook:

```typescript
'use client';

import { use } from 'react';

export default function Page({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const { slug } = use(params);
  const { query } = use(searchParams);

  return <div>{slug} - {query}</div>;
}
```

### Type Generation

Generate type helpers with:

```bash
npx next typegen
```

This creates `PageProps`, `LayoutProps`, and `RouteContext` types:

```typescript
import type { PageProps } from '.next/types/app/blog/[slug]/page';

export default async function Page(props: PageProps<'/blog/[slug]'>) {
  const { slug } = await props.params;
  return <div>{slug}</div>;
}
```

### cookies()

```typescript
import { cookies } from 'next/headers';

export default async function Page() {
  const cookieStore = await cookies();
  const token = cookieStore.get('token');
  return <div>{token?.value}</div>;
}
```

### headers()

```typescript
import { headers } from 'next/headers';

export default async function Page() {
  const headersList = await headers();
  const userAgent = headersList.get('user-agent');
  return <div>{userAgent}</div>;
}
```

### draftMode()

```typescript
import { draftMode } from 'next/headers';

export default async function Page() {
  const draft = await draftMode();
  const isEnabled = draft.isEnabled;
  return <div>{isEnabled ? 'Draft' : 'Published'}</div>;
}
```

---

## Proxy (Middleware Replacement)

### Migration

The `middleware.ts` file has been deprecated and replaced with `proxy.ts`.

**Rename:**
```bash
mv middleware.ts proxy.ts
```

**Update exports:**
```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function proxy(request: NextRequest) {
  return NextResponse.next();
}
```

### Key Differences

- Explicitly Node.js runtime (edge runtime not supported)
- Clarifies network boundary role
- Not safe for authentication (see Security section)

### Basic Proxy

```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function proxy(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/about')) {
    return NextResponse.rewrite(new URL('/about-2', request.url));
  }

  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.rewrite(new URL('/dashboard/user', request.url));
  }
}
```

### Conditional Rewrites

```typescript
import { NextResponse } from 'next/server';

export function proxy(request: Request) {
  const nextUrl = request.nextUrl;

  if (nextUrl.pathname === '/dashboard') {
    if (request.cookies.authToken) {
      return NextResponse.rewrite(new URL('/auth/dashboard', request.url));
    } else {
      return NextResponse.rewrite(new URL('/public/dashboard', request.url));
    }
  }
}
```

### Internationalized Routing

```javascript
import { NextResponse } from 'next/server';

let locales = ['en-US', 'nl-NL', 'nl'];

function getLocale(request) {
  return 'en-US';
}

export function proxy(request) {
  const { pathname } = request.nextUrl;
  const pathnameHasLocale = locales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  );

  if (pathnameHasLocale) return;

  const locale = getLocale(request);
  request.nextUrl.pathname = `/${locale}${pathname}`;
  return NextResponse.redirect(request.nextUrl);
}

export const config = {
  matcher: ['/((?!_next).*)'],
};
```

### Configuration

```typescript
const nextConfig: NextConfig = {
  skipProxyUrlNormalize: true,
};
```

---

## Security (CVE-2025-29927 & Data Access Layer)

### Critical Security Update

Following CVE-2025-29927, **middleware/proxy is no longer safe for authentication**. You must use the Data Access Layer pattern.

### Data Access Layer Pattern

Create a centralized data access layer with authentication checks:

**lib/dal.ts:**
```typescript
import 'server-only';
import { cookies } from 'next/headers';
import { decrypt } from '@/app/lib/session';
import { cache } from 'react';

export const verifySession = cache(async () => {
  const cookie = (await cookies()).get('session')?.value;
  const session = await decrypt(cookie);

  if (!session?.userId) {
    return null;
  }

  return { isAuth: true, userId: session.userId };
});
```

**data/users.ts:**
```typescript
import 'server-only';
import { verifySession } from '@/app/lib/dal';

export async function getUser() {
  const session = await verifySession();
  if (!session) return null;

  return await db.query.users.findFirst({
    where: eq(users.id, session.userId),
    columns: {
      id: true,
      name: true,
      email: true,
    },
  });
}
```

### Multi-layered Security

Implement security at multiple layers:

1. **Data Layer**: Add auth checks in Data Access Layer functions
2. **Route Level**: Check authentication in page components
3. **UI Elements**: Hide sensitive components when users aren't authenticated
4. **Server Actions**: Verify authentication in all mutation functions

### Route-Level Protection

```typescript
import { redirect } from 'next/navigation';
import { verifySession } from '@/app/lib/dal';

export default async function Page() {
  const session = await verifySession();

  if (!session) {
    redirect('/login');
  }

  return <div>Protected content</div>;
}
```

### Server Action Protection

```typescript
'use server';

import { verifySession } from '@/app/lib/dal';

export async function deletePost(postId: string) {
  const session = await verifySession();

  if (!session) {
    throw new Error('Unauthorized');
  }

  const post = await db.query.posts.findFirst({
    where: eq(posts.id, postId),
  });

  if (post.userId !== session.userId) {
    throw new Error('Forbidden');
  }

  await db.delete(posts).where(eq(posts.id, postId));
}
```

### Input Validation with Zod

Validate on both client and server:

```typescript
'use server';

import { z } from 'zod';

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export async function createUser(prevState: any, formData: FormData) {
  const validatedFields = schema.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
  });

  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  const { email, password } = validatedFields.data;
}
```

### Security Headers

Configure in `next.config.js`:

```javascript
module.exports = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline';",
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ];
  },
};
```

### Sanitization

Always sanitize user input before rendering:

```typescript
import DOMPurify from 'isomorphic-dompurify';

export function UserContent({ content }: { content: string }) {
  const sanitized = DOMPurify.sanitize(content);
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

---

## Turbopack

### Overview

Turbopack is now the default bundler for both development and production builds.

**Performance Improvements:**
- 2-5× faster production builds
- Up to 10× faster Fast Refresh in development
- 20% of production builds already using Turbopack (Next.js 15.3+)

### Configuration

Turbopack configuration is now at the top level (moved from `experimental`):

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  turbopack: {
    resolveAlias: {
      canvas: './empty-module.ts',
    },
  },
};

export default nextConfig;
```

### File System Caching (Beta)

Enable for improved build times:

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    turbopackFileSystemCacheForDev: true,
    turbopackFileSystemCacheForBuild: true,
  },
};

export default nextConfig;
```

### Opt Out

To use Webpack instead:

```json
{
  "scripts": {
    "dev": "next dev --webpack",
    "build": "next build --webpack"
  }
}
```

### Sass Import Resolution

Turbopack doesn't support the `~` tilde prefix:

**Deprecated:**
```scss
@import '~bootstrap/scss/bootstrap';
```

**Use:**
```scss
@import 'bootstrap/scss/bootstrap';
```

Or configure alias:

```typescript
const nextConfig = {
  turbopack: {
    resolveAlias: {
      '~*': '*',
    },
  },
};
```

---

## React 19 Integration

Next.js 16 includes React 19 with enhanced server actions and hooks.

### useActionState

For form handling with state:

**Server Action:**
```typescript
'use server';

import { z } from 'zod';

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export async function createUser(prevState: any, formData: FormData) {
  const validatedFields = schema.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
  });

  if (!validatedFields.success) {
    return {
      message: 'Validation failed',
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  return { message: 'User created successfully' };
}
```

**Client Component:**
```typescript
'use client';

import { useActionState } from 'react';
import { createUser } from '@/app/actions';

const initialState = { message: '' };

export function Signup() {
  const [state, formAction, pending] = useActionState(createUser, initialState);

  return (
    <form action={formAction}>
      <input type="email" name="email" required />
      {state?.errors?.email && <p>{state.errors.email}</p>}

      <input type="password" name="password" required />
      {state?.errors?.password && <p>{state.errors.password}</p>}

      <p aria-live="polite">{state?.message}</p>
      <button disabled={pending}>Sign up</button>
    </form>
  );
}
```

### useFormStatus

For submit button states:

```typescript
'use client';

import { useFormStatus } from 'react-dom';

export function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending} aria-disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}
```

Usage:

```typescript
import { SubmitButton } from './button';
import { createUser } from '@/app/actions';

export function Signup() {
  return (
    <form action={createUser}>
      <input type="email" name="email" required />
      <SubmitButton />
    </form>
  );
}
```

### Server Actions Through Cached Components

Pass server actions through cached components without calling them:

```typescript
import ClientComponent from './ClientComponent'

export default async function Page() {
  const performUpdate = async () => {
    'use server'
    await db.update(...)
  }

  return <CacheComponent performUpdate={performUpdate} />
}

async function CachedComponent({
  performUpdate,
}: {
  performUpdate: () => Promise<void>
}) {
  'use cache'
  return <ClientComponent action={performUpdate} />
}
```

**Client Component:**
```typescript
'use client';

export default function ClientComponent({
  action
}: {
  action: () => Promise<void>
}) {
  return <button onClick={action}>Update</button>;
}
```

### useOptimistic

For optimistic UI updates:

```typescript
'use client';

import { useOptimistic } from 'react';

export function TodoList({ todos }: { todos: Todo[] }) {
  const [optimisticTodos, addOptimisticTodo] = useOptimistic(
    todos,
    (state, newTodo: Todo) => [...state, newTodo]
  );

  return (
    <ul>
      {optimisticTodos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}
```

---

## Image Optimization

### Basic Image Component

```typescript
import Image from 'next/image';
import profilePic from '../public/me.png';

export default function Page() {
  return (
    <Image
      src={profilePic}
      alt="Picture of the author"
      width={500}
      height={500}
      priority
    />
  );
}
```

### Remote Images

Configure allowed domains:

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        port: '',
        pathname: '/account123/**',
        search: '',
      },
    ],
  },
};
```

### Local Images with Query Strings

Now requires explicit configuration:

```typescript
const nextConfig: NextConfig = {
  images: {
    localPatterns: [
      {
        pathname: '/assets/**',
        search: '?v=1',
      },
    ],
  },
};
```

### Custom Image Loader

**next.config.js:**
```javascript
module.exports = {
  images: {
    loader: 'custom',
    loaderFile: './my/image/loader.js',
  },
};
```

**my/image/loader.js:**
```javascript
export default function myImageLoader({ src, width, quality }) {
  return `https://example.com/${src}?w=${width}&q=${quality || 75}`;
}
```

### Responsive Images

```typescript
<Image
  src="/hero.jpg"
  alt="Hero image"
  width={1920}
  height={1080}
  priority
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
/>
```

### Configuration Changes in Next.js 16

| Property | Old Default | New Default |
|----------|-------------|-------------|
| `minimumCacheTTL` | 60s | 14,400s (4 hours) |
| `imageSizes` | `[16, 32, 48, 64, 96, 128, 256, 384]` | `[32, 48, 64, 96, 128, 256, 384]` (removed 16) |
| `qualities` | `[75, 100]` | `[75]` |
| `maximumRedirects` | unlimited | 3 |
| `dangerouslyAllowLocalIP` | allows | blocks by default |

---

## Routing Patterns

### Dynamic Routes

```typescript
export default async function BlogPostPage({
  params
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params;
  const post = await getPost(slug);

  return (
    <div>
      <h1>{post.title}</h1>
      <p>{post.content}</p>
    </div>
  );
}
```

### Parallel Routes

**Layout:**
```typescript
export default function Layout({
  children,
  team,
  analytics,
}: {
  children: React.ReactNode;
  analytics: React.ReactNode;
  team: React.ReactNode;
}) {
  return (
    <>
      {children}
      {team}
      {analytics}
    </>
  );
}
```

**Default Component (Required):**
```typescript
import { notFound } from 'next/navigation';

export default function Default() {
  notFound();
}
```

### Intercepting Routes

```typescript
import { Modal } from '@/app/ui/modal';
import { Login } from '@/app/ui/login';

export default function Page() {
  return (
    <Modal>
      <Login />
    </Modal>
  );
}
```

### Catch-All Routes

```typescript
export default function CatchAll() {
  return null;
}
```

### Route Groups

Use `(group-name)` for organization without affecting URL structure:

```tree
app/
├── (marketing)/
│   ├── about/
│   └── blog/
└── (shop)/
    ├── checkout/
    └── products/
```

---

## Error Handling

### Error Boundaries

```typescript
'use client';

import { useEffect } from 'react';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div>
      <h2>Something went wrong!</h2>
      <button onClick={() => reset()}>Try again</button>
    </div>
  );
}
```

### Global Error Boundary

```typescript
'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body>
        <h2>Something went wrong!</h2>
        <button onClick={() => reset()}>Try again</button>
      </body>
    </html>
  );
}
```

### Server Component Error Handling

```typescript
export default async function Page() {
  const res = await fetch(`https://...`);
  const data = await res.json();

  if (!res.ok) {
    return 'There was an error.';
  }

  return <div>{data}</div>;
}
```

### Event Handler Error Handling

```typescript
'use client';

import { useState } from 'react';

export function Button() {
  const [error, setError] = useState(null);

  const handleClick = () => {
    try {
      throw new Error('Exception');
    } catch (reason) {
      setError(reason);
    }
  };

  if (error) {
    return <div>Error: {error.message}</div>;
  }

  return (
    <button type="button" onClick={handleClick}>
      Click me
    </button>
  );
}
```

---

## Font Optimization

### Google Fonts

```typescript
import { Geist } from 'next/font/google';

const geist = Geist({
  subsets: ['latin'],
});

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={geist.className}>
      <body>{children}</body>
    </html>
  );
}
```

### Local Fonts

```javascript
import localFont from 'next/font/local';

const roboto = localFont({
  src: [
    {
      path: './Roboto-Regular.woff2',
      weight: '400',
      style: 'normal',
    },
    {
      path: './Roboto-Italic.woff2',
      weight: '400',
      style: 'italic',
    },
    {
      path: './Roboto-Bold.woff2',
      weight: '700',
      style: 'normal',
    },
    {
      path: './Roboto-BoldItalic.woff2',
      weight: '700',
      style: 'italic',
    },
  ],
});
```

### Multiple Fonts

```typescript
import { Inter, Roboto_Mono } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
});

const roboto_mono = Roboto_Mono({
  subsets: ['latin'],
  display: 'swap',
});

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.className}>
      <body>
        <div>{children}</div>
        <div className={roboto_mono.className}>Code block</div>
      </body>
    </html>
  );
}
```

---

## Breaking Changes

### Async Request APIs (Required)

These APIs now MUST be awaited:
- `cookies()`
- `headers()`
- `draftMode()`
- `params` prop
- `searchParams` prop

### Middleware → Proxy Rename

- Rename `middleware.ts` to `proxy.ts`
- Change export from `middleware()` to `proxy()`
- Update `next.config.js` from `skipMiddlewareUrlNormalize` to `skipProxyUrlNormalize`

### Image Configuration

| Change | Old | New |
|--------|-----|-----|
| `minimumCacheTTL` | 60s | 14,400s (4 hours) |
| `imageSizes` | includes 16 | removed 16 |
| `qualities` | `[75, 100]` | `[75]` |
| `maximumRedirects` | unlimited | 3 |
| `dangerouslyAllowLocalIP` | allows | blocks |

Local images with query strings require explicit `localPatterns` configuration.

### revalidateTag Signature

Now requires second argument:

**Old:**
```typescript
revalidateTag('products');
```

**New:**
```typescript
revalidateTag('products', 'max');
```

Or with expire time:

```typescript
revalidateTag('products', { expire: 3600 });
```

### revalidatePath Signature

Now requires second argument:

**Old:**
```typescript
revalidatePath('/products');
```

**New:**
```typescript
revalidatePath('/products', 'page');
```

For layouts:

```typescript
revalidatePath('/products', 'layout');
```

### after() Dynamic Rendering

The `after()` API no longer opts routes into dynamic rendering. Use `connection()` for dynamic behavior:

```typescript
import { after, connection } from 'next/server';

export default async function Layout({ children }: { children: React.ReactNode }) {
  await connection();

  after(async () => {
    await logAnalytics();
  });

  return <>{children}</>;
}
```

### fetch() Cache Default

`fetch()` requests are now **uncached by default** unless inside a cached scope:

```typescript
const response = await fetch('https://api.example.com/data');
```

To cache:

```typescript
const response = await fetch('https://api.example.com/data', {
  cache: 'force-cache',
});
```

Or use `use cache` directive:

```typescript
async function getData() {
  'use cache';
  return fetch('https://api.example.com/data');
}
```

### Route Segment Config Changes

These options have been deprecated:

**Deprecated:**
- `export const dynamic = 'force-static'`
- `export const fetchCache = 'default-cache'`
- `export const revalidate = false`
- `export const dynamicParams = true`

**Use instead:**

```typescript
'use cache';
import { cacheLife } from 'next/cache';

export default async function Page() {
  cacheLife('hours');
  return <div>Cached page</div>;
}
```

---

## Common Gotchas

### Cannot Use Runtime APIs in Cached Components

**Incorrect:**
```typescript
export default async function Page() {
  'use cache';

  const cookieStore = await cookies();
  return <div>Error!</div>;
}
```

**Correct:**
```typescript
export default async function Page() {
  const cookieStore = await cookies();
  const token = cookieStore.get('token');

  return <CachedComponent token={token} />;
}

async function CachedComponent({ token }: { token: string }) {
  'use cache';
  return <div>{token}</div>;
}
```

### Middleware No Longer Safe for Authentication

**DO NOT USE:**
```typescript
export function proxy(request: NextRequest) {
  const session = request.cookies.get('session');
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

**USE Data Access Layer:**
```typescript
import { redirect } from 'next/navigation';
import { verifySession } from '@/app/lib/dal';

export default async function Page() {
  const session = await verifySession();

  if (!session) {
    redirect('/login');
  }

  return <div>Protected content</div>;
}
```

### Async Context Loss with setTimeout

**Incorrect:**
```typescript
import { cookies } from 'next/headers';

async function getCookieData() {
  return new Promise((resolve) =>
    setTimeout(async () => {
      const cookieStore = await cookies();
      resolve(cookieStore.getAll());
    }, 1000)
  );
}
```

**Correct:**
```typescript
import { cookies } from 'next/headers';

async function getCookieData() {
  const cookieStore = await cookies();
  const cookieData = cookieStore.getAll();

  return new Promise((resolve) =>
    setTimeout(() => {
      resolve(cookieData);
    }, 1000)
  );
}
```

### Parallel Routes Require default.js

All parallel route slots must include `default.js`:

```typescript
import { notFound } from 'next/navigation';

export default function Default() {
  notFound();
}
```

### Turbopack Sass Import Tilde

Turbopack doesn't support the `~` tilde prefix:

**Deprecated:**
```scss
@import '~bootstrap/scss/bootstrap';
```

**Use:**
```scss
@import 'bootstrap/scss/bootstrap';
```

### Cache Key Includes Closure Variables

```typescript
async function Component({ userId }: { userId: string }) {
  const getData = async (filter: string) => {
    'use cache';
    return fetch(`/api/users/${userId}/data?filter=${filter}`);
  };

  return getData('active');
}
```

Cache key includes both `userId` (from closure) and `filter` (argument).

---

## Anti-Patterns

### Don't Mix Server and Client Code Carelessly

**Bad:**
```typescript
'use client';

import { db } from '@/lib/db';

export default function Page() {
  const users = db.query.users.findMany();
  return <div>{users}</div>;
}
```

**Good:**
```typescript
import { getUsers } from '@/app/data/users';

export default async function Page() {
  const users = await getUsers();
  return <UserList users={users} />;
}
```

Client component:

```typescript
'use client';

export function UserList({ users }: { users: User[] }) {
  return (
    <div>
      {users.map(u => <div key={u.id}>{u.name}</div>)}
    </div>
  );
}
```

### Don't Use force-static Without Understanding

**Bad:**
```typescript
export const dynamic = 'force-static';

export default async function Page() {
  const data = await fetch('https://api.example.com/data');
  return <div>{data}</div>;
}
```

**Good (use cache directive):**
```typescript
export default async function Page() {
  'use cache';
  const data = await fetch('https://api.example.com/data');
  return <div>{data}</div>;
}
```

### Don't Call Server Actions in Cached Components

**Bad:**
```typescript
async function CachedComponent() {
  'use cache'
  const performUpdate = async () => {
    'use server'
    await db.update(...)
  }

  performUpdate()
  return <div>Updated</div>
}
```

**Good (pass through without calling):**
```typescript
async function CachedComponent({
  performUpdate
}: {
  performUpdate: () => Promise<void>
}) {
  'use cache';
  return <ClientComponent action={performUpdate} />;
}
```

### Don't Return Full Objects to Client

**Bad:**
```typescript
'use server';

export async function getUser(userId: string) {
  return await db.query.users.findFirst({
    where: eq(users.id, userId),
  });
}
```

**Good (use DTOs):**
```typescript
'use server';

export async function getUser(userId: string) {
  const user = await db.query.users.findFirst({
    where: eq(users.id, userId),
    columns: {
      id: true,
      name: true,
      email: true,
    },
  });

  return {
    id: user.id,
    name: user.name,
    email: user.email,
  };
}
```

### Don't Use Middleware for Authentication

**Bad (deprecated pattern):**
```typescript
export function proxy(request: NextRequest) {
  const session = request.cookies.get('session');
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

**Good (Data Access Layer):**
```typescript
import { verifySession } from '@/app/lib/dal';
import { redirect } from 'next/navigation';

export default async function Page() {
  const session = await verifySession();
  if (!session) {
    redirect('/login');
  }

  return <div>Protected</div>;
}
```

### Don't Prop Drill When Composition Works

**Bad:**
```typescript
export default async function Page() {
  const user = await getUser();

  return (
    <Layout>
      <Header user={user} />
      <Content user={user} />
    </Layout>
  );
}
```

**Good:**
```typescript
export default async function Page() {
  return (
    <Layout>
      <Header />
      <Content />
    </Layout>
  );
}

async function Header() {
  const user = await getUser();
  return <div>{user.name}</div>;
}

async function Content() {
  const user = await getUser();
  return <div>{user.email}</div>;
}
```

---

## API Reference Summary

### Caching APIs

| API | Purpose | Usage |
|-----|---------|-------|
| `'use cache'` | Mark component/function as cacheable | `'use cache'` |
| `cacheLife()` | Set cache duration | `cacheLife('hours')` |
| `cacheTag()` | Tag cache entries | `cacheTag('products')` |
| `updateTag()` | Invalidate with read-your-writes | `updateTag('products')` |
| `refresh()` | Refresh uncached data | `refresh()` |
| `revalidateTag()` | Revalidate tagged entries | `revalidateTag('products', 'max')` |
| `revalidatePath()` | Revalidate path | `revalidatePath('/blog', 'page')` |

### Request APIs

| API | Returns | Usage |
|-----|---------|-------|
| `cookies()` | Promise<ReadonlyRequestCookies> | `await cookies()` |
| `headers()` | Promise<ReadonlyHeaders> | `await headers()` |
| `draftMode()` | Promise<DraftMode> | `await draftMode()` |
| `params` | Promise<Record<string, string>> | `await params` |
| `searchParams` | Promise<Record<string, string \| string[]>> | `await searchParams` |

### Server APIs

| API | Purpose | Usage |
|-----|---------|-------|
| `after()` | Execute after response | `after(async () => {...})` |
| `connection()` | Mark route as dynamic | `await connection()` |
| `unstable_noStore()` | Opt out of caching | `unstable_noStore()` |

### Navigation APIs

| API | Purpose | Usage |
|-----|---------|-------|
| `redirect()` | Server-side redirect | `redirect('/login')` |
| `notFound()` | Trigger 404 | `notFound()` |
| `useRouter()` | Client-side navigation | `router.push('/path')` |
| `usePathname()` | Get current pathname | `const pathname = usePathname()` |
| `useSearchParams()` | Get search params | `const searchParams = useSearchParams()` |

### React Hooks

| Hook | Purpose | Usage |
|------|---------|-------|
| `useActionState()` | Form state management | `const [state, action, pending] = useActionState(fn, initial)` |
| `useFormStatus()` | Form submission status | `const { pending } = useFormStatus()` |
| `useOptimistic()` | Optimistic updates | `const [optimistic, add] = useOptimistic(state, fn)` |
| `use()` | Unwrap promises | `const value = use(promise)` |

---

## References

- **Official Blog Post**: https://nextjs.org/blog/next-16
- **Upgrade Guide**: https://nextjs.org/docs/app/guides/upgrading/version-16
- **Caching Documentation**: https://nextjs.org/docs/app/building-your-application/caching
- **Security Best Practices**: https://nextjs.org/docs/app/building-your-application/authentication
- **CVE-2025-29927**: https://github.com/advisories/GHSA-example
- **React 19 Documentation**: https://react.dev/blog/2024/04/25/react-19

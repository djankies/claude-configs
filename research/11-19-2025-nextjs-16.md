# Next.js 16 Research

## Overview

- **Version**: 16.0.0
- **Release Date**: October 21, 2025
- **Purpose in Project**: Building modern React web applications with server-side rendering, static site generation, and API routes
- **Official Documentation**: https://nextjs.org/blog/next-16
- **Official Upgrade Guide**: https://nextjs.org/docs/app/guides/upgrading/version-16
- **Last Updated**: 2025-11-19

## Installation

### Automated Upgrade (Recommended)

```bash
npx @next/codemod@canary upgrade latest
```

The codemod automatically handles:

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

## System Requirements

| Requirement | Minimum Version | Notes                          |
| ----------- | --------------- | ------------------------------ |
| Node.js     | 20.9.0 (LTS)    | Node.js 18 no longer supported |
| TypeScript  | 5.1.0           | Required if using TypeScript   |
| Chrome/Edge | 111+            | Minimum browser support        |
| Firefox     | 111+            | Minimum browser support        |
| Safari      | 16.4+           | Minimum browser support        |

## Core Concepts

### Cache Components Model

Next.js 16 introduces a new caching paradigm centered on the `use cache` directive. This represents a fundamental shift from implicit caching to explicit, opt-in caching.

**Key Principles:**

- All dynamic code in any page, layout, or API route is executed at request time by default
- Caching is explicit and requires the `use cache` directive
- Replaces the implicit caching behavior of previous versions
- Completes the Partial Pre-Rendering (PPR) implementation

### Turbopack as Default

Turbopack has reached stability and is now the default bundler for both development and production builds.

**Performance Improvements:**

- 2-5× faster production builds
- Up to 10× faster Fast Refresh in development
- More than 50% of development sessions already using Turbopack (Next.js 15.3+)
- 20% of production builds already on Turbopack (Next.js 15.3+)

### Proxy vs Middleware

The `middleware.ts` file has been deprecated and replaced with `proxy.ts` to clarify the network boundary role.

**Important Security Update (2025):**

- Following CVE-2025-29927, middleware is no longer considered safe for authentication
- Use Data Access Layer pattern for authentication instead
- Proxy is explicitly Node.js runtime (edge runtime not supported)

## Configuration

### Enable Cache Components

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  cacheComponents: true,
};

export default nextConfig;
```

```javascript
const nextConfig = {
  cacheComponents: true,
};

module.exports = nextConfig;
```

### Turbopack Configuration

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

### Enable Turbopack File System Caching (Beta)

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

### Enable React Compiler (Stable)

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactCompiler: true,
};

export default nextConfig;
```

Install the required plugin:

```bash
npm install -D babel-plugin-react-compiler
```

### Opt Out of Turbopack

```json
{
  "scripts": {
    "dev": "next dev --webpack",
    "build": "next build --webpack"
  }
}
```

## Usage Patterns

### Basic Usage: Cache Directive

The `use cache` directive can be applied at file, component, or function level:

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

### Advanced Patterns: Cache with Lifecycle

#### Using cacheLife

```typescript
import { cacheLife } from 'next/cache';

export default async function Page() {
  'use cache';
  cacheLife('hours');

  const users = await db.query('SELECT * FROM users');

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

#### Using cacheTag

```typescript
import { cacheTag } from 'next/cache';

export async function getProducts() {
  'use cache';
  cacheTag('products');

  const products = await db.query('SELECT * FROM products');
  return products;
}
```

#### Private Caching with Cookies

```typescript
import { Suspense } from 'react';
import { cookies } from 'next/headers';
import { cacheLife, cacheTag } from 'next/cache';

async function getRecommendations(productId: string) {
  'use cache: private';
  cacheTag(`recommendations-${productId}`);
  cacheLife({ stale: 60 });

  const sessionId = (await cookies()).get('session-id')?.value || 'guest';
  return getPersonalizedRecommendations(productId, sessionId);
}

export default async function ProductPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  return (
    <div>
      <ProductDetails id={id} />
      <Suspense fallback={<div>Loading recommendations...</div>}>
        <Recommendations productId={id} />
      </Suspense>
    </div>
  );
}

async function Recommendations({ productId }: { productId: string }) {
  const recommendations = await getRecommendations(productId);

  return (
    <div>
      {recommendations.map((rec) => (
        <ProductCard key={rec.id} product={rec} />
      ))}
    </div>
  );
}
```

#### Remote Caching for Streaming

```typescript
import { Suspense } from 'react';
import { connection } from 'next/server';
import { cacheLife, cacheTag } from 'next/cache';

async function getFeedItems() {
  'use cache: remote';
  cacheTag('feed-items');
  cacheLife({ expire: 120 });

  const response = await fetch('https://api.example.com/feed');
  return response.json();
}

export default async function FeedPage() {
  return (
    <div>
      <Suspense fallback={<Skeleton />}>
        <FeedItems />
      </Suspense>
    </div>
  );
}

async function FeedItems() {
  await connection();
  const items = await getFeedItems();
  return items.map((item) => <FeedItem key={item.id} item={item} />);
}
```

### New Caching APIs

#### updateTag() - Read-Your-Writes Semantics

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

#### refresh() - Refresh Uncached Data

```typescript
'use server';

import { refresh } from 'next/cache';

export async function markNotificationAsRead(notificationId: string) {
  await db.notifications.markAsRead(notificationId);
  refresh();
}
```

#### revalidateTag() - Enhanced with Cache Life

```typescript
'use server';

import { revalidateTag } from 'next/cache';

export async function updateArticle(articleId: string) {
  await db.articles.update(articleId, data);
  revalidateTag(`article-${articleId}`, 'max');
}
```

Alternative with expire time:

```typescript
revalidateTag('analytics', { expire: 3600 });
```

### Async Request APIs

All request APIs now require async/await:

#### Async params and searchParams

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

  return (
    <div>
      {slug} - {query}
    </div>
  );
}
```

#### Generate Type Helpers

```bash
npx next typegen
```

This generates `PageProps`, `LayoutProps`, and `RouteContext` types:

```typescript
import type { PageProps } from '.next/types/app/blog/[slug]/page';

export default async function Page(props: PageProps<'/blog/[slug]'>) {
  const { slug } = await props.params;
  return <div>{slug}</div>;
}
```

#### Async cookies, headers, draftMode

```typescript
import { cookies, headers, draftMode } from 'next/headers';

export default async function Page() {
  const cookieStore = await cookies();
  const token = cookieStore.get('token');

  const headersList = await headers();
  const userAgent = headersList.get('user-agent');

  const draft = await draftMode();
  const isEnabled = draft.isEnabled;

  return <div>{token?.value}</div>;
}
```

#### Client Components with use()

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

  return (
    <div>
      {slug} - {query}
    </div>
  );
}
```

### Proxy Configuration

#### Basic Proxy (Replaces Middleware)

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

#### Conditional Rewrites with Authentication

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

#### Internationalized Routing

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

### React 19 Integration

#### Server Actions with useActionState

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

Client component:

```typescript
'use client';

import { useActionState } from 'react';
import { createUser } from '@/app/actions';

const initialState = {
  message: '',
};

export function Signup() {
  const [state, formAction, pending] = useActionState(createUser, initialState);

  return (
    <form action={formAction}>
      <label htmlFor="email">Email</label>
      <input type="text" id="email" name="email" required />

      {state?.errors?.email && <p>{state.errors.email}</p>}

      <p aria-live="polite">{state?.message}</p>
      <button disabled={pending}>Sign up</button>
    </form>
  );
}
```

#### useFormStatus for Submit Button

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

#### Passing Server Actions Through Cached Components

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

Client component:

```typescript
'use client';

export default function ClientComponent({ action }: { action: () => Promise<void> }) {
  return <button onClick={action}>Update</button>;
}
```

### Error Handling

#### Error Boundaries

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

#### Global Error Boundary

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

#### Server Component Error Handling

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

#### Event Handler Error Handling

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

### Image Optimization

#### Basic Image Component

```typescript
import Image from 'next/image';
import profilePic from '../public/me.png';

export default function Page() {
  return <Image src={profilePic} alt="Picture of the author" width={500} height={500} priority />;
}
```

#### Remote Images Configuration

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

#### Local Images Configuration

```javascript
module.exports = {
  images: {
    localPatterns: [
      {
        pathname: '/assets/images/**',
        search: '',
      },
    ],
  },
};
```

#### Custom Image Loader

```javascript
module.exports = {
  images: {
    loader: 'custom',
    loaderFile: './my/image/loader.js',
  },
};
```

Loader file:

```javascript
export default function myImageLoader({ src, width, quality }) {
  return `https://example.com/${src}?w=${width}&q=${quality || 75}`;
}
```

### Font Optimization

#### Google Fonts

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

#### Local Fonts

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

### Routing Patterns

#### Dynamic Routes

```typescript
export default async function BlogPostPage({ params }: { params: Promise<{ slug: string }> }) {
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

#### Parallel Routes

Layout component:

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

Default component for slots:

```typescript
import { notFound } from 'next/navigation';

export default function Default() {
  notFound();
}
```

#### Intercepting Routes

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

#### Catch-All Routes

```typescript
export default function CatchAll() {
  return null;
}
```

## Best Practices

### Security Best Practices (2025)

#### Data Access Layer Pattern

Create a centralized data access layer with authentication checks:

```typescript
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

#### Multi-layered Security

1. Data layer: Add auth checks in Data Access Layer functions
2. Route level: Check authentication in page components
3. UI elements: Hide sensitive components when users aren't authenticated
4. Server actions: Verify authentication in all mutation functions

#### Server Actions Protection

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

#### Validation with Zod

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

#### Security Headers

Configure security headers in `next.config.js`:

```javascript
module.exports = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Content-Security-Policy',
            value:
              "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline';",
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

### Performance Best Practices

#### Use Server Components by Default

Server components are the default in Next.js 16. Only use client components when you need:

- Event handlers (onClick, onChange, etc.)
- useState, useEffect, or other React hooks
- Browser-only APIs

#### Avoid State Too High in Component Tree

```typescript
'use client';

import { useState } from 'react';

export function SearchResults() {
  const [searchTerm, setSearchTerm] = useState('');

  return (
    <div>
      <SearchInput value={searchTerm} onChange={setSearchTerm} />
      <Results searchTerm={searchTerm} />
    </div>
  );
}

function Results({ searchTerm }: { searchTerm: string }) {
  const results = useSearch(searchTerm);
  return <div>{results}</div>;
}
```

#### Use Caching Strategically

Apply `use cache` at the appropriate granularity:

```typescript
async function ExpensiveComponent() {
  'use cache';
  cacheLife('hours');

  const data = await expensiveOperation();
  return <div>{data}</div>;
}
```

#### Image Optimization

- Always specify width and height
- Use priority for above-the-fold images
- Use responsive images with srcSet
- Optimize remote image patterns

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

### Component Architecture

#### Composition Over Prop Drilling

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

Better:

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

#### Colocation of Data Fetching

Fetch data where it's needed:

```typescript
async function UserProfile({ userId }: { userId: string }) {
  const user = await db.query.users.findFirst({
    where: eq(users.id, userId),
  });

  return (
    <div>
      <h1>{user.name}</h1>
      <UserPosts userId={userId} />
    </div>
  );
}

async function UserPosts({ userId }: { userId: string }) {
  const posts = await db.query.posts.findMany({
    where: eq(posts.userId, userId),
  });

  return posts.map((post) => <PostCard key={post.id} post={post} />);
}
```

## Common Gotchas

### Cannot Use Runtime APIs in Cached Components

```typescript
export default async function Page() {
  'use cache';

  const cookieStore = await cookies();
  return <div>Error!</div>;
}
```

Solution: Read runtime APIs outside cached scope:

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

Do NOT use middleware for authentication:

```typescript
export function proxy(request: NextRequest) {
  const session = request.cookies.get('session');
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

Use Data Access Layer instead:

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

Incorrect:

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

Correct:

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

```scss
@import '~bootstrap/scss/bootstrap';
```

Solution:

```scss
@import 'bootstrap/scss/bootstrap';
```

Or configure resolve alias:

```typescript
const nextConfig = {
  turbopack: {
    resolveAlias: {
      '~*': '*',
    },
  },
};
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

The cache key includes both `userId` (from closure) and `filter` (argument).

## Anti-Patterns

### Don't Mix Server and Client Code Carelessly

Bad:

```typescript
'use client';

import { db } from '@/lib/db';

export default function Page() {
  const users = db.query.users.findMany();
  return <div>{users}</div>;
}
```

Good:

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
      {users.map((u) => (
        <div key={u.id}>{u.name}</div>
      ))}
    </div>
  );
}
```

### Don't Use force-static Without Understanding

Bad:

```typescript
export const dynamic = 'force-static';

export default async function Page() {
  const data = await fetch('https://api.example.com/data');
  return <div>{data}</div>;
}
```

Good (use cache directive):

```typescript
export default async function Page() {
  'use cache';
  const data = await fetch('https://api.example.com/data');
  return <div>{data}</div>;
}
```

### Don't Call Server Actions in Cached Components

Bad:

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

Good (pass through without calling):

```typescript
async function CachedComponent({ performUpdate }: { performUpdate: () => Promise<void> }) {
  'use cache';
  return <ClientComponent action={performUpdate} />;
}
```

### Don't Return Full Objects to Client

Bad:

```typescript
'use server';

export async function getUser(userId: string) {
  return await db.query.users.findFirst({
    where: eq(users.id, userId),
  });
}
```

Good (use DTOs):

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

Bad (deprecated pattern):

```typescript
export function proxy(request: NextRequest) {
  const session = request.cookies.get('session');
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

Good (Data Access Layer):

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

## Breaking Changes

### Async Request APIs (Required)

These APIs now MUST be awaited:

- `cookies()`
- `headers()`
- `draftMode()`
- `params` prop
- `searchParams` prop

### Middleware → Proxy Rename

Rename files:

```bash
mv middleware.ts proxy.ts
mv middleware.js proxy.js
```

Update exports:

```typescript
export function proxy(request: NextRequest) {
  return NextResponse.next();
}
```

Update config:

```typescript
const nextConfig: NextConfig = {
  skipProxyUrlNormalize: true,
};
```

### Image Configuration Changes

- `minimumCacheTTL`: 60s → 14,400s (4 hours)
- `imageSizes`: removed `16` from defaults
- `qualities`: now `[75]` only
- `maximumRedirects`: unlimited → 3
- `dangerouslyAllowLocalIP`: now blocks by default

### Local Images with Query Strings

Require explicit configuration:

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

### revalidateTag Signature

Now requires second argument:

```typescript
revalidateTag('blog-posts', 'max');

revalidateTag('analytics', { expire: 3600 });
```

### Removed Features

- AMP support completely removed
- `next lint` command removed (use ESLint directly)
- `devIndicators` configuration removed
- `serverRuntimeConfig` and `publicRuntimeConfig` removed
- `next/legacy/image` removed
- `images.domains` removed (use `remotePatterns`)
- `unstable_rootParams()` removed
- Automatic `scroll-behavior: smooth` removed

### PPR Implementation Changed

If using PPR in Next.js 15 canary, stay on current version. Next.js 16 replaces experimental PPR with Cache Components:

```javascript
const nextConfig = {
  cacheComponents: true,
};
```

### Concurrent Dev and Build

`next dev` outputs to `.next/dev` directory (separate from `next build`).

Update trace command:

```bash
npx next internal trace .next/dev/trace-turbopack
```

### Sass Loader v16

Upgraded to Sass Loader v16 with modern syntax support.

### ESLint Flat Config

`@next/eslint-plugin-next` defaults to ESLint Flat Config format.

## Version-Specific Notes

### React 19.2 Features

Next.js 16 includes React 19.2 features:

- **View Transitions**: Animated element updates
- **useEffectEvent**: Non-reactive Effect logic
- **Activity Component**: Background operations management

### Node.js Version Support

- Node.js 18: No longer supported
- Node.js 20.9.0+: Minimum required version

### TypeScript Version Support

- TypeScript 5.1.0+: Minimum required version

### Browser Support

Minimum versions:

- Chrome 111+
- Edge 111+
- Firefox 111+
- Safari 16.4+

## Security Considerations

### Critical: CVE-2025-29927

Middleware is no longer considered safe for authentication following this security vulnerability.

### Data Access Layer Pattern

Implement a centralized data access layer:

```typescript
import 'server-only';
import { cookies } from 'next/headers';
import { decrypt } from '@/app/lib/session';
import { cache } from 'react';

export const verifySession = cache(async () => {
  const cookie = (await cookies()).get('session')?.value;
  const session = await decrypt(cookie);

  if (!session?.userId) {
    redirect('/login');
  }

  return { isAuth: true, userId: session.userId };
});
```

### Defense in Depth

Implement security at multiple layers:

1. **Route Level**: Check auth in page components
2. **Data Layer**: Verify permissions in data functions
3. **UI Layer**: Hide sensitive UI elements
4. **Server Actions**: Authenticate all mutations
5. **API Routes**: Validate all requests

### Environment Variables

Use proper prefixes:

- `NEXT_PUBLIC_`: Client-side accessible
- No prefix: Server-side only

```typescript
const apiKey = process.env.API_KEY;
const publicApiUrl = process.env.NEXT_PUBLIC_API_URL;
```

### Content Security Policy

Implement strict CSP headers:

```javascript
module.exports = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline';",
          },
        ],
      },
    ];
  },
};
```

## Performance Tips

### Leverage Turbopack

Turbopack is now the default with significant performance improvements:

- 2-5× faster production builds
- Up to 10× faster Fast Refresh

### Enable File System Caching

```typescript
const nextConfig = {
  experimental: {
    turbopackFileSystemCacheForDev: true,
    turbopackFileSystemCacheForBuild: true,
  },
};
```

### Use React Compiler

Enable automatic memoization:

```typescript
const nextConfig = {
  reactCompiler: true,
};
```

### Strategic Caching

Apply caching at the right level:

```typescript
async function getData() {
  'use cache';
  cacheLife('hours');

  const data = await fetch('...');
  return data;
}
```

### Image Optimization

- Use `next/image` for automatic optimization
- Configure remote patterns for external images
- Use `priority` for above-the-fold images
- Specify `sizes` for responsive images

### Font Optimization

- Use `next/font` for automatic font optimization
- Self-host fonts for privacy and performance
- Preload critical fonts

### Incremental Prefetching

Next.js 16 automatically:

- Prefetches only uncached portions
- Cancels requests when links leave viewport
- Re-prefetches when data invalidates

### Layout Deduplication

Shared layouts download once across multiple prefetched URLs.

## Code Examples

### Complete Authentication Flow

```typescript
import 'server-only';
import { cookies } from 'next/headers';
import { decrypt } from '@/app/lib/session';
import { redirect } from 'next/navigation';
import { cache } from 'react';

export const verifySession = cache(async () => {
  const cookie = (await cookies()).get('session')?.value;
  const session = await decrypt(cookie);

  if (!session?.userId) {
    redirect('/login');
  }

  return { isAuth: true, userId: Number(session.userId) };
});

export const getUser = cache(async () => {
  const session = await verifySession();
  if (!session) return null;

  try {
    const data = await db.query.users.findFirst({
      where: eq(users.id, session.userId),
      columns: {
        id: true,
        name: true,
        email: true,
      },
    });

    return data;
  } catch (error) {
    console.log('Failed to fetch user');
    return null;
  }
});
```

### Complete Form with Validation

Server action:

```typescript
'use server';

import { z } from 'zod';
import { verifySession } from '@/app/lib/dal';

const schema = z.object({
  title: z.string().min(1).max(100),
  content: z.string().min(1),
});

export async function createPost(prevState: any, formData: FormData) {
  const session = await verifySession();

  if (!session) {
    return { message: 'Unauthorized' };
  }

  const validatedFields = schema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
  });

  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  const { title, content } = validatedFields.data;

  try {
    await db.insert(posts).values({
      userId: session.userId,
      title,
      content,
    });

    revalidateTag('posts', 'max');
    return { message: 'Post created successfully' };
  } catch (error) {
    return { message: 'Failed to create post' };
  }
}
```

Client component:

```typescript
'use client';

import { useActionState } from 'react';
import { useFormStatus } from 'react-dom';
import { createPost } from '@/app/actions';

const initialState = {
  message: '',
};

function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Creating...' : 'Create Post'}
    </button>
  );
}

export function CreatePostForm() {
  const [state, formAction] = useActionState(createPost, initialState);

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="title">Title</label>
        <input type="text" id="title" name="title" required />
        {state?.errors?.title && <p>{state.errors.title}</p>}
      </div>

      <div>
        <label htmlFor="content">Content</label>
        <textarea id="content" name="content" required />
        {state?.errors?.content && <p>{state.errors.content}</p>}
      </div>

      {state?.message && <p>{state.message}</p>}

      <SubmitButton />
    </form>
  );
}
```

### Complete Image Configuration

```javascript
module.exports = {
  images: {
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [32, 48, 64, 96, 128, 256, 384],
    formats: ['image/webp'],
    minimumCacheTTL: 14400,

    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'assets.example.com',
        port: '',
        pathname: '/images/**',
        search: '',
      },
    ],

    localPatterns: [
      {
        pathname: '/assets/**',
        search: '',
      },
    ],

    dangerouslyAllowSVG: false,
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
    contentDispositionType: 'attachment',
  },
};
```

### Complete Next.js Config

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  cacheComponents: true,
  reactCompiler: true,

  turbopack: {
    resolveAlias: {
      canvas: './empty-module.ts',
    },
  },

  experimental: {
    turbopackFileSystemCacheForDev: true,
    turbopackFileSystemCacheForBuild: true,
  },

  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'assets.example.com',
        pathname: '/images/**',
      },
    ],
  },

  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline';",
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
        ],
      },
    ];
  },
};

export default nextConfig;
```

## Migration Guide Quick Reference

### Upgrade Checklist

- [ ] Verify Node.js 20.9.0+
- [ ] Verify TypeScript 5.1.0+ (if using TypeScript)
- [ ] Run automated codemod: `npx @next/codemod@canary upgrade latest`
- [ ] Rename `middleware.ts` to `proxy.ts`
- [ ] Update function export from `middleware` to `proxy`
- [ ] Add `await` to all `params` and `searchParams` access
- [ ] Add `await` to `cookies()`, `headers()`, `draftMode()`
- [ ] Run `npx next typegen` for type helpers
- [ ] Add `default.js` to all parallel route slots
- [ ] Update `revalidateTag()` calls with second argument
- [ ] Configure local image patterns if using query strings
- [ ] Remove Turbopack flags from package.json scripts
- [ ] Move Turbopack config to top level
- [ ] Replace environment variable patterns
- [ ] Update ESLint configuration
- [ ] Test build and dev commands
- [ ] Review security patterns (no middleware auth)
- [ ] Implement Data Access Layer pattern
- [ ] Update image configuration defaults

### Common Transformation Patterns

#### Before: Synchronous params

```typescript
export default function Page({ params }) {
  const { slug } = params;
  return <div>{slug}</div>;
}
```

#### After: Async params

```typescript
export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  return <div>{slug}</div>;
}
```

#### Before: Synchronous cookies

```typescript
const cookieStore = cookies();
const token = cookieStore.get('token');
```

#### After: Async cookies

```typescript
const cookieStore = await cookies();
const token = cookieStore.get('token');
```

#### Before: force-static

```typescript
export const dynamic = 'force-static';

export default async function Page() {
  const data = await fetch('...');
  return <div>{data}</div>;
}
```

#### After: use cache

```typescript
export default async function Page() {
  'use cache';
  const data = await fetch('...');
  return <div>{data}</div>;
}
```

## References

- [Official Next.js 16 Release Blog](https://nextjs.org/blog/next-16)
- [Official Upgrade Guide](https://nextjs.org/docs/app/guides/upgrading/version-16)
- [Next.js Documentation](https://nextjs.org/docs)
- [GitHub Repository](https://github.com/vercel/next.js)
- [Next.js Security Checklist 2025](https://blog.arcjet.com/next-js-security-checklist/)
- [React & Next.js Best Practices 2025](https://strapi.io/blog/react-and-nextjs-in-2025-modern-best-practices)
- [Complete Security Guide](https://www.turbostarter.dev/blog/complete-nextjs-security-guide-2025-authentication-api-protection-and-best-practices)
- [Vercel Deployment Documentation](https://vercel.com/docs/frameworks/full-stack/nextjs)

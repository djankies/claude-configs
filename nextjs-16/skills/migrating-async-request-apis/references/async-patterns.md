# Async Request APIs - Detailed Examples

This document contains detailed migration examples, edge cases, and troubleshooting for Next.js 16 async request APIs.

## Complete Migration Examples

### Example 1: Blog Post Page with Multiple Request APIs

**Before (Next.js 15):**
```typescript
import { cookies, headers } from 'next/headers';

export default function BlogPost({
  params,
  searchParams
}: {
  params: { slug: string };
  searchParams: { preview?: string };
}) {
  const cookieStore = cookies();
  const theme = cookieStore.get('theme')?.value || 'light';

  const headersList = headers();
  const userAgent = headersList.get('user-agent');

  return (
    <article data-theme={theme}>
      <h1>{params.slug}</h1>
      {searchParams.preview && <div>Preview Mode</div>}
      <div>User Agent: {userAgent}</div>
    </article>
  );
}

export async function generateMetadata({ params }: { params: { slug: string } }) {
  return { title: params.slug };
}
```

**After (Next.js 16):**
```typescript
import { cookies, headers } from 'next/headers';

export default async function BlogPost({
  params,
  searchParams
}: {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ preview?: string }>;
}) {
  const [{ slug }, search, cookieStore, headersList] = await Promise.all([
    params,
    searchParams,
    cookies(),
    headers()
  ]);

  const theme = cookieStore.get('theme')?.value || 'light';
  const userAgent = headersList.get('user-agent');

  return (
    <article data-theme={theme}>
      <h1>{slug}</h1>
      {search.preview && <div>Preview Mode</div>}
      <div>User Agent: {userAgent}</div>
    </article>
  );
}

export async function generateMetadata({
  params
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params;
  return { title: slug };
}
```

### Example 2: API Route with Authentication

**Before (Next.js 15):**
```typescript
import { cookies, headers } from 'next/headers';

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const headersList = headers();
  const authorization = headersList.get('authorization');

  const cookieStore = cookies();
  const session = cookieStore.get('session');

  if (!authorization && !session) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();

  return Response.json({
    id: params.id,
    data: body
  });
}
```

**After (Next.js 16):**
```typescript
import { cookies, headers } from 'next/headers';

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const [{ id }, headersList, cookieStore, body] = await Promise.all([
    params,
    headers(),
    cookies(),
    request.json()
  ]);

  const authorization = headersList.get('authorization');
  const session = cookieStore.get('session');

  if (!authorization && !session) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  return Response.json({
    id,
    data: body
  });
}
```

### Example 3: Multi-Segment Dynamic Route

**Before (Next.js 15):**
```typescript
export default function CategoryProduct({
  params
}: {
  params: { category: string; product: string }
}) {
  return (
    <div>
      <h1>Category: {params.category}</h1>
      <h2>Product: {params.product}</h2>
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
export default async function CategoryProduct({
  params
}: {
  params: Promise<{ category: string; product: string }>
}) {
  const { category, product } = await params;

  return (
    <div>
      <h1>Category: {category}</h1>
      <h2>Product: {product}</h2>
    </div>
  );
}
```

### Example 4: Nested Layout with Locale

**Before (Next.js 15):**
```typescript
import { cookies } from 'next/headers';

export default function Layout({
  children,
  params
}: {
  children: React.ReactNode;
  params: { locale: string };
}) {
  const cookieStore = cookies();
  const direction = cookieStore.get('text-direction')?.value || 'ltr';

  return (
    <html lang={params.locale} dir={direction}>
      <body>{children}</body>
    </html>
  );
}
```

**After (Next.js 16):**
```typescript
import { cookies } from 'next/headers';

export default async function Layout({
  children,
  params
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const [{ locale }, cookieStore] = await Promise.all([
    params,
    cookies()
  ]);

  const direction = cookieStore.get('text-direction')?.value || 'ltr';

  return (
    <html lang={locale} dir={direction}>
      <body>{children}</body>
    </html>
  );
}
```

### Example 5: Search Page with Pagination

**Before (Next.js 15):**
```typescript
import { headers } from 'next/headers';

export default function SearchPage({
  searchParams
}: {
  searchParams: { q?: string; page?: string; sort?: string }
}) {
  const query = searchParams.q || '';
  const page = Number(searchParams.page) || 1;
  const sort = searchParams.sort || 'relevance';

  const headersList = headers();
  const userAgent = headersList.get('user-agent');
  const isMobile = /mobile/i.test(userAgent || '');

  return (
    <div>
      <h1>Search: {query}</h1>
      <p>Page {page} - Sorted by {sort}</p>
      {isMobile && <p>Mobile view</p>}
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
import { headers } from 'next/headers';

export default async function SearchPage({
  searchParams
}: {
  searchParams: Promise<{ q?: string; page?: string; sort?: string }>
}) {
  const [params, headersList] = await Promise.all([
    searchParams,
    headers()
  ]);

  const query = params.q || '';
  const page = Number(params.page) || 1;
  const sort = params.sort || 'relevance';

  const userAgent = headersList.get('user-agent');
  const isMobile = /mobile/i.test(userAgent || '');

  return (
    <div>
      <h1>Search: {query}</h1>
      <p>Page {page} - Sorted by {sort}</p>
      {isMobile && <p>Mobile view</p>}
    </div>
  );
}
```

### Example 6: Draft Mode with CMS Preview

**Before (Next.js 15):**
```typescript
import { draftMode } from 'next/headers';

export default function CMSContent({
  params
}: {
  params: { slug: string }
}) {
  const { isEnabled } = draftMode();

  const content = isEnabled
    ? fetchDraftContent(params.slug)
    : fetchPublishedContent(params.slug);

  return (
    <article>
      {isEnabled && <div className="preview-banner">Preview Mode</div>}
      <h1>{content.title}</h1>
      <div>{content.body}</div>
    </article>
  );
}
```

**After (Next.js 16):**
```typescript
import { draftMode } from 'next/headers';

export default async function CMSContent({
  params
}: {
  params: Promise<{ slug: string }>
}) {
  const [{ slug }, { isEnabled }] = await Promise.all([
    params,
    draftMode()
  ]);

  const content = isEnabled
    ? await fetchDraftContent(slug)
    : await fetchPublishedContent(slug);

  return (
    <article>
      {isEnabled && <div className="preview-banner">Preview Mode</div>}
      <h1>{content.title}</h1>
      <div>{content.body}</div>
    </article>
  );
}
```

### Example 7: Complex Route Handler with Multiple Operations

**Before (Next.js 15):**
```typescript
import { cookies, headers } from 'next/headers';

export async function PUT(
  request: Request,
  { params }: { params: { userId: string; postId: string } }
) {
  const headersList = headers();
  const apiKey = headersList.get('x-api-key');

  const cookieStore = cookies();
  const sessionToken = cookieStore.get('session')?.value;

  if (!apiKey && !sessionToken) {
    return Response.json({ error: 'Authentication required' }, { status: 401 });
  }

  const body = await request.json();

  const result = await updatePost(params.userId, params.postId, body);

  cookieStore.set('last-modified', new Date().toISOString());

  return Response.json(result);
}
```

**After (Next.js 16):**
```typescript
import { cookies, headers } from 'next/headers';

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ userId: string; postId: string }> }
) {
  const [{ userId, postId }, headersList, cookieStore, body] = await Promise.all([
    params,
    headers(),
    cookies(),
    request.json()
  ]);

  const apiKey = headersList.get('x-api-key');
  const sessionToken = cookieStore.get('session')?.value;

  if (!apiKey && !sessionToken) {
    return Response.json({ error: 'Authentication required' }, { status: 401 });
  }

  const result = await updatePost(userId, postId, body);

  cookieStore.set('last-modified', new Date().toISOString());

  return Response.json(result);
}
```

### Example 8: Catch-All Route

**Before (Next.js 15):**
```typescript
export default function CatchAllPage({
  params
}: {
  params: { slug: string[] }
}) {
  const path = params.slug.join('/');

  return (
    <div>
      <h1>Path: {path}</h1>
      <ul>
        {params.slug.map((segment, i) => (
          <li key={i}>{segment}</li>
        ))}
      </ul>
    </div>
  );
}
```

**After (Next.js 16):**
```typescript
export default async function CatchAllPage({
  params
}: {
  params: Promise<{ slug: string[] }>
}) {
  const { slug } = await params;
  const path = slug.join('/');

  return (
    <div>
      <h1>Path: {path}</h1>
      <ul>
        {slug.map((segment, i) => (
          <li key={i}>{segment}</li>
        ))}
      </ul>
    </div>
  );
}
```

## Edge Cases and Troubleshooting

### Edge Case 1: Optional Catch-All Routes

```typescript
export default async function Page({
  params
}: {
  params: Promise<{ slug?: string[] }>
}) {
  const { slug } = await params;

  if (!slug) {
    return <div>Home Page</div>;
  }

  return <div>Path: {slug.join('/')}</div>;
}
```

### Edge Case 2: Parallel Routes with Params

```typescript
export default async function Layout({
  children,
  parallel,
  params
}: {
  children: React.ReactNode;
  parallel: React.ReactNode;
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  return (
    <div>
      <aside data-id={id}>{parallel}</aside>
      <main>{children}</main>
    </div>
  );
}
```

### Edge Case 3: Intercepting Routes

```typescript
export default async function InterceptedModal({
  params
}: {
  params: Promise<{ photoId: string }>
}) {
  const { photoId } = await params;

  return (
    <dialog open>
      <img src={`/photos/${photoId}`} alt="Photo" />
    </dialog>
  );
}
```

### Edge Case 4: Route Groups

```typescript
export default async function Page({
  params
}: {
  params: Promise<{ category: string; item: string }>
}) {
  const { category, item } = await params;

  return (
    <div>
      <h1>{category}</h1>
      <h2>{item}</h2>
    </div>
  );
}
```

### Troubleshooting: Promise.all Error Handling

```typescript
export default async function Page({
  params,
  searchParams
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ tab?: string }>;
}) {
  try {
    const [{ id }, search] = await Promise.all([
      params,
      searchParams
    ]);

    return <div>ID: {id}, Tab: {search.tab}</div>;
  } catch (error) {
    console.error('Failed to resolve params:', error);
    return <div>Error loading page</div>;
  }
}
```

### Troubleshooting: Type Narrowing with Awaited

```typescript
type PageParams = Promise<{ id: string }>;

export default async function Page({ params }: { params: PageParams }) {
  const resolvedParams: Awaited<PageParams> = await params;

  return <div>ID: {resolvedParams.id}</div>;
}
```

### Troubleshooting: Conditional Params Access

```typescript
export default async function Page({
  params,
  searchParams
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ mode?: 'edit' | 'view' }>;
}) {
  const search = await searchParams;

  if (search.mode === 'edit') {
    const { id } = await params;
    return <EditForm id={id} />;
  }

  return <ViewMode />;
}
```

## Performance Patterns

### Pattern 1: Parallel Resolution

```typescript
const [{ id }, search, cookieStore, headersList] = await Promise.all([
  params,
  searchParams,
  cookies(),
  headers()
]);
```

### Pattern 2: Sequential Resolution (When Dependencies Exist)

```typescript
const { id } = await params;

const data = await fetchData(id);

const cookieStore = await cookies();
const preferences = cookieStore.get('preferences');
```

### Pattern 3: Conditional Resolution

```typescript
const search = await searchParams;

const additionalData = search.includeExtra
  ? await fetchExtraData()
  : null;
```

### Pattern 4: Deferred Resolution

```typescript
export default async function Page({
  params,
  searchParams
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ tab?: string }>;
}) {
  const paramsPromise = params;
  const searchPromise = searchParams;

  const data = await fetchData();

  const [{ id }, search] = await Promise.all([
    paramsPromise,
    searchPromise
  ]);

  return <Component data={data} id={id} tab={search.tab} />;
}
```

## Type Safety Patterns

### Reusable Type Definitions

```typescript
type PageParams<T = {}> = Promise<T>;
type SearchParams = Promise<{ [key: string]: string | string[] | undefined }>;

type PageProps<T = {}> = {
  params: PageParams<T>;
  searchParams: SearchParams;
};

export default async function Page({
  params,
  searchParams
}: PageProps<{ id: string }>) {
  const { id } = await params;
  const search = await searchParams;

  return <div>{id}</div>;
}
```

### Type Guards for Promise Resolution

For type guard patterns with Promises, see `@typescript/TYPES-type-guards` skill.

```typescript
function isValidId(id: string): id is string {
  return /^[a-z0-9]+$/i.test(id);
}

export default async function Page({
  params
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params;

  if (!isValidId(id)) {
    return <div>Invalid ID</div>;
  }

  return <div>Valid ID: {id}</div>;
}
```

### Generic Route Handler Types

```typescript
type RouteContext<T = {}> = {
  params: Promise<T>;
};

export async function GET(
  request: Request,
  context: RouteContext<{ id: string }>
) {
  const { id } = await context.params;

  return Response.json({ id });
}
```

## Cookie Operations

### Setting Cookies After Await

```typescript
export async function POST(request: Request) {
  const cookieStore = await cookies();

  cookieStore.set('token', 'value', {
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 7
  });

  return Response.json({ success: true });
}
```

### Reading and Modifying Cookies

```typescript
export default async function Page() {
  const cookieStore = await cookies();

  const theme = cookieStore.get('theme')?.value || 'light';
  const allCookies = cookieStore.getAll();

  return (
    <div>
      <p>Current theme: {theme}</p>
      <p>Total cookies: {allCookies.length}</p>
    </div>
  );
}
```

### Deleting Cookies

```typescript
export async function POST(request: Request) {
  const cookieStore = await cookies();

  cookieStore.delete('session');

  return Response.json({ logged_out: true });
}
```

## Headers Operations

### Reading Multiple Headers

```typescript
export default async function Page() {
  const headersList = await headers();

  const userAgent = headersList.get('user-agent');
  const referer = headersList.get('referer');
  const acceptLanguage = headersList.get('accept-language');

  return (
    <div>
      <p>User Agent: {userAgent}</p>
      <p>Referer: {referer}</p>
      <p>Language: {acceptLanguage}</p>
    </div>
  );
}
```

### Iterating Headers

```typescript
export async function GET() {
  const headersList = await headers();

  const headersObj: Record<string, string> = {};
  headersList.forEach((value, key) => {
    headersObj[key] = value;
  });

  return Response.json({ headers: headersObj });
}
```

## Draft Mode Operations

### Enabling Draft Mode

```typescript
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const secret = searchParams.get('secret');

  if (secret !== process.env.DRAFT_SECRET) {
    return Response.json({ error: 'Invalid secret' }, { status: 401 });
  }

  const draft = await draftMode();
  draft.enable();

  return Response.redirect('/preview');
}
```

### Disabling Draft Mode

```typescript
export async function GET() {
  const draft = await draftMode();
  draft.disable();

  return Response.redirect('/');
}
```

### Checking Draft Mode Status

```typescript
export default async function Page() {
  const { isEnabled } = await draftMode();

  return (
    <div>
      <p>Draft mode: {isEnabled ? 'enabled' : 'disabled'}</p>
    </div>
  );
}
```

## Common Errors and Solutions

### Error: "Cannot access property of undefined"

**Problem:**
```typescript
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  return <div>{params.id}</div>;
}
```

**Solution:**
```typescript
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <div>{id}</div>;
}
```

### Error: "Type 'Promise' is not assignable to type"

**Problem:**
```typescript
export default async function Page({ params }: { params: { id: string } }) {
  const { id } = await params;
  return <div>{id}</div>;
}
```

**Solution:**
```typescript
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <div>{id}</div>;
}
```

### Error: "await is only valid in async functions"

**Problem:**
```typescript
export default function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <div>{id}</div>;
}
```

**Solution:**
```typescript
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <div>{id}</div>;
}
```

### Error: "Property does not exist on type ReadonlyRequestCookies"

**Problem:**
```typescript
const cookieStore = cookies();
const token = cookieStore.get('token');
```

**Solution:**
```typescript
const cookieStore = await cookies();
const token = cookieStore.get('token');
```

## Migration Testing Strategy

### Test 1: Verify Params Resolution

```typescript
export default async function TestPage({
  params
}: {
  params: Promise<{ id: string }>
}) {
  console.log('Params type:', typeof params);
  console.log('Params is Promise:', params instanceof Promise);

  const resolved = await params;
  console.log('Resolved params:', resolved);

  return <div>Test: {resolved.id}</div>;
}
```

### Test 2: Verify Search Params

```typescript
export default async function TestPage({
  searchParams
}: {
  searchParams: Promise<{ q?: string }>
}) {
  const search = await searchParams;
  console.log('Search params:', search);

  return <div>Query: {search.q || 'none'}</div>;
}
```

### Test 3: Verify Cookie Operations

```typescript
export default async function TestPage() {
  const cookieStore = await cookies();

  cookieStore.set('test', 'value');
  const test = cookieStore.get('test');

  console.log('Cookie test:', test);

  return <div>Cookie: {test?.value}</div>;
}
```

### Test 4: Verify Headers Access

```typescript
export default async function TestPage() {
  const headersList = await headers();

  const userAgent = headersList.get('user-agent');
  console.log('User agent:', userAgent);

  return <div>UA: {userAgent}</div>;
}
```

### Test 5: Verify Draft Mode

```typescript
export default async function TestPage() {
  const { isEnabled } = await draftMode();

  console.log('Draft mode:', isEnabled);

  return <div>Draft: {isEnabled.toString()}</div>;
}
```

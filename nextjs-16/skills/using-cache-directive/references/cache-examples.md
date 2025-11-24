# Next.js 16 Cache Examples

Comprehensive examples demonstrating the `'use cache'` directive in various scenarios.

## Table of Contents

1. [Basic Caching Patterns](#basic-caching-patterns)
2. [E-commerce Examples](#e-commerce-examples)
3. [Blog/CMS Examples](#blogcms-examples)
4. [Dashboard Examples](#dashboard-examples)
5. [API Route Examples](#api-route-examples)
6. [Advanced Patterns](#advanced-patterns)
7. [Migration Examples](#migration-examples)

## Basic Caching Patterns

### File-Level Page Cache

```typescript
'use cache'
export const cacheLife = 'hours'

export default async function AboutPage() {
  const content = await db.query.pages.findFirst({
    where: eq(pages.slug, 'about')
  })

  return (
    <article>
      <h1>{content.title}</h1>
      <div dangerouslySetInnerHTML={{ __html: content.body }} />
    </article>
  )
}
```

### Component-Level Cache

```typescript
import { Suspense } from 'react'

async function CachedStats() {
  'use cache'
  export const cacheLife = 'minutes'

  const stats = await db.query.stats.findFirst()

  return (
    <div className="stats-grid">
      <StatCard label="Users" value={stats.userCount} />
      <StatCard label="Posts" value={stats.postCount} />
      <StatCard label="Comments" value={stats.commentCount} />
    </div>
  )
}

export default function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<StatsLoading />}>
        <CachedStats />
      </Suspense>
    </div>
  )
}
```

### Function-Level Cache

```typescript
async function getCategories() {
  'use cache'
  export const cacheLife = 'days'

  return db.query.categories.findMany({
    orderBy: { name: 'asc' }
  })
}

export default async function Sidebar() {
  const categories = await getCategories()

  return (
    <nav>
      <h2>Categories</h2>
      <ul>
        {categories.map(cat => (
          <li key={cat.id}>
            <Link href={`/category/${cat.slug}`}>{cat.name}</Link>
          </li>
        ))}
      </ul>
    </nav>
  )
}
```

## E-commerce Examples

### Product Catalog Page

```typescript
'use cache'
export const cacheLife = 'hours'
export const cacheTag = 'products'

export default async function ProductsPage({
  searchParams
}: {
  searchParams: { category?: string }
}) {
  const products = await db.query.products.findMany({
    where: searchParams.category
      ? eq(products.categoryId, searchParams.category)
      : undefined
  })

  return (
    <div>
      <h1>Products</h1>
      <ProductGrid products={products} />
    </div>
  )
}
```

### Product Detail Page with Mixed Content

```typescript
async function CachedProductInfo({ id }: { id: string }) {
  'use cache'
  export const cacheLife = 'hours'
  export const cacheTag = 'products'

  const product = await db.query.products.findFirst({
    where: eq(products.id, id),
    with: {
      images: true,
      variants: true
    }
  })

  return (
    <>
      <ProductImages images={product.images} />
      <ProductDetails product={product} />
      <ProductVariants variants={product.variants} />
    </>
  )
}

export default async function ProductPage({
  params
}: {
  params: { id: string }
}) {
  const session = await auth()

  return (
    <div>
      <CachedProductInfo id={params.id} />
      <AddToCartButton userId={session?.userId} />
      <RecentlyViewed userId={session?.userId} />
    </div>
  )
}
```

### Inventory Management

```typescript
async function getInventoryLevel(productId: string) {
  'use cache'
  export const cacheLife = {
    stale: 30,
    revalidate: 60,
    expire: 120
  }
  export const cacheTag = 'inventory'

  const inventory = await db.query.inventory.findFirst({
    where: eq(inventory.productId, productId)
  })

  return inventory?.quantity ?? 0
}

export default async function ProductStock({ productId }: { productId: string }) {
  const quantity = await getInventoryLevel(productId)

  return (
    <div>
      {quantity > 0 ? (
        <span className="in-stock">In Stock ({quantity} available)</span>
      ) : (
        <span className="out-of-stock">Out of Stock</span>
      )}
    </div>
  )
}
```

### Shopping Cart (No Cache)

```typescript
export default async function CartPage() {
  const session = await auth()

  if (!session) {
    redirect('/login')
  }

  const cart = await db.query.carts.findFirst({
    where: eq(carts.userId, session.userId),
    with: {
      items: {
        with: {
          product: true
        }
      }
    }
  })

  return (
    <div>
      <h1>Shopping Cart</h1>
      <CartItems items={cart?.items ?? []} />
      <CartSummary cart={cart} />
      <CheckoutButton />
    </div>
  )
}
```

## Blog/CMS Examples

### Blog Post List

```typescript
async function getBlogPosts() {
  'use cache'
  export const cacheLife = 'hours'
  export const cacheTag = 'blog-posts'

  return db.query.posts.findMany({
    where: eq(posts.published, true),
    orderBy: { publishedAt: 'desc' },
    limit: 20,
    with: {
      author: true
    }
  })
}

export default async function BlogPage() {
  const posts = await getBlogPosts()

  return (
    <div>
      <h1>Blog</h1>
      <div className="post-grid">
        {posts.map(post => (
          <PostCard key={post.id} post={post} />
        ))}
      </div>
    </div>
  )
}
```

### Blog Post Detail

```typescript
async function getPost(slug: string) {
  'use cache'
  export const cacheLife = 'days'
  export const cacheTag = 'blog-posts'

  return db.query.posts.findFirst({
    where: and(
      eq(posts.slug, slug),
      eq(posts.published, true)
    ),
    with: {
      author: true,
      tags: true
    }
  })
}

async function CachedPostContent({ slug }: { slug: string }) {
  'use cache'
  export const cacheLife = 'days'

  const post = await getPost(slug)

  if (!post) {
    notFound()
  }

  return (
    <article>
      <header>
        <h1>{post.title}</h1>
        <PostMeta author={post.author} publishedAt={post.publishedAt} />
      </header>
      <div dangerouslySetInnerHTML={{ __html: post.content }} />
      <TagList tags={post.tags} />
    </article>
  )
}

export default async function PostPage({
  params
}: {
  params: { slug: string }
}) {
  const session = await auth()

  return (
    <div>
      <CachedPostContent slug={params.slug} />
      <CommentSection slug={params.slug} userId={session?.userId} />
    </div>
  )
}
```

### Related Posts

```typescript
async function getRelatedPosts(postId: string) {
  'use cache'
  export const cacheLife = 'hours'

  const post = await db.query.posts.findFirst({
    where: eq(posts.id, postId),
    with: { tags: true }
  })

  const relatedPosts = await db.query.posts.findMany({
    where: and(
      eq(posts.published, true),
      ne(posts.id, postId)
    ),
    limit: 3
  })

  return relatedPosts
}

export default async function RelatedPosts({ postId }: { postId: string }) {
  const posts = await getRelatedPosts(postId)

  return (
    <aside>
      <h2>Related Posts</h2>
      <div className="related-grid">
        {posts.map(post => (
          <PostCard key={post.id} post={post} />
        ))}
      </div>
    </aside>
  )
}
```

## Dashboard Examples

### Admin Dashboard with Mixed Caching

```typescript
async function CachedOverviewStats() {
  'use cache'
  export const cacheLife = 'minutes'

  const stats = await db.query.stats.findFirst()

  return (
    <div className="stats-grid">
      <StatCard label="Total Users" value={stats.totalUsers} />
      <StatCard label="Total Revenue" value={stats.totalRevenue} />
      <StatCard label="Total Orders" value={stats.totalOrders} />
    </div>
  )
}

export default async function AdminDashboard() {
  const session = await auth()

  if (!session || session.user.role !== 'admin') {
    redirect('/login')
  }

  const recentActivity = await db.query.activities.findMany({
    limit: 10,
    orderBy: { createdAt: 'desc' }
  })

  return (
    <div>
      <h1>Admin Dashboard</h1>
      <Suspense fallback={<StatsLoading />}>
        <CachedOverviewStats />
      </Suspense>
      <RecentActivity items={recentActivity} />
    </div>
  )
}
```

### User Profile (No Cache)

```typescript
export default async function ProfilePage() {
  const session = await auth()

  if (!session) {
    redirect('/login')
  }

  const user = await db.query.users.findFirst({
    where: eq(users.id, session.userId),
    with: {
      profile: true,
      preferences: true
    }
  })

  return (
    <div>
      <h1>Profile</h1>
      <ProfileForm user={user} />
      <PreferencesForm preferences={user.preferences} />
    </div>
  )
}
```

## API Route Examples

### Cached API Response

```typescript
'use cache'
export const cacheLife = 'hours'
export const cacheTag = 'api-products'

export async function GET() {
  const products = await db.query.products.findMany({
    where: eq(products.active, true)
  })

  return Response.json({
    products,
    timestamp: new Date().toISOString()
  })
}
```

### Dynamic API Response

```typescript
import { auth } from '@/lib/auth'

export async function GET() {
  const session = await auth()

  if (!session) {
    return Response.json(
      { error: 'Unauthorized' },
      { status: 401 }
    )
  }

  const userData = await db.query.users.findFirst({
    where: eq(users.id, session.userId)
  })

  return Response.json({ user: userData })
}
```

### Cached Helper Function in API

```typescript
async function getPublicConfig() {
  'use cache'
  export const cacheLife = 'days'

  return db.query.config.findFirst({
    where: eq(config.public, true)
  })
}

export async function GET() {
  const config = await getPublicConfig()

  return Response.json({
    config,
    version: '1.0.0'
  })
}
```

## Advanced Patterns

### Incremental Static Regeneration (ISR) Pattern

```typescript
'use cache'
export const cacheLife = {
  stale: 3600,
  revalidate: 7200,
  expire: 86400
}
export const cacheTag = 'products'

export default async function ProductPage({
  params
}: {
  params: { id: string }
}) {
  const product = await db.query.products.findFirst({
    where: eq(products.id, params.id)
  })

  if (!product) {
    notFound()
  }

  return <ProductView product={product} />
}
```

### Parallel Data Fetching with Mixed Caching

```typescript
async function getCachedProducts() {
  'use cache'
  export const cacheLife = 'hours'

  return db.query.products.findMany()
}

export default async function Page() {
  const session = await auth()

  const [products, userPreferences] = await Promise.all([
    getCachedProducts(),
    session
      ? db.query.preferences.findFirst({
          where: eq(preferences.userId, session.userId)
        })
      : null
  ])

  return (
    <div>
      <ProductList
        products={products}
        preferences={userPreferences}
      />
    </div>
  )
}
```

### Conditional Caching Based on Parameters

```typescript
async function getProducts(options: {
  userId?: string
  cached?: boolean
}) {
  if (options.cached && !options.userId) {
    'use cache'
    export const cacheLife = 'hours'
  }

  return db.query.products.findMany({
    where: options.userId
      ? eq(products.userId, options.userId)
      : undefined
  })
}

export default async function ProductsPage() {
  const session = await auth()

  const products = await getProducts({
    userId: session?.userId,
    cached: !session
  })

  return <ProductGrid products={products} />
}
```

### Nested Cache Layers

```typescript
async function getBaseProducts() {
  'use cache'
  export const cacheLife = 'days'
  export const cacheTag = 'products-base'

  return db.query.products.findMany({
    where: eq(products.active, true)
  })
}

async function getProductsWithPricing() {
  'use cache'
  export const cacheLife = 'hours'
  export const cacheTag = 'products-pricing'

  const products = await getBaseProducts()
  const pricing = await db.query.pricing.findMany()

  return products.map(product => ({
    ...product,
    price: pricing.find(p => p.productId === product.id)
  }))
}

export default async function ProductsPage() {
  const products = await getProductsWithPricing()
  return <ProductGrid products={products} />
}
```

### Tag-Based Revalidation System

```typescript
async function getProducts() {
  'use cache'
  export const cacheTag = 'products'

  return db.query.products.findMany()
}

async function getCategories() {
  'use cache'
  export const cacheTag = 'categories'

  return db.query.categories.findMany()
}

async function getProductsWithCategories() {
  'use cache'
  export const cacheTag = ['products', 'categories']

  const [products, categories] = await Promise.all([
    getProducts(),
    getCategories()
  ])

  return products.map(product => ({
    ...product,
    category: categories.find(c => c.id === product.categoryId)
  }))
}
```

Server Actions for Revalidation:

```typescript
'use server'

import { revalidateTag } from 'next/cache'

export async function updateProduct(id: string, data: ProductInput) {
  await db.update(products).set(data).where(eq(products.id, id))
  revalidateTag('products')
}

export async function updateCategory(id: string, data: CategoryInput) {
  await db.update(categories).set(data).where(eq(categories.id, id))
  revalidateTag('categories')
}

export async function updateProductCategory(productId: string, categoryId: string) {
  await db.update(products)
    .set({ categoryId })
    .where(eq(products.id, productId))

  revalidateTag('products')
  revalidateTag('categories')
}
```

## Migration Examples

### Before: Next.js 15 with Route Segment Config

```typescript
export const revalidate = 3600
export const dynamic = 'auto'

export default async function Page() {
  const data = await fetch('https://api.example.com/data')
  return <div>{JSON.stringify(data)}</div>
}
```

### After: Next.js 16 with 'use cache'

```typescript
'use cache'
export const cacheLife = 'hours'

export default async function Page() {
  const data = await fetch('https://api.example.com/data')
  return <div>{JSON.stringify(data)}</div>
}
```

### Before: Next.js 15 with unstable_cache

```typescript
import { unstable_cache } from 'next/cache'

const getProducts = unstable_cache(
  async () => {
    return db.query.products.findMany()
  },
  ['products'],
  {
    revalidate: 3600,
    tags: ['products']
  }
)

export default async function Page() {
  const products = await getProducts()
  return <ProductList products={products} />
}
```

### After: Next.js 16 with Function-Level Cache

```typescript
async function getProducts() {
  'use cache'
  export const cacheLife = 'hours'
  export const cacheTag = 'products'

  return db.query.products.findMany()
}

export default async function Page() {
  const products = await getProducts()
  return <ProductList products={products} />
}
```

### Before: Next.js 15 with Fetch Cache Options

```typescript
export default async function Page() {
  const staticData = await fetch('https://api.example.com/static', {
    cache: 'force-cache'
  })

  const revalidatedData = await fetch('https://api.example.com/revalidate', {
    next: { revalidate: 3600 }
  })

  const dynamicData = await fetch('https://api.example.com/dynamic', {
    cache: 'no-store'
  })

  return (
    <div>
      <StaticSection data={staticData} />
      <RevalidatedSection data={revalidatedData} />
      <DynamicSection data={dynamicData} />
    </div>
  )
}
```

### After: Next.js 16 with Granular Caching

```typescript
async function getStaticData() {
  'use cache'
  export const cacheLife = 'max'

  return fetch('https://api.example.com/static')
}

async function getRevalidatedData() {
  'use cache'
  export const cacheLife = 'hours'

  return fetch('https://api.example.com/revalidate')
}

async function getDynamicData() {
  return fetch('https://api.example.com/dynamic')
}

export default async function Page() {
  const [staticData, revalidatedData, dynamicData] = await Promise.all([
    getStaticData(),
    getRevalidatedData(),
    getDynamicData()
  ])

  return (
    <div>
      <StaticSection data={staticData} />
      <RevalidatedSection data={revalidatedData} />
      <DynamicSection data={dynamicData} />
    </div>
  )
}
```

### Before: Next.js 15 Mixed Static and Dynamic

```typescript
export const dynamic = 'force-dynamic'

export default async function Page() {
  const user = await auth()
  const products = await db.query.products.findMany()

  return (
    <div>
      <UserGreeting user={user} />
      <ProductList products={products} />
    </div>
  )
}
```

### After: Next.js 16 with Component-Level Cache

```typescript
async function CachedProductList() {
  'use cache'
  export const cacheLife = 'hours'

  const products = await db.query.products.findMany()
  return <ProductList products={products} />
}

export default async function Page() {
  const user = await auth()

  return (
    <div>
      <UserGreeting user={user} />
      <CachedProductList />
    </div>
  )
}
```

# Next.js Setup Guide

## Next.js 15+ with App Router

**Install dependencies:**

```bash
npx create-next-app@latest my-app
cd my-app
npm install tailwindcss @tailwindcss/postcss
```

**postcss.config.js:**

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

**app/globals.css:**

```css
@import 'tailwindcss';

@theme {
  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);

  --color-primary: oklch(0.65 0.25 270);
  --color-secondary: oklch(0.75 0.22 320);
}
```

**app/layout.tsx:**

```typescript
import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: 'My App',
  description: 'Built with Next.js and Tailwind CSS v4',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        {children}
      </body>
    </html>
  );
}
```

**app/page.tsx:**

```typescript
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold text-primary">
        Next.js + Tailwind v4
      </h1>
      <p className="mt-4 text-lg text-gray-600 dark:text-gray-300">
        CSS-first configuration with @theme directive
      </p>
    </main>
  );
}
```

## Pages Router Setup

**pages/_app.tsx:**

```typescript
import type { AppProps } from 'next/app';
import '@/styles/globals.css';

export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />;
}
```

**styles/globals.css:**

```css
@import 'tailwindcss';

@theme {
  --color-primary: oklch(0.65 0.25 270);
}
```

**pages/index.tsx:**

```typescript
export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <h1 className="text-4xl font-bold text-primary">
        Next.js Pages Router + Tailwind v4
      </h1>
    </div>
  );
}
```

## Dark Mode Setup

**app/layout.tsx:**

```typescript
import './globals.css';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
        {children}
      </body>
    </html>
  );
}
```

**Dynamic dark mode with next-themes:**

```bash
npm install next-themes
```

**app/providers.tsx:**

```typescript
'use client';

import { ThemeProvider } from 'next-themes';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      {children}
    </ThemeProvider>
  );
}
```

**app/layout.tsx:**

```typescript
import { Providers } from './providers';
import './globals.css';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

## Component Library Integration

**Shared theme across apps:**

**packages/ui/theme.css:**

```css
@theme {
  --*: initial;

  --font-sans: 'Inter', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;

  --color-primary: oklch(0.65 0.25 270);
  --color-secondary: oklch(0.75 0.22 320);
  --color-success: oklch(0.72 0.15 142);
  --color-warning: oklch(0.78 0.18 60);
  --color-error: oklch(0.65 0.22 25);
}
```

**apps/web/app/globals.css:**

```css
@import 'tailwindcss';
@import '@my-company/ui/theme.css';
```

**postcss.config.js:**

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

## TypeScript Component Example

**components/Button.tsx:**

```typescript
import { ButtonHTMLAttributes, forwardRef } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', className = '', children, ...props }, ref) => {
    const baseStyles = 'rounded-lg font-medium transition-colors';

    const variantStyles = {
      primary: 'bg-primary text-white hover:opacity-90',
      secondary: 'bg-secondary text-white hover:opacity-90',
      outline: 'border-2 border-primary text-primary hover:bg-primary hover:text-white',
    };

    const sizeStyles = {
      sm: 'px-3 py-1.5 text-sm',
      md: 'px-4 py-2 text-base',
      lg: 'px-6 py-3 text-lg',
    };

    return (
      <button
        ref={ref}
        className={`${baseStyles} ${variantStyles[variant]} ${sizeStyles[size]} ${className}`}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';

export default Button;
```

## Server Components with Tailwind

**app/components/Card.tsx:**

```typescript
interface CardProps {
  title: string;
  description: string;
  children?: React.ReactNode;
}

export default function Card({ title, description, children }: CardProps) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-md dark:border-gray-700 dark:bg-gray-800">
      <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
        {title}
      </h2>
      <p className="mt-2 text-gray-600 dark:text-gray-300">
        {description}
      </p>
      {children && <div className="mt-4">{children}</div>}
    </div>
  );
}
```

## Environment-Specific Styling

**app/globals.css:**

```css
@import 'tailwindcss';

@theme {
  --color-primary: oklch(0.65 0.25 270);
}

@layer base {
  body {
    @apply antialiased;
  }
}
```

## Performance Optimization

**next.config.js:**

```javascript
const nextConfig = {
  experimental: {
    optimizeCss: true,
  },
};

export default nextConfig;
```

**Production build:**

```bash
NODE_ENV=production npm run build
```

## Deployment

**Vercel:**

No additional configuration needed. Vercel automatically detects PostCSS config.

**Self-hosted:**

```bash
npm run build
npm start
```

**Docker:**

```dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package*.json ./
RUN npm ci --production

EXPOSE 3000
CMD ["npm", "start"]
```

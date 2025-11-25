# PostCSS Setup Examples

## Basic PostCSS Configuration

**Install dependencies:**

```bash
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

**input.css:**

```css
@import 'tailwindcss';

@theme {
  --color-primary: oklch(0.65 0.25 270);
}
```

## CommonJS Format

**postcss.config.cjs:**

```javascript
module.exports = {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

## Next.js Integration

**Install dependencies:**

```bash
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

**app/globals.css or styles/globals.css:**

```css
@import 'tailwindcss';

@theme {
  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);
  --color-primary: oklch(0.65 0.25 270);
}
```

**app/layout.tsx:**

```typescript
import './globals.css';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

## Webpack Integration

**webpack.config.js:**

```javascript
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          'style-loader',
          'css-loader',
          {
            loader: 'postcss-loader',
            options: {
              postcssOptions: {
                plugins: {
                  '@tailwindcss/postcss': {},
                },
              },
            },
          },
        ],
      },
    ],
  },
};
```

## Custom PostCSS Plugins

**Note:** Tailwind v4 replaces the need for `postcss-import` and `autoprefixer`.

**postcss.config.js:**

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

## Build Scripts

**package.json:**

```json
{
  "scripts": {
    "dev": "postcss src/input.css -o dist/output.css --watch",
    "build": "NODE_ENV=production postcss src/input.css -o dist/output.css"
  }
}
```

## Angular Integration

**Install dependencies:**

```bash
npm install tailwindcss @tailwindcss/postcss
```

**Create postcss.config.js:**

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

**angular.json:**

```json
{
  "projects": {
    "my-app": {
      "architect": {
        "build": {
          "options": {
            "postcssConfig": "postcss.config.js",
            "styles": ["src/styles.css"]
          }
        }
      }
    }
  }
}
```

**src/styles.css:**

```css
@import 'tailwindcss';

@theme {
  --color-primary: oklch(0.65 0.25 270);
}
```

## Nuxt 3 Integration

**Install dependencies:**

```bash
npm install tailwindcss @tailwindcss/postcss
```

**nuxt.config.ts:**

```typescript
export default defineNuxtConfig({
  postcss: {
    plugins: {
      '@tailwindcss/postcss': {},
    },
  },
});
```

**assets/css/main.css:**

```css
@import 'tailwindcss';

@theme {
  --color-primary: oklch(0.65 0.25 270);
}
```

**app.vue:**

```vue
<template>
  <NuxtPage />
</template>

<style>
@import '@/assets/css/main.css';
</style>
```

## Gatsby Integration

**Install dependencies:**

```bash
npm install tailwindcss @tailwindcss/postcss gatsby-plugin-postcss
```

**gatsby-config.js:**

```javascript
module.exports = {
  plugins: ['gatsby-plugin-postcss'],
};
```

**postcss.config.js:**

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

**src/styles/global.css:**

```css
@import 'tailwindcss';

@theme {
  --color-primary: oklch(0.65 0.25 270);
}
```

**gatsby-browser.js:**

```javascript
import './src/styles/global.css';
```

## Common Issues

**Module parse failed: Unexpected character '@'**

Ensure PostCSS is configured correctly and using `@tailwindcss/postcss`:

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

**Styles not applying**

Check that:
1. CSS import is present: `@import "tailwindcss";`
2. PostCSS config uses correct plugin
3. Template files aren't in `.gitignore`
4. Class names are complete strings

**Production builds missing styles**

Set `NODE_ENV=production`:

```bash
NODE_ENV=production npm run build
```

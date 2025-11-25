# Vite Setup Examples

## Basic React + Vite Setup

**Install dependencies:**

```bash
npm create vite@latest my-app -- --template react
cd my-app
npm install tailwindcss @tailwindcss/vite
```

**vite.config.js:**

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

**src/index.css:**

```css
@import 'tailwindcss';

@theme {
  --color-brand: oklch(0.65 0.25 270);
  --font-sans: 'Inter', sans-serif;
}
```

**src/main.jsx:**

```javascript
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

## Vue + Vite Setup

**Install dependencies:**

```bash
npm create vite@latest my-app -- --template vue
cd my-app
npm install tailwindcss @tailwindcss/vite
```

**vite.config.js:**

```javascript
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [vue(), tailwindcss()],
});
```

**src/style.css:**

```css
@import 'tailwindcss';

@theme {
  --color-primary: oklch(0.65 0.25 142);
  --font-sans: 'Roboto', sans-serif;
}
```

## Svelte + Vite Setup

**Install dependencies:**

```bash
npm create vite@latest my-app -- --template svelte
cd my-app
npm install tailwindcss @tailwindcss/vite
```

**vite.config.js:**

```javascript
import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [svelte(), tailwindcss()],
});
```

**src/app.css:**

```css
@import 'tailwindcss';
```

## Multi-Environment Configuration

**Development with watch mode:**

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig(({ mode }) => ({
  plugins: [
    react(),
    tailwindcss({
      watch: mode === 'development',
    }),
  ],
}));
```

## Monorepo Setup

**Root vite.config.js:**

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@ui': '/packages/ui/src',
      '@shared': '/packages/shared/src',
    },
  },
});
```

**Root CSS with package sources:**

```css
@import 'tailwindcss';

@source "../packages/ui";
@source "../packages/shared";

@theme {
  --color-brand: oklch(0.65 0.25 270);
}
```

## Custom Build Output

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  build: {
    outDir: 'dist',
    cssCodeSplit: true,
    rollupOptions: {
      output: {
        assetFileNames: 'assets/[name].[hash][extname]',
      },
    },
  },
});
```

## Performance Optimization

**Exclude unnecessary directories:**

```css
@import 'tailwindcss';

@source not "./docs";
@source not "./legacy";
@source not "./scripts";
```

**Production build:**

```bash
NODE_ENV=production npm run build
```

**Build time monitoring:**

```bash
time npm run build
```

Expected performance:
- Full builds: ~100ms
- Incremental rebuilds: ~5ms
- No-change rebuilds: ~192µs

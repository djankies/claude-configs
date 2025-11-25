# Theme Variable Namespace Reference

## Complete Namespace Documentation

### Color Namespace: `--color-*`

**Generates utilities:** bg-, text-, fill-, stroke-, border-, ring-, outline-, decoration-, caret-

**Definition:**

```css
@theme {
  --color-primary: oklch(0.65 0.25 270);
  --color-brand: oklch(0.75 0.22 320);
  --color-error: oklch(0.65 0.22 25);
}
```

**Usage:**

```html
<div class="bg-primary text-white border-primary"></div>
<svg class="fill-brand stroke-brand"></svg>
<input class="ring-error outline-error caret-error" />
```

**With opacity modifiers:**

```html
<div class="bg-primary/50 text-brand/75"></div>
```

### Font Family: `--font-*`

**Generates utilities:** font-{name}

**Definition:**

```css
@theme {
  --font-sans: 'Inter', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  --font-display: 'Satoshi', sans-serif;
  --font-script: 'Great Vibes', cursive;
}
```

**Usage:**

```html
<body class="font-sans">
  <h1 class="font-display">Heading</h1>
  <code class="font-mono">Code</code>
  <p class="font-script">Script text</p>
</body>
```

### Font Size: `--text-*`

**Generates utilities:** text-{size}

**Definition:**

```css
@theme {
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;
}
```

**Usage:**

```html
<p class="text-sm">Small text</p>
<h1 class="text-4xl">Large heading</h1>
```

### Font Weight: `--font-weight-*`

**Generates utilities:** font-{weight}

**Definition:**

```css
@theme {
  --font-weight-thin: 100;
  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --font-weight-black: 900;
}
```

**Usage:**

```html
<p class="font-light">Light text</p>
<strong class="font-bold">Bold text</strong>
<h1 class="font-black">Black weight</h1>
```

### Letter Spacing: `--tracking-*`

**Generates utilities:** tracking-{size}

**Definition:**

```css
@theme {
  --tracking-tighter: -0.05em;
  --tracking-tight: -0.025em;
  --tracking-normal: 0em;
  --tracking-wide: 0.025em;
  --tracking-wider: 0.05em;
  --tracking-widest: 0.1em;
}
```

**Usage:**

```html
<p class="tracking-tight">Tight spacing</p>
<p class="tracking-wide">Wide spacing</p>
```

### Line Height: `--leading-*`

**Generates utilities:** leading-{size}

**Definition:**

```css
@theme {
  --leading-none: 1;
  --leading-tight: 1.25;
  --leading-snug: 1.375;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;
  --leading-loose: 2;
}
```

**Usage:**

```html
<p class="leading-tight">Tight line height</p>
<p class="leading-loose">Loose line height</p>
```

### Breakpoints: `--breakpoint-*`

**Generates responsive variants:** {breakpoint}:

**Definition:**

```css
@theme {
  --breakpoint-sm: 40rem;
  --breakpoint-md: 48rem;
  --breakpoint-lg: 64rem;
  --breakpoint-xl: 80rem;
  --breakpoint-2xl: 96rem;
  --breakpoint-3xl: 120rem;
}
```

**Usage:**

```html
<div class="grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"></div>
<p class="text-base lg:text-lg 2xl:text-xl 3xl:text-2xl"></p>
```

### Spacing: `--spacing-*`

**Generates utilities:** p-, m-, w-, h-, gap-, space-, inset-, top-, right-, bottom-, left-

**Definition:**

```css
@theme {
  --spacing: 0.25rem;
  --spacing-px: 1px;
  --spacing-0: 0;
  --spacing-1: calc(var(--spacing) * 1);
  --spacing-2: calc(var(--spacing) * 2);
  --spacing-4: calc(var(--spacing) * 4);
  --spacing-8: calc(var(--spacing) * 8);
  --spacing-16: calc(var(--spacing) * 16);
  --spacing-18: 4.5rem;
  --spacing-72: 18rem;
}
```

**Usage:**

```html
<div class="p-4 m-2 w-18 h-72"></div>
<div class="gap-8 space-x-4"></div>
<div class="top-16 left-8"></div>
```

### Border Radius: `--radius-*`

**Generates utilities:** rounded-{size}

**Definition:**

```css
@theme {
  --radius-none: 0;
  --radius-sm: 0.125rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-2xl: 1rem;
  --radius-3xl: 1.5rem;
  --radius-4xl: 2rem;
  --radius-full: 9999px;
}
```

**Usage:**

```html
<div class="rounded-md"></div>
<button class="rounded-lg"></button>
<div class="rounded-4xl"></div>
<img class="rounded-full" />
```

### Box Shadow: `--shadow-*`

**Generates utilities:** shadow-{size}

**Definition:**

```css
@theme {
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-sm: 0 1px 3px 0 rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);
  --shadow-2xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);
  --shadow-brutal: 8px 8px 0 0 rgb(0 0 0);
}
```

**Usage:**

```html
<div class="shadow-md"></div>
<div class="shadow-xl hover:shadow-2xl"></div>
<div class="shadow-brutal"></div>
```

### Animations: `--animate-*`

**Generates utilities:** animate-{name}

**Definition:**

```css
@theme {
  --animate-spin: spin 1s linear infinite;
  --animate-ping: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;
  --animate-pulse: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  --animate-bounce: bounce 1s infinite;
  --animate-fade-in: fade-in 0.3s ease-out;

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  @keyframes ping {
    75%, 100% {
      transform: scale(2);
      opacity: 0;
    }
  }

  @keyframes pulse {
    50% {
      opacity: 0.5;
    }
  }

  @keyframes bounce {
    0%, 100% {
      transform: translateY(-25%);
      animation-timing-function: cubic-bezier(0.8, 0, 1, 1);
    }
    50% {
      transform: none;
      animation-timing-function: cubic-bezier(0, 0, 0.2, 1);
    }
  }

  @keyframes fade-in {
    0% {
      opacity: 0;
    }
    100% {
      opacity: 1;
    }
  }
}
```

**Usage:**

```html
<div class="animate-spin"></div>
<div class="animate-pulse"></div>
<div class="animate-fade-in"></div>
```

### Z-Index: `--z-*`

**Generates utilities:** z-{index}

**Definition:**

```css
@theme {
  --z-0: 0;
  --z-10: 10;
  --z-20: 20;
  --z-30: 30;
  --z-40: 40;
  --z-50: 50;
  --z-modal: 100;
  --z-dropdown: 200;
  --z-tooltip: 300;
}
```

**Usage:**

```html
<div class="z-10"></div>
<div class="z-modal"></div>
<div class="z-tooltip"></div>
```

### Aspect Ratio: `--aspect-*`

**Generates utilities:** aspect-{ratio}

**Definition:**

```css
@theme {
  --aspect-auto: auto;
  --aspect-square: 1 / 1;
  --aspect-video: 16 / 9;
  --aspect-portrait: 3 / 4;
  --aspect-ultrawide: 21 / 9;
}
```

**Usage:**

```html
<img class="aspect-square" />
<video class="aspect-video" />
<div class="aspect-portrait"></div>
```

## Complete Example

```css
@import 'tailwindcss';

@theme {
  --font-sans: 'Inter', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  --font-display: 'Satoshi', sans-serif;

  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;

  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  --tracking-tight: -0.025em;
  --tracking-normal: 0em;
  --tracking-wide: 0.025em;

  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  --color-white: #ffffff;
  --color-black: #000000;
  --color-gray-50: oklch(0.99 0 0);
  --color-gray-900: oklch(0.21 0 0);

  --color-primary: oklch(0.65 0.25 270);
  --color-secondary: oklch(0.75 0.22 320);
  --color-success: oklch(0.72 0.15 142);
  --color-error: oklch(0.65 0.22 25);

  --spacing: 0.25rem;
  --spacing-1: calc(var(--spacing) * 1);
  --spacing-2: calc(var(--spacing) * 2);
  --spacing-4: calc(var(--spacing) * 4);
  --spacing-8: calc(var(--spacing) * 8);

  --radius-sm: 0.125rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-full: 9999px;

  --shadow-sm: 0 1px 3px 0 rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);

  --breakpoint-sm: 40rem;
  --breakpoint-md: 48rem;
  --breakpoint-lg: 64rem;
  --breakpoint-xl: 80rem;

  --animate-spin: spin 1s linear infinite;

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }
}
```

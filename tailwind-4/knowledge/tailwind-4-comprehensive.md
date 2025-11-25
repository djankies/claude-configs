# Tailwind CSS v4 Research

## Overview

- **Version**: 4.1 (Stable release: January 22, 2025)
- **Purpose in Project**: Utility-first CSS framework for rapid UI development
- **Official Documentation**: https://tailwindcss.com/
- **Last Updated**: November 19, 2025

## Installation

### Vite Projects (Recommended)

**Step 1: Install Dependencies**

```bash
npm install tailwindcss @tailwindcss/vite
```

**Step 2: Configure Vite**

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

**Step 3: Add Tailwind to CSS**

```css
@import 'tailwindcss';
```

### PostCSS Projects

**Step 1: Install Dependencies**

```bash
npm install tailwindcss @tailwindcss/postcss
```

**Step 2: Configure PostCSS**

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

**Step 3: Add Tailwind to CSS**

```css
@import 'tailwindcss';
```

### CLI Usage

**Step 1: Install CLI**

```bash
npm install tailwindcss @tailwindcss/cli
```

**Step 2: Create CSS File**

```css
@import 'tailwindcss';
```

**Step 3: Build Command**

```bash
npx @tailwindcss/cli -i input.css -o output.css --watch
```

## Core Concepts

### CSS-First Configuration

Tailwind v4 completely removes the JavaScript configuration file (tailwind.config.js) in favor of CSS-based configuration using the `@theme` directive. All customization happens directly in CSS.

### Automatic Content Detection

Template files are discovered automatically using built-in heuristics. No content array configuration is required. Files in .gitignore are automatically excluded.

### Modern CSS Foundation

Built on cutting-edge CSS features:

- Native cascade layers
- Registered custom properties with @property
- color-mix() for dynamic color operations
- OkLCh color space for wider gamut

### Performance Architecture

- Full builds: 3.78x faster than v3 (378ms → 100ms)
- Incremental rebuilds with new CSS: 8.8x faster (44ms → 5ms)
- Incremental rebuilds without new CSS: 182x faster (35ms → 192µs)

## Configuration

### Theme Variables with @theme

Define custom design tokens:

```css
@import 'tailwindcss';

@theme {
  --font-display: 'Satoshi', 'sans-serif';
  --font-body: 'Inter', 'sans-serif';

  --color-brand-primary: oklch(0.65 0.25 270);
  --color-brand-accent: oklch(0.75 0.22 320);

  --breakpoint-3xl: 120rem;
  --breakpoint-4xl: 160rem;

  --spacing-18: 4.5rem;
  --spacing-72: 18rem;

  --radius-4xl: 2rem;

  --shadow-brutal: 8px 8px 0 0 rgb(0 0 0);
}
```

### Theme Variable Namespaces

| Namespace         | Utilities Generated                        |
| ----------------- | ------------------------------------------ |
| `--color-*`       | bg-, text-, fill-, stroke-, border-, ring- |
| `--font-*`        | font-family utilities                      |
| `--text-*`        | font-size utilities                        |
| `--font-weight-*` | font-weight utilities                      |
| `--tracking-*`    | letter-spacing utilities                   |
| `--leading-*`     | line-height utilities                      |
| `--breakpoint-*`  | responsive breakpoint variants             |
| `--spacing-*`     | padding, margin, sizing utilities          |
| `--radius-*`      | border-radius utilities                    |
| `--shadow-*`      | box-shadow utilities                       |
| `--animate-*`     | animation utilities                        |

### Extending Default Theme

Add new values without removing defaults:

```css
@theme {
  --color-lagoon: oklch(0.72 0.11 221.19);
  --color-coral: oklch(0.74 0.17 40.24);
  --font-script: 'Great Vibes', cursive;
}
```

### Complete Theme Replacement

Remove all defaults and define only custom variables:

```css
@theme {
  --*: initial;

  --spacing: 4px;
  --font-body: 'Inter', sans-serif;
  --color-lagoon: oklch(0.72 0.11 221.19);
  --color-coral: oklch(0.74 0.17 40.24);
}
```

### Animation Keyframes

Define animations within @theme:

```css
@theme {
  --animate-fade-in-scale: fade-in-scale 0.3s ease-out;

  @keyframes fade-in-scale {
    0% {
      opacity: 0;
      transform: scale(0.95);
    }
    100% {
      opacity: 1;
      transform: scale(1);
    }
  }
}
```

### Inline Theme Variables

Reference other variables using the inline option:

```css
@theme inline {
  --font-sans: var(--font-inter);
  --color-primary: var(--color-red-500);
}
```

### Static Theme Variables

Generate all CSS variables even if unused:

```css
@theme static {
  --color-primary: var(--color-red-500);
  --color-secondary: var(--color-blue-500);
}
```

## Usage Patterns

### Basic Utility Classes

```html
<div class="flex items-center justify-between p-4 bg-white rounded-lg shadow-md">
  <h2 class="text-2xl font-bold text-gray-900">Title</h2>
  <button class="px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700">Click Me</button>
</div>
```

### Responsive Design

```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
  <div class="p-4 bg-white">Card 1</div>
  <div class="p-4 bg-white">Card 2</div>
  <div class="p-4 bg-white">Card 3</div>
</div>
```

### Dark Mode

```html
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  <h1 class="text-xl dark:text-2xl">Responsive Dark Text</h1>
  <a href="#" class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300">
    Link with dark mode hover
  </a>
</div>
```

### State Variants

```html
<input
  type="text"
  class="
    border border-gray-300
    focus:border-sky-500 focus:outline focus:outline-sky-500
    invalid:border-pink-500 invalid:text-pink-600
    focus:invalid:border-pink-500 focus:invalid:outline-pink-500
    disabled:border-gray-200 disabled:bg-gray-50 disabled:text-gray-500
    dark:disabled:border-gray-700 dark:disabled:bg-gray-800/20
  " />
```

### Variant Stacking

Variants can be stacked (responsive → dark → state):

```html
<button class="bg-blue-500 lg:dark:hover:bg-blue-700">Multi-variant button</button>
```

### Arbitrary Values

Use square brackets for one-off values:

```html
<div class="top-[117px] lg:top-[344px]">
  <div class="bg-[#bada55] text-[22px]">Custom values</div>
  <div class="grid-cols-[1fr_500px_2fr]">Grid with spaces (underscores)</div>
  <div class="before:content-['Festivus']">Custom content</div>
</div>
```

### Container Queries

Built-in container queries without plugin:

```html
<div class="@container">
  <div class="grid grid-cols-1 @sm:grid-cols-2 @lg:grid-cols-4 gap-4">
    <div>Card 1</div>
    <div>Card 2</div>
    <div>Card 3</div>
    <div>Card 4</div>
  </div>
</div>
```

Named containers:

```html
<div class="@container/main">
  <div class="flex flex-row @sm/main:flex-col">Content adapts to main container</div>
</div>
```

### 3D Transforms

Native 3D transform support:

```html
<div class="transform-3d">
  <img class="rotate-x-50 rotate-y-30 translate-z-12" />
  <img class="rotate-x-45 rotate-z-45 -translate-z-8" />
</div>
```

### Gradients

**Linear Gradients:**

```html
<div class="h-14 bg-linear-to-r from-cyan-500 to-blue-500"></div>
<div class="h-14 bg-linear-to-t from-sky-500 to-indigo-500"></div>
<div class="h-14 bg-linear-to-bl from-violet-500 to-fuchsia-500"></div>
```

**Radial Gradients:**

```html
<div class="bg-radial from-yellow-400 to-orange-500"></div>
<div class="bg-radial-[at_50%_75%] from-sky-200 via-blue-400 to-indigo-900 to-90%"></div>
```

**Conic Gradients:**

```html
<div class="bg-conic from-blue-600 to-sky-400 to-50%"></div>
<div class="bg-conic-180 from-indigo-600 via-indigo-50 to-indigo-600"></div>
```

**Custom Interpolation:**

```html
<div class="bg-linear-to-r/oklch from-indigo-500 to-teal-400"></div>
<div class="bg-linear-to-r/hsl from-red-500 to-blue-500"></div>
```

### Entry Animations with starting:

```html
<div class="opacity-100 transition-opacity duration-300 starting:opacity-0">Fades in smoothly</div>

<div
  class="translate-y-0 opacity-100 transition-all duration-300 starting:translate-y-4 starting:opacity-0">
  Slides up while fading in
</div>
```

## Advanced Patterns

### Custom Utilities with @utility

**Static Utility:**

```css
@utility content-auto {
  content-visibility: auto;
}
```

**Functional Utility with Integer Values:**

```css
@utility mt-* {
  margin-top: calc(0.25rem * --value(integer));
}
```

**Theme-Based Utility:**

```css
@theme {
  --tab-size-2: 2;
  --tab-size-github: 8;
}

@utility tab-* {
  tab-size: --value(--tab-size- *);
}
```

**Multi-Value Utility:**

```css
@utility text-stroke-* {
  -webkit-text-stroke-width: --value(integer) px;
  -webkit-text-stroke-color: --value(--color- *);
}
```

**Arbitrary Values Support:**

```css
@utility tab-* {
  tab-size: --value(integer);
  tab-size: --value([integer]);
}
```

### Component Classes with @layer

```css
@layer components {
  .card {
    background-color: var(--color-white);
    border-radius: var(--radius-lg);
    padding: var(--spacing-6);
    box-shadow: var(--shadow-xl);
  }

  .btn-primary {
    padding: var(--spacing-2) var(--spacing-4);
    background-color: var(--color-blue-600);
    color: var(--color-white);
    border-radius: var(--radius-md);
  }
}
```

### Custom Variants

```css
@custom-variant theme-midnight {
  &:where([data-theme='midnight'] *) {
    @slot;
  }
}
```

Usage:

```html
<button class="theme-midnight:bg-black">Themed button</button>
```

### Using @variant in Custom CSS

```css
.my-element {
  background: white;

  @variant dark {
    background: black;
  }

  @variant hover {
    background: gray;
  }
}
```

### Base Styles

```css
@layer base {
  h1 {
    font-size: var(--text-2xl);
    font-weight: var(--font-weight-bold);
    line-height: var(--leading-tight);
  }

  h2 {
    font-size: var(--text-xl);
    font-weight: var(--font-weight-semibold);
  }

  a {
    color: var(--color-blue-600);
    text-decoration: underline;
  }
}
```

### Content Detection with @source

Explicitly add source files not auto-detected:

```css
@import 'tailwindcss';
@source "../node_modules/@my-company/ui-lib";
@source "./legacy-components";
```

Exclude paths (v4.1+):

```css
@source not "./legacy";
```

Safelist utilities (v4.1+):

```css
@source inline(flex items-center justify-between);
```

Disable automatic detection:

```css
@import 'tailwindcss' source(none);
@source "./src";
```

### Sharing Themes Across Projects

**Create theme file:**

```css
@theme {
  --*: initial;
  --spacing: 4px;
  --font-body: 'Inter', sans-serif;
  --color-lagoon: oklch(0.72 0.11 221.19);
  --color-coral: oklch(0.74 0.17 40.24);
}
```

**Import in projects:**

```css
@import 'tailwindcss';
@import '../brand/theme.css';
```

### Accessing Theme Variables in JavaScript

```javascript
let styles = getComputedStyle(document.documentElement);
let shadow = styles.getPropertyValue('--shadow-xl');
let color = styles.getPropertyValue('--color-blue-500');
```

In animation libraries:

```jsx
<motion.div animate={{ backgroundColor: 'var(--color-blue-500)' }} />
```

## Best Practices

### 1. Use Component-Based Architecture

Tailwind works best with component frameworks (React, Vue, Svelte). Avoid using it in plain HTML projects where duplication becomes problematic.

### 2. Define Semantic Design Tokens

Create meaningful theme variables instead of using arbitrary values:

```css
@theme {
  --color-primary: oklch(0.65 0.25 270);
  --color-secondary: oklch(0.75 0.22 320);
  --color-success: oklch(0.72 0.15 142);
  --color-warning: oklch(0.78 0.18 60);
  --color-error: oklch(0.65 0.22 25);
}
```

### 3. Replace Default Color Palette

Don't rely on the default expansive color palette. Define only the colors you need:

```css
@theme {
  --*: initial;

  --color-white: #ffffff;
  --color-black: #000000;
  --color-primary: oklch(0.65 0.25 270);
  --color-accent: oklch(0.75 0.22 320);
}
```

### 4. Use @utility for Custom Utilities

Don't use @layer utilities for custom classes. Use @utility for proper variant support:

```css
@utility my-button {
  padding: var(--spacing-2) var(--spacing-4);
  background: var(--color-blue-600);
  border-radius: var(--radius-md);
}
```

### 5. Organize Classes Systematically

Group related utility classes together:

```html
<div
  class="
  flex items-center justify-between
  p-4 m-2
  bg-white dark:bg-gray-900
  border border-gray-200 rounded-lg
  shadow-md hover:shadow-lg
"></div>
```

### 6. Leverage Automatic Content Detection

Let Tailwind auto-detect your template files. Only use @source for edge cases:

```css
@import 'tailwindcss';
@source "../node_modules/@my-company/ui-lib";
```

### 7. Use Container Queries for Component Portability

Prefer container queries over viewport media queries for reusable components:

```html
<div class="@container">
  <div class="grid grid-cols-1 @md:grid-cols-2 @lg:grid-cols-3"></div>
</div>
```

### 8. Minimize Arbitrary Values

Use arbitrary values sparingly. When used repeatedly, define theme variables:

```css
@theme {
  --spacing-117: 29.25rem;
}
```

Then use: `top-117` instead of `top-[117px]`

### 9. Optimize Production Builds

Ensure .gitignore excludes node_modules to prevent scanning Tailwind's own files.

### 10. Use CSS Variables for Runtime Theming

Access theme variables in JavaScript for dynamic theming:

```javascript
document.documentElement.style.setProperty('--color-primary', 'oklch(0.70 0.20 180)');
```

## Common Gotchas

### 1. Browser Support Requirements

Tailwind v4 requires:

- Safari 16.4+
- Chrome 111+
- Firefox 128+

Projects requiring older browser support must stay on v3.4.

### 2. @apply Restrictions in v4

@apply only works for a small subset of utilities in v4. Use @utility for custom classes instead:

```css
@utility btn {
  padding: var(--spacing-2) var(--spacing-4);
  background: var(--color-blue-600);
}
```

### 3. CSS Variable Performance

Re-assigning CSS variables or defining them on multiple elements can cause performance issues. Define variables at :root level when possible.

### 4. Default Color Changes

Border and ring utilities now default to `currentColor` instead of gray:

```html
<div class="border">Uses current text color</div>
<div class="border border-gray-200">Explicit gray border</div>
```

### 5. Mobile Hover Behavior

Hover styles only apply on devices supporting hover. Touch devices no longer trigger hover states by default.

### 6. Shadow/Blur Naming Changes

- `shadow-sm` → `shadow-xs`
- Default `ring` changed from 3px to 1px (use `ring-3` for old behavior)

### 7. Opacity Modifier Changes

Old opacity utilities removed:

- `bg-opacity-50` → `bg-black/50`
- `text-opacity-75` → `text-gray-900/75`

### 8. Flex/Grow Utility Renames

- `flex-shrink-*` → `shrink-*`
- `flex-grow-*` → `grow-*`

### 9. Preflight Style Changes

- Placeholder text now uses current text color at 50% opacity (not gray-400)
- Buttons use `cursor: default` instead of `cursor: pointer`

### 10. No CSS Preprocessor Support

Tailwind v4 is incompatible with Sass, Less, or Stylus. It functions as the preprocessing layer.

### 11. Grid/Object Utilities Space Handling

Commas no longer replaced with spaces. Use underscores:

- `grid-cols-[1fr_500px_2fr]` (correct)
- `grid-cols-[1fr 500px 2fr]` (incorrect in arbitrary values)

### 12. Import Syntax Changes

Replace `@tailwind` directives with CSS imports:

```css
@import 'tailwindcss';
```

### 13. PostCSS Plugin Changes

Use `@tailwindcss/postcss` instead of `tailwindcss`:

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

### 14. Cannot Apply Unknown Utility Errors

Some valid utilities may throw errors with @apply. Solution: Use @utility to register them first.

### 15. Color Space Migration

V4 uses OkLCh instead of RGB. Custom colors should use oklch():

```css
--color-brand: oklch(0.65 0.25 270);
```

## Anti-Patterns

### 1. Overusing @apply

Creating custom classes with @apply defeats the utility-first philosophy:

```css
.my-button {
  @apply px-4 py-2 bg-blue-500 text-white rounded;
}
```

This increases CSS build size and reduces flexibility. Use utility classes directly in HTML.

### 2. Using Tailwind Without Components

Don't use Tailwind in plain HTML projects. It creates massive duplication:

```html
<button class="px-4 py-2 bg-blue-500...">Button 1</button>
<button class="px-4 py-2 bg-blue-500...">Button 2</button>
<button class="px-4 py-2 bg-blue-500...">Button 3</button>
```

Use component frameworks instead:

```jsx
<Button>Button 1</Button>
<Button>Button 2</Button>
<Button>Button 3</Button>
```

### 3. Arbitrary Values with User Input

Never generate Tailwind classes dynamically from unsanitized user input:

```javascript
const className = `bg-[${userColor}]`;
```

This creates XSS vulnerabilities. Define allowed values in theme.

### 4. Magic Numbers Everywhere

Excessive arbitrary values make projects unmaintainable:

```html
<div class="top-[117px] left-[344px] w-[892px]"></div>
```

Define semantic theme variables instead.

### 5. Ignoring Semantic Color Names

Using numbered colors (blue-500, gray-700) instead of semantic names:

```css
@theme {
  --color-primary: var(--color-blue-500);
  --color-text: var(--color-gray-900);
  --color-text-muted: var(--color-gray-600);
}
```

### 6. rem Units for Everything (Accessibility Issue)

Tailwind's default theme uses rem for spacing, sizing, and media queries. This is an accessibility anti-pattern. Spacing and sizing should use px units; only font-size should use rem.

### 7. Creating Component Classes Incorrectly

Using @layer utilities without variants support:

```css
@layer utilities {
  .my-button {
    padding: 1rem;
  }
}
```

Won't work with `hover:my-button`. Use @utility instead:

```css
@utility my-button {
  padding: 1rem;
}
```

### 8. Mixing Tailwind with CSS Preprocessors

Attempting to use Sass/Less/Stylus with Tailwind v4 causes compatibility issues. Tailwind v4 is a complete build tool.

### 9. Not Using Automatic Content Detection

Manually configuring content paths when automatic detection works:

```css
@import 'tailwindcss' source(none);
@source "./src/**/*.{html,js}";
```

Let Tailwind auto-detect unless you have specific needs.

### 10. Inline Styles Instead of Utilities

Using style attributes instead of utility classes:

```html
<div style="display: flex; padding: 1rem;"></div>
```

Use utilities:

```html
<div class="flex p-4"></div>
```

## Error Handling

### Build Errors

**Module Parse Failed: Unexpected '@'**

```
Module parse failed: Unexpected character '@' (1:0)
```

**Solution:** Ensure PostCSS is configured correctly and using @tailwindcss/postcss.

**Cannot Apply Unknown Utility Class**

```
Cannot apply unknown utility class bg-gray-50
```

**Solution:** Register custom utilities with @utility before using @apply.

**Unexpected ")" CSS Syntax Error**

```
Unexpected ")" CSS syntax error
```

**Solution:** Check for malformed arbitrary values or theme variable syntax.

### Runtime Issues

**Styles Not Applying**
Check that:

1. CSS import is present: `@import "tailwindcss";`
2. Vite/PostCSS plugin is configured
3. Template files aren't in .gitignore
4. Class names are complete (not dynamically concatenated)

**Dark Mode Not Working**
Ensure dark mode is enabled via class or media strategy:

```html
<html class="dark"></html>
```

**Container Queries Not Working**
Verify parent has `@container` class:

```html
<div class="@container">
  <div class="@md:grid-cols-2"></div>
</div>
```

### Development Debugging

**Enable verbose logging:**

```bash
NODE_ENV=development npx @tailwindcss/cli -i input.css -o output.css --watch
```

**Check generated CSS:**
Inspect the output CSS file to verify utilities are being generated.

**Use browser DevTools:**
Install Tailwind CSS Devtools extension for Chrome/Firefox to visualize applied classes.

**Validate theme variables:**

```javascript
const styles = getComputedStyle(document.documentElement);
console.log(styles.getPropertyValue('--color-primary'));
```

## Security Considerations

### 1. Input Sanitization

Never use unsanitized user input in Tailwind classes, especially with arbitrary values:

```javascript
const userInput = req.body.color;
const className = `bg-[${userInput}]`;
```

This creates XSS vulnerabilities. Always validate and sanitize:

```javascript
const allowedColors = ['red', 'blue', 'green'];
const color = allowedColors.includes(userInput) ? userInput : 'gray';
const className = `bg-${color}-500`;
```

### 2. Server-Side Validation

Validate and encode user input on the server before sending to client:

```javascript
const sanitizedInput = DOMPurify.sanitize(userInput);
```

### 3. Content Security Policy (CSP)

Implement CSP headers to restrict script and style sources:

```html
<meta
  http-equiv="Content-Security-Policy"
  content="default-src 'self'; style-src 'self' 'unsafe-inline';" />
```

### 4. Avoid Dynamic Class Generation from User Input

Don't generate Tailwind classes dynamically based on user input:

```javascript
const userClass = `text-[${userInput}]`;
```

Instead, map user input to predefined classes:

```javascript
const sizeMap = {
  small: 'text-sm',
  medium: 'text-base',
  large: 'text-lg',
};
const className = sizeMap[userInput] || 'text-base';
```

### 5. Limit Arbitrary Value Usage

Minimize arbitrary values to reduce attack surface. Prefer theme variables:

```css
@theme {
  --color-safe-primary: oklch(0.65 0.25 270);
}
```

### 6. Dependency Security

Regularly audit dependencies:

```bash
npm audit
```

Tailwind CSS itself has no known vulnerabilities in Snyk's database.

### 7. Build-Time Safety

Ensure production builds don't include development-only features:

```bash
NODE_ENV=production npm run build
```

### 8. CORS and Asset Loading

When loading theme files from external sources, validate CORS headers:

```css
@import url('https://trusted-domain.com/theme.css');
```

## Performance Tips

### 1. Use Vite Plugin for Best Performance

The dedicated Vite plugin is faster than PostCSS:

```javascript
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss()],
});
```

### 2. Optimize Content Detection

Exclude unnecessary directories:

```css
@source not "./docs";
@source not "./legacy";
```

### 3. Minimize Arbitrary Values

Arbitrary values increase build time. Use theme variables:

```css
@theme {
  --spacing-custom: 29.25rem;
}
```

### 4. Leverage Automatic Purging

V4 automatically purges unused styles. Ensure .gitignore excludes node_modules.

### 5. Use CSS Variables for Runtime Changes

Avoid regenerating CSS for theme changes. Use CSS variables:

```javascript
document.documentElement.style.setProperty('--color-primary', newColor);
```

### 6. Enable Production Builds

Always build with NODE_ENV=production:

```bash
NODE_ENV=production npm run build
```

### 7. Avoid Deep Nesting

Deeply nested HTML increases selector complexity:

```html
<div class="flex">
  <div class="grid">
    <div class="flex"></div>
  </div>
</div>
```

Flatten when possible.

### 8. Use Transform-3D Sparingly

3D transforms are GPU-intensive. Use only when necessary:

```html
<div class="transform-3d">
  <img class="rotate-x-45 translate-z-12" />
</div>
```

### 9. Optimize Gradients

Complex gradients impact rendering performance. Simplify when possible:

```html
<div class="bg-linear-to-r from-blue-500 to-blue-600"></div>
```

### 10. Monitor Build Times

Track build performance:

```bash
time npm run build
```

V4 provides significant speed improvements:

- Full builds: 3.78x faster
- Incremental: up to 182x faster

## Version-Specific Notes

### Breaking Changes from v3 to v4

**Configuration Migration:**

- JavaScript config → CSS-first configuration
- `@tailwind` directives → `@import "tailwindcss"`
- Manual content paths → Automatic detection

**Utility Changes:**

- Opacity modifiers removed (`bg-opacity-*` → `bg-black/50`)
- Flex utilities renamed (`flex-grow-*` → `grow-*`)
- Shadow utilities renamed (`shadow-sm` → `shadow-xs`)
- Default ring changed from 3px to 1px

**Color System:**

- RGB → OkLCh color space
- Wider gamut support
- More vivid colors on modern displays

**Browser Support:**

- Dropped support for older browsers
- Requires Safari 16.4+, Chrome 111+, Firefox 128+

**PostCSS Changes:**

- New plugin: `@tailwindcss/postcss`
- No longer need `postcss-import` or `autoprefixer`

**Feature Additions:**

- Container queries built-in (no plugin)
- 3D transforms native support
- `@starting-style` for entry animations
- Enhanced gradient utilities
- `not-*` variant for negation

### Migration Tool

Automated upgrade tool available:

```bash
npx @tailwindcss/upgrade@next
```

**Requirements:**

- Node.js 20 or higher
- Run in a new git branch
- Review all changes manually
- Test thoroughly

**What it handles:**

- Updates dependencies
- Migrates configuration to CSS
- Updates template files
- Converts utility class names

### v4.1 New Features (Latest)

**Text Shadows:**

```html
<h1 class="text-shadow-sm">Subtle shadow</h1>
<h1 class="text-shadow-lg">Large shadow</h1>
```

**Masks:**

```html
<div class="mask-linear-to-b from-black to-transparent">Masked content</div>
```

**@source Enhancements:**

- `@source not` for exclusions
- `@source inline()` for safelisting

**Performance Improvements:**

- Further build speed optimizations
- Improved content detection algorithms

### Compatibility Notes

**Vue/Svelte/CSS Modules:**
Use @reference for scoped stylesheets:

```css
@reference "../../app.css";

.component {
  color: var(--color-primary);
}
```

**Next.js:**
Compatible with Next.js 15+ using PostCSS mode:

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

**Angular:**
Use PostCSS plugin in angular.json configuration.

**Workspace/Monorepos:**
Use @source to include packages:

```css
@import 'tailwindcss';
@source "../packages/ui";
@source "../packages/shared";
```

## Code Examples

### Complete Vite + React Setup

**1. Install dependencies:**

```bash
npm create vite@latest my-app -- --template react
cd my-app
npm install tailwindcss @tailwindcss/vite
```

**2. vite.config.js:**

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

**3. src/index.css:**

```css
@import 'tailwindcss';

@theme {
  --color-brand: oklch(0.65 0.25 270);
  --font-sans: 'Inter', sans-serif;
}
```

**4. src/App.jsx:**

```jsx
export default function App() {
  return (
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-white">Tailwind CSS v4</h1>
        <button class="px-4 py-2 mt-4 text-white bg-brand rounded-lg hover:opacity-90">
          Click Me
        </button>
      </div>
    </div>
  );
}
```

### Advanced Theme Configuration

```css
@import 'tailwindcss';

@theme {
  --*: initial;

  --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;

  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;

  --color-white: #ffffff;
  --color-black: #000000;

  --color-gray-50: oklch(0.99 0 0);
  --color-gray-100: oklch(0.97 0 0);
  --color-gray-200: oklch(0.93 0 0);
  --color-gray-300: oklch(0.88 0 0);
  --color-gray-400: oklch(0.74 0 0);
  --color-gray-500: oklch(0.62 0 0);
  --color-gray-600: oklch(0.51 0 0);
  --color-gray-700: oklch(0.42 0 0);
  --color-gray-800: oklch(0.31 0 0);
  --color-gray-900: oklch(0.21 0 0);

  --color-primary: oklch(0.65 0.25 270);
  --color-secondary: oklch(0.75 0.22 320);
  --color-success: oklch(0.72 0.15 142);
  --color-warning: oklch(0.78 0.18 60);
  --color-error: oklch(0.65 0.22 25);

  --spacing: 0.25rem;
  --spacing-px: 1px;
  --spacing-0: 0;
  --spacing-1: calc(var(--spacing) * 1);
  --spacing-2: calc(var(--spacing) * 2);
  --spacing-3: calc(var(--spacing) * 3);
  --spacing-4: calc(var(--spacing) * 4);
  --spacing-6: calc(var(--spacing) * 6);
  --spacing-8: calc(var(--spacing) * 8);
  --spacing-12: calc(var(--spacing) * 12);
  --spacing-16: calc(var(--spacing) * 16);
  --spacing-24: calc(var(--spacing) * 24);
  --spacing-32: calc(var(--spacing) * 32);

  --radius-none: 0;
  --radius-sm: 0.125rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-2xl: 1rem;
  --radius-full: 9999px;

  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);

  --breakpoint-sm: 40rem;
  --breakpoint-md: 48rem;
  --breakpoint-lg: 64rem;
  --breakpoint-xl: 80rem;
  --breakpoint-2xl: 96rem;

  --animate-spin: spin 1s linear infinite;
  --animate-ping: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;
  --animate-pulse: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  @keyframes ping {
    75%,
    100% {
      transform: scale(2);
      opacity: 0;
    }
  }

  @keyframes pulse {
    50% {
      opacity: 0.5;
    }
  }
}
```

### Complex Component Example

```html
<div class="@container relative overflow-hidden">
  <div
    class="
    grid grid-cols-1 @sm:grid-cols-2 @lg:grid-cols-3 @xl:grid-cols-4
    gap-4 @md:gap-6 @lg:gap-8
    p-4 @md:p-6 @lg:p-8
  ">
    <article
      class="
      group
      relative
      bg-white dark:bg-gray-800
      rounded-lg @md:rounded-xl
      shadow-md hover:shadow-xl
      transition-all duration-300
      transform hover:-translate-y-1
      border border-gray-200 dark:border-gray-700
      overflow-hidden
    ">
      <div class="relative h-48 bg-gradient-to-br from-blue-500 to-purple-600 overflow-hidden">
        <img
          src="/image.jpg"
          class="
            w-full h-full object-cover
            transform group-hover:scale-110
            transition-transform duration-500
          " />
        <div
          class="
          absolute inset-0
          bg-linear-to-t from-black/60 to-transparent
          opacity-0 group-hover:opacity-100
          transition-opacity duration-300
        "></div>
      </div>

      <div class="p-4 @md:p-6">
        <h3
          class="
          text-lg @md:text-xl @lg:text-2xl
          font-bold
          text-gray-900 dark:text-white
          group-hover:text-blue-600 dark:group-hover:text-blue-400
          transition-colors duration-200
        ">
          Card Title
        </h3>

        <p
          class="
          mt-2
          text-sm @md:text-base
          text-gray-600 dark:text-gray-300
          line-clamp-3
        ">
          This is a card description that demonstrates advanced Tailwind v4 features.
        </p>

        <div class="mt-4 flex items-center justify-between">
          <span
            class="
            text-xs @md:text-sm
            text-gray-500 dark:text-gray-400
            font-medium
          ">
            2 days ago
          </span>

          <button
            class="
            px-3 @md:px-4
            py-1.5 @md:py-2
            text-sm @md:text-base
            text-white
            bg-blue-600 hover:bg-blue-700
            dark:bg-blue-500 dark:hover:bg-blue-600
            rounded-md @md:rounded-lg
            transform active:scale-95
            transition-all duration-150
            focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-blue-500
          ">
            Read More
          </button>
        </div>
      </div>
    </article>
  </div>
</div>
```

### Custom Utility Library

```css
@import 'tailwindcss';

@utility content-auto {
  content-visibility: auto;
}

@utility content-hidden {
  content-visibility: hidden;
}

@utility aspect-* {
  aspect-ratio: --value(--aspect- *);
  aspect-ratio: --value([number]);
}

@utility truncate-* {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: --value(integer);
  overflow: hidden;
}

@utility text-balance {
  text-wrap: balance;
}

@utility text-pretty {
  text-wrap: pretty;
}

@utility bg-glass {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

@theme {
  --aspect-square: 1 / 1;
  --aspect-video: 16 / 9;
  --aspect-portrait: 3 / 4;
}
```

## References

### Official Resources

- Main Documentation: https://tailwindcss.com/
- v4.0 Release Blog: https://tailwindcss.com/blog/tailwindcss-v4
- v4.1 Release Blog: https://tailwindcss.com/blog/tailwindcss-v4-1
- Upgrade Guide: https://tailwindcss.com/docs/upgrade-guide
- GitHub Repository: https://github.com/tailwindlabs/tailwindcss

### API Documentation

- Theme Variables: https://tailwindcss.com/docs/theme
- Functions and Directives: https://tailwindcss.com/docs/functions-and-directives
- Adding Custom Styles: https://tailwindcss.com/docs/adding-custom-styles
- Installation Guide: https://tailwindcss.com/docs/installation/using-postcss

### Community Resources

- Tailwind CSS Discord: https://discord.gg/tailwindcss
- Frontend Masters Course: https://frontendmasters.com/courses/tailwind-css-v2/
- Steve Kinney's Tailwind Course: https://stevekinney.com/courses/tailwind

### Tools & Extensions

- Tailwind CSS IntelliSense (VS Code): Official extension for autocomplete
- Tailwind CSS DevTools: Browser extension for debugging
- Prettier Plugin: https://github.com/tailwindlabs/prettier-plugin-tailwindcss

### Related Packages

- @tailwindcss/vite: First-party Vite plugin
- @tailwindcss/postcss: PostCSS plugin for v4
- @tailwindcss/cli: Standalone CLI tool
- @tailwindcss/upgrade: Automated migration tool

### Articles & Guides

- Tailwind v4 Multi-Theme Strategy: https://simonswiss.com/posts/tailwind-v4-multi-theme
- Security Risks of Arbitrary Values: https://dansasser.me/posts/navigating-the-security-risks-of-arbitrary-values-in-tailwind-css/
- Enterprise Best Practices: https://medium.com/@sureshdotariya/tailwind-css-4-best-practices-for-enterprise-scale-projects-2025-playbook-bf2910402581

### Browser Support

- Can I Use - CSS Container Queries: https://caniuse.com/css-container-queries
- Can I Use - @property: https://caniuse.com/mdn-css_at-rules_property
- Can I Use - color-mix(): https://caniuse.com/mdn-css_types_color_color-mix

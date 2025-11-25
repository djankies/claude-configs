# Browser Testing Patterns Reference

## Component Testing

### React Components

**Installation:**
```bash
npm install -D vitest-browser-react @testing-library/react
```

**Setup:**
```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
    },
  },
});
```

**Test:**
```typescript
import { test, expect } from 'vitest';
import { render } from 'vitest-browser-react';
import { LoginForm } from './LoginForm';

test('submits form', async () => {
  const handleSubmit = vi.fn();
  const screen = render(<LoginForm onSubmit={handleSubmit} />);

  await screen.getByLabelText(/email/i).fill('user@example.com');
  await screen.getByLabelText(/password/i).fill('password123');
  await screen.getByRole('button', { name: /submit/i }).click();

  expect(handleSubmit).toHaveBeenCalledWith({
    email: 'user@example.com',
    password: 'password123',
  });
});
```

### Vue Components

**Installation:**
```bash
npm install -D vitest-browser-vue @testing-library/vue
```

**Setup:**
```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
    },
  },
});
```

**Test:**
```typescript
import { test, expect } from 'vitest';
import { render } from 'vitest-browser-vue';
import Component from './Component.vue';

test('component renders', async () => {
  const screen = render(Component, {
    props: { name: 'Alice' },
  });

  await expect.element(screen.getByText('Hi, my name is Alice')).toBeInTheDocument();

  const input = screen.getByLabelText(/username/i);
  await input.fill('Bob');

  await expect.element(screen.getByText('Hi, my name is Bob')).toBeInTheDocument();
});
```

## Common Testing Patterns

### Form Testing

```typescript
test('form submission', async () => {
  const form = page.getByRole('form');
  const emailInput = form.getByLabelText(/email/i);
  const passwordInput = form.getByLabelText(/password/i);
  const submitButton = form.getByRole('button', { name: /submit/i });

  await userEvent.fill(emailInput, 'user@example.com');
  await userEvent.fill(passwordInput, 'password123');
  await userEvent.click(submitButton);

  const successMessage = page.getByText('Login successful');
  await expect.element(successMessage).toBeInTheDocument();
});
```

### Navigation Testing

```typescript
test('navigation', async () => {
  const link = page.getByRole('link', { name: /about/i });
  await userEvent.click(link);

  const heading = page.getByRole('heading', { name: /about us/i });
  await expect.element(heading).toBeInTheDocument();
});
```

### Modal Testing

```typescript
test('modal dialog', async () => {
  const openButton = page.getByRole('button', { name: /open/i });
  await userEvent.click(openButton);

  const dialog = page.getByRole('dialog');
  await expect.element(dialog).toBeVisible();

  const closeButton = dialog.getByRole('button', { name: /close/i });
  await userEvent.click(closeButton);

  await expect.element(dialog).not.toBeVisible();
});
```

### Dropdown Testing

```typescript
test('dropdown selection', async () => {
  const select = page.getByLabelText(/country/i);
  await userEvent.selectOptions(select, 'US');

  await expect.element(select).toHaveValue('US');
});
```

### Checkbox Testing

```typescript
test('checkbox toggle', async () => {
  const checkbox = page.getByRole('checkbox', { name: /accept terms/i });

  await userEvent.click(checkbox);
  await expect.element(checkbox).toBeChecked();

  await userEvent.click(checkbox);
  await expect.element(checkbox).not.toBeChecked();
});
```

### File Upload Testing

```typescript
test('file upload', async () => {
  const fileInput = page.getByLabelText(/upload file/i);

  const file = new File(['content'], 'test.txt', { type: 'text/plain' });
  await fileInput.setInputFiles(file);

  await expect.element(fileInput).toHaveValue('test.txt');
});
```

## Multi-Project Browser Testing

Combine browser and Node.js tests:

```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    projects: [
      {
        test: {
          name: 'unit',
          include: ['tests/unit/**/*.test.ts'],
          environment: 'node',
        },
      },
      {
        test: {
          name: 'browser',
          include: ['tests/browser/**/*.test.ts'],
          browser: {
            enabled: true,
            provider: playwright(),
            instances: [{ browser: 'chromium' }],
          },
        },
      },
    ],
  },
});
```

## Cross-Browser Testing

Test across multiple browsers:

```typescript
const browsers = ['chromium', 'firefox', 'webkit'];

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: browsers.map((browser) => ({ browser })),
    },
  },
});
```

## Visual Regression Testing

### Screenshot Assertions

```typescript
test('visual regression', async () => {
  await page.goto('http://localhost:3000');

  const main = page.getByRole('main');
  await expect(main).toMatchScreenshot();
});
```

### Screenshot Options

```typescript
await expect(element).toMatchScreenshot({
  threshold: 0.2,
  maxDiffPixels: 100,
});
```

### Viewport Assertions

```typescript
test('element in viewport', async () => {
  const banner = page.getByRole('banner');
  await expect.element(banner).toBeInViewport();
});
```

## Debugging

### Visual Debugging

Run in headed mode:

```bash
vitest --browser.headless=false
```

### Enable Traces

```bash
vitest --browser.trace on
```

View traces in Playwright Trace Viewer.

### Console Logs

Browser console logs appear in test output.

## Common Mistakes

1. **Using wrong import path**: Use `vitest/browser`, not `@vitest/browser/context`
2. **Missing provider package**: Install `@vitest/browser-playwright` or `@vitest/browser-webdriverio`
3. **Wrong browser instance config**: Use `instances: [{ browser: 'chromium' }]`, not `name: 'chromium'`
4. **Not awaiting interactions**: Always `await` user events
5. **Not using expect.element**: Use `expect.element()` for element assertions

## Performance Optimization

### Parallel Execution

```typescript
export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
      fileParallelism: true,
    },
  },
});
```

### Headless Mode

Always use headless in CI:

```typescript
export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
      headless: process.env.CI ? true : false,
    },
  },
});
```

## Mobile Testing

Test mobile viewports:

```typescript
export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [
        {
          browser: 'chromium',
          context: {
            viewport: { width: 375, height: 667 },
            isMobile: true,
            hasTouch: true,
          },
        },
      ],
    },
  },
});
```

## Authentication Testing

### Persistent Authentication

```typescript
instances: [
  {
    browser: 'chromium',
    context: {
      storageState: './auth.json',
    },
  },
]
```

### Login Flow

```typescript
test('login flow', async () => {
  await page.goto('/login');

  await page.getByLabelText(/email/i).fill('user@example.com');
  await page.getByLabelText(/password/i).fill('password123');
  await page.getByRole('button', { name: /login/i }).click();

  await expect.element(page.getByText(/welcome/i)).toBeInTheDocument();
});
```

## Accessibility Testing

### ARIA Roles

```typescript
test('accessibility', async () => {
  const nav = page.getByRole('navigation');
  await expect.element(nav).toBeInTheDocument();

  const links = nav.getByRole('link');
  const count = await links.count();
  expect(count).toBeGreaterThan(0);
});
```

### Keyboard Navigation

```typescript
test('keyboard navigation', async () => {
  const button = page.getByRole('button');
  await button.focus();

  await userEvent.keyboard('Enter');

  await expect.element(page.getByText('Clicked')).toBeInTheDocument();
});
```

# Browser APIs Reference

## Importing APIs

**Correct (Vitest 4.x):**
```typescript
import { page, userEvent } from 'vitest/browser';
```

**Incorrect (Vitest 3.x):**
```typescript
import { page, userEvent } from '@vitest/browser/context';
```

## Page Locators

### Basic Locators

```typescript
import { page } from 'vitest/browser';

page.getByRole(role, options)
page.getByLabelText(text)
page.getByPlaceholderText(text)
page.getByText(text)
page.getByDisplayValue(value)
page.getByAltText(text)
page.getByTitle(text)
page.getByTestId(testId)
```

### Locator Examples

```typescript
const button = page.getByRole('button', { name: /submit/i });
const input = page.getByLabelText(/username/i);
const heading = page.getByRole('heading');
const text = page.getByText('Welcome');
const link = page.getByRole('link', { name: /about/i });
const dialog = page.getByRole('dialog');
```

### Locator Methods

```typescript
const element = page.getByRole('button');

await element.click();
await element.fill('text');
await element.check();
await element.uncheck();
await element.focus();
await element.blur();
await element.hover();
```

## User Events

### Click Events

```typescript
import { userEvent } from 'vitest/browser';

await userEvent.click(element);
await userEvent.dblClick(element);
```

### Input Events

```typescript
await userEvent.fill(element, 'text');
await userEvent.clear(element);
await userEvent.type(element, 'text');
```

### Select Events

```typescript
await userEvent.selectOptions(element, 'option1');
await userEvent.selectOptions(element, ['option1', 'option2']);
```

### Hover Events

```typescript
await userEvent.hover(element);
await userEvent.unhover(element);
```

### Keyboard Events

```typescript
await userEvent.keyboard('Enter');
await userEvent.keyboard('{Shift>}A{/Shift}');
await userEvent.keyboard('{Control>}c{/Control}');
```

## Assertions

### Element Matchers

```typescript
import { expect } from 'vitest';
import { page } from 'vitest/browser';

const element = page.getByRole('button');

await expect.element(element).toBeInTheDocument();
await expect.element(element).toBeVisible();
await expect.element(element).toBeEnabled();
await expect.element(element).toBeDisabled();
await expect.element(element).toBeChecked();
await expect.element(element).toBeFocused();
await expect.element(element).toHaveTextContent('text');
await expect.element(element).toHaveValue('value');
await expect.element(element).toHaveAttribute('name', 'value');
await expect.element(element).toHaveClass('className');
```

### Negation

```typescript
await expect.element(element).not.toBeVisible();
await expect.element(element).not.toBeEnabled();
```

## Frame Locators

For testing iframes:

```typescript
const frame = page.frameLocator('iframe[title="preview"]');
const button = frame.getByRole('button');
await button.click();
```

## Waiting for Elements

### Implicit Waiting

Assertions automatically wait:

```typescript
await expect.element(page.getByText('Success')).toBeInTheDocument();
```

### Custom Waiting

```typescript
await page.waitForTimeout(1000);

const element = page.getByRole('alert');
await expect.element(element).toBeVisible();
```

## Screenshot Testing

### Screenshot Assertions

```typescript
const element = page.getByRole('main');
await expect(element).toMatchScreenshot();
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
const banner = page.getByRole('banner');
await expect.element(banner).toBeInViewport();
```

## Navigation

### Page Navigation

```typescript
await page.goto('http://localhost:3000');
await page.goto('/about');
```

### Browser Context

```typescript
const context = page.context();
await context.addCookies([
  {
    name: 'session',
    value: 'abc123',
    domain: 'localhost',
    path: '/',
  },
]);
```

## Advanced Patterns

### Multiple Elements

```typescript
const buttons = page.getByRole('button');
const count = await buttons.count();

for (let i = 0; i < count; i++) {
  await buttons.nth(i).click();
}
```

### Chaining Locators

```typescript
const form = page.getByRole('form');
const input = form.getByLabelText(/email/i);
await input.fill('user@example.com');
```

### Filtering

```typescript
const buttons = page.getByRole('button').filter({ hasText: 'Submit' });
await buttons.click();
```

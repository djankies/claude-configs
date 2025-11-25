# Provider Setup Reference

## Playwright Provider

### Installation

```bash
npm install -D vitest @vitest/browser-playwright
```

### Basic Configuration

```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
      headless: true,
    },
  },
});
```

### Multiple Browsers

```typescript
export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [
        { browser: 'chromium' },
        { browser: 'firefox' },
        { browser: 'webkit' },
      ],
    },
  },
});
```

### Browser-Specific Options

```typescript
instances: [
  {
    browser: 'chromium',
    launch: {
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    },
  },
  {
    browser: 'firefox',
    launch: {
      firefoxUserPrefs: {
        'media.navigator.streams.fake': true,
      },
    },
  },
]
```

## WebDriverIO Provider

### Installation

```bash
npm install -D vitest @vitest/browser-webdriverio
```

### Basic Configuration

```typescript
import { defineConfig } from 'vitest/config';
import { webdriverio } from '@vitest/browser-webdriverio';

export default defineConfig({
  test: {
    browser: {
      provider: webdriverio(),
      instances: [{ browser: 'chrome' }],
    },
  },
});
```

### Multiple Browsers

```typescript
export default defineConfig({
  test: {
    browser: {
      provider: webdriverio(),
      instances: [
        { browser: 'chrome' },
        { browser: 'firefox' },
        { browser: 'edge' },
      ],
    },
  },
});
```

## Preview Provider

### Installation

```bash
npm install -D vitest @vitest/browser-preview
```

### Basic Configuration

```typescript
import { defineConfig } from 'vitest/config';
import { preview } from '@vitest/browser-preview';

export default defineConfig({
  test: {
    browser: {
      provider: preview(),
      instances: [{ browser: 'chromium' }],
    },
  },
});
```

**Note:** Not recommended for CI environments.

## Headless vs Headed Mode

### Headless (Production/CI)

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  headless: true,
}
```

### Headed (Development/Debug)

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  headless: false,
}
```

### Conditional Mode

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  headless: process.env.CI ? true : false,
}
```

## Trace Configuration

### Enable Traces

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  trace: 'on',
}
```

### Trace Modes

- `off` - No traces
- `on` - Always generate traces
- `on-first-retry` - Generate on first retry
- `on-all-retries` - Generate on all retries
- `retain-on-failure` - Keep only failed test traces

### CI-Specific Traces

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  trace: process.env.CI ? 'retain-on-failure' : 'off',
}
```

## Screenshot Configuration

### On Failure

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  screenshot: 'only-on-failure',
}
```

### Screenshot Options

- `off` - No screenshots
- `on` - Always take screenshots
- `only-on-failure` - Only on test failure

## Viewport Configuration

### Default Viewport

```typescript
instances: [
  {
    browser: 'chromium',
    context: {
      viewport: { width: 1280, height: 720 },
    },
  },
]
```

### Mobile Viewport

```typescript
instances: [
  {
    browser: 'chromium',
    context: {
      viewport: { width: 375, height: 667 },
      isMobile: true,
      hasTouch: true,
    },
  },
]
```

## Context Configuration

### Authentication

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

### Permissions

```typescript
instances: [
  {
    browser: 'chromium',
    context: {
      permissions: ['clipboard-read', 'clipboard-write'],
    },
  },
]
```

### Geolocation

```typescript
instances: [
  {
    browser: 'chromium',
    context: {
      geolocation: { latitude: 37.7749, longitude: -122.4194 },
      permissions: ['geolocation'],
    },
  },
]
```

## Performance Options

### File Parallelism

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  fileParallelism: true,
}
```

### Isolate Tests

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  isolate: true,
}
```

## Running Browser Tests

### CLI Commands

```bash
vitest --browser.enabled
vitest --browser.name chromium
vitest --browser.headless
vitest --browser.headless=false
```

### Run Specific Project

```bash
vitest --project browser
```

### Debug Mode

```bash
vitest --browser.headless=false
```

## Migration from Vitest 3.x

### Old Config

**Before (Vitest 3.x):**
```typescript
export default defineConfig({
  test: {
    browser: {
      enabled: true,
      name: 'chromium',
      provider: 'playwright',
    },
  },
});
```

### New Config

**After (Vitest 4.x):**
```typescript
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
    },
  },
});
```

### Old Imports

**Before (Vitest 3.x):**
```typescript
import { page } from '@vitest/browser/context';
```

### New Imports

**After (Vitest 4.x):**
```typescript
import { page } from 'vitest/browser';
```

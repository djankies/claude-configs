# Browser Mode Configuration Reference

## Playwright Provider

Install provider package:

```bash
npm install -D @vitest/browser-playwright
```

Configure browser tests:

```typescript
import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

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
      headless: true,
    },
  },
});
```

## WebDriverIO Provider

Install provider package:

```bash
npm install -D @vitest/browser-webdriverio
```

Configure browser tests:

```typescript
import { webdriverio } from '@vitest/browser-webdriverio';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    browser: {
      provider: webdriverio(),
      instances: [
        { browser: 'chrome' },
        { browser: 'firefox' },
      ],
    },
  },
});
```

## Preview Provider

Install provider package:

```bash
npm install -D @vitest/browser-preview
```

Configure for local development:

```typescript
import { preview } from '@vitest/browser-preview';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    browser: {
      provider: preview(),
      instances: [{ browser: 'chromium' }],
    },
  },
});
```

**Note:** Preview provider is not recommended for CI environments.

## Browser Instance Configuration

### Single Browser

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
}
```

### Multiple Browsers

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [
    { browser: 'chromium' },
    { browser: 'firefox' },
    { browser: 'webkit' },
  ],
}
```

### Browser-Specific Options

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [
    {
      browser: 'chromium',
      launch: {
        args: ['--no-sandbox'],
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
  ],
}
```

## Headless vs Headed Mode

### Headless (CI/Production)

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

## Viewport Configuration

### Default Viewport

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [
    {
      browser: 'chromium',
      context: {
        viewport: { width: 1280, height: 720 },
      },
    },
  ],
}
```

### Mobile Viewport

```typescript
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
}
```

### Multiple Viewports

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [
    {
      browser: 'chromium',
      context: {
        viewport: { width: 1920, height: 1080 },
      },
    },
    {
      browser: 'chromium',
      context: {
        viewport: { width: 375, height: 667 },
      },
    },
  ],
}
```

## Custom HTML Template

### Tester HTML Path

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
  testerHtmlPath: './custom-tester.html',
}
```

### Custom Template Example

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Vitest Browser Tests</title>
</head>
<body>
  <div id="root"></div>
</body>
</html>
```

## Deprecated Browser Options

**Never use these (removed in Vitest 4.0):**

| Vitest 3.x | Vitest 4.x | Notes |
|-----------|-----------|-------|
| `browser.name` | `browser.instances[].browser` | Array-based config |
| `browser.provider: 'playwright'` | `browser.provider: playwright()` | Function call required |
| `browser.testerScripts` | `browser.testerHtmlPath` | Renamed option |
| Package: `@vitest/browser` | `@vitest/browser-playwright` or `@vitest/browser-webdriverio` | Separate packages |

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

```typescript
browser: {
  trace: 'off',                   // No traces
  trace: 'on',                    // Always generate
  trace: 'on-first-retry',        // On first retry
  trace: 'on-all-retries',        // On all retries
  trace: 'retain-on-failure',     // Keep only failed
}
```

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

```typescript
browser: {
  screenshot: 'off',              // No screenshots
  screenshot: 'on',               // Always take screenshots
  screenshot: 'only-on-failure',  // Only on test failure
}
```

## Context Configuration

### Authentication

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [
    {
      browser: 'chromium',
      context: {
        storageState: './auth.json',
      },
    },
  ],
}
```

### Permissions

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [
    {
      browser: 'chromium',
      context: {
        permissions: ['clipboard-read', 'clipboard-write'],
      },
    },
  ],
}
```

### Geolocation

```typescript
browser: {
  enabled: true,
  provider: playwright(),
  instances: [
    {
      browser: 'chromium',
      context: {
        geolocation: { latitude: 37.7749, longitude: -122.4194 },
        permissions: ['geolocation'],
      },
    },
  ],
}
```

## Advanced Patterns

### Cross-Browser Matrix

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

### Conditional Browser Testing

```typescript
browser: {
  enabled: Boolean(process.env.BROWSER_TESTS),
  provider: playwright(),
  instances: [{ browser: 'chromium' }],
}
```

### Multi-Project Browser Setup

```typescript
projects: [
  {
    test: {
      name: 'chromium',
      include: ['tests/browser/**/*.test.ts'],
      browser: {
        enabled: true,
        provider: playwright(),
        instances: [{ browser: 'chromium' }],
      },
    },
  },
  {
    test: {
      name: 'firefox',
      include: ['tests/browser/**/*.test.ts'],
      browser: {
        enabled: true,
        provider: playwright(),
        instances: [{ browser: 'firefox' }],
      },
    },
  },
]
```

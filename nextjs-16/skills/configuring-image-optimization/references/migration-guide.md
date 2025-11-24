# Migration Guide: Next.js 15 to 16

## Overview of Changes

### Removed
- `domains` configuration option
- Default loader implicit fallback
- Old format priority defaults

### Changed Defaults
- `minimumCacheTTL`: 60s → 31536000s (1 year)
- `deviceSizes`: Added 4096px breakpoint
- `imageSizes`: Added 512px size
- AVIF enabled by default

### New Security Requirements
- `dangerouslyAllowSVG` requires explicit `contentDispositionType`
- Stricter `unoptimized` enforcement

## Step-by-Step Migration

### Step 1: Update domains to remotePatterns

**Before:**
```javascript
module.exports = {
  images: {
    domains: [
      'example.com',
      'cdn.example.com',
      'images.example.com',
    ],
  },
}
```

**After:**
```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'images.example.com',
        pathname: '/**',
      },
    ],
  },
}
```

### Step 2: Adjust Cache TTL

If you relied on 60s cache:

**Before (implicit):**
```javascript
module.exports = {
  images: {
    domains: ['api.example.com'],
  },
}
```

**After (explicit):**
```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'api.example.com',
        pathname: '/**',
      },
    ],
    minimumCacheTTL: 60,
  },
}
```

### Step 3: Update SVG Configuration

**Before:**
```javascript
module.exports = {
  images: {
    domains: ['cdn.example.com'],
    dangerouslyAllowSVG: true,
  },
}
```

**After:**
```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/**',
      },
    ],
    dangerouslyAllowSVG: true,
    contentDispositionType: 'inline',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },
}
```

### Step 4: Review Size Arrays

**Before (Next.js 15):**
```javascript
module.exports = {
  images: {
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },
}
```

**After (Next.js 16 defaults):**
```javascript
module.exports = {
  images: {
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840, 4096],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384, 512],
  },
}
```

Only specify if you need custom values.

### Step 5: Verify Format Configuration

**Before (Next.js 15 default):**
- WebP enabled by default
- AVIF opt-in

**After (Next.js 16 default):**
- Both WebP and AVIF enabled
- AVIF preferred when supported

No change needed unless customizing:

```javascript
module.exports = {
  images: {
    formats: ['image/avif', 'image/webp'],
  },
}
```

## Complex Migration Scenarios

### Scenario 1: Multiple Environments with Different Domains

**Before:**
```javascript
const domains = process.env.NODE_ENV === 'production'
  ? ['cdn.prod.com']
  : ['cdn.staging.com', 'localhost']

module.exports = {
  images: {
    domains,
  },
}
```

**After:**
```javascript
const remotePatterns = process.env.NODE_ENV === 'production'
  ? [
      {
        protocol: 'https',
        hostname: 'cdn.prod.com',
        pathname: '/**',
      },
    ]
  : [
      {
        protocol: 'https',
        hostname: 'cdn.staging.com',
        pathname: '/**',
      },
      {
        protocol: 'http',
        hostname: 'localhost',
        port: '3001',
        pathname: '/**',
      },
    ]

module.exports = {
  images: {
    remotePatterns,
    minimumCacheTTL: process.env.NODE_ENV === 'production' ? 31536000 : 60,
  },
}
```

### Scenario 2: Wildcard Subdomains

**Before:**
```javascript
module.exports = {
  images: {
    domains: [
      'cdn1.example.com',
      'cdn2.example.com',
      'cdn3.example.com',
    ],
  },
}
```

**After:**
```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.example.com',
        pathname: '/**',
      },
    ],
  },
}
```

### Scenario 3: Path-Specific Access

**Before (all paths allowed):**
```javascript
module.exports = {
  images: {
    domains: ['cdn.example.com'],
  },
}
```

**After (restricted paths):**
```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/public/**',
      },
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/images/**',
      },
    ],
  },
}
```

### Scenario 4: Custom Loader Migration

**Before:**
```javascript
module.exports = {
  images: {
    loader: 'custom',
    domains: ['cdn.example.com'],
  },
}
```

**After:**
```javascript
module.exports = {
  images: {
    loader: 'custom',
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/**',
      },
    ],
  },
}
```

Custom loader config in component:

```javascript
const customLoader = ({ src, width, quality }) => {
  return `https://cdn.example.com/${src}?w=${width}&q=${quality || 75}`
}

<Image loader={customLoader} src="photo.jpg" width={800} height={600} />
```

### Scenario 5: Incremental Migration

Large codebase? Migrate incrementally:

**Phase 1: Add remotePatterns alongside domains**
```javascript
module.exports = {
  images: {
    domains: ['cdn.example.com'],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'new-cdn.example.com',
        pathname: '/**',
      },
    ],
  },
}
```

**Phase 2: Move all domains to remotePatterns**
```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'new-cdn.example.com',
        pathname: '/**',
      },
    ],
  },
}
```

**Phase 3: Remove domains**

## Verification Checklist

After migration:

- [ ] All images loading correctly
- [ ] No 400/403 errors for remote images
- [ ] Cache headers match expectations
- [ ] SVGs rendering (if applicable)
- [ ] Build completes without warnings
- [ ] No deprecated config warnings
- [ ] Performance metrics acceptable
- [ ] Test all environments (dev, staging, prod)

## Common Migration Issues

### Issue: Images stopped loading after update

**Solution:** Check that protocol and pathname are specified in remotePatterns

### Issue: Cache behavior changed

**Solution:** Explicitly set minimumCacheTTL to previous 60s default if needed

### Issue: Build warnings about domains

**Solution:** Remove domains entirely after migrating to remotePatterns

### Issue: SVG rendering broken

**Solution:** Add contentDispositionType and contentSecurityPolicy

### Issue: Wildcard subdomains not working

**Solution:** Use `*.example.com` pattern instead of listing each subdomain

## Rollback Plan

If issues arise:

1. Keep Next.js 15 config in version control
2. Document all breaking changes
3. Test rollback in staging first
4. Revert next.config.js to previous version
5. Downgrade Next.js if necessary:
   ```bash
   npm install next@15
   ```

## Testing Strategy

### Unit Tests

Test pattern matching:

```javascript
describe('Image patterns', () => {
  it('matches CDN URLs', () => {
    const url = 'https://cdn.example.com/image.jpg'
    expect(matchesPattern(url, remotePatterns)).toBe(true)
  })
})
```

### Integration Tests

Test image loading:

```javascript
describe('Image loading', () => {
  it('loads remote images', async () => {
    render(<Image src="https://cdn.example.com/test.jpg" width={100} height={100} />)
    await waitFor(() => {
      expect(screen.getByRole('img')).toBeInTheDocument()
    })
  })
})
```

### Visual Regression Tests

Use tools like Percy or Chromatic to verify no visual changes.

## Performance Impact

Measure before and after:

- Page load times
- Largest Contentful Paint (LCP)
- Cumulative Layout Shift (CLS)
- Image load times
- Cache hit rates

## Additional Resources

- Next.js 16 release notes
- Image optimization documentation
- Migration tool (if available)
- Community migration guides

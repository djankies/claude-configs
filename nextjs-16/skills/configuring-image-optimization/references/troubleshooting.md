# Troubleshooting Guide

## Image Not Loading

### Pattern Mismatch

**Symptom:** Image returns 400 or 403 error

**Check URL against pattern:**

```javascript
remotePatterns: [
  {
    protocol: 'https',
    hostname: 'example.com',
    pathname: '/images/**',
  },
]
```

**Common mismatches:**

1. Protocol difference:
   - Pattern: `https`
   - Image URL: `http://example.com/images/photo.jpg`
   - Fix: Update pattern to `http` or image URL to `https`

2. Hostname mismatch:
   - Pattern: `cdn.example.com`
   - Image URL: `https://www.example.com/images/photo.jpg`
   - Fix: Add pattern for `www.example.com`

3. Path outside pattern:
   - Pattern: `/images/**`
   - Image URL: `https://example.com/media/photo.jpg`
   - Fix: Update pattern to `/**` or add separate pattern

### Port Specification Required

**Symptom:** Image on custom port not loading

```javascript
remotePatterns: [
  {
    protocol: 'https',
    hostname: 'example.com',
    port: '8080',
    pathname: '/**',
  },
]
```

### Wildcard Hostname Issues

**Symptom:** Subdomain not matching wildcard

Correct wildcard usage:

```javascript
remotePatterns: [
  {
    protocol: 'https',
    hostname: '*.example.com',
    pathname: '/**',
  },
]
```

Matches:
- `https://cdn.example.com/image.jpg`
- `https://assets.example.com/image.jpg`

Does NOT match:
- `https://example.com/image.jpg` (needs separate pattern)
- `https://cdn.sub.example.com/image.jpg` (needs `**.example.com`)

## Cache Not Expiring

### Default TTL Override Not Applied

**Symptom:** Images cached longer than expected

**Verify configuration:**

```javascript
module.exports = {
  images: {
    minimumCacheTTL: 3600,
  },
}
```

**Check cache headers:**

```bash
curl -I https://your-site.com/_next/image?url=/photo.jpg&w=640&q=75
```

Look for:
```
Cache-Control: public, max-age=3600, immutable
```

### Build Cache Interference

**Symptom:** Old images persist after config changes

**Clear caches:**

```bash
rm -rf .next
rm -rf node_modules/.cache
npm run build
```

### Browser Cache Override

**Development testing:**

```bash
curl -H "Cache-Control: no-cache" https://your-site.com/_next/image?url=/photo.jpg&w=640&q=75
```

Or use browser DevTools with cache disabled.

## SVG Not Rendering

### Missing dangerouslyAllowSVG

**Symptom:** SVG returns as download or 403

**Enable SVG support:**

```javascript
module.exports = {
  images: {
    dangerouslyAllowSVG: true,
    contentDispositionType: 'inline',
  },
}
```

### CSP Blocking Rendering

**Symptom:** SVG loads but doesn't render

**Check CSP policy:**

```javascript
contentSecurityPolicy: "default-src 'self'; script-src 'none'; style-src 'unsafe-inline'; sandbox;"
```

For styled SVGs, ensure `style-src 'unsafe-inline'` is present.

### Content Disposition Type

**Symptom:** SVG downloads instead of displaying

```javascript
module.exports = {
  images: {
    dangerouslyAllowSVG: true,
    contentDispositionType: 'inline',
  },
}
```

## Performance Issues

### Too Many Size Variants

**Symptom:** Slow builds, large disk usage

**Reduce variants:**

```javascript
module.exports = {
  images: {
    deviceSizes: [640, 828, 1200, 1920],
    imageSizes: [32, 64, 128, 256],
  },
}
```

**Impact:**
- Fewer size variants generated
- Faster builds
- Less disk space
- Slightly larger images for some viewports

### Format Conversion Overhead

**Symptom:** Slow image optimization

**Adjust format priority:**

```javascript
module.exports = {
  images: {
    formats: ['image/webp'],
  },
}
```

WebP is faster to encode than AVIF.

### Optimization Timeout

**Symptom:** Large images fail to optimize

Check for timeout errors in logs. Consider:

1. Increasing Next.js timeout (custom server)
2. Pre-optimizing large images
3. Using external image service

## Format Issues

### AVIF Not Supported

**Symptom:** Some browsers show fallback format

This is expected behavior. Next.js serves:
1. AVIF to supporting browsers
2. WebP to older browsers
3. Original format as final fallback

### Format Priority Not Respected

**Symptom:** Wrong format served

**Verify format array order:**

```javascript
formats: ['image/avif', 'image/webp']
```

First supported format is served.

## Local Image Issues

### Static Import Not Optimized

**Symptom:** Local images not optimizing

**Check disableStaticImages:**

```javascript
module.exports = {
  images: {
    disableStaticImages: false,
  },
}
```

### Local Pattern Mismatch

**Symptom:** Public folder images not loading

```javascript
module.exports = {
  images: {
    localPatterns: [
      {
        pathname: '/public/uploads/**',
        search: '',
      },
    ],
  },
}
```

Ensure pathname matches actual directory structure.

## Build Errors

### Invalid Configuration Schema

**Symptom:** Build fails with config error

**Validate schema:**

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        pathname: '/**',
      },
    ],
  },
}
```

Common issues:
- Missing required fields (protocol, hostname)
- Invalid protocol value
- Malformed pathname pattern

### Removed Property Used

**Symptom:** Warning about deprecated config

Replace `domains` with `remotePatterns`:

```javascript
remotePatterns: [
  {
    protocol: 'https',
    hostname: 'example.com',
    pathname: '/**',
  },
]
```

## Runtime Errors

### Out of Memory

**Symptom:** Server crashes during image optimization

Solutions:
1. Increase Node.js memory:
   ```bash
   NODE_OPTIONS=--max_old_space_size=4096 npm run build
   ```

2. Reduce concurrent optimizations

3. Use external image service

### Timeout on First Request

**Symptom:** First image load times out

Expected for on-demand optimization. Subsequent requests are cached.

Consider:
- Pre-generating common sizes at build time
- Using ISR for popular images
- CDN caching

## Edge Cases

### Query Parameters in Image URL

**Symptom:** Image with query params not loading

Ensure `search` property allows params:

```javascript
localPatterns: [
  {
    pathname: '/public/images/**',
    search: '?v=*',
  },
]
```

### Image URL with Fragment

**Symptom:** Hash fragments in URL cause issues

Remove fragments before passing to Image component:

```javascript
const cleanUrl = imageUrl.split('#')[0]
```

### Encoded URL Characters

**Symptom:** Images with special characters not loading

Ensure proper URL encoding:

```javascript
const encodedUrl = encodeURIComponent(imageUrl)
```

### Mixed Content Warnings

**Symptom:** HTTP images on HTTPS site blocked

Use HTTPS for all remote patterns in production:

```javascript
remotePatterns: [
  {
    protocol: 'https',
    hostname: 'cdn.example.com',
    pathname: '/**',
  },
]
```

## Debugging Tools

### Enable Image Optimization Logs

```bash
DEBUG=next:image* npm run dev
```

### Check Generated srcset

```bash
curl https://your-site.com/_next/image?url=/photo.jpg&w=640&q=75
```

### Inspect Response Headers

```bash
curl -I https://your-site.com/_next/image?url=/photo.jpg&w=640&q=75
```

### Test Pattern Matching

Create test endpoint:

```javascript
export default function handler(req, res) {
  const { url } = req.query
  res.json({
    matches: testPattern(url),
  })
}
```

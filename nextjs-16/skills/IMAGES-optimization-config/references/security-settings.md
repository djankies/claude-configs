# Security Settings

## SVG Handling

### Trusted Sources Only

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'trusted-cdn.example.com',
        pathname: '/svg/**',
      },
    ],
    dangerouslyAllowSVG: true,
    contentDispositionType: 'inline',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },
}
```

### User Uploads (High Security)

```javascript
module.exports = {
  images: {
    localPatterns: [
      {
        pathname: '/public/user-uploads/**',
        search: '',
      },
    ],
    dangerouslyAllowSVG: true,
    contentDispositionType: 'attachment',
    contentSecurityPolicy: "default-src 'none'; sandbox;",
  },
}
```

### Documentation SVGs

```javascript
module.exports = {
  images: {
    localPatterns: [
      {
        pathname: '/public/docs/diagrams/**',
        search: '',
      },
    ],
    dangerouslyAllowSVG: true,
    contentDispositionType: 'inline',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; style-src 'unsafe-inline'; sandbox;",
  },
}
```

## Content Security Policy Options

### Strictest (Recommended for User Content)

```javascript
contentSecurityPolicy: "default-src 'none'; sandbox;"
```

Blocks all content execution and sandboxes the SVG.

### Standard (Recommended for Trusted Content)

```javascript
contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;"
```

Allows same-origin content but blocks scripts.

### With Inline Styles (For Styled SVGs)

```javascript
contentSecurityPolicy: "default-src 'self'; script-src 'none'; style-src 'unsafe-inline'; sandbox;"
```

Allows inline styles for complex SVG styling.

### Development Only (Not for Production)

```javascript
contentSecurityPolicy: "default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline';"
```

Less restrictive for development debugging.

## Content Disposition Types

### Attachment (Most Secure)

```javascript
contentDispositionType: 'attachment'
```

Forces download, prevents inline rendering. Use for:
- User-uploaded SVGs
- Untrusted sources
- Public file sharing platforms

### Inline (Requires Trust)

```javascript
contentDispositionType: 'inline'
```

Allows browser rendering. Use for:
- Internal CDN content
- Vetted design assets
- Documentation diagrams
- Icon libraries

## Security Best Practices

### Layered Security Approach

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'trusted-cdn.example.com',
        pathname: '/verified-svg/**',
      },
    ],
    localPatterns: [
      {
        pathname: '/public/uploads/**',
        search: '',
      },
    ],
    dangerouslyAllowSVG: true,
    contentDispositionType: 'attachment',
    contentSecurityPolicy: "default-src 'none'; sandbox;",
  },
}
```

Implement server-side:
- SVG sanitization before upload
- File type validation
- Size limits
- Rate limiting

### Separate Configurations by Trust Level

```javascript
const isTrustedSource = (hostname) => {
  return ['internal-cdn.example.com', 'design-system.example.com'].includes(hostname)
}

module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'internal-cdn.example.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'user-uploads.example.com',
        pathname: '/**',
      },
    ],
    dangerouslyAllowSVG: true,
    contentDispositionType: 'attachment',
    contentSecurityPolicy: "default-src 'none'; sandbox;",
  },
}
```

Handle trusted sources differently in application code.

## Unoptimized Images Security

### Production Restrictions

```javascript
module.exports = {
  images: {
    unoptimized: false,
  },
}
```

Always optimize in production for:
- Security scanning during optimization
- Format validation
- Size constraints
- Metadata stripping

### Development Exceptions

```javascript
const isDev = process.env.NODE_ENV === 'development'

module.exports = {
  images: {
    unoptimized: isDev,
  },
}
```

Only bypass optimization in development.

## Local Pattern Security

### Restrict to Specific Directories

```javascript
module.exports = {
  images: {
    localPatterns: [
      {
        pathname: '/public/assets/approved/**',
        search: '',
      },
      {
        pathname: '/public/user-content/**',
        search: '',
      },
    ],
  },
}
```

Never use broad patterns like `/public/**`.

### Combine with File System Permissions

Ensure directory permissions prevent unauthorized writes:

```bash
chmod 755 /public/assets/approved
chmod 700 /public/user-content
```

## Remote Pattern Security

### Explicit Protocol Requirements

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
  },
}
```

Never allow `http` in production.

### Hostname Validation

Prefer exact matches over wildcards:

```javascript
remotePatterns: [
  {
    protocol: 'https',
    hostname: 'cdn1.example.com',
    pathname: '/**',
  },
  {
    protocol: 'https',
    hostname: 'cdn2.example.com',
    pathname: '/**',
  },
]
```

Instead of:

```javascript
remotePatterns: [
  {
    protocol: 'https',
    hostname: '*.example.com',
    pathname: '/**',
  },
]
```

### Path Restrictions

Limit to specific paths:

```javascript
remotePatterns: [
  {
    protocol: 'https',
    hostname: 'cdn.example.com',
    pathname: '/public-images/**',
  },
]
```

Avoid `pathname: '/**'` when possible.

## Security Monitoring

### Log Suspicious Patterns

Implement middleware to log:
- Unoptimized image requests
- SVG access patterns
- Pattern match failures
- Unusual image sources

### Rate Limiting

Apply rate limits to image optimization endpoints:

```javascript
const rateLimit = {
  windowMs: 15 * 60 * 1000,
  max: 100,
}
```

### Regular Security Audits

Check for:
- Overly permissive patterns
- Unnecessary SVG enablement
- Unoptimized production images
- Weak CSP policies

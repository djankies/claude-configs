# Configuration Examples

## Complete Configuration Template

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        port: '',
        pathname: '/images/**',
      },
    ],
    localPatterns: [
      {
        pathname: '/public/uploads/**',
        search: '',
      },
    ],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    formats: ['image/webp', 'image/avif'],
    minimumCacheTTL: 31536000,
    disableStaticImages: false,
    dangerouslyAllowSVG: false,
    contentDispositionType: 'attachment',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
    unoptimized: false,
  },
}
```

## E-Commerce Platform

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cdn.shopify.com',
        pathname: '/s/files/**',
      },
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/products/**',
      },
    ],
    localPatterns: [
      {
        pathname: '/public/product-images/**',
        search: '',
      },
    ],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],
    imageSizes: [64, 128, 256, 384, 512],
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 86400,
  },
}
```

## Content Management System

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cms.example.com',
        pathname: '/media/**',
      },
      {
        protocol: 'https',
        hostname: '*.contentful.com',
        pathname: '/**',
      },
    ],
    deviceSizes: [640, 828, 1200, 1920, 2048],
    imageSizes: [32, 64, 128, 256, 384],
    minimumCacheTTL: 3600,
  },
}
```

## User-Generated Content Platform

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'storage.googleapis.com',
        pathname: '/user-uploads/**',
      },
    ],
    localPatterns: [
      {
        pathname: '/public/temp-uploads/**',
        search: '',
      },
    ],
    deviceSizes: [375, 640, 750, 828, 1080],
    imageSizes: [48, 64, 96, 128],
    minimumCacheTTL: 300,
    dangerouslyAllowSVG: true,
    contentDispositionType: 'attachment',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },
}
```

## Multi-CDN Setup

```javascript
module.exports = {
  images: {
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
      {
        protocol: 'https',
        hostname: 'images.cloudflare.com',
        pathname: '/**',
      },
    ],
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 31536000,
  },
}
```

## Marketing Landing Pages

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'marketing-cdn.example.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'assets.example.com',
        pathname: '/campaigns/**',
      },
    ],
    deviceSizes: [375, 640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384, 512],
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 86400,
  },
}
```

## Blog or News Site

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.example.com',
        pathname: '/articles/**',
      },
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/blog/**',
      },
    ],
    deviceSizes: [640, 828, 1200, 1920],
    imageSizes: [64, 128, 256, 384],
    formats: ['image/webp', 'image/avif'],
    minimumCacheTTL: 604800,
  },
}
```

## Social Media Application

```javascript
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'avatars.example.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'media.example.com',
        pathname: '/posts/**',
      },
    ],
    deviceSizes: [375, 414, 640, 750, 828],
    imageSizes: [24, 32, 48, 64, 96, 128],
    minimumCacheTTL: 3600,
  },
}
```

## Documentation Site

```javascript
module.exports = {
  images: {
    localPatterns: [
      {
        pathname: '/public/docs/images/**',
        search: '',
      },
    ],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'docs-cdn.example.com',
        pathname: '/**',
      },
    ],
    deviceSizes: [640, 828, 1200, 1920],
    imageSizes: [32, 64, 128, 256],
    formats: ['image/webp'],
    minimumCacheTTL: 2592000,
    dangerouslyAllowSVG: true,
    contentDispositionType: 'inline',
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },
}
```

## Portfolio or Agency Site

```javascript
module.exports = {
  images: {
    localPatterns: [
      {
        pathname: '/public/portfolio/**',
        search: '',
      },
    ],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'behance.net',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'dribbble.com',
        pathname: '/**',
      },
    ],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [128, 256, 384, 512],
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 604800,
  },
}
```

# Deployment Guide

This guide covers deploying the authentication modal system to production environments.

## Prerequisites

Before deploying to production, you MUST:

1. Replace mock authentication with real backend
2. Implement proper password hashing
3. Set up database for user storage
4. Configure session management
5. Enable HTTPS
6. Add rate limiting
7. Set up monitoring

**WARNING**: This demo uses mock authentication and is NOT production-ready as-is.

## Environment Setup

### Environment Variables

Create `.env.production`:

```bash
DATABASE_URL=postgresql://user:password@host:5432/dbname
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
SESSION_SECRET=your-session-secret-min-32-chars
NEXTAUTH_URL=https://yourdomain.com
NEXTAUTH_SECRET=your-nextauth-secret

EMAIL_SERVER=smtp://username:password@smtp.example.com:587
EMAIL_FROM=noreply@yourdomain.com

RATE_LIMIT_MAX=5
RATE_LIMIT_WINDOW=900000

NODE_ENV=production
```

### Security Checklist

- [ ] All secrets are strong (32+ characters, random)
- [ ] Environment variables never committed to git
- [ ] Production uses separate database
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] CSP policy defined

## Vercel Deployment

### Quick Deploy

```bash
npm install -g vercel
vercel login
vercel --prod
```

### Configuration

Create `vercel.json`:

```json
{
  "version": 2,
  "build": {
    "env": {
      "NEXT_PUBLIC_APP_URL": "https://yourdomain.com"
    }
  },
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=63072000; includeSubDomains; preload"
        },
        {
          "key": "X-Frame-Options",
          "value": "SAMEORIGIN"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "Referrer-Policy",
          "value": "origin-when-cross-origin"
        }
      ]
    }
  ]
}
```

### Environment Variables in Vercel

1. Go to Project Settings
2. Navigate to Environment Variables
3. Add all production variables
4. Redeploy

## Docker Deployment

### Dockerfile

```dockerfile
FROM node:20-alpine AS base

FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV production
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT 3000
CMD ["node", "server.js"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    env_file:
      - .env.production
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: authdb
      POSTGRES_USER: authuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

### Build and Run

```bash
docker-compose build
docker-compose up -d
```

## AWS Deployment

### Using AWS Amplify

```bash
npm install -g @aws-amplify/cli
amplify init
amplify add hosting
amplify publish
```

### Using EC2

1. Launch EC2 instance (t3.medium recommended)
2. Install Node.js and PM2:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2
```

3. Clone and build:

```bash
git clone your-repo
cd your-repo
npm ci
npm run build
```

4. Start with PM2:

```bash
pm2 start npm --name "auth-app" -- start
pm2 save
pm2 startup
```

5. Configure Nginx:

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

6. Enable HTTPS with Let's Encrypt:

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

## Database Setup

### PostgreSQL (Recommended)

```bash
createdb authdb
psql authdb < schema.sql
```

### Prisma Schema

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id            String   @id @default(cuid())
  email         String   @unique
  name          String
  passwordHash  String
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  sessions      Session[]
}

model Session {
  id        String   @id @default(cuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())
  user      User     @relation(fields: [userId], references: [id])
}
```

### Migrate Database

```bash
npx prisma migrate deploy
```

## Monitoring Setup

### Sentry for Error Tracking

```bash
npm install @sentry/nextjs
```

```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 1.0,
});
```

### Log Management

Use structured logging:

```typescript
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});
```

### Health Check Endpoint

Create `/api/health`:

```typescript
export async function GET() {
  return Response.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
}
```

## Performance Optimization

### Enable Caching

```typescript
export const revalidate = 3600;
```

### Image Optimization

Use Next.js Image component:

```typescript
import Image from 'next/image';
```

### Bundle Analysis

```bash
npm install @next/bundle-analyzer
```

```javascript
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({});
```

## CDN Setup

### Cloudflare

1. Add site to Cloudflare
2. Update DNS records
3. Enable SSL/TLS
4. Configure caching rules
5. Enable DDoS protection

### Cache Configuration

```javascript
module.exports = {
  async headers() {
    return [
      {
        source: '/static/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          },
        ],
      },
    ];
  },
};
```

## Load Testing

### Using Artillery

```bash
npm install -g artillery
```

Create `load-test.yml`:

```yaml
config:
  target: 'https://yourdomain.com'
  phases:
    - duration: 60
      arrivalRate: 10
      name: Warm up
    - duration: 120
      arrivalRate: 50
      name: Sustained load

scenarios:
  - name: "Login flow"
    flow:
      - get:
          url: "/"
      - post:
          url: "/api/auth"
          json:
            email: "test@example.com"
            password: "Password123"
```

Run test:

```bash
artillery run load-test.yml
```

## Backup Strategy

### Database Backups

Automated daily backups:

```bash
0 2 * * * pg_dump authdb | gzip > /backups/authdb-$(date +\%Y\%m\%d).sql.gz
```

### Retention Policy

- Daily backups: 7 days
- Weekly backups: 4 weeks
- Monthly backups: 12 months

## Disaster Recovery

### Backup Restoration

```bash
gunzip < backup.sql.gz | psql authdb
```

### Failover Plan

1. Monitor primary server
2. Automatic failover to standby
3. Update DNS to point to backup
4. Restore from latest backup
5. Verify data integrity

## Security Hardening

### Firewall Rules

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Fail2ban

```bash
sudo apt-get install fail2ban
sudo systemctl enable fail2ban
```

### Regular Updates

```bash
sudo apt-get update
sudo apt-get upgrade
```

## Monitoring Dashboards

### Key Metrics

1. **Response Time**: < 200ms p95
2. **Error Rate**: < 0.1%
3. **Uptime**: > 99.9%
4. **CPU Usage**: < 70%
5. **Memory Usage**: < 80%

### Alerts

Configure alerts for:
- Server down
- High error rate
- Slow response time
- Database connection issues
- High memory usage
- Failed login spike

## Post-Deployment Checklist

- [ ] All environment variables set
- [ ] Database migrated
- [ ] HTTPS enabled
- [ ] Security headers configured
- [ ] Rate limiting active
- [ ] Monitoring set up
- [ ] Backups configured
- [ ] Error tracking enabled
- [ ] Load testing passed
- [ ] Health check responding
- [ ] Logs aggregating properly
- [ ] CDN configured
- [ ] DNS propagated
- [ ] SSL certificate valid
- [ ] Firewall rules applied

## Rollback Procedure

If deployment fails:

```bash
vercel rollback

# Or for Docker:
docker-compose down
git checkout previous-tag
docker-compose up -d
```

## Support

For deployment issues:
- Check logs: `pm2 logs` or `docker logs`
- Review monitoring dashboards
- Check database connectivity
- Verify environment variables
- Test health endpoint

## Production URLs

- Application: https://yourdomain.com
- API: https://api.yourdomain.com
- Admin: https://admin.yourdomain.com
- Monitoring: https://monitoring.yourdomain.com

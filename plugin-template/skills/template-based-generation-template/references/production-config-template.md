# Production Configuration Template

Complete example of generating production-ready configuration with security best practices.

## Configuration Template Structure

```json
{
  "environment": "production",
  "server": {
    "port": 3000,
    "host": "0.0.0.0",
    "trustProxy": true
  },
  "database": {
    "url": "${DATABASE_URL}",
    "ssl": true,
    "poolSize": 20,
    "connectionTimeout": 10000
  },
  "redis": {
    "url": "${REDIS_URL}",
    "tls": true,
    "maxRetries": 3
  },
  "security": {
    "cors": {
      "origin": ["https://app.example.com"],
      "credentials": true
    },
    "rateLimit": {
      "windowMs": 60000,
      "max": 1000
    },
    "headers": {
      "contentSecurityPolicy": true,
      "hsts": true
    }
  },
  "monitoring": {
    "datadog": {
      "apiKey": "${DATADOG_API_KEY}",
      "service": "${SERVICE_NAME}",
      "env": "production"
    },
    "healthCheck": {
      "enabled": true,
      "path": "/health"
    }
  },
  "logging": {
    "level": "info",
    "format": "json",
    "destination": "stdout"
  },
  "features": {
    "caching": true,
    "analytics": true,
    "experimental": false
  }
}
```

## Security Checklist

### ✓ Secrets Management
- All secrets in environment variables
- No hardcoded credentials
- Proper secret rotation support

### ✓ Network Security
- SSL/TLS enabled for all connections
- CORS properly configured
- Rate limiting enabled
- Security headers set

### ✓ Data Protection
- Database connections encrypted
- Connection pooling configured
- Timeouts set appropriately

### ✓ Monitoring
- Health checks enabled
- Error tracking configured
- Performance monitoring active
- Log aggregation setup

## Generation Example

**Input Requirements:**
```javascript
{
  environment: 'production',
  database: 'postgresql',
  cache: 'redis',
  monitoring: 'datadog',
  features: ['caching', 'rate-limiting', 'analytics']
}
```

**Generated Configuration:**

```json
{
  "environment": "production",
  "server": {
    "port": 3000,
    "host": "0.0.0.0",
    "trustProxy": true
  },
  "database": {
    "url": "${DATABASE_URL}",
    "ssl": {
      "rejectUnauthorized": true
    },
    "poolSize": 20,
    "connectionTimeout": 10000,
    "idleTimeout": 30000,
    "retryAttempts": 3
  },
  "redis": {
    "url": "${REDIS_URL}",
    "tls": {
      "rejectUnauthorized": true
    },
    "maxRetries": 3,
    "retryStrategy": "exponential"
  },
  "security": {
    "cors": {
      "origin": "${CORS_ORIGIN}",
      "credentials": true,
      "methods": ["GET", "POST", "PUT", "DELETE"],
      "allowedHeaders": ["Content-Type", "Authorization"]
    },
    "rateLimit": {
      "windowMs": 60000,
      "max": 1000,
      "message": "Too many requests, please try again later.",
      "standardHeaders": true,
      "legacyHeaders": false
    },
    "helmet": {
      "contentSecurityPolicy": {
        "directives": {
          "defaultSrc": ["'self'"],
          "scriptSrc": ["'self'"],
          "styleSrc": ["'self'", "'unsafe-inline'"],
          "imgSrc": ["'self'", "data:", "https:"],
          "connectSrc": ["'self'"],
          "fontSrc": ["'self'"],
          "objectSrc": ["'none'"],
          "mediaSrc": ["'self'"],
          "frameSrc": ["'none'"]
        }
      },
      "hsts": {
        "maxAge": 31536000,
        "includeSubDomains": true,
        "preload": true
      },
      "referrerPolicy": {
        "policy": "strict-origin-when-cross-origin"
      }
    }
  },
  "monitoring": {
    "datadog": {
      "apiKey": "${DATADOG_API_KEY}",
      "service": "${SERVICE_NAME}",
      "env": "production",
      "version": "${APP_VERSION}",
      "logInjection": true,
      "runtimeMetrics": true
    },
    "healthCheck": {
      "enabled": true,
      "path": "/health",
      "timeout": 5000
    },
    "metrics": {
      "enabled": true,
      "path": "/metrics",
      "interval": 10000
    }
  },
  "logging": {
    "level": "info",
    "format": "json",
    "destination": "stdout",
    "excludePaths": ["/health", "/metrics"],
    "redactFields": ["password", "token", "apiKey", "secret"]
  },
  "features": {
    "caching": {
      "enabled": true,
      "ttl": 3600,
      "checkPeriod": 600
    },
    "analytics": {
      "enabled": true,
      "sampling": 1.0
    },
    "experimental": false
  },
  "performance": {
    "compression": true,
    "keepAlive": true,
    "timeout": 30000
  }
}
```

## Validation Rules

### Required Fields
- `environment` must be "production"
- `database.url` must reference environment variable
- `database.ssl` must be true
- `security.cors.origin` must not be "*"
- `logging.level` must be "info" or "warn" or "error"

### Security Validations
```javascript
function validateProductionConfig(config) {
  const errors = [];

  if (config.database.ssl !== true) {
    errors.push('Database SSL must be enabled in production');
  }

  if (config.security.cors.origin === '*') {
    errors.push('CORS origin cannot be "*" in production');
  }

  if (config.logging.level === 'debug') {
    errors.push('Debug logging not allowed in production');
  }

  const secretFields = ['apiKey', 'password', 'token', 'secret'];
  const hardcodedSecrets = findHardcodedSecrets(config, secretFields);
  if (hardcodedSecrets.length > 0) {
    errors.push(`Hardcoded secrets found: ${hardcodedSecrets.join(', ')}`);
  }

  return errors;
}
```

## Environment Variables Required

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# Cache
REDIS_URL=redis://user:pass@host:6379

# Monitoring
DATADOG_API_KEY=your-api-key-here

# Security
CORS_ORIGIN=https://app.example.com

# Application
SERVICE_NAME=my-service
APP_VERSION=1.2.3
```

## Post-Generation Steps

1. **Validate configuration**
   ```bash
   npm run validate-config config/production.json
   ```

2. **Test configuration loading**
   ```bash
   NODE_ENV=production npm run test:config
   ```

3. **Deploy configuration**
   ```bash
   kubectl create configmap app-config --from-file=config/production.json
   ```

4. **Verify in production**
   - Check health endpoint
   - Verify database connectivity
   - Confirm monitoring integration
   - Test rate limiting

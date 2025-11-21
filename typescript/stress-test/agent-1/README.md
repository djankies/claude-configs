# User Input Validation API

A production-ready REST API for user registration with comprehensive input validation.

## Features

- TypeScript implementation with strict type safety
- Email format validation using industry-standard validator library
- Password strength requirements enforcement
- Name validation with character restrictions
- Duplicate email prevention
- Proper HTTP status codes and error responses
- In-memory database for fast prototyping
- Health check endpoint for monitoring

## Installation

```bash
npm install
```

## Build

```bash
npm run build
```

## Run

Development mode:
```bash
npm run dev
```

Production mode:
```bash
npm run build
npm start
```

## API Endpoints

### POST /api/users/register

Register a new user with validation.

**Request Body:**
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "password": "SecurePass123!"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "id": "user_1234567890_abc123def",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "2025-11-21T10:30:00.000Z"
  }
}
```

**Validation Error Response (400):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    },
    {
      "field": "password",
      "message": "Password must be at least 8 characters long"
    }
  ]
}
```

**Duplicate Email Response (409):**
```json
{
  "success": false,
  "message": "Email already registered",
  "errors": [
    {
      "field": "email",
      "message": "This email is already in use"
    }
  ]
}
```

### GET /api/users/health

Health check endpoint.

**Success Response (200):**
```json
{
  "success": true,
  "message": "API is healthy",
  "data": {
    "status": "operational",
    "timestamp": "2025-11-21T10:30:00.000Z",
    "stats": {
      "totalUsers": 42
    }
  }
}
```

## Validation Rules

### Email
- Required field
- Must be valid email format
- Maximum 255 characters
- Normalized to lowercase

### Name
- Required field
- Minimum 2 characters
- Maximum 100 characters
- Only letters, spaces, hyphens, and apostrophes allowed

### Password
- Required field
- Minimum 8 characters
- Maximum 128 characters
- Must contain at least one lowercase letter
- Must contain at least one uppercase letter
- Must contain at least one number
- Must contain at least one special character (@$!%*?&)

## Project Structure

```
stress-test/agent-1/
├── src/
│   ├── index.ts           # Application entry point
│   ├── routes.ts          # Route definitions
│   ├── controller.ts      # Request handlers
│   ├── validator.ts       # Validation logic
│   ├── database.ts        # In-memory database
│   ├── middleware.ts      # Error handling and logging
│   └── types.ts           # TypeScript interfaces
├── dist/                  # Compiled JavaScript output
├── package.json
├── tsconfig.json
└── README.md
```

## Testing the API

Using curl:

```bash
curl -X POST http://localhost:3000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "password": "SecurePass123!"
  }'
```

Using Postman or any HTTP client, send POST requests to the registration endpoint with the required fields.

## Production Considerations

This implementation uses an in-memory database for simplicity. For production deployment:

1. Replace the in-memory database with a persistent database (PostgreSQL, MongoDB, etc.)
2. Add proper password hashing (bcrypt, argon2)
3. Implement rate limiting to prevent abuse
4. Add CORS configuration for frontend integration
5. Set up environment variables for configuration
6. Add comprehensive logging and monitoring
7. Implement authentication tokens (JWT)
8. Add input sanitization to prevent XSS attacks
9. Set up HTTPS/TLS encryption
10. Add database connection pooling and error recovery

## License

ISC

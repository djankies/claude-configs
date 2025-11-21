# Correct Security Implementations

## Password Hashing with bcrypt

```typescript
import bcrypt from "bcrypt";

const SALT_ROUNDS = 12;

async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  return await bcrypt.compare(password, hash);
}

interface User {
  id: string;
  email: string;
  passwordHash: string;
}

async function createUser(
  email: string,
  password: string
): Promise<User> {
  const passwordHash = await hashPassword(password);

  return {
    id: generateId(),
    email,
    passwordHash
  };
}

async function loginUser(
  email: string,
  password: string
): Promise<User | null> {
  const user = await database.findByEmail(email);

  if (!user) {
    return null;
  }

  const isValid = await verifyPassword(password, user.passwordHash);

  return isValid ? user : null;
}
```

**Why this is correct**:
- Uses bcrypt (designed for passwords)
- Automatic salting
- Slow (intentional, prevents brute force)
- Cost factor 12 (good balance)
- Never stores actual password
- Async to avoid blocking

## argon2 Implementation

```typescript
import argon2 from "argon2";

async function hashPassword(password: string): Promise<string> {
  return await argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 2 ** 16,
    timeCost: 3,
    parallelism: 1
  });
}

async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  try {
    return await argon2.verify(hash, password);
  } catch {
    return false;
  }
}
```

**Why this is correct**:
- argon2id (latest standard, winner of Password Hashing Competition)
- Memory-hard (resists GPU attacks)
- Configurable parameters
- Better than bcrypt for new projects

## OAuth for Third-Party Services

```typescript
import { google } from "googleapis";

const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  "http://localhost:3000/auth/callback"
);

function getAuthUrl(): string {
  return oauth2Client.generateAuthUrl({
    access_type: "offline",
    scope: ["https://www.googleapis.com/auth/userinfo.email"]
  });
}

async function handleCallback(code: string) {
  const { tokens } = await oauth2Client.getToken(code);
  oauth2Client.setCredentials(tokens);

  return tokens;
}
```

**Why this is correct**:
- Uses OAuth (industry standard)
- Never sees user's Google password
- Token-based authentication
- Revocable access
- Follows Terms of Service

## API Key Storage

```typescript
interface Config {
  stripeApiKey: string;
  sendgridApiKey: string;
}

function loadConfig(): Config {
  const stripeApiKey = process.env.STRIPE_API_KEY;
  const sendgridApiKey = process.env.SENDGRID_API_KEY;

  if (!stripeApiKey || !sendgridApiKey) {
    throw new Error("Missing required API keys");
  }

  return {
    stripeApiKey,
    sendgridApiKey
  };
}
```

**Why this is correct**:
- Reads from environment variables
- Never hardcoded
- Not committed to git
- Validated at startup

## Session Tokens

```typescript
import crypto from "crypto";

function generateSessionToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

interface Session {
  id: string;
  userId: string;
  token: string;
  expiresAt: Date;
}

async function createSession(userId: string): Promise<Session> {
  const token = generateSessionToken();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

  const session = {
    id: generateId(),
    userId,
    token,
    expiresAt
  };

  await database.sessions.insert(session);

  return session;
}
```

**Why this is correct**:
- Cryptographically random tokens
- Time-based expiration
- Separate from password
- Can be revoked

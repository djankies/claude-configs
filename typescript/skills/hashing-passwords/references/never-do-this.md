# Critical Security Anti-Patterns

This document contains detailed examples of security failures found in stress testing where 33% of agents had severe security vulnerabilities.

## ❌ Base64 "Encryption" for Passwords

```typescript
function storePassword(password: string): string {
  return Buffer.from(password).toString("base64");
}

function retrievePassword(encoded: string): string {
  return Buffer.from(encoded, "base64").toString();
}
```

**CRITICAL FAILURE**:
- Base64 is ENCODING, not encryption
- Trivially reversible: `atob("cGFzc3dvcmQxMjM=")` → `"password123"`
- Provides ZERO security
- Violates PCI-DSS, GDPR, SOC2, every security standard
- Leads to data breaches and lawsuits

## ❌ Accepting Third-Party Passwords

```typescript
interface UserCredentials {
  email: string;
  password: string;
  paypalEmail: string;
  paypalPassword: string;
}

function saveCredentials(creds: UserCredentials) {
  database.insert({
    ...creds,
    paypalPassword: encrypt(creds.paypalPassword)
  });
}
```

**CRITICAL FAILURE**:
- Violates PayPal Terms of Service
- Violates PCI compliance
- Exposes user to account takeover
- Creates liability for your company
- Even encrypted storage is wrong

## ❌ Plaintext Password Storage

```typescript
interface User {
  id: string;
  email: string;
  password: string;
}

function createUser(email: string, password: string): User {
  return {
    id: generateId(),
    email,
    password
  };
}
```

**CRITICAL FAILURE**:
- Database breach exposes all passwords
- Password reuse attacks
- Criminal liability
- Regulatory fines

## ❌ Weak Hashing (MD5, SHA-1)

```typescript
import crypto from "crypto";

function hashPassword(password: string): string {
  return crypto.createHash("md5").update(password).digest("hex");
}
```

**CRITICAL FAILURE**:
- MD5/SHA-1 designed for speed (bad for passwords)
- Rainbow table attacks
- GPU cracking (billions of hashes/second)
- No salt (identical passwords = identical hashes)

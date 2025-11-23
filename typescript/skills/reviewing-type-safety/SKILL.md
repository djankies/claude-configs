---
name: review-type-safety
description: Code review skill that checks TypeScript type safety, exported for use by cross-cutting review plugin
review: true
---

# TypeScript Type Safety Review

**Purpose:** Comprehensive type safety review for TypeScript code, detecting violations that compromise compile-time safety and runtime reliability.

**When to use:** During code review process, invoked by review plugin to validate TypeScript type safety across the codebase.

**Exported for:** Cross-cutting review plugin that orchestrates multi-concern reviews.

## Review Checklist

When reviewing TypeScript code, systematically check for these type safety violations:

### 1. `any` Type Abuse

**Check for:**
- Generic defaults using `any`: `<T = any>`
- Function parameters typed as `any`: `function process(data: any)`
- Return types using `any`: `): any {`
- Array or object types with `any`: `any[]`, `Record<string, any>`
- Type assertions to `any`: `as any`

**Correct alternatives:**
- Use `unknown` with type guards instead of `any`
- Use specific types or generic constraints
- See @typescript/TYPES-any-vs-unknown for guidance

**Severity:** HIGH - Defeats TypeScript's purpose entirely

### 2. Unsafe Type Assertions

**Check for:**
- Type assertions on external data without validation: `JSON.parse(response) as T`
- Downcasting without runtime checks: `value as SpecificType`
- Double assertions: `value as unknown as T`
- Type assertions in parsers or API handlers

**Acceptable assertions:**
- `as const` for literal types
- `as unknown as T` only AFTER runtime validation
- Type assertions on known internal data structures

**Severity:** HIGH - Bypasses type safety, causes runtime errors

### 3. Missing Type Guards

**Check for:**
- Error handling without type checks: `catch (error) { error.message }`
- Array operations without bounds checking
- Object property access without `in` operator
- Discriminated unions without exhaustive checks

**Required patterns:**
- Error type guards: `error instanceof Error`
- Array bounds: check length or use `noUncheckedIndexedAccess`
- Object properties: `'key' in obj` before access
- Exhaustive switch with `never` type

**Severity:** MEDIUM - Leads to runtime errors in edge cases

### 4. Missing Runtime Validation

**Check for:**
- API responses used directly without validation
- User input processed without sanitization
- JSON parsing without schema validation
- External configuration loaded without checks

**Required:**
- Use Zod, io-ts, or similar for runtime validation
- Validate at system boundaries
- Never trust external data
- See @typescript/VALIDATION-runtime-checks

**Severity:** HIGH - Security and reliability issue

### 5. Deprecated JavaScript APIs

**Check for:**
- `substr()` - use `slice()` instead
- `escape()` - use `encodeURIComponent()` instead
- `unescape()` - use `decodeURIComponent()` instead

**Severity:** LOW - Future compatibility issue

### 6. Security Violations

**Check for:**
- Base64 encoding for passwords (not encryption!)
- Direct password storage without hashing
- Accepting third-party credentials (use OAuth instead)
- Missing input sanitization (XSS risk)
- Unsafe SQL query construction

**Required:**
- Use bcrypt/argon2 for password hashing
- OAuth for third-party authentication
- Sanitize all user input
- Use parameterized queries
- See @typescript/SECURITY-credentials

**Severity:** CRITICAL - Production security breach risk

### 7. Missing Generic Constraints

**Check for:**
- Unconstrained generics: `<T>` when `<T extends SomeType>` is appropriate
- Generic defaults to `any`
- Missing type parameter relationships

**Correct patterns:**
- Constrain to expected shape: `<T extends { id: string }>`
- Use multiple type parameters with relationships: `<T extends U>`
- See @typescript/TYPES-generics

**Severity:** MEDIUM - Reduces type safety guarantees

### 8. Compiler Configuration Issues

**Check for:**
- `strict: false` in tsconfig.json
- Missing `noUncheckedIndexedAccess: true`
- `skipLibCheck: false` (performance issue)
- Incorrect module resolution for Node.js projects

**Required settings:**
- `strict: true` (enables all strict checks)
- `noUncheckedIndexedAccess: true` (prevents array out-of-bounds)
- `skipLibCheck: true` (improves build performance)
- `moduleResolution: "NodeNext"` for Node.js projects

**Severity:** MEDIUM - Affects entire project safety

## Review Process

1. **Automated Checks**
   - Run TypeScript compiler: `tsc --noEmit`
   - Run ESLint with TypeScript rules
   - Check for `any` usage: `grep -r ": any" src/`
   - Check for type assertions: `grep -r " as " src/`

2. **Manual Review**
   - Focus on type safety at system boundaries (API handlers, parsers)
   - Verify runtime validation exists for external data
   - Check error handling has proper type guards
   - Review security-sensitive code (authentication, authorization)

3. **Report Findings**
   - Group by severity (CRITICAL > HIGH > MEDIUM > LOW)
   - Provide specific file location and line number
   - Explain why it's a violation
   - Suggest specific fix with code example

## Example Violations and Fixes

### Violation: `any` Type on API Response

```typescript
async function fetchUser(id: string): Promise<any> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}
```

**Fix:**

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
});

type User = z.infer<typeof UserSchema>;

async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return UserSchema.parse(data);
}
```

### Violation: Type Assertion Without Validation

```typescript
function parseConfig(json: string) {
  return JSON.parse(json) as Config;
}
```

**Fix:**

```typescript
import { z } from 'zod';

const ConfigSchema = z.object({
  apiKey: z.string(),
  timeout: z.number(),
});

type Config = z.infer<typeof ConfigSchema>;

function parseConfig(json: string): Config {
  const data = JSON.parse(json);
  return ConfigSchema.parse(data);
}
```

### Violation: Missing Error Type Guard

```typescript
try {
  await riskyOperation();
} catch (error) {
  console.error(error.message);
}
```

**Fix:**

```typescript
try {
  await riskyOperation();
} catch (error) {
  if (error instanceof Error) {
    console.error(error.message);
  } else {
    console.error('Unknown error:', error);
  }
}
```

## Integration with Review Plugin

This skill is exported with `review: true` frontmatter, making it discoverable by the cross-cutting review plugin.

**Review plugin should:**
- Invoke this skill for TypeScript files (`.ts`, `.tsx`)
- Run automated checks first
- Present findings grouped by severity
- Generate actionable review comments

**Cross-plugin references:**
- React plugin: References this skill for component prop type safety
- Next.js plugin: References this skill for server action type safety
- Node.js plugin: References this skill for API handler type safety

## Stress Test Prevention

This review skill addresses all 23 violations found in the TypeScript stress test:

- ✅ Detects `any` abuse (5/6 agents)
- ✅ Catches type assertion misuse (4/6 agents)
- ✅ Identifies security failures (2/6 agents)
- ✅ Flags deprecated API usage (3/6 agents)
- ✅ Ensures TypeScript vs JavaScript (2/6 agents)
- ✅ Validates runtime checking presence

**Target:** 90% reduction in type safety violations when used during code review.

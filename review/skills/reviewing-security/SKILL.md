---
name: reviewing-security
description: Automated tooling and detection patterns for JavaScript/TypeScript security vulnerabilities. Provides scan commands, vulnerability patterns, and severity mapping—not output formatting or workflow.
allowed-tools: Bash, Read, Grep, Glob
version: 1.0.0
---

# Security Review Skill

## Purpose

This skill provides automated security scanning commands and vulnerability detection patterns. Use this as a reference for WHAT to check and HOW to detect security issues—not for output formatting or workflow.

## Automated Security Scan

Run Semgrep security analysis (if available):

```bash
bash ~/.claude/plugins/marketplaces/claude-configs/review/scripts/review-security.sh
```

**Returns:** Security issues by severity, vulnerability types (XSS, injection, etc.), file:line locations, CWE/OWASP references

## Vulnerability Detection Patterns

When automated tools unavailable or for deeper analysis, use Read/Grep/Glob to detect:

### Input Validation Vulnerabilities

**XSS (Cross-Site Scripting):**

```bash
grep -rn "innerHTML.*=\|dangerouslySetInnerHTML\|document\.write" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx"
```

Look for: User input assigned to innerHTML, dangerouslySetInnerHTML usage, document.write with variables

**SQL Injection:**

```bash
grep -rn "query.*+\|query.*\${" --include="*.ts" --include="*.js"
```

Look for: String concatenation in SQL queries, template literals in queries without parameterization

**Command Injection:**

```bash
grep -rn "exec\|spawn\|execSync\|spawnSync" --include="*.ts" --include="*.js"
```

Look for: User input passed to exec/spawn, unsanitized command arguments

**Path Traversal:**

```bash
grep -rn "readFile.*req\|readFile.*params\|\.\./" --include="*.ts" --include="*.js"
```

Look for: File paths from user input, ../ in file operations

**Code Injection:**

```bash
grep -rn "eval\|new Function\|setTimeout.*string\|setInterval.*string" --include="*.ts" --include="*.js"
```

Look for: eval() usage, Function constructor, string-based setTimeout/setInterval

### Authentication & Authorization Issues

**Hardcoded Credentials:**

```bash
grep -rn "password\s*=\s*['\"][^'\"]\+['\"]" --include="*.ts" --include="*.js"
grep -rn "api_key\s*=\s*['\"][^'\"]\+['\"]" --include="*.ts" --include="*.js"
grep -rn "secret\s*=\s*['\"][^'\"]\+['\"]" --include="*.ts" --include="*.js"
grep -rn "token\s*=\s*['\"][^'\"]\+['\"]" --include="*.ts" --include="*.js"
```

Look for: Hardcoded passwords, API keys, secrets, tokens in source code

**Weak Authentication:**

```bash
grep -rn "password\.length\|minLength.*password" --include="*.ts" --include="*.js"
```

Look for: Weak password requirements (<8 chars), missing complexity checks

**Missing Authorization:**

```bash
grep -rn "router\.\(get\|post\|put\|delete\)" --include="*.ts" --include="*.js"
```

Look for: Routes without authentication middleware, missing role checks

**JWT Issues:**

```bash
grep -rn "jwt\.sign.*algorithm.*none\|jwt\.verify.*algorithms.*\[\]" --include="*.ts" --include="*.js"
```

Look for: JWT with "none" algorithm, missing algorithm verification

### Data Exposure Issues

**Sensitive Data in Logs:**

```bash
grep -rn "console\.log.*password\|console\.log.*token\|console\.log.*secret" --include="*.ts" --include="*.js"
```

Look for: Passwords, tokens, secrets in console.log statements

**Secrets in Environment Files:**

```bash
grep -rn "API_KEY\|SECRET\|PASSWORD\|TOKEN" .env .env.example
```

Look for: Actual secrets in .env files (should be in .env.example as placeholders only)

**Client-Side Secrets:**

```bash
grep -rn "process\.env\." --include="*.tsx" --include="*.jsx"
```

Look for: Environment variables accessed in client-side React components

**Verbose Error Messages:**

```bash
grep -rn "error\.stack\|error\.message.*res\.send\|throw.*Error.*password" --include="*.ts" --include="*.js"
```

Look for: Stack traces sent to client, error messages exposing system details

### Cryptography Issues

**Weak Algorithms:**

```bash
grep -rn "createHash.*md5\|createHash.*sha1\|crypto\.MD5\|crypto\.SHA1" --include="*.ts" --include="*.js"
```

Look for: MD5, SHA1 usage for security-sensitive operations

**Insecure Randomness:**

```bash
grep -rn "Math\.random" --include="*.ts" --include="*.js"
```

Look for: Math.random() for tokens, session IDs, cryptographic keys

**Hardcoded Encryption Keys:**

```bash
grep -rn "encrypt.*key.*=.*['\"]" --include="*.ts" --include="*.js"
```

Look for: Encryption keys hardcoded in source

**Improper Certificate Validation:**

```bash
grep -rn "rejectUnauthorized.*false\|NODE_TLS_REJECT_UNAUTHORIZED.*0" --include="*.ts" --include="*.js"
```

Look for: Disabled SSL/TLS certificate validation

### Dependency Vulnerabilities

**Check for Known Vulnerabilities:**

```bash
npm audit --json
# or
yarn audit --json
```

Look for: Packages with known CVEs, outdated dependencies with security patches

**Check Package Integrity:**

```bash
grep -rn "http://registry\|--ignore-scripts" package.json
```

Look for: Insecure registry URLs, disabled install scripts (security bypass)

## Severity Mapping

Use these criteria when classifying security findings:

| Vulnerability Type                           | Severity | Rationale                       |
| -------------------------------------------- | -------- | ------------------------------- |
| SQL injection                                | critical | Database compromise, data theft |
| Command injection                            | critical | Remote code execution           |
| Hardcoded credentials in production code     | critical | Unauthorized access             |
| Authentication bypass                        | critical | Complete security failure       |
| XSS with user data                           | high     | Account takeover, data theft    |
| Missing authentication on sensitive routes   | high     | Unauthorized access to data     |
| Secrets in logs                              | high     | Credential exposure             |
| Weak cryptography (MD5/SHA1 for passwords)   | high     | Password cracking               |
| Path traversal                               | high     | Arbitrary file access           |
| Missing authorization checks                 | medium   | Privilege escalation risk       |
| Insecure randomness (Math.random for tokens) | medium   | Token prediction                |
| Verbose error messages                       | medium   | Information disclosure          |
| Outdated dependencies with CVEs              | medium   | Known vulnerability exposure    |
| Weak password requirements                   | medium   | Brute force risk                |
| Missing HTTPS enforcement                    | medium   | Man-in-the-middle risk          |
| Disabled certificate validation              | medium   | MITM attacks possible           |
| Secrets in .env.example                      | nitpick  | Best practice violation         |
| console.log with non-sensitive data          | nitpick  | Production noise                |

## Analysis Priority

1. **Run automated security scan first** (Semgrep if available)
2. **Parse scan outputs** for critical/high severity issues
3. **Check for hardcoded secrets** (grep patterns above)
4. **Audit authentication/authorization** in routes and middleware
5. **Inspect input validation** at API boundaries
6. **Review cryptography usage** for weak algorithms
7. **Check dependencies** for known vulnerabilities
8. **Cross-reference findings** (e.g., missing auth + XSS = higher priority)

If performing comprehensive Prisma code review covering security vulnerabilities and performance anti-patterns, use the reviewing-prisma-patterns skill from prisma-6 for systematic validation.

## Common Vulnerability Examples

### XSS Example

```typescript
// VULNERABLE
element.innerHTML = userInput;
<div dangerouslySetInnerHTML={{ __html: data }} />;

// SECURE
element.textContent = userInput;
<div>{DOMPurify.sanitize(data)}</div>;
```

### SQL Injection Example

```typescript
// VULNERABLE
db.query("SELECT * FROM users WHERE id = " + userId);
db.query(\`SELECT * FROM users WHERE email = '\${email}'\`);

// SECURE
db.query("SELECT * FROM users WHERE id = ?", [userId]);
db.query("SELECT * FROM users WHERE email = $1", [email]);
```

If reviewing Prisma 6 SQL injection prevention patterns, use the preventing-sql-injection skill from prisma-6 for $queryRaw guidance.

### Command Injection Example

```typescript
// VULNERABLE
exec(\`ping \${userInput}\`);

// SECURE
execFile('ping', [userInput]);
```

### Insecure Randomness Example

```typescript
// VULNERABLE
const sessionId = Math.random().toString(36);

// SECURE
const sessionId = crypto.randomBytes(32).toString('hex');
```

## Integration Notes

- This skill provides detection methods and severity mapping only
- Output formatting is handled by the calling agent
- Prioritize automated Semgrep scan results over manual inspection
- Manual patterns supplement automated findings
- All findings must map to specific file:line locations

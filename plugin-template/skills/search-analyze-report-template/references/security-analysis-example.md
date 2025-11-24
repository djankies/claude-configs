# Security Analysis Example

This reference demonstrates a complete security vulnerability analysis workflow.

## Complete Example: SQL Injection Audit

### Search Phase

```
Pattern: Direct string concatenation in SQL queries
Files searched: **/*.{ts,js,tsx,jsx}
Patterns:
  - `${.*}` within SQL template strings
  - String concatenation with + in query building
```

### Analysis Phase

**Findings categorized by severity:**

**CRITICAL (Immediate Data Exposure):**
1. User-controlled input directly concatenated
2. No input validation present
3. Database returns sensitive data

**HIGH (Potential Exploitation):**
1. Partial validation but bypassable
2. Input sanitization incomplete
3. Error messages expose schema

**MEDIUM (Defense-in-Depth):**
1. Validated input but vulnerable pattern
2. Prepared statement alternatives available

### Report Phase

## Security Audit Report

### Summary
- Total vulnerabilities: 26
- Critical: 5
- High: 12
- Medium: 9

### Critical Issues

#### 1. Unsanitized User Input in Query (src/api/users.ts:45)
```typescript
const query = `SELECT * FROM users WHERE id = ${req.params.id}`;
```

**Risk:** Direct SQL injection via user-controlled parameter

**Recommendation:**
```typescript
const query = 'SELECT * FROM users WHERE id = ?';
db.execute(query, [req.params.id]);
```

**Impact:** Full database compromise, data exfiltration

---

### High Priority Issues

#### 2. Dynamic Table Name Construction (src/api/reports.ts:78)
...

## Actionable Recommendations

1. **Immediate:** Fix all Critical issues within 24 hours
2. **Short-term:** Implement parameterized queries across codebase
3. **Long-term:** Add SQL injection testing to CI/CD pipeline

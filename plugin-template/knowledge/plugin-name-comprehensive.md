# {Plugin Name} Comprehensive Knowledge Base

**Version**: {version}
**Release Date**: {YYYY-MM-DD}
**Last Updated**: {YYYY-MM-DD}

This document serves as the single source of truth for {plugin name} API patterns, breaking changes, and best practices. All skills should reference this document rather than duplicating information.

## Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Installation & Upgrade](#installation--upgrade)
4. [Core Concepts](#core-concepts)
5. [API Reference](#api-reference)
6. [Breaking Changes](#breaking-changes)
7. [Migration Guide](#migration-guide)
8. [Common Gotchas](#common-gotchas)
9. [Anti-Patterns](#anti-patterns)
10. [Performance Considerations](#performance-considerations)

---

## Overview

Brief description of the library/framework and major changes in this version.

**Key Features:**
- Feature 1
- Feature 2
- Feature 3

**Official Documentation**: {link}
**Upgrade Guide**: {link}
**Release Notes**: {link}

---

## System Requirements

| Component | Minimum Version | Notes |
|-----------|----------------|-------|
| Node.js   | 20.9.0 (LTS)  | Required |
| {dep}     | {version}     | ... |

---

## Installation & Upgrade

### New Projects

```bash
npm install {package}@{version}
```

### Upgrading Existing Projects

```bash
npm install {package}@latest
```

**Breaking changes to address:** [Link to section](#breaking-changes)

---

## Core Concepts

### Concept 1

Explanation of core concept...

**Example:**
```typescript
// Example demonstrating concept
```

### Concept 2

Explanation of another core concept...

---

## API Reference

### Category 1

#### `apiFunction(param: Type): ReturnType`

**Description:** What this function does

**Parameters:**
- `param` (Type): Description of parameter

**Returns:** Description of return value

**Example:**
```typescript
const result = apiFunction(value);
```

**Common mistakes:**
- ❌ Mistake 1 - Why it's wrong
- ❌ Mistake 2 - Why it's wrong

**Best practices:**
- ✅ Best practice 1
- ✅ Best practice 2

---

## Breaking Changes

### Breaking Change 1: {Title}

**What changed:** Description of the change

**Why:** Reason for the breaking change

**Impact:** Who is affected and how

**Migration path:**

**Before (deprecated):**
```typescript
// Old code that no longer works
```

**After (current):**
```typescript
// New code following current best practices
```

---

## Migration Guide

### From Version X.0 to Version Y.0

Step-by-step migration instructions...

1. **Update dependencies**
   ```bash
   npm install {package}@{version}
   ```

2. **Address breaking change 1**
   - What to change
   - Why to change it
   - Code examples

3. **Address breaking change 2**
   - What to change
   - Why to change it
   - Code examples

4. **Test thoroughly**
   - What to test
   - How to test it

---

## Common Gotchas

### Gotcha 1: {Title}

**Problem:** Description of the gotcha

**Symptoms:**
- Symptom 1
- Symptom 2

**Solution:**
```typescript
// Code showing the solution
```

**Why it works:** Explanation

---

## Anti-Patterns

### Anti-Pattern 1: {Title}

**Don't:**
```typescript
// Bad code demonstrating anti-pattern
```

**Problem:** Why this is an anti-pattern

**Do:**
```typescript
// Good code showing the correct pattern
```

**Why:** Explanation of why the correct pattern is better

---

## Performance Considerations

### Consideration 1: {Title}

**Impact:** Description of performance impact

**Example:**
```typescript
// Code demonstrating performance consideration
```

**Measurement:** How to measure the impact

**Best practices:**
- Best practice 1
- Best practice 2

---

## Additional Resources

- **Official Documentation**: {link}
- **Release Notes**: {link}
- **Community Resources**: {link}
- **GitHub Repository**: {link}
- **Examples**: {link}

---

**Related Skills:**
- `@{plugin-name}/skill-1` - Description
- `@{plugin-name}/skill-2` - Description

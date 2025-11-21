---
description: TypeScript operations - check types, fix errors, or extract/refactor types
argument-hint: (check|fix|extract) <file>
allowed-tools: Skill
---

Execute TypeScript operations using specialized skills.

Operation: $1
Target file: $2

Based on the operation requested, use the appropriate skill:

## check

Analyze TypeScript errors and provide detailed diagnostics for **$2**.

Use the TypeScript Type Checking skill:

@typescript/TYPES-check

## fix

Resolve all TypeScript errors in **$2**.

Use the TypeScript Error Resolution skill:

@typescript/TYPES-fix

## extract

Refactor inline types into reusable type definitions for **$2**.

Use the TypeScript Type Extraction skill:

@typescript/TYPES-extract

## Invalid Operation

If `$1` is not one of (check|fix|extract), show usage:

```
Usage: /ts (check|fix|extract) <file>

Operations:
  check   - Analyze TypeScript errors with detailed diagnostics
  fix     - Resolve all TypeScript errors with root cause analysis
  extract - Refactor inline types into reusable modules
```

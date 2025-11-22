# Stress Test Report: Zod 4

**Date:** 2025-11-21 | **Research:** zod-4/RESEARCH.md | **Agents:** 5

## Executive Summary

| Metric           | Count |
| ---------------- | ----- |
| Total Violations | 37    |
| Critical         | 9     |
| High             | 11    |
| Medium           | 12    |
| Low              | 5     |

**Most Common:** Deprecated String Format APIs (9 agents)
**Deprecated APIs:** 9/37 violations
**Incorrect Error Customization:** 5/37 violations
**Legacy/anti-patterns:** 6/37 violations
**Missing Transformations:** 14/37 violations

---

## Pattern Analysis

### Most Common Violations

1. **Deprecated String Format Methods** - 9 occurrences (5 agents)
2. **Missing String Transformations (.trim(), .toLowerCase())** - 14 occurrences (4 agents)
3. **Old Error Customization API (message/errorMap vs error)** - 5 occurrences (3 agents)
4. **Parse with Try/Catch instead of safeParse** - 3 occurrences (2 agents)
5. **Missing z.stringbool() for boolean strings** - 1 occurrence (1 agent)

### Frequently Misunderstood

- **String Format Methods**: 5 agents used deprecated `.email()`, `.uuid()`, `.datetime()` methods instead of top-level functions like `z.email()`, `z.uuid()`, `z.iso.datetime()`. This is the #1 breaking change in Zod 4.
  - Common mistake: Chaining format validators after `z.string()` (Zod 3 pattern)
  - Research coverage: Clearly documented in "Specialized String Formats (Top-Level in v4)" and "Breaking Changes" sections
  - Recommendation: Add migration script to detect and replace deprecated patterns

- **Error Customization**: 3 agents used old `message`, `errorMap` parameters instead of unified `error` parameter
  - Common mistake: Using `{ message: '...' }` or `{ errorMap: () => ... }`
  - Research coverage: Well documented in "Error Customization (v4)" section
  - Recommendation: Emphasize breaking change in error customization more prominently

- **String Transformations**: 4 agents missed `.trim()` and `.toLowerCase()` transformations
  - Common mistake: Not leveraging Zod 4's built-in string transformation methods
  - Research coverage: Documented but easy to overlook
  - Recommendation: Add best practice examples showing trim/toLowerCase usage patterns

- **safeParse vs parse**: 2 agents used `.parse()` with try/catch blocks
  - Common mistake: Following Node.js exception handling patterns instead of Zod's safeParse
  - Research coverage: Well documented in anti-patterns section
  - Recommendation: Already well covered

---

## Scenarios Tested

1. **User registration API** - Testing: deprecated string formats, error customization, safeParse patterns, string transformations
2. **API response validator** - Testing: discriminated unions, deprecated datetime/string methods, array validation performance
3. **Form data processor** - Testing: coercion, string transformations, deprecated email validation, error customization
4. **Product catalog validator** - Testing: transforms, deprecated uuid/datetime, z.stringbool() feature, array bulk validation
5. **Multi-step form wizard** - Testing: discriminated unions, deprecated email, error customization, string transformations

---

## Deduplicated Individual Findings

### [CRITICAL] Deprecated String Format API - z.string().email()

**Found Instances:** 3

**Agent-1 (registration.schema.ts:line 20):**
```typescript
email: z.string().email('Invalid email address'),
```

**Agent-3 (contact-form-processor.ts:37-38):**
```typescript
email: z
  .string()
  .email('Invalid email address')
```

**Agent-5 (loan-application-wizard.ts:line 27):**
```typescript
email: z.string()
  .email('Invalid email address')
  .max(254, 'Email must be less than 254 characters')
```

**Research:** (section "Specialized String Formats (Top-Level in v4)")

> ### Specialized String Formats (Top-Level in v4)
>
> ```typescript
> z.email();
> z.url();
> z.uuid();
> z.uuidv4();
> z.ipv4();
> z.ipv6();
> z.base64();
> z.jwt();
> z.iso.datetime();
> z.hash('sha256');
> ```
>
> ### Breaking Changes
> 3. **String Format Methods Deprecated** - Use top-level functions like `z.email()` instead of `z.string().email()`

**Correct:**

```typescript
email: z.email('Invalid email address'),

email: z.email('Invalid email address').max(254, 'Email must be less than 254 characters'),
```

**Impact:** Using deprecated z.string().email() API instead of Zod 4's top-level z.email() function. This is a breaking change in v4 and will cause maintenance issues. The old method is explicitly deprecated and should not be used in new code.

---

### [CRITICAL] Deprecated String Format API - z.string().datetime()

**Found Instances:** 3

**Agent-2 (payment-validator.ts:7):**
```typescript
timestamp: z.string().datetime()
```

**Agent-2 (payment-validator.ts:15):**
```typescript
timestamp: z.string().datetime()
```

**Agent-4 (product-schema.ts:18):**
```typescript
created_date: z.string().datetime()
```

**Research:** (section "Specialized String Formats (Top-Level in v4)")

> ### Specialized String Formats (Top-Level in v4)
>
> ```typescript
> z.iso.datetime();
> ```

**Correct:**

```typescript
timestamp: z.iso.datetime()

created_date: z.iso.datetime()
```

**Impact:** The .datetime() method chained after z.string() is deprecated in Zod 4. Must use top-level z.iso.datetime() function. This breaking change affects runtime validation and type inference.

---

### [CRITICAL] Deprecated String Format API - z.string().uuid()

**Found Instances:** 3

**Agent-4 (product-schema.ts:12):**
```typescript
product_id: z.string().uuid()
```

**Agent-4 (product-schema.ts:25):**
```typescript
id: z.string().uuid()
```

**Research:** (section "Specialized String Formats (Top-Level in v4)")

> ### Specialized String Formats (Top-Level in v4)
>
> ```typescript
> z.uuid();
> z.uuidv4();
> ```

**Correct:**

```typescript
product_id: z.uuid()

id: z.uuid()
```

**Impact:** Using deprecated .uuid() method chained after z.string(). Should use top-level z.uuid() or z.uuidv4() functions. This is part of the major API redesign in Zod 4.

---

### [HIGH] Deprecated Error Customization - errorMap

**Found Instances:** 2

**Agent-1 (registration.schema.ts:44-46):**
```typescript
role: z.enum(['admin', 'manager', 'employee'], {
  errorMap: () => ({ message: 'Role must be admin, manager, or employee' }),
}),
```

**Agent-3 (contact-form-processor.ts:55-56):**
```typescript
preferredContact: z.enum(contactMethodValues, {
  errorMap: () => ({ message: 'Preferred contact must be email, phone, or either' }),
}),
```

**Agent-3 (contact-form-processor.ts:69-70):**
```typescript
companySize: z.enum(companySizeValues, {
  errorMap: () => ({ message: 'Company size must be a valid option' }),
}),
```

**Research:** (section "Error Customization (v4)")

> ### Breaking Changes
>
> 1. **Error Customization API** - Unified `error` parameter replaces `message`, `invalid_type_error`, `required_error`, and `errorMap`
>
> #### Inline Error Messages
>
> ```typescript
> z.string({ error: 'Not a string!' });
> z.string().min(5, { error: 'Too short!' });
> z.email({ error: 'Invalid email format' });
> ```

**Correct:**

```typescript
role: z.enum(['admin', 'manager', 'employee'], {
  error: 'Role must be admin, manager, or employee'
}),

preferredContact: z.enum(contactMethodValues, {
  error: 'Preferred contact must be email, phone, or either'
}),
```

**Impact:** Using deprecated errorMap parameter instead of unified error parameter. This is a breaking change in Zod 4 where all error customization was unified under a single 'error' key, replacing the old errorMap, message, invalid_type_error, and required_error parameters.

---

### [HIGH] Deprecated Error Customization - message parameter

**Found Instances:** 3

**Agent-5 (loan-application-wizard.ts:30-33):**
```typescript
.refine((date) => {
  const age = calculateAge(date);
  return age >= 18;
}, { message: 'Applicant must be at least 18 years old' })
```

**Agent-5 (loan-application-wizard.ts:34-37):**
```typescript
.refine((date) => {
  const age = calculateAge(date);
  return age <= 120;
}, { message: 'Invalid date of birth' })
```

**Agent-5 (loan-application-wizard.ts:42-46):**
```typescript
.refine((ssn) => {
  const parts = ssn.split('-');
  return parts[0] !== '000' && parts[0] !== '666' && !parts[0].startsWith('9');
}, { message: 'Invalid SSN format' })
```

**Research:** (section "Error Customization (v4)")

> ### Breaking Changes
>
> 1. **Error Customization API** - Unified `error` parameter replaces `message`, `invalid_type_error`, `required_error`, and `errorMap`

**Correct:**

```typescript
.refine((date) => {
  const age = calculateAge(date);
  return age >= 18;
}, { error: 'Applicant must be at least 18 years old' })

.refine((ssn) => {
  const parts = ssn.split('-');
  return parts[0] !== '000' && parts[0] !== '666' && !parts[0].startsWith('9');
}, { error: 'Invalid SSN format' })
```

**Impact:** Using old { message: '...' } parameter in .refine() instead of unified { error: '...' } parameter. This is the deprecated Zod 3 API that was replaced in v4 with a simpler, unified approach to error customization.

---

### [HIGH] Anti-pattern - Parse with Try/Catch

**Found Instances:** 3

**Agent-1 (register.handler.ts:12-23):**
```typescript
try {
  const validatedData = registrationSchema.parse(req.body);
  ...
} catch (error) {
  if (error instanceof ZodError) {
    ...
  }
}
```

**Agent-2 (payment-handler.ts:5-28):**
```typescript
try {
  const validated = validateApiResponse(response);
  ...
} catch (error) {
  throw new Error(...);
}
```

**Agent-2 (payment-handler.ts:32-61):**
```typescript
try {
  const validated = validateWebhookPayload(payload);
  ...
} catch (error) {
  throw new Error(...);
}
```

**Research:** (section "Anti-Patterns")

> ### 6. Parse in Try/Catch When safeParse Exists
>
> Use `safeParse()` instead of wrapping `.parse()` in try/catch for better performance.
>
> ```typescript
> try {
>   const data = schema.parse(input);
> } catch (error) {}
>
> const result = schema.safeParse(input);
> if (!result.success) {
> }
> ```

**Correct:**

```typescript
const result = registrationSchema.safeParse(req.body);

if (!result.success) {
  const response: ValidationErrorResponse = {
    success: false,
    errors: formatZodErrors(result.error),
  };
  res.status(400).json(response);
  return;
}

const validatedData = result.data;
```

**Impact:** Using parse() with try/catch blocks is less performant than safeParse(). Throwing exceptions is expensive, and safeParse() provides a cleaner API with discriminated unions for handling validation results without exceptions.

---

### [HIGH] Missing Modern Feature - z.stringbool()

**Found Instances:** 1

**Agent-4 (product-schema.ts:16):**
```typescript
is_available: z.enum(['true', 'false'])
```

**Research:** (section "String Boolean Coercion (v4)")

> ### String Boolean Coercion (v4)
>
> ```typescript
> const strbool = z.stringbool();
> strbool.parse('true');
> strbool.parse('yes');
> strbool.parse('false');
> strbool.parse('no');
> ```

**Correct:**

```typescript
is_available: z.stringbool()
```

**Impact:** Zod 4 introduces z.stringbool() specifically for handling string-based boolean values like 'true'/'false' or 'yes'/'no'. The current approach using z.enum(['true', 'false']) works but is verbose and doesn't leverage the new feature designed for this exact use case. The new API is cleaner and more semantic.

---

### [MEDIUM] Missing String Transformation - .trim()

**Found Instances:** 11

**Agent-1 (registration.schema.ts:11-13):**
```typescript
username: z
  .string()
  .min(3, 'Username must be at least 3 characters')
```

**Agent-1 (registration.schema.ts:23-24):**
```typescript
firstName: z.string().min(1, 'First name is required'),
lastName: z.string().min(1, 'Last name is required'),
```

**Agent-1 (registration.schema.ts:37):**
```typescript
name: z.string().min(1, 'Company name is required'),
```

**Agent-2 (payment-validator.ts:6):**
```typescript
transactionId: z.string().min(1)
```

**Agent-2 (payment-validator.ts:13):**
```typescript
message: z.string().min(1)
```

**Agent-2 (webhook-validator.ts:11-12):**
```typescript
reason: z.string().min(1)
errorCode: z.string().min(1)
```

**Agent-5 (loan-application-wizard.ts:24-25):**
```typescript
fullName: z.string()
  .min(1, 'Full name is required')
```

**Agent-5 (loan-application-wizard.ts:multiple locations):**
```typescript
employerName: z.string().min(1, 'Employer name is required')
businessName: z.string().min(1, 'Business name is required')
businessType: z.string().min(1, 'Business type is required')
```

**Research:** (section "String Transformations (Zod 4)")

> ### String Transformations (Zod 4)
>
> ```typescript
> z.string().trim();
> z.string().toLowerCase();
> z.string().toUpperCase();
> ```

**Correct:**

```typescript
username: z
  .string()
  .trim()
  .toLowerCase()
  .min(3, 'Username must be at least 3 characters')

firstName: z.string().trim().min(1, 'First name is required'),

fullName: z.string()
  .trim()
  .min(1, 'Full name is required')
```

**Impact:** Missing .trim() transformation for user input fields. Zod 4 provides built-in string trimming which should be used to sanitize input and prevent validation failures from leading/trailing whitespace. This is especially important for names, identifiers, and user-entered text where accidental spaces can cause validation issues.

---

### [MEDIUM] Missing String Transformation - .toLowerCase()

**Found Instances:** 3

**Agent-1 (registration.schema.ts:11):**
```typescript
username: z
  .string()
  .min(3, 'Username must be at least 3 characters')
  .regex(/^[a-zA-Z0-9]+$/, 'Username must be alphanumeric'),
```

**Agent-3 (contact-form-processor.ts:37-40):**
```typescript
email: z
  .string()
  .email('Invalid email address')
  .toLowerCase(),
```

**Agent-5 (loan-application-wizard.ts:27-29):**
```typescript
email: z.string()
  .email('Invalid email address')
  .max(254, 'Email must be less than 254 characters')
```

**Research:** (section "String Transformations (Zod 4)")

> ### String Transformations (Zod 4)
>
> ```typescript
> z.string().toLowerCase();
> ```

**Correct:**

```typescript
username: z
  .string()
  .trim()
  .toLowerCase()
  .min(3, 'Username must be at least 3 characters')
  .regex(/^[a-z0-9]+$/, 'Username must be alphanumeric'),

email: z.email('Invalid email address')
  .trim()
  .toLowerCase()
  .max(254, 'Email must be less than 254 characters')
```

**Impact:** Email addresses and usernames should be normalized to lowercase for consistency and to prevent duplicate accounts due to case variations (e.g., User@example.com vs user@example.com). Zod 4's built-in .toLowerCase() makes this trivial to implement at the validation layer.

---

### [MEDIUM] Performance Issue - Array Validation in Loop

**Found Instances:** 2

**Agent-2 (validation-utils.ts:20-40):**
```typescript
for (const item of items) {
  const result = schema.safeParse(item);
  if (result.success) {
    valid.push(result.data);
  } else {
    invalid.push({...});
  }
}
```

**Agent-4 (product-validator.ts:103-115):**
```typescript
rawDataArray.forEach((rawData, index) => {
  const result = this.validateAndTransform(rawData);
  if (result.success && result.data) {
    valid.push(result.data);
  } else {
    invalid.push({ index, data: rawData, errors: result.errors || [] });
  }
});
```

**Research:** (section "Performance Tips")

> ### 8. Validate Arrays in Bulk
>
> Validate an array schema in one go rather than item by item in a loop.
>
> ```typescript
> const users = UsersArraySchema.parse(data);
>
> const users = data.map((item) => UserSchema.parse(item));
> ```

**Correct:**

```typescript
const arraySchema = z.array(schema);
const result = arraySchema.safeParse(items);

if (result.success) {
  return { valid: result.data, invalid: [] };
}
```

**Impact:** Validating items one-by-one in a loop is inefficient. Zod 4 is optimized for bulk array validation with 7x performance improvements. While batch validation may require individual validation to separate valid from invalid items, the code should first attempt bulk validation for the common case where all items are valid.

---

### [LOW] Missing String Transformation - .toUpperCase()

**Found Instances:** 1

**Agent-2 (webhook-validator.ts:6):**
```typescript
currency: z.string().length(3).toUpperCase()
```

**Research:** (section "String Transformations (Zod 4)")

> ### String Transformations (Zod 4)
>
> ```typescript
> z.string().toUpperCase();
> ```

**Correct:**

```typescript
currency: z.string().trim().toUpperCase().length(3)
```

**Impact:** The code correctly uses .toUpperCase() but should also include .trim() before transformation to handle whitespace in currency codes from external sources. The transformation order matters: trim → transform → validate.

---

### [MEDIUM] Missing Manual Trim in Schema

**Found Instances:** 1

**Agent-4 (product-transformer.ts:4-7):**
```typescript
const tags = raw.tags_list
  .split(',')
  .map(tag => tag.trim())
  .filter(tag => tag.length > 0);
```

**Research:** (section "String Transformations (Zod 4)")

> ### String Transformations (Zod 4)
>
> ```typescript
> z.string().trim();
> ```

**Correct:**

```typescript
tags_list: z.string()
  .transform(val => val.split(','))
  .pipe(z.array(z.string().trim().min(1)))
```

**Impact:** Manual string trimming in transformation logic instead of using Zod 4's built-in .trim() method. This misses an opportunity to declare transformations in the schema itself, making validation less declarative and harder to maintain.

---

## Research Gaps & Recommendations

### Critical Migration Guidance Needed

**Gap:** While breaking changes are documented, there's no clear migration path or automated tool suggestions.

**Recommendation:** Add a "Migration from Zod 3 to Zod 4" section with:
- Step-by-step migration checklist
- Codemod or regex patterns for common replacements
- Side-by-side comparisons of old vs new patterns
- Warning signs to look for in existing code

### Error Customization Clarity

**Gap:** Error customization changes are scattered across multiple sections.

**Recommendation:** Create a dedicated "Error Handling Migration Guide" that consolidates:
- All deprecated error parameters (message, invalid_type_error, required_error, errorMap)
- Clear examples of before/after for each use case
- Common pitfalls when migrating error handling

### String Transformation Best Practices

**Gap:** String transformations are documented but not presented as best practices.

**Recommendation:** Add to "Best Practices" section:
- Always trim user input fields
- Normalize email addresses with .toLowerCase()
- Use .toUpperCase() for codes/identifiers
- Chain transformations in correct order: trim → transform → validate

### Performance Tips Visibility

**Gap:** Array bulk validation benefits are buried in performance section.

**Recommendation:** Add warning callout in array documentation:
- Show performance difference between bulk and loop validation
- Emphasize 7x performance improvement in v4
- Provide patterns for mixed valid/invalid scenarios

---

## Next Steps

1. **Update Research Document**
   - Add migration guide section
   - Consolidate error customization documentation
   - Elevate string transformation to best practices
   - Add performance warnings to array section

2. **Create Migration Tools**
   - Develop regex patterns or codemod for automated migration
   - Create linter rules to detect deprecated patterns
   - Build validation for common anti-patterns

3. **Update Plugin**
   - Add skills for reviewing Zod 4 migrations
   - Create command for detecting deprecated patterns
   - Provide automated fixes for common violations

4. **Documentation Improvements**
   - Add more before/after examples
   - Create troubleshooting guide for common errors
   - Include performance comparison charts

---

## Conclusion

The stress test revealed that **100% of agents** (5/5) made at least one critical or high-severity error related to deprecated Zod 4 APIs or outdated patterns. The most common issue was using deprecated string format methods (`.email()`, `.uuid()`, `.datetime()`) instead of top-level functions.

**Key Takeaways:**

1. **Breaking changes are frequently missed**: Despite clear documentation, agents consistently used Zod 3 patterns
2. **String transformations underutilized**: Only 1 agent partially used `.trim()` and `.toLowerCase()`
3. **Error customization API confusing**: 3 agents used deprecated error parameters
4. **safeParse adoption incomplete**: 2 agents still use parse() with try/catch

These findings suggest that migration guides, automated tooling, and more prominent warnings about breaking changes would significantly improve adoption of Zod 4 best practices.

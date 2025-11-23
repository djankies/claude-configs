# Validation Error Handling

## Basic Error Handling

### Using safeParse

```typescript
const result = UserSchema.safeParse(data);

if (result.success) {
  const user: User = result.data;
  console.log(user.name);
} else {
  console.error("Validation failed:", result.error);
}
```

### Using parse (throwing)

```typescript
try {
  const user = UserSchema.parse(data);
  console.log(user.name);
} catch (error) {
  if (error instanceof z.ZodError) {
    console.error("Validation failed:", error.issues);
  }
}
```

## Processing Validation Issues

### Extracting Error Details

```typescript
if (!result.success) {
  const issues = result.error.issues.map(issue => ({
    path: issue.path.join("."),
    message: issue.message,
    code: issue.code
  }));

  throw new ValidationError("Invalid user data", issues);
}
```

### User-Friendly Error Messages

```typescript
function formatValidationError(error: z.ZodError): string {
  return error.issues
    .map(issue => {
      const field = issue.path.join(".");
      return `${field}: ${issue.message}`;
    })
    .join(", ");
}

try {
  const validated = validateLoginForm(form);
  await login(validated);
} catch (error) {
  if (error instanceof z.ZodError) {
    const message = formatValidationError(error);
    showError(message);
  }
}
```

## Error Recovery Strategies

### Fallback Values

```typescript
const result = ConfigSchema.safeParse(data);

const config = result.success
  ? result.data
  : getDefaultConfig();
```

### Partial Success

```typescript
function validateItemsWithPartialSuccess<T>(
  items: unknown[],
  schema: z.ZodType<T>
): { valid: T[], invalid: { item: unknown, error: z.ZodError }[] } {
  const valid: T[] = [];
  const invalid: { item: unknown, error: z.ZodError }[] = [];

  for (const item of items) {
    const result = schema.safeParse(item);
    if (result.success) {
      valid.push(result.data);
    } else {
      invalid.push({ item, error: result.error });
    }
  }

  return { valid, invalid };
}
```

## Custom Error Classes

```typescript
class ValidationError extends Error {
  constructor(
    message: string,
    public readonly issues: Array<{ path: string; message: string }>
  ) {
    super(message);
    this.name = "ValidationError";
  }
}

function validateOrThrow<T>(data: unknown, schema: z.ZodType<T>): T {
  const result = schema.safeParse(data);

  if (!result.success) {
    const issues = result.error.issues.map(issue => ({
      path: issue.path.join("."),
      message: issue.message
    }));
    throw new ValidationError("Validation failed", issues);
  }

  return result.data;
}
```

## Logging Validation Errors

```typescript
function validateWithLogging<T>(
  data: unknown,
  schema: z.ZodType<T>,
  context: string
): T | null {
  const result = schema.safeParse(data);

  if (!result.success) {
    logger.error({
      context,
      error: "Validation failed",
      issues: result.error.issues,
      data: sanitizeForLogging(data)
    });
    return null;
  }

  return result.data;
}
```

## API Error Responses

```typescript
app.post("/api/users", (req, res) => {
  const result = UserSchema.safeParse(req.body);

  if (!result.success) {
    return res.status(400).json({
      error: "Invalid request body",
      details: result.error.issues.map(issue => ({
        field: issue.path.join("."),
        message: issue.message
      }))
    });
  }

  const user = result.data;
});
```

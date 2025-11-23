# Zod Patterns Reference

## Advanced Schema Composition

### Union Types

```typescript
const SuccessResponseSchema = z.object({
  status: z.literal("success"),
  data: z.unknown()
});

const ErrorResponseSchema = z.object({
  status: z.literal("error"),
  error: z.string(),
  code: z.number()
});

const ApiResponseSchema = z.discriminatedUnion("status", [
  SuccessResponseSchema,
  ErrorResponseSchema
]);

type ApiResponse = z.infer<typeof ApiResponseSchema>;
```

### Transform and Coerce

```typescript
const DateSchema = z.string().datetime().transform(str => new Date(str));

const UserWithDatesSchema = z.object({
  id: z.string(),
  name: z.string(),
  createdAt: DateSchema,
  updatedAt: DateSchema
});

type UserWithDates = z.infer<typeof UserWithDatesSchema>;

const CoerceNumberSchema = z.coerce.number();

const QueryParamsSchema = z.object({
  page: CoerceNumberSchema.int().positive().default(1),
  limit: CoerceNumberSchema.int().min(1).max(100).default(20),
  sort: z.enum(["asc", "desc"]).default("asc")
});
```

### Custom Refinements

```typescript
const PasswordSchema = z
  .string()
  .min(8)
  .refine(
    password => /[A-Z]/.test(password),
    "Password must contain at least one uppercase letter"
  )
  .refine(
    password => /[a-z]/.test(password),
    "Password must contain at least one lowercase letter"
  )
  .refine(
    password => /[0-9]/.test(password),
    "Password must contain at least one number"
  );

const SignupSchema = z.object({
  email: z.string().email(),
  password: PasswordSchema,
  confirmPassword: z.string()
}).refine(
  data => data.password === data.confirmPassword,
  {
    message: "Passwords don't match",
    path: ["confirmPassword"]
  }
);
```

### Partial and Optional Schemas

```typescript
const UpdateUserSchema = UserSchema.partial();

type UpdateUser = z.infer<typeof UpdateUserSchema>;

async function updateUser(id: string, updates: unknown): Promise<User> {
  const validated = UpdateUserSchema.parse(updates);

  const response = await fetch(`/api/users/${id}`, {
    method: "PATCH",
    body: JSON.stringify(validated)
  });

  return UserSchema.parse(await response.json());
}
```

### Nested Objects

```typescript
const AddressSchema = z.object({
  street: z.string(),
  city: z.string(),
  state: z.string().length(2),
  zipCode: z.string().regex(/^\d{5}(-\d{4})?$/)
});

const UserWithAddressSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
  address: AddressSchema,
  billingAddress: AddressSchema.optional()
});

type UserWithAddress = z.infer<typeof UserWithAddressSchema>;
```

### Array Validation

```typescript
const TagSchema = z.string().min(1).max(20);

const PostSchema = z.object({
  id: z.string(),
  title: z.string().min(1).max(200),
  content: z.string(),
  tags: z.array(TagSchema).min(1).max(10),
  metadata: z.record(z.string(), z.unknown())
});

type Post = z.infer<typeof PostSchema>;

async function fetchPosts(): Promise<Post[]> {
  const response = await fetch("/api/posts");
  const data: unknown = await response.json();

  const PostsSchema = z.array(PostSchema);
  return PostsSchema.parse(data);
}
```

## Generic Validation Helpers

```typescript
async function apiCall<T>(
  endpoint: string,
  dataSchema: z.ZodType<T>
): Promise<T> {
  const response = await fetch(endpoint);
  const rawData: unknown = await response.json();

  const apiResponse = ApiResponseSchema.parse(rawData);

  if (apiResponse.status === "error") {
    throw new Error(`API Error ${apiResponse.code}: ${apiResponse.error}`);
  }

  return dataSchema.parse(apiResponse.data);
}
```

## Validation Middleware

```typescript
import { Request, Response, NextFunction } from "express";

function validateBody<T>(schema: z.ZodType<T>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return res.status(400).json({
        error: "Validation failed",
        issues: result.error.issues
      });
    }

    req.body = result.data;
    next();
  };
}

app.post("/users", validateBody(UserSchema), (req, res) => {
  const user: User = req.body;
});
```

## Safe JSON Parse

```typescript
function safeJsonParse<T>(
  json: string,
  schema: z.ZodType<T>
): T {
  try {
    const data: unknown = JSON.parse(json);
    return schema.parse(data);
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new Error("Invalid JSON");
    }
    throw error;
  }
}
```

## Configuration Validation

```typescript
const ConfigSchema = z.object({
  port: z.number().int().positive().default(3000),
  database: z.object({
    host: z.string(),
    port: z.number().int().positive(),
    name: z.string()
  }),
  redis: z.object({
    url: z.string().url()
  }).optional()
});

type Config = z.infer<typeof ConfigSchema>;

function loadConfig(): Config {
  const data: unknown = process.env;

  return ConfigSchema.parse({
    port: data.PORT,
    database: {
      host: data.DB_HOST,
      port: data.DB_PORT,
      name: data.DB_NAME
    },
    redis: data.REDIS_URL ? { url: data.REDIS_URL } : undefined
  });
}
```

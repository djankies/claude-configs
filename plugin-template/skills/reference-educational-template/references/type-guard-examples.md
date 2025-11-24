# Type Guard Examples

Comprehensive examples of TypeScript type guards and type narrowing patterns.

## Basic Type Guards

### typeof Guard
```typescript
function formatValue(value: string | number | boolean): string {
  if (typeof value === "string") {
    return value.toUpperCase();
  }

  if (typeof value === "number") {
    return value.toFixed(2);
  }

  return value ? "true" : "false";
}
```

### instanceof Guard
```typescript
class Dog {
  bark() { return "Woof!"; }
}

class Cat {
  meow() { return "Meow!"; }
}

function makeSound(animal: Dog | Cat): string {
  if (animal instanceof Dog) {
    return animal.bark();
  }
  return animal.meow();
}
```

### in Operator Guard
```typescript
interface Fish {
  swim: () => void;
}

interface Bird {
  fly: () => void;
}

function move(animal: Fish | Bird) {
  if ("swim" in animal) {
    animal.swim();
  } else {
    animal.fly();
  }
}
```

## Custom Type Predicates

### Basic Type Predicate
```typescript
function isString(value: unknown): value is string {
  return typeof value === "string";
}

function processValue(value: unknown) {
  if (isString(value)) {
    console.log(value.toUpperCase());
  }
}
```

### Object Type Predicate
```typescript
interface User {
  id: number;
  name: string;
}

function isUser(obj: unknown): obj is User {
  return (
    typeof obj === "object" &&
    obj !== null &&
    "id" in obj &&
    "name" in obj &&
    typeof obj.id === "number" &&
    typeof obj.name === "string"
  );
}
```

### Array Type Predicate
```typescript
function isStringArray(value: unknown): value is string[] {
  return (
    Array.isArray(value) &&
    value.every(item => typeof item === "string")
  );
}
```

## Advanced Patterns

### Discriminated Unions
```typescript
interface Success {
  type: "success";
  data: string;
}

interface Error {
  type: "error";
  message: string;
}

type Result = Success | Error;

function handleResult(result: Result) {
  if (result.type === "success") {
    console.log(result.data);
  } else {
    console.error(result.message);
  }
}
```

### Nullable Type Narrowing
```typescript
function processUser(user: User | null | undefined) {
  if (user == null) {
    return "No user";
  }

  return user.name;
}
```

### Array.isArray with Element Type
```typescript
function sumNumbers(values: unknown): number {
  if (!Array.isArray(values)) {
    throw new Error("Expected array");
  }

  return values.reduce((sum, val) => {
    if (typeof val !== "number") {
      throw new Error("Expected number array");
    }
    return sum + val;
  }, 0);
}
```

## Common Pitfalls

### ❌ Type Narrowing Doesn't Cross Function Boundaries
```typescript
function isString(value: unknown) {
  return typeof value === "string";
}

function process(value: unknown) {
  if (isString(value)) {
    value.toUpperCase();
  }
}
```

### ✓ Use Type Predicates Instead
```typescript
function isString(value: unknown): value is string {
  return typeof value === "string";
}

function process(value: unknown) {
  if (isString(value)) {
    value.toUpperCase();
  }
}
```

### ❌ Incomplete Object Validation
```typescript
function isUser(obj: unknown): obj is User {
  return typeof obj === "object" && "name" in obj;
}
```

### ✓ Validate All Properties
```typescript
function isUser(obj: unknown): obj is User {
  return (
    typeof obj === "object" &&
    obj !== null &&
    "id" in obj &&
    "name" in obj &&
    typeof obj.id === "number" &&
    typeof obj.name === "string"
  );
}
```

### ❌ Mutating Variables Breaks Narrowing
```typescript
function process(value: string | number) {
  if (typeof value === "string") {
    value = value.length;
    value.toFixed(2);
  }
}
```

### ✓ Use New Variables
```typescript
function process(value: string | number) {
  if (typeof value === "string") {
    const length = value.length;
    length.toFixed(2);
  }
}
```

## Real-World Examples

### API Response Validation
```typescript
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

function isSuccessResponse<T>(
  response: ApiResponse<T>
): response is ApiResponse<T> & { success: true; data: T } {
  return response.success === true && response.data !== undefined;
}

async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data: ApiResponse<User> = await response.json();

  if (isSuccessResponse(data)) {
    return data.data;
  }

  throw new Error(data.error || "Unknown error");
}
```

### Event Handler Type Guards
```typescript
function handleEvent(event: MouseEvent | KeyboardEvent) {
  if ("key" in event) {
    console.log(`Key pressed: ${event.key}`);
  } else {
    console.log(`Mouse clicked at: ${event.clientX}, ${event.clientY}`);
  }
}
```

### Form Validation
```typescript
interface ContactForm {
  name: string;
  email: string;
  message: string;
}

function isValidContactForm(data: unknown): data is ContactForm {
  if (typeof data !== "object" || data === null) {
    return false;
  }

  const form = data as Record<string, unknown>;

  return (
    typeof form.name === "string" && form.name.length > 0 &&
    typeof form.email === "string" && /\S+@\S+\.\S+/.test(form.email) &&
    typeof form.message === "string" && form.message.length > 0
  );
}
```

## Performance Considerations

### Expensive Type Guards
```typescript
function isUserArray(value: unknown): value is User[] {
  return (
    Array.isArray(value) &&
    value.every(isUser)
  );
}
```

**Note:** This validates every element. For large arrays, consider:
- Sampling first N elements
- Lazy validation
- Runtime validation only in development

### Reusable Type Guards
```typescript
const typeGuards = {
  isString: (value: unknown): value is string =>
    typeof value === "string",

  isNumber: (value: unknown): value is number =>
    typeof value === "number",

  isArray: <T>(
    value: unknown,
    guard: (item: unknown) => item is T
  ): value is T[] =>
    Array.isArray(value) && value.every(guard)
};

if (typeGuards.isArray(data, typeGuards.isString)) {
  data.forEach(str => console.log(str.toUpperCase()));
}
```

## Summary

**Key Takeaways:**
1. Use `typeof` for primitives
2. Use `instanceof` for classes
3. Use `in` for object properties
4. Use type predicates for reusable guards
5. Use discriminated unions for tagged types
6. Always validate all properties in custom guards
7. Type narrowing doesn't cross function boundaries

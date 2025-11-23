# Testing Type Guards

Complete guide to unit testing type guards with comprehensive test cases.

## Testing Strategy

When testing type guards, ensure coverage for:

1. Valid inputs (happy path)
2. Missing required properties
3. Wrong property types
4. Null and undefined
5. Non-object primitives
6. Edge cases specific to your type

## Complete Test Suite Example

```typescript
describe("isUser", () => {
  it("returns true for valid user", () => {
    expect(isUser({ id: "1", name: "Alice", email: "alice@example.com" })).toBe(true);
  });

  it("returns false for missing property", () => {
    expect(isUser({ id: "1", name: "Alice" })).toBe(false);
  });

  it("returns false for wrong property type", () => {
    expect(isUser({ id: 1, name: "Alice", email: "alice@example.com" })).toBe(false);
  });

  it("returns false for null", () => {
    expect(isUser(null)).toBe(false);
  });

  it("returns false for undefined", () => {
    expect(isUser(undefined)).toBe(false);
  });

  it("returns false for non-object", () => {
    expect(isUser("not an object")).toBe(false);
  });
});
```

## Testing Array Guards

```typescript
describe("isStringArray", () => {
  it("returns true for array of strings", () => {
    expect(isStringArray(["a", "b", "c"])).toBe(true);
  });

  it("returns true for empty array", () => {
    expect(isStringArray([])).toBe(true);
  });

  it("returns false for mixed types", () => {
    expect(isStringArray(["a", 1, "c"])).toBe(false);
  });

  it("returns false for non-array", () => {
    expect(isStringArray("not array")).toBe(false);
  });
});
```

## Testing Assertion Functions

```typescript
describe("assertIsUser", () => {
  it("does not throw for valid user", () => {
    expect(() => assertIsUser({ id: "1", name: "Alice", email: "alice@example.com" })).not.toThrow();
  });

  it("throws for invalid user", () => {
    expect(() => assertIsUser({ id: "1" })).toThrow("Invalid user data");
  });

  it("throws for null", () => {
    expect(() => assertIsUser(null)).toThrow();
  });
});
```

## Test Coverage Checklist

- [ ] Valid inputs
- [ ] Each required property missing
- [ ] Each property with wrong type
- [ ] Null input
- [ ] Undefined input
- [ ] Non-object primitives
- [ ] Empty objects/arrays
- [ ] Nested object validation
- [ ] Optional properties (present and absent)
- [ ] Edge cases for your domain

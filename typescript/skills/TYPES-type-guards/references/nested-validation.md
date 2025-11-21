# Nested Type Guard Validation

Examples of validating complex nested object structures.

## Basic Nested Validation

```typescript
interface Address {
  street: string;
  city: string;
  zipCode: string;
}

interface UserWithAddress {
  id: string;
  name: string;
  address: Address;
}

function isAddress(value: unknown): value is Address {
  return (
    typeof value === "object" &&
    value !== null &&
    "street" in value &&
    "city" in value &&
    "zipCode" in value &&
    typeof (value as Address).street === "string" &&
    typeof (value as Address).city === "string" &&
    typeof (value as Address).zipCode === "string"
  );
}

function isUserWithAddress(value: unknown): value is UserWithAddress {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    "name" in value &&
    "address" in value &&
    typeof (value as UserWithAddress).id === "string" &&
    typeof (value as UserWithAddress).name === "string" &&
    isAddress((value as UserWithAddress).address)
  );
}
```

## Composable Guards Pattern

Build complex guards by composing simpler ones:

```typescript
function hasStringProperty(obj: unknown, key: string): boolean {
  return (
    typeof obj === "object" &&
    obj !== null &&
    key in obj &&
    typeof (obj as Record<string, unknown>)[key] === "string"
  );
}

function isUserWithAddress(value: unknown): value is UserWithAddress {
  return (
    hasStringProperty(value, "id") &&
    hasStringProperty(value, "name") &&
    typeof value === "object" &&
    value !== null &&
    "address" in value &&
    isAddress((value as UserWithAddress).address)
  );
}
```

## Deep Nesting Example

```typescript
interface Company {
  name: string;
  address: Address;
}

interface Employee {
  id: string;
  name: string;
  company: Company;
}

function isCompany(value: unknown): value is Company {
  return (
    typeof value === "object" &&
    value !== null &&
    "name" in value &&
    "address" in value &&
    typeof (value as Company).name === "string" &&
    isAddress((value as Company).address)
  );
}

function isEmployee(value: unknown): value is Employee {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    "name" in value &&
    "company" in value &&
    typeof (value as Employee).id === "string" &&
    typeof (value as Employee).name === "string" &&
    isCompany((value as Employee).company)
  );
}
```

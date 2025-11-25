# TypeScript Research

## Overview

- **Version**: 5.9.3 (Released October 1, 2025)
- **Purpose in Project**: Typed superset of JavaScript that compiles to plain JavaScript
- **Official Documentation**: https://www.typescriptlang.org/docs/
- **GitHub Repository**: https://github.com/microsoft/TypeScript
- **Last Updated**: November 19, 2025

## Installation

### Prerequisites

Before installing TypeScript, ensure Node.js and npm are installed on your machine.

### Global Installation

```bash
npm install -g typescript
```

This installs the latest stable version (currently 5.9.3) globally, making the TypeScript compiler `tsc` available system-wide.

### Local/Project Installation (Recommended)

```bash
npm install -D typescript
```

Installing TypeScript as a development dependency ensures each project uses a specific TypeScript version, preventing version conflicts and making the setup more reliable.

### Nightly Builds

```bash
npm install -D typescript@next
```

### Verifying Installation

```bash
tsc --version
```

This command prints the TypeScript compiler version installed on your machine.

### Initialization

```bash
tsc --init
```

Creates a `tsconfig.json` file in your project directory with prescriptive defaults.

## Core Concepts

### Type System Fundamentals

TypeScript adds optional types to JavaScript that support tools for large-scale JavaScript applications. It compiles to readable, standards-based JavaScript.

**Key Principles:**

- Optional static typing
- Type inference
- Structural type system
- Cross-platform compatibility (any browser, host, or OS)
- Superset of JavaScript (valid JavaScript is valid TypeScript)

### Primitive Types

JavaScript has three very commonly used primitives, each with a corresponding TypeScript type:

```typescript
let isDone: boolean = false;
let decimal: number = 6;
let color: string = 'blue';
```

### Arrays

```typescript
let list: number[] = [1, 2, 3];
let genericList: Array<number> = [1, 2, 3];
```

### Interfaces

Interfaces define the structure of objects and provide type checking:

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

const user: User = {
  id: 1,
  name: 'John Doe',
  email: 'john@example.com',
};
```

### Generics

Generics are a TypeScript feature that allows passing in various types of data and creating reusable code to handle different inputs:

```typescript
function createPair<S, T>(v1: S, v2: T): [S, T] {
  return [v1, v2];
}

console.log(createPair<string, number>('hello', 42));
```

**Generic Class:**

```typescript
class NamedValue<T> {
  private _value: T | undefined;

  constructor(private name: string) {}

  public setValue(value: T) {
    this._value = value;
  }

  public getValue(): T | undefined {
    return this._value;
  }

  public toString(): string {
    return `${this.name}: ${this._value}`;
  }
}
```

**Generic Interface:**

```typescript
interface Pair<K, V> {
  key: K;
  value: V;
}

interface Collection<T> {
  add(o: T): void;
  remove(o: T): void;
}
```

### Type Narrowing and Type Guards

Type guards are special checks that TypeScript uses to refine broad types into more specific types.

**typeof Type Guard:**

```typescript
function padLeft(padding: number | string, input: string): string {
  if (typeof padding === 'number') {
    return ' '.repeat(padding) + input;
  }
  return padding + input;
}
```

**instanceof Type Guard:**

```typescript
class Dog {
  bark() {
    console.log('Woof!');
  }
}

class Cat {
  meow() {
    console.log('Meow!');
  }
}

function makeSound(animal: Dog | Cat) {
  if (animal instanceof Dog) {
    animal.bark();
  } else {
    animal.meow();
  }
}
```

**in Operator:**

```typescript
interface Fish {
  swim: () => void;
}

interface Bird {
  fly: () => void;
}

function move(animal: Fish | Bird) {
  if ('swim' in animal) {
    animal.swim();
  } else {
    animal.fly();
  }
}
```

**Custom Type Guards (Type Predicates):**

```typescript
function isFish(pet: Fish | Bird): pet is Fish {
  return (pet as Fish).swim !== undefined;
}

function handlePet(pet: Fish | Bird) {
  if (isFish(pet)) {
    pet.swim();
  } else {
    pet.fly();
  }
}
```

### Async/Await and Promises

**Promise Type Annotation:**

```typescript
function fetchData(url: string): Promise<string> {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (Math.random() > 0.5) {
        resolve('Data fetched successfully!');
      } else {
        reject(new Error('Network error'));
      }
    }, 1000);
  });
}
```

**Async/Await with Type Annotations:**

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

async function getUser(id: number): Promise<User> {
  const response = await fetch(`https://api.example.com/users/${id}`);
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  const user = await response.json();
  return user;
}
```

**Error Handling:**

```typescript
async function fetchDataAsync(): Promise<void> {
  try {
    const result = await fetchData('https://api.example.com/data');
    console.log(result);
  } catch (error) {
    console.error('Error fetching data:', error);
  }
}
```

## Configuration

### tsconfig.json

Every TypeScript project requires a `tsconfig.json` file, which specifies the compiler configuration.

### TypeScript 5.9 Improved `tsc --init`

TypeScript 5.9 generates a more concise `tsconfig.json` with prescriptive defaults rather than extensive commented options.

**Key Default Settings in 5.9:**

- `moduleDetection: "force"`
- `target: "esnext"`
- Stricter type-checking settings like `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`

### Essential Configuration Options

**Recommended Base Configuration:**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",

    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,

    "incremental": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,

    "noImplicitOverride": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Important Compiler Options

**Type Checking:**

- `strict: true` - Enables all strict type checking options
- `noImplicitAny: true` - Explicitly type every variable
- `strictNullChecks: true` - Prevent null and undefined errors
- `noImplicitThis: true` - Error on implicit 'this' type
- `noUncheckedIndexedAccess: true` - Adds undefined to indexed access
- `exactOptionalPropertyTypes: true` - Differentiates between undefined and absent

**Module Resolution:**

- `module: "NodeNext"` - For Node.js projects (mirrors current Node.js behavior)
- `module: "node20"` - Stable option modeling Node.js v20 (will not change)
- `moduleResolution: "Bundler"` - For projects using modern bundlers
- `moduleResolution: "NodeNext"` - For Node.js projects

**Performance:**

- `incremental: true` - Enables incremental compilation (caches previous build)
- `skipLibCheck: true` - Skip type checking of declaration files

**Code Quality:**

- `forceConsistentCasingInFileNames: true` - Ensures case-sensitive file paths across platforms
- `noImplicitOverride: true` - Requires override keyword for overridden methods

**Migration Support:**

- `allowJs: true` - Accept JavaScript files as inputs (for gradual migration)

**Interoperability:**

- `esModuleInterop: true` - Refined type checking of imports
- `verbatimModuleSyntax: true` - Enforces explicit import/export syntax (TypeScript 5.0+)

### Base Configurations

TypeScript provides base configurations at https://github.com/tsconfig/bases which simplify your `tsconfig.json` by handling runtime support:

```json
{
  "extends": "@tsconfig/node20/tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist"
  }
}
```

## What's New in TypeScript 5.9

### Minimal and Updated `tsc --init`

The TypeScript compiler now generates a more concise `tsconfig.json` with prescriptive defaults rather than extensive commented options, addressing common pain points when creating new TypeScript projects.

### Support for `import defer`

TypeScript now supports ECMAScript's deferred module evaluation proposal, which defers module execution until first access of its exports:

```typescript
import defer * as feature from "./some-feature.js";

console.log(feature.specialConstant);
```

**Key Constraint:** Only namespace imports are permitted with `import defer`.

### Support for `--module node20`

A stable module option modeling Node.js v20 behavior, intended to remain unchanged. It will imply `--target es2023` unlike the floating `nodenext` option.

### DOM API Improvements

Summary descriptions were added to numerous DOM APIs based on MDN documentation, providing quick reference without navigating external links.

### Expandable Hovers (Preview)

A new preview feature allowing users to expand/collapse type information in editor tooltips via `+` and `-` buttons for deeper inspection in editors like VS Code.

### Configurable Maximum Hover Length

The `js/ts.hover.maximumLength` setting in VS Code now controls hover tooltip truncation, with substantially increased defaults.

### Performance Optimizations

- **Type instantiation caching** reduces redundant intermediate type calculations
- **Closure elimination** in file existence checks provides ~11% speed improvement
- Up to 10% faster incremental builds with smarter caching in many real-world setups

## Usage Patterns

### Basic Usage

**Type Annotations:**

```typescript
function greet(name: string): string {
  return `Hello, ${name}!`;
}

const result: string = greet('TypeScript');
```

**Object Types:**

```typescript
interface Point {
  x: number;
  y: number;
}

function printCoord(pt: Point) {
  console.log(`The coordinate's x value is ${pt.x}`);
  console.log(`The coordinate's y value is ${pt.y}`);
}

printCoord({ x: 3, y: 7 });
```

**Union Types:**

```typescript
function printId(id: number | string) {
  if (typeof id === 'string') {
    console.log(id.toUpperCase());
  } else {
    console.log(id);
  }
}

printId(101);
printId('202');
```

**Type Aliases:**

```typescript
type ID = number | string;
type Point = {
  x: number;
  y: number;
};

function printPoint(pt: Point) {
  console.log(`${pt.x}, ${pt.y}`);
}
```

### Advanced Patterns

**Utility Types:**

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  password: string;
}

type PartialUser = Partial<User>;

type RequiredUser = Required<User>;

type BasicUser = Pick<User, 'id' | 'name'>;

type SafeUser = Omit<User, 'password'>;

type ReadonlyUser = Readonly<User>;

type UserRecord = Record<string, User>;
```

**Mapped Types:**

```typescript
type Readonly<T> = {
  readonly [P in keyof T]: T[P];
};

type Optional<T> = {
  [P in keyof T]?: T[P];
};

type Nullable<T> = {
  [P in keyof T]: T[P] | null;
};
```

**Conditional Types:**

```typescript
type NonNullable<T> = T extends null | undefined ? never : T;

type ArrayElementType<T> = T extends (infer E)[] ? E : T;

type ReturnType<T extends (...args: any) => any> = T extends (...args: any) => infer R ? R : any;
```

**Distributive Conditional Types:**

```typescript
type ToArray<T> = T extends any ? T[] : never;

type StrOrNumArray = ToArray<string | number>;
```

**Template Literal Types:**

```typescript
type EmailLocale = 'welcome_email' | 'reset_password_email';

type EmailLocaleKey = `${EmailLocale}_subject` | `${EmailLocale}_body`;

type PropEventSource<Type> = {
  on(eventName: `${string & keyof Type}Changed`, callback: (newValue: any) => void): void;
};
```

### Integration Examples

**With Express.js:**

```typescript
import express, { Request, Response } from 'express';

interface CreateUserRequest {
  name: string;
  email: string;
}

const app = express();

app.post('/users', (req: Request<{}, {}, CreateUserRequest>, res: Response) => {
  const { name, email } = req.body;
  res.json({ id: 1, name, email });
});
```

**With React:**

```typescript
interface ButtonProps {
  label: string;
  onClick: () => void;
  disabled?: boolean;
}

const Button: React.FC<ButtonProps> = ({ label, onClick, disabled = false }) => {
  return (
    <button onClick={onClick} disabled={disabled}>
      {label}
    </button>
  );
};
```

**With Node.js and Promises:**

```typescript
import { readFile } from 'fs/promises';

async function loadConfig(path: string): Promise<Record<string, unknown>> {
  const content = await readFile(path, 'utf-8');
  return JSON.parse(content);
}

loadConfig('./config.json')
  .then((config) => console.log(config))
  .catch((error) => console.error(error));
```

## Modules and Import/Export

### ES Modules (ESM)

```typescript
export interface User {
  id: number;
  name: string;
}

export function createUser(name: string): User {
  return { id: Date.now(), name };
}

export default class UserService {
  getUser(id: number): User | null {
    return null;
  }
}
```

**Importing:**

```typescript
import UserService, { User, createUser } from './user-service.js';

const service = new UserService();
const user = createUser('John');
```

### CommonJS

```typescript
interface User {
  id: number;
  name: string;
}

function createUser(name: string): User {
  return { id: Date.now(), name };
}

module.exports = { createUser };
```

**Importing:**

```typescript
const { createUser } = require('./user-service');
```

### ESM/CommonJS Interoperability

**Important Flags:**

- `esModuleInterop: true` - Enables better compatibility between ESM and CommonJS
- `verbatimModuleSyntax: true` - Enforces explicit import/export syntax

**Importing CommonJS into ESM:**

```typescript
import pkg from './commonjs-module';
const { method } = pkg;
```

**Importing ESM into CommonJS:**

```typescript
const importDynamic = async () => {
  const { method } = await import('./esm-module.js');
  method();
};
```

### Supporting Both Formats

In `package.json`:

```json
{
  "type": "module",
  "exports": {
    "import": "./dist/esm/index.js",
    "require": "./dist/cjs/index.js"
  }
}
```

## Best Practices

### Type Safety

1. **Enable strict mode**: Always set `strict: true` in `tsconfig.json`
2. **Avoid `any` type**: Use `unknown` when unsure about a type, then use type guards
3. **Use explicit return types**: Specify return types for public API functions
4. **Leverage type inference**: Let TypeScript infer types where it's obvious

```typescript
function getUserById(id: number): Promise<User | null> {
  return fetch(`/api/users/${id}`)
    .then((res) => res.json())
    .catch(() => null);
}
```

### Code Organization

1. **Use interfaces for object shapes**: Interfaces are more performant and extendable
2. **Prefer interfaces over type aliases for objects**: Interfaces can be extended and merged
3. **Use type aliases for unions and intersections**: More appropriate for complex types

```typescript
interface User {
  id: number;
  name: string;
}

interface AdminUser extends User {
  role: 'admin';
  permissions: string[];
}

type ID = string | number;
type Result<T> = { success: true; data: T } | { success: false; error: string };
```

### Error Handling

1. **Always throw Error objects**: Never throw strings or primitives
2. **Use `unknown` type for caught errors**: Enabled by default in strict mode
3. **Use type guards to check error types**: Use `instanceof` checks before accessing properties
4. **Create custom error classes**: Provide more context about what went wrong

```typescript
class ValidationError extends Error {
  constructor(public field: string, message: string) {
    super(message);
    this.name = 'ValidationError';
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}

async function processData(data: unknown): Promise<void> {
  try {
    if (!isValidData(data)) {
      throw new ValidationError('data', 'Invalid data format');
    }
  } catch (error) {
    if (error instanceof ValidationError) {
      console.error(`Validation failed for ${error.field}: ${error.message}`);
    } else if (error instanceof Error) {
      console.error(`Unexpected error: ${error.message}`);
    } else {
      console.error('Unknown error occurred');
    }
  }
}
```

### Generics Best Practices

1. **Use meaningful type parameter names**: Use descriptive names like `TItem` instead of `T` for complex cases
2. **Add constraints when needed**: Use `extends` to constrain generic types
3. **Avoid over-engineering**: Don't use generics if a simple type works

```typescript
interface Lengthwise {
  length: number;
}

function loggingIdentity<T extends Lengthwise>(arg: T): T {
  console.log(arg.length);
  return arg;
}
```

### Module Organization

1. **Use barrel exports**: Create index files that re-export from multiple modules
2. **Organize by feature**: Group related types, interfaces, and functions together
3. **Separate types from implementation**: Consider keeping types in separate `.d.ts` files for large projects

```typescript
export { User, UserService } from './user';
export { Product, ProductService } from './product';
export { Order, OrderService } from './order';
```

## Common Gotchas

### 1. Overusing the `any` Type

**Problem:** Using `any` disables type checking and defeats the purpose of TypeScript.

**Solution:** Use `unknown` for truly unknown values, then narrow with type guards:

```typescript
function processValue(value: unknown) {
  if (typeof value === 'string') {
    return value.toUpperCase();
  }
  if (typeof value === 'number') {
    return value.toFixed(2);
  }
  throw new Error('Unsupported type');
}
```

### 2. Misusing Type Assertions

**Problem:** Type assertions bypass type checking and can lead to runtime errors.

**Bad:**

```typescript
const value = getSomeValue() as string;
```

**Good:**

```typescript
const value = getSomeValue();
if (typeof value === 'string') {
  console.log(value.toUpperCase());
}
```

### 3. Ignoring Compiler Errors

**Problem:** Suppressing errors with `@ts-ignore` or `@ts-expect-error` without addressing root causes.

**Solution:** Fix the underlying type issue or properly narrow the types.

### 4. Overusing Classes (Traditional OOP Patterns)

**Problem:** Wrapping everything in classes when simpler patterns would work.

**Solution:** Use object literals or functions when a single instance is needed:

```typescript
const userUtils = {
  formatName(user: User): string {
    return `${user.firstName} ${user.lastName}`;
  },

  isActive(user: User): boolean {
    return user.status === 'active';
  },
};
```

### 5. Not Using Strict Null Checks

**Problem:** Allows `null` and `undefined` to be assigned to any type, leading to runtime errors.

**Solution:** Enable `strictNullChecks` and handle null/undefined explicitly:

```typescript
function getUser(id: number): User | null {
  return users.find((u) => u.id === id) ?? null;
}

const user = getUser(1);
if (user !== null) {
  console.log(user.name);
}
```

### 6. Silent Error Handling

**Problem:** Catching errors without proper handling or logging.

**Bad:**

```typescript
try {
  riskyOperation();
} catch (e) {}
```

**Good:**

```typescript
try {
  riskyOperation();
} catch (error) {
  if (error instanceof Error) {
    logger.error('Operation failed:', error.message);
    throw error;
  }
}
```

### 7. Breaking Changes in TypeScript 5.9

**ArrayBuffer Type Hierarchy:**
`ArrayBuffer` is no longer a supertype of `TypedArray` types. Solutions include accessing the `.buffer` property or specifying explicit buffer types like `Uint8Array<ArrayBuffer>`.

**Type Inference Changes:**
Stricter type variable inference may introduce new errors, often resolved by explicitly providing type arguments to generic functions.

## Anti-Patterns

### 1. God Object Anti-Pattern

**Avoid:** Concentrating too much functionality in one class or object.

```typescript
class ApplicationManager {
  handleUsers() {}
  handleProducts() {}
  handleOrders() {}
  handlePayments() {}
  handleShipping() {}
  handleAnalytics() {}
}
```

**Better:** Separate concerns into dedicated classes/modules.

```typescript
class UserManager {
  handleUsers() {}
}

class ProductManager {
  handleProducts() {}
}

class OrderManager {
  handleOrders() {}
  handlePayments() {}
}
```

### 2. Magic Numbers and Strings

**Avoid:** Hard-coding values without named constants.

```typescript
if (user.status === 3) {
}
```

**Better:** Use named constants or enums.

```typescript
enum UserStatus {
  Inactive = 0,
  Active = 1,
  Suspended = 2,
  Deleted = 3,
}

if (user.status === UserStatus.Deleted) {
}
```

### 3. Copy-Paste Programming

**Avoid:** Duplicating code instead of creating reusable functions.

**Better:** Extract common logic into utility functions or generics.

```typescript
function findById<T extends { id: number }>(items: T[], id: number): T | undefined {
  return items.find((item) => item.id === id);
}

const user = findById(users, 1);
const product = findById(products, 2);
```

### 4. Premature Optimization

**Avoid:** Optimizing before identifying actual performance bottlenecks.

**Better:** Write clear, maintainable code first, then profile and optimize as needed.

### 5. Throwing Non-Error Objects

**Avoid:**

```typescript
throw 'Something went wrong';
throw 404;
```

**Better:**

```typescript
throw new Error('Something went wrong');
throw new HttpError(404, 'Not found');
```

## Error Handling

### Best Practices

1. **Always throw Error instances** for proper stack traces
2. **Use `unknown` type for caught errors** (enabled by default in strict mode)
3. **Use type guards to verify error types** before accessing properties
4. **Create custom error classes** for specific error scenarios
5. **Never silently catch errors** - always log or handle appropriately
6. **Re-throw errors when appropriate** to allow callers to handle them

### Error Handling Pattern

```typescript
class AppError extends Error {
  constructor(public code: string, message: string, public statusCode: number = 500) {
    super(message);
    this.name = 'AppError';
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

async function handleRequest(): Promise<void> {
  try {
    const data = await fetchData();
    await processData(data);
  } catch (error) {
    if (error instanceof AppError) {
      console.error(`Application error [${error.code}]: ${error.message}`);
      throw error;
    } else if (error instanceof Error) {
      console.error(`Unexpected error: ${error.message}`);
      throw new AppError('INTERNAL_ERROR', error.message);
    } else {
      console.error('Unknown error occurred');
      throw new AppError('UNKNOWN_ERROR', 'An unknown error occurred');
    }
  }
}
```

### Result Pattern

An alternative to throwing errors for expected failures:

```typescript
type Result<T, E = Error> = { success: true; data: T } | { success: false; error: E };

function divide(a: number, b: number): Result<number> {
  if (b === 0) {
    return { success: false, error: new Error('Division by zero') };
  }
  return { success: true, data: a / b };
}

const result = divide(10, 2);
if (result.success) {
  console.log(result.data);
} else {
  console.error(result.error.message);
}
```

## Security Considerations

### 1. Avoid the `any` Type

Using `any` bypasses type checking and can introduce security vulnerabilities. Always use `unknown` and type guards instead.

### 2. Enable Strict TypeScript Configuration

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true
  }
}
```

### 3. Prevent Cross-Site Scripting (XSS)

**Sanitize User Input:**

```typescript
import DOMPurify from 'dompurify';

function renderUserContent(html: string): string {
  return DOMPurify.sanitize(html);
}
```

**Content Security Policy (CSP):**
Implement a CSP to restrict executable script sources and mitigate XSS attacks.

### 4. Input Validation and Sanitization

Always validate and sanitize user input on both client and server sides:

```typescript
interface CreateUserInput {
  email: string;
  name: string;
}

function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function createUser(input: unknown): CreateUserInput | null {
  if (
    typeof input === 'object' &&
    input !== null &&
    'email' in input &&
    'name' in input &&
    typeof input.email === 'string' &&
    typeof input.name === 'string' &&
    validateEmail(input.email)
  ) {
    return {
      email: input.email,
      name: input.name,
    };
  }
  return null;
}
```

### 5. Avoid Dynamic Code Execution

Never use `eval()` or `Function()` constructor with user input:

```typescript
const userInput = 'malicious code';
eval(userInput);
```

### 6. Dependency Management

```bash
npm audit
npm audit fix
```

Regularly update dependencies and monitor for vulnerabilities using automated tools.

### 7. TypeScript Runtime Limitations

TypeScript is a compile-time tool. Types are erased at runtime, so:

- Always validate external input at runtime
- Don't rely on TypeScript types for security validation
- Use runtime validation libraries like Zod, Yup, or io-ts

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.number(),
  email: z.string().email(),
  name: z.string().min(1),
});

function validateUser(data: unknown) {
  return UserSchema.parse(data);
}
```

## Performance Tips

### 1. Compiler Configuration Optimizations

```json
{
  "compilerOptions": {
    "incremental": true,
    "skipLibCheck": true,
    "isolatedModules": true
  }
}
```

- **`incremental: true`** - Caches previous builds (up to 10% faster builds)
- **`skipLibCheck: true`** - Skips type checking of declaration files (32% reduction in time)
- **`isolatedModules: true`** - Ensures each file can be compiled independently

### 2. Type Complexity Management

**Avoid overly deep/recursive types:**

```typescript
type DeepNested = {
  level1: {
    level2: {
      level3: {
        level4: string;
      };
    };
  };
};
```

**Better - Split into simpler types:**

```typescript
interface Level4 {
  value: string;
}

interface Level3 {
  level4: Level4;
}

interface Level2 {
  level3: Level3;
}

interface Level1 {
  level2: Level2;
}
```

### 3. Prefer Interfaces Over Type Aliases for Objects

Interfaces are more performant and extendable for object definitions:

```typescript
interface User {
  id: number;
  name: string;
}

interface AdminUser extends User {
  permissions: string[];
}
```

### 4. Project Structure Optimization

For large monorepos, break down into project references:

```json
{
  "references": [
    { "path": "./packages/core" },
    { "path": "./packages/utils" },
    { "path": "./packages/ui" }
  ]
}
```

### 5. Alternative Compilers

For faster development builds, use SWC or esbuild for compilation and TypeScript only for type checking:

```bash
tsc -w --pretty --skipLibCheck --noEmit
```

### 6. Diagnostics

Identify performance bottlenecks:

```bash
tsc --extendedDiagnostics
tsc --generateTrace trace-output
```

### 7. Selective Imports

Import only what you need instead of entire modules:

```typescript
import { specific } from 'large-library';
```

Instead of:

```typescript
import * as lib from 'large-library';
```

### 8. Avoid Circular Dependencies

Circular dependencies slow down compilation and can cause runtime issues. Restructure code to eliminate them.

## Migration from JavaScript

### Step-by-Step Migration Guide

#### 1. Install TypeScript

```bash
npm install -D typescript @types/node
```

Install type definitions for your dependencies:

```bash
npm install -D @types/react @types/react-dom @types/jest
```

#### 2. Create tsconfig.json

```bash
tsc --init
```

Initial configuration for migration:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "allowJs": true,
    "checkJs": false,
    "outDir": "./dist",
    "rootDir": "./src",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "strict": false
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

#### 3. Rename Files Incrementally

Start with a single file:

- `.js` → `.ts`
- `.jsx` → `.tsx`

TypeScript is a superset of JavaScript, so valid JavaScript is valid TypeScript.

#### 4. Handle Initial Type Errors

Use `any` temporarily to get the project running:

```typescript
let data: any = fetchData();
```

Add comments to find these later:

```typescript
let data: any = fetchData();
```

#### 5. Add Type Annotations Gradually

Start with function signatures:

```typescript
function calculateTotal(items: any[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

Then add interface definitions:

```typescript
interface Item {
  id: number;
  name: string;
  price: number;
}

function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

#### 6. Enable Strict Mode Incrementally

Once all files are migrated:

```json
{
  "compilerOptions": {
    "allowJs": false,
    "strict": true
  }
}
```

Enable strict checks one at a time if needed:

```json
{
  "compilerOptions": {
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true
  }
}
```

#### 7. Migration Best Practices

- **Start with leaf modules** (modules with no dependencies on other project files)
- **Focus on critical modules first** (core business logic)
- **Migrate in small batches** - one module or feature at a time
- **Don't rewrite** - TypeScript supports gradual adoption
- **Run tests frequently** to catch regressions
- **Use `checkJs: true`** temporarily to get type checking in JS files without renaming

## Code Examples

### 1. Basic Type Annotations

```typescript
let username: string = 'John';
let age: number = 30;
let isActive: boolean = true;
let scores: number[] = [90, 85, 95];
let tuple: [string, number] = ['John', 30];
```

### 2. Function Types

```typescript
function add(a: number, b: number): number {
  return a + b;
}

const multiply = (a: number, b: number): number => a * b;

type MathOperation = (a: number, b: number) => number;

const divide: MathOperation = (a, b) => a / b;
```

### 3. Interface and Type Composition

```typescript
interface Address {
  street: string;
  city: string;
  country: string;
}

interface Person {
  name: string;
  age: number;
  address: Address;
}

type ContactInfo = {
  email: string;
  phone?: string;
};

type PersonWithContact = Person & ContactInfo;

const person: PersonWithContact = {
  name: 'John',
  age: 30,
  address: {
    street: '123 Main St',
    city: 'New York',
    country: 'USA',
  },
  email: 'john@example.com',
};
```

### 4. Discriminated Unions

```typescript
interface Square {
  kind: 'square';
  size: number;
}

interface Rectangle {
  kind: 'rectangle';
  width: number;
  height: number;
}

interface Circle {
  kind: 'circle';
  radius: number;
}

type Shape = Square | Rectangle | Circle;

function getArea(shape: Shape): number {
  switch (shape.kind) {
    case 'square':
      return shape.size ** 2;
    case 'rectangle':
      return shape.width * shape.height;
    case 'circle':
      return Math.PI * shape.radius ** 2;
  }
}
```

### 5. Generic Constraints

```typescript
interface HasId {
  id: number;
}

function findById<T extends HasId>(items: T[], id: number): T | undefined {
  return items.find((item) => item.id === id);
}

interface User extends HasId {
  name: string;
}

interface Product extends HasId {
  title: string;
  price: number;
}

const users: User[] = [{ id: 1, name: 'John' }];
const products: Product[] = [{ id: 1, title: 'Book', price: 20 }];

const user = findById(users, 1);
const product = findById(products, 1);
```

### 6. Async/Await with Generic Types

```typescript
interface ApiResponse<T> {
  data: T;
  status: number;
  message: string;
}

async function fetchApi<T>(url: string): Promise<ApiResponse<T>> {
  const response = await fetch(url);
  const data = await response.json();
  return {
    data: data as T,
    status: response.status,
    message: response.statusText,
  };
}

interface User {
  id: number;
  name: string;
}

async function getUser(id: number): Promise<User> {
  const response = await fetchApi<User>(`/api/users/${id}`);
  if (response.status !== 200) {
    throw new Error(response.message);
  }
  return response.data;
}
```

### 7. Decorators (Experimental)

```typescript
function sealed(constructor: Function) {
  Object.seal(constructor);
  Object.seal(constructor.prototype);
}

function readonly(target: any, propertyKey: string) {
  Object.defineProperty(target, propertyKey, {
    writable: false,
  });
}

@sealed
class Person {
  @readonly
  name: string;

  constructor(name: string) {
    this.name = name;
  }
}
```

**Configuration required:**

```json
{
  "compilerOptions": {
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  }
}
```

### 8. Namespace and Module Augmentation

```typescript
declare global {
  interface Window {
    customProperty: string;
  }
}

window.customProperty = 'value';

export {};
```

### 9. Advanced Mapped Types

```typescript
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface User {
  name: string;
  age: number;
}

type UserGetters = Getters<User>;
```

### 10. Recursive Types

```typescript
interface TreeNode<T> {
  value: T;
  children?: TreeNode<T>[];
}

function traverse<T>(node: TreeNode<T>, callback: (value: T) => void): void {
  callback(node.value);
  if (node.children) {
    node.children.forEach((child) => traverse(child, callback));
  }
}

const tree: TreeNode<number> = {
  value: 1,
  children: [
    { value: 2 },
    {
      value: 3,
      children: [{ value: 4 }, { value: 5 }],
    },
  ],
};

traverse(tree, (value) => console.log(value));
```

## Version-Specific Notes

### TypeScript 5.9 Breaking Changes

#### ArrayBuffer Type Hierarchy

`ArrayBuffer` is no longer a supertype of `TypedArray` types, causing new type errors.

**Solutions:**

1. Access the `.buffer` property:

   ```typescript
   function processBuffer(buffer: ArrayBuffer) {}

   const uint8 = new Uint8Array(10);
   processBuffer(uint8.buffer);
   ```

2. Specify explicit buffer types:
   ```typescript
   function processTypedArray(array: Uint8Array<ArrayBuffer>) {}
   ```

#### Type Inference Changes

Stricter type variable inference may introduce new errors.

**Solution:** Explicitly provide type arguments to generic functions:

```typescript
function identity<T>(value: T): T {
  return value;
}

const result = identity<string>('hello');
```

### Migration from Earlier Versions

#### From TypeScript 4.x to 5.x

Key changes include:

- Improved support for ES modules
- Better const type parameters
- Decorators moving toward standardization
- Faster build times with incremental improvements

#### Recommended Upgrade Path

1. Update to the latest 5.x version: `npm install -D typescript@latest`
2. Run `tsc --noEmit` to check for new errors
3. Address breaking changes identified in release notes
4. Update `tsconfig.json` with new recommended settings
5. Run full test suite to verify functionality

## References

### Official Documentation

- TypeScript Official Website: https://www.typescriptlang.org/
- TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/intro.html
- TypeScript GitHub: https://github.com/microsoft/TypeScript
- TypeScript 5.9 Release Notes: https://devblogs.microsoft.com/typescript/announcing-typescript-5-9/
- TSConfig Reference: https://www.typescriptlang.org/tsconfig/

### Community Resources

- TypeScript Deep Dive: https://basarat.gitbook.io/typescript/
- DefinitelyTyped (@types packages): https://github.com/DefinitelyTyped/DefinitelyTyped
- TSConfig Bases: https://github.com/tsconfig/bases
- TypeScript Playground: https://www.typescriptlang.org/play/

### Tools and Libraries

- ts-node: TypeScript execution for Node.js
- ts-jest: TypeScript preprocessor for Jest
- ESLint TypeScript: TypeScript support for ESLint
- Prettier: Code formatter with TypeScript support
- SWC: Fast TypeScript/JavaScript compiler
- esbuild: Extremely fast JavaScript bundler and minifier

### Type Definition Sources

- npm @types scope: https://www.npmjs.com/~types
- TypeSearch: https://www.typescriptlang.org/dt/search

### Learning Resources

- FreeCodeCamp TypeScript Course: https://www.freecodecamp.org/news/learn-typescript-beginners-guide/
- W3Schools TypeScript Tutorial: https://www.w3schools.com/typescript/
- TypeScript Tutorial for Beginners: https://www.typescripttutorial.net/

### Security

- Snyk TypeScript Security: https://snyk.io/blog/best-practices-react-typescript-security/
- OWASP Secure Coding Practices
- npm audit documentation

### Performance

- TypeScript Performance Wiki: https://github.com/microsoft/TypeScript/wiki/Performance
- TypeScript Compiler Options for Performance
- Build Performance Optimization Guides

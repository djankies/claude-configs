# Configuration Loading System

A type-safe Node.js configuration loading system with JSON validation and runtime type checking.

## Features

- Load and parse JSON configuration files
- Runtime validation with detailed error messages
- Type-safe access to configuration properties
- Nested property access with dot notation
- Default value handling
- Comprehensive error handling for missing or invalid configurations

## Installation

```bash
npm install
npm run build
```

## Quick Start

```typescript
import { loadConfig, ConfigValidationSchema } from './index';

interface MyConfig {
  server: {
    port: number;
    host: string;
  };
}

const schema: ConfigValidationSchema = {
  server: {
    type: 'object',
    required: true,
    properties: {
      port: { type: 'number', required: true, min: 1, max: 65535 },
      host: { type: 'string', required: true }
    }
  }
};

const config = loadConfig<MyConfig>('./config.json', schema);
console.log(config.server.port);
```

## API Reference

### ConfigLoader Class

Main class for loading and managing configurations.

#### Methods

- `load(filePath: string, schema?: ConfigValidationSchema): T` - Load configuration from file
- `loadFromObject(data: any, schema?: ConfigValidationSchema): T` - Load from object
- `get<K>(key: K): T[K]` - Get configuration value by key
- `getOrDefault<K>(key: K, defaultValue: T[K]): T[K]` - Get value or return default
- `getNested(path: string): ConfigValue` - Get nested value using dot notation
- `getNestedOrDefault(path: string, defaultValue: ConfigValue): ConfigValue` - Get nested or default
- `has<K>(key: K): boolean` - Check if key exists
- `getAll(): T` - Get entire configuration object
- `reload(filePath: string, schema?: ConfigValidationSchema): T` - Reload configuration
- `isLoaded(): boolean` - Check if config is loaded
- `clear(): void` - Clear loaded configuration

### Validation Rules

#### Basic Types

- `type`: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'null'
- `required`: boolean - Whether field is required (default: true)

#### String Validation

- `pattern`: RegExp - Regular expression pattern
- `min`: number - Minimum length
- `max`: number - Maximum length
- `enum`: any[] - Allowed values

#### Number Validation

- `min`: number - Minimum value
- `max`: number - Maximum value
- `enum`: any[] - Allowed values

#### Object Validation

- `properties`: { [key: string]: ValidationRule } - Property schemas

#### Array Validation

- `items`: ValidationRule - Schema for array items

## Usage Examples

### Basic Loading

```typescript
import { createConfigLoader } from './index';

const loader = createConfigLoader();
loader.load('./config.json');

const value = loader.get('someKey');
```

### With Validation

```typescript
const schema = {
  database: {
    type: 'object',
    required: true,
    properties: {
      host: { type: 'string', required: true },
      port: { type: 'number', required: true, min: 1, max: 65535 }
    }
  }
};

loader.load('./config.json', schema);
```

### Nested Access

```typescript
const port = loader.getNested('database.port');
const host = loader.getNestedOrDefault('database.host', 'localhost');
```

### Error Handling

```typescript
try {
  loader.load('./config.json', schema);
} catch (error) {
  if (error instanceof ConfigurationError) {
    console.error('Config error:', error.message, error.path);
  } else if (error instanceof ValidationError) {
    console.error('Validation error:', error.message, error.path, error.value);
  }
}
```

## Configuration Options

```typescript
const loader = createConfigLoader({
  strict: true,
  allowUnknownProperties: false,
  throwOnMissing: true
});
```

- `strict`: Enable strict validation (default: true)
- `allowUnknownProperties`: Allow properties not in schema (default: false)
- `throwOnMissing`: Throw error when file not found (default: true)

## Running Examples

```bash
npm run example
```

## Testing

```bash
npm test
```

## Error Types

### ConfigurationError

Thrown when configuration file is missing, invalid JSON, or keys are not found.

### ValidationError

Thrown when configuration values don't match the validation schema.

## License

MIT

export interface ConfigSchema {
  [key: string]: ConfigValue;
}

export type ConfigValue =
  | string
  | number
  | boolean
  | null
  | ConfigValue[]
  | { [key: string]: ConfigValue };

export interface ValidationRule {
  type: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'null';
  required?: boolean;
  properties?: { [key: string]: ValidationRule };
  items?: ValidationRule;
  enum?: any[];
  min?: number;
  max?: number;
  pattern?: RegExp;
}

export interface ConfigValidationSchema {
  [key: string]: ValidationRule;
}

export interface ConfigOptions {
  strict?: boolean;
  allowUnknownProperties?: boolean;
  throwOnMissing?: boolean;
}

export class ConfigurationError extends Error {
  constructor(message: string, public readonly path?: string) {
    super(message);
    this.name = 'ConfigurationError';
  }
}

export class ValidationError extends Error {
  constructor(
    message: string,
    public readonly path: string,
    public readonly value: any
  ) {
    super(message);
    this.name = 'ValidationError';
  }
}

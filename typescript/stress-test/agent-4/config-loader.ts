import * as fs from 'fs';
import * as path from 'path';
import {
  ConfigSchema,
  ConfigValue,
  ConfigValidationSchema,
  ConfigOptions,
  ConfigurationError,
} from './types';
import { ConfigValidator } from './validator';

export class ConfigLoader<T extends ConfigSchema = ConfigSchema> {
  private config: T | null = null;
  private validator: ConfigValidator;
  private options: Required<ConfigOptions>;

  constructor(options: ConfigOptions = {}) {
    this.validator = new ConfigValidator();
    this.options = {
      strict: options.strict ?? true,
      allowUnknownProperties: options.allowUnknownProperties ?? false,
      throwOnMissing: options.throwOnMissing ?? true,
    };
  }

  load(filePath: string, schema?: ConfigValidationSchema): T {
    const resolvedPath = path.resolve(filePath);

    if (!fs.existsSync(resolvedPath)) {
      const error = new ConfigurationError(
        `Configuration file not found: ${resolvedPath}`,
        resolvedPath
      );
      if (this.options.throwOnMissing) {
        throw error;
      }
      throw error;
    }

    try {
      const fileContent = fs.readFileSync(resolvedPath, 'utf-8');
      const parsed = JSON.parse(fileContent);

      if (schema) {
        this.validator.validate(parsed, schema);
      }

      this.config = parsed as T;
      return this.config;
    } catch (error) {
      if (error instanceof SyntaxError) {
        throw new ConfigurationError(
          `Invalid JSON in configuration file: ${error.message}`,
          resolvedPath
        );
      }
      throw error;
    }
  }

  loadFromObject(data: any, schema?: ConfigValidationSchema): T {
    if (schema) {
      this.validator.validate(data, schema);
    }

    this.config = data as T;
    return this.config;
  }

  get<K extends keyof T>(key: K): T[K] {
    if (this.config === null) {
      throw new ConfigurationError('Configuration not loaded');
    }

    if (!(key in this.config)) {
      throw new ConfigurationError(`Configuration key not found: ${String(key)}`);
    }

    return this.config[key];
  }

  getOrDefault<K extends keyof T>(key: K, defaultValue: T[K]): T[K] {
    if (this.config === null) {
      return defaultValue;
    }

    if (!(key in this.config)) {
      return defaultValue;
    }

    return this.config[key];
  }

  has<K extends keyof T>(key: K): boolean {
    return this.config !== null && key in this.config;
  }

  getAll(): T {
    if (this.config === null) {
      throw new ConfigurationError('Configuration not loaded');
    }

    return { ...this.config };
  }

  getNested(path: string): ConfigValue {
    if (this.config === null) {
      throw new ConfigurationError('Configuration not loaded');
    }

    const keys = path.split('.');
    let current: any = this.config;

    for (const key of keys) {
      if (current === null || typeof current !== 'object' || !(key in current)) {
        throw new ConfigurationError(`Configuration path not found: ${path}`);
      }
      current = current[key];
    }

    return current;
  }

  getNestedOrDefault(path: string, defaultValue: ConfigValue): ConfigValue {
    try {
      return this.getNested(path);
    } catch (error) {
      if (error instanceof ConfigurationError) {
        return defaultValue;
      }
      throw error;
    }
  }

  reload(filePath: string, schema?: ConfigValidationSchema): T {
    return this.load(filePath, schema);
  }

  isLoaded(): boolean {
    return this.config !== null;
  }

  clear(): void {
    this.config = null;
  }
}

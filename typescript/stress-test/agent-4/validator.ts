import {
  ConfigValue,
  ValidationRule,
  ConfigValidationSchema,
  ValidationError,
} from './types';

export class ConfigValidator {
  validate(
    data: any,
    schema: ConfigValidationSchema,
    path: string = 'root'
  ): void {
    if (typeof data !== 'object' || data === null) {
      throw new ValidationError(
        'Configuration must be an object',
        path,
        data
      );
    }

    for (const [key, rule] of Object.entries(schema)) {
      const fieldPath = `${path}.${key}`;
      const value = data[key];

      if (value === undefined) {
        if (rule.required !== false) {
          throw new ValidationError(
            `Required field missing: ${key}`,
            fieldPath,
            undefined
          );
        }
        continue;
      }

      this.validateValue(value, rule, fieldPath);
    }
  }

  private validateValue(
    value: any,
    rule: ValidationRule,
    path: string
  ): void {
    if (rule.enum && !rule.enum.includes(value)) {
      throw new ValidationError(
        `Value must be one of: ${rule.enum.join(', ')}`,
        path,
        value
      );
    }

    const actualType = this.getType(value);

    if (actualType !== rule.type) {
      throw new ValidationError(
        `Expected type ${rule.type} but got ${actualType}`,
        path,
        value
      );
    }

    switch (rule.type) {
      case 'string':
        this.validateString(value, rule, path);
        break;
      case 'number':
        this.validateNumber(value, rule, path);
        break;
      case 'array':
        this.validateArray(value, rule, path);
        break;
      case 'object':
        this.validateObject(value, rule, path);
        break;
    }
  }

  private validateString(value: string, rule: ValidationRule, path: string): void {
    if (rule.pattern && !rule.pattern.test(value)) {
      throw new ValidationError(
        `String does not match pattern ${rule.pattern}`,
        path,
        value
      );
    }

    if (rule.min !== undefined && value.length < rule.min) {
      throw new ValidationError(
        `String length must be at least ${rule.min}`,
        path,
        value
      );
    }

    if (rule.max !== undefined && value.length > rule.max) {
      throw new ValidationError(
        `String length must be at most ${rule.max}`,
        path,
        value
      );
    }
  }

  private validateNumber(value: number, rule: ValidationRule, path: string): void {
    if (rule.min !== undefined && value < rule.min) {
      throw new ValidationError(
        `Number must be at least ${rule.min}`,
        path,
        value
      );
    }

    if (rule.max !== undefined && value > rule.max) {
      throw new ValidationError(
        `Number must be at most ${rule.max}`,
        path,
        value
      );
    }
  }

  private validateArray(value: any[], rule: ValidationRule, path: string): void {
    if (rule.items) {
      value.forEach((item, index) => {
        this.validateValue(item, rule.items!, `${path}[${index}]`);
      });
    }
  }

  private validateObject(
    value: { [key: string]: any },
    rule: ValidationRule,
    path: string
  ): void {
    if (rule.properties) {
      for (const [key, propRule] of Object.entries(rule.properties)) {
        const propValue = value[key];
        const propPath = `${path}.${key}`;

        if (propValue === undefined) {
          if (propRule.required !== false) {
            throw new ValidationError(
              `Required property missing: ${key}`,
              propPath,
              undefined
            );
          }
          continue;
        }

        this.validateValue(propValue, propRule, propPath);
      }
    }
  }

  private getType(value: any): string {
    if (value === null) return 'null';
    if (Array.isArray(value)) return 'array';
    return typeof value;
  }
}

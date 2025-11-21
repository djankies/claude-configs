export { ConfigLoader } from './config-loader';
export { ConfigValidator } from './validator';
export {
  ConfigSchema,
  ConfigValue,
  ValidationRule,
  ConfigValidationSchema,
  ConfigOptions,
  ConfigurationError,
  ValidationError,
} from './types';

export function createConfigLoader<T extends ConfigSchema>(
  options?: ConfigOptions
): ConfigLoader<T> {
  return new ConfigLoader<T>(options);
}

export function loadConfig<T extends ConfigSchema>(
  filePath: string,
  schema?: ConfigValidationSchema,
  options?: ConfigOptions
): T {
  const loader = new ConfigLoader<T>(options);
  return loader.load(filePath, schema);
}

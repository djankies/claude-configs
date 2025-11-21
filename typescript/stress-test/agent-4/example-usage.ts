import { loadConfig, createConfigLoader, ConfigValidationSchema } from './index';

interface AppConfig {
  app: {
    name: string;
    version: string;
    environment: string;
  };
  server: {
    host: string;
    port: number;
    timeout: number;
    secure: boolean;
  };
  database: {
    host: string;
    port: number;
    name: string;
    user: string;
    password: string;
    poolSize: number;
  };
  logging: {
    level: string;
    format: string;
    outputs: string[];
  };
  features: {
    enableCache: boolean;
    enableMetrics: boolean;
    maxUploadSize: number;
  };
}

const configSchema: ConfigValidationSchema = {
  app: {
    type: 'object',
    required: true,
    properties: {
      name: { type: 'string', required: true },
      version: { type: 'string', required: true, pattern: /^\d+\.\d+\.\d+$/ },
      environment: {
        type: 'string',
        required: true,
        enum: ['development', 'staging', 'production'],
      },
    },
  },
  server: {
    type: 'object',
    required: true,
    properties: {
      host: { type: 'string', required: true },
      port: { type: 'number', required: true, min: 1, max: 65535 },
      timeout: { type: 'number', required: true, min: 0 },
      secure: { type: 'boolean', required: true },
    },
  },
  database: {
    type: 'object',
    required: true,
    properties: {
      host: { type: 'string', required: true },
      port: { type: 'number', required: true, min: 1, max: 65535 },
      name: { type: 'string', required: true },
      user: { type: 'string', required: true },
      password: { type: 'string', required: true },
      poolSize: { type: 'number', required: true, min: 1, max: 100 },
    },
  },
  logging: {
    type: 'object',
    required: true,
    properties: {
      level: {
        type: 'string',
        required: true,
        enum: ['debug', 'info', 'warn', 'error'],
      },
      format: { type: 'string', required: true, enum: ['json', 'text'] },
      outputs: {
        type: 'array',
        required: true,
        items: { type: 'string' },
      },
    },
  },
  features: {
    type: 'object',
    required: true,
    properties: {
      enableCache: { type: 'boolean', required: true },
      enableMetrics: { type: 'boolean', required: true },
      maxUploadSize: { type: 'number', required: true, min: 0 },
    },
  },
};

function example1() {
  console.log('Example 1: Simple loading with validation');
  try {
    const config = loadConfig<AppConfig>(
      './example-config.json',
      configSchema
    );
    console.log('Config loaded successfully:', config.app.name);
    console.log('Server port:', config.server.port);
  } catch (error) {
    console.error('Failed to load config:', error);
  }
}

function example2() {
  console.log('\nExample 2: Using ConfigLoader instance');
  const loader = createConfigLoader<AppConfig>();

  try {
    loader.load('./example-config.json', configSchema);

    const appName = loader.get('app');
    console.log('App name:', appName.name);

    const serverPort = loader.getNested('server.port');
    console.log('Server port:', serverPort);

    const dbHost = loader.getNestedOrDefault('database.host', 'localhost');
    console.log('DB host:', dbHost);

    const hasLogging = loader.has('logging');
    console.log('Has logging config:', hasLogging);
  } catch (error) {
    console.error('Failed:', error);
  }
}

function example3() {
  console.log('\nExample 3: Error handling');
  const loader = createConfigLoader<AppConfig>();

  try {
    loader.load('./non-existent.json');
  } catch (error) {
    console.error('Expected error for missing file:', error.message);
  }

  try {
    const invalidConfig = {
      app: {
        name: 'Test',
        version: 'invalid-version',
        environment: 'production',
      },
    };
    loader.loadFromObject(invalidConfig, configSchema);
  } catch (error) {
    console.error('Expected validation error:', error.message);
  }
}

function example4() {
  console.log('\nExample 4: Optional fields and defaults');
  const loader = createConfigLoader<AppConfig>({
    strict: false,
    throwOnMissing: false,
  });

  loader.load('./example-config.json');

  const defaultValue = loader.getOrDefault('nonExistent' as any, {
    default: 'value',
  });
  console.log('Using default:', defaultValue);

  const allConfig = loader.getAll();
  console.log('All config keys:', Object.keys(allConfig));
}

if (require.main === module) {
  example1();
  example2();
  example3();
  example4();
}

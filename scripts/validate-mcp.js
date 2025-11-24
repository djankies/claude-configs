#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const VALID_TYPES = ['stdio', 'http', 'sse'];

function validateMcpConfig(filePath) {
  const errors = [];
  const warnings = [];

  if (!fs.existsSync(filePath)) {
    return { valid: false, errors: [`File not found: ${filePath}`], warnings: [] };
  }

  let config;
  try {
    config = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    return { valid: false, errors: [`Invalid JSON: ${e.message}`], warnings: [] };
  }

  if (!config.mcpServers) {
    return { valid: false, errors: ['Missing required field: mcpServers'], warnings: [] };
  }

  if (typeof config.mcpServers !== 'object' || config.mcpServers === null || Array.isArray(config.mcpServers)) {
    return { valid: false, errors: ['Field "mcpServers" must be an object'], warnings: [] };
  }

  Object.entries(config.mcpServers).forEach(([serverName, serverConfig]) => {
    const serverPath = `mcpServers.${serverName}`;

    if (typeof serverConfig !== 'object' || serverConfig === null) {
      errors.push(`${serverPath} must be an object`);
      return;
    }

    if (!serverConfig.type) {
      errors.push(`${serverPath}.type is required (stdio, http, or sse)`);
      return;
    }

    if (!VALID_TYPES.includes(serverConfig.type)) {
      errors.push(`${serverPath}.type must be "stdio", "http", or "sse", got "${serverConfig.type}"`);
      return;
    }

    const serverType = serverConfig.type;

    if (serverType === 'stdio') {
      if (!serverConfig.command) {
        errors.push(`${serverPath}.command is required for stdio servers`);
      } else if (typeof serverConfig.command !== 'string') {
        errors.push(`${serverPath}.command must be a string`);
      }

      if (serverConfig.args !== undefined) {
        if (!Array.isArray(serverConfig.args)) {
          errors.push(`${serverPath}.args must be an array`);
        } else if (!serverConfig.args.every(a => typeof a === 'string')) {
          errors.push(`${serverPath}.args must contain only strings`);
        }
      }

      if (serverConfig.env !== undefined) {
        if (typeof serverConfig.env !== 'object' || serverConfig.env === null || Array.isArray(serverConfig.env)) {
          errors.push(`${serverPath}.env must be an object`);
        } else {
          Object.entries(serverConfig.env).forEach(([key, value]) => {
            if (typeof value !== 'string') {
              errors.push(`${serverPath}.env.${key} must be a string`);
            }
          });
        }
      }

      if (serverConfig.cwd !== undefined && typeof serverConfig.cwd !== 'string') {
        errors.push(`${serverPath}.cwd must be a string`);
      }

      if (serverConfig.url !== undefined) {
        warnings.push(`${serverPath}.url is ignored for stdio servers`);
      }
      if (serverConfig.headers !== undefined) {
        warnings.push(`${serverPath}.headers is ignored for stdio servers`);
      }

    } else if (serverType === 'http' || serverType === 'sse') {
      if (!serverConfig.url) {
        errors.push(`${serverPath}.url is required for ${serverType} servers`);
      } else if (typeof serverConfig.url !== 'string') {
        errors.push(`${serverPath}.url must be a string`);
      } else {
        const urlPattern = /^(\$\{[^}]+\}|https?:\/\/)/;
        if (!urlPattern.test(serverConfig.url)) {
          warnings.push(`${serverPath}.url should start with http:// or https://`);
        }
      }

      if (serverConfig.headers !== undefined) {
        if (typeof serverConfig.headers !== 'object' || serverConfig.headers === null || Array.isArray(serverConfig.headers)) {
          errors.push(`${serverPath}.headers must be an object`);
        } else {
          Object.entries(serverConfig.headers).forEach(([key, value]) => {
            if (typeof value !== 'string') {
              errors.push(`${serverPath}.headers.${key} must be a string`);
            }
          });
        }
      }

      if (serverConfig.command !== undefined) {
        warnings.push(`${serverPath}.command is ignored for ${serverType} servers`);
      }
      if (serverConfig.args !== undefined) {
        warnings.push(`${serverPath}.args is ignored for ${serverType} servers`);
      }

      if (serverType === 'sse') {
        warnings.push(`${serverPath}: SSE transport is deprecated, use HTTP instead`);
      }
    }

    const envVarPattern = /\$\{([^}]+)\}/g;
    const checkEnvVars = (value, fieldPath) => {
      if (typeof value !== 'string') return;
      let match;
      while ((match = envVarPattern.exec(value)) !== null) {
        const varExpr = match[1];
        const validPattern = /^[A-Z_][A-Z0-9_]*(:-[^}]*)?$/;
        if (!validPattern.test(varExpr)) {
          const knownVars = ['CLAUDE_PLUGIN_ROOT', 'CLAUDE_PROJECT_DIR'];
          if (!knownVars.some(v => varExpr.startsWith(v))) {
            warnings.push(`${fieldPath}: env var "${varExpr}" may have invalid format`);
          }
        }
      }
    };

    if (serverConfig.command) checkEnvVars(serverConfig.command, `${serverPath}.command`);
    if (serverConfig.url) checkEnvVars(serverConfig.url, `${serverPath}.url`);
    if (serverConfig.cwd) checkEnvVars(serverConfig.cwd, `${serverPath}.cwd`);
    if (serverConfig.args) {
      serverConfig.args.forEach((arg, i) => checkEnvVars(arg, `${serverPath}.args[${i}]`));
    }
    if (serverConfig.env) {
      Object.entries(serverConfig.env).forEach(([key, value]) => {
        checkEnvVars(value, `${serverPath}.env.${key}`);
      });
    }
    if (serverConfig.headers) {
      Object.entries(serverConfig.headers).forEach(([key, value]) => {
        checkEnvVars(value, `${serverPath}.headers.${key}`);
      });
    }
  });

  return { valid: errors.length === 0, errors, warnings };
}

function main() {
  const filePath = process.argv[2];

  if (!filePath) {
    console.log('USAGE: validate-mcp.js <path-to-.mcp.json>');
    process.exit(1);
  }

  const result = validateMcpConfig(path.resolve(filePath));

  if (result.valid) {
    console.log('VALID');
    if (result.warnings.length > 0) {
      console.log('\nWARNINGS:');
      result.warnings.forEach(w => console.log(`- ${w}`));
    }
    process.exit(0);
  } else {
    console.log('INVALID');
    console.log('\nERRORS:');
    result.errors.forEach(e => console.log(`- ${e}`));
    if (result.warnings.length > 0) {
      console.log('\nWARNINGS:');
      result.warnings.forEach(w => console.log(`- ${w}`));
    }
    process.exit(1);
  }
}

main();

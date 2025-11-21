#!/usr/bin/env node

/**
 * Validation script for Claude Code Plugin Marketplace
 * 
 * This script validates:
 * - marketplace.json structure and required fields
 * - Plugin repository references
 * - JSON file validity
 * - Naming conventions (kebab-case)
 * - Version format (semver)
 */

const fs = require('fs');
const path = require('path');
const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const { glob } = require('glob');

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

// Initialize AJV for JSON schema validation
const ajv = new Ajv({ allErrors: true });
addFormats(ajv);

// Schemas
const marketplaceSchema = {
  type: 'object',
  properties: {
    name: {
      type: 'string',
      pattern: '^[a-z0-9]+(-[a-z0-9]+)*$', // kebab-case
      description: 'Marketplace name in kebab-case'
    },
    owner: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        email: { type: 'string', format: 'email' }
      },
      required: ['name', 'email']
    },
    metadata: {
      type: 'object',
      properties: {
        description: { type: 'string' },
        version: { type: 'string', pattern: '^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9]+)?$' } // semver
      },
      required: ['description', 'version']
    },
    plugins: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string', pattern: '^[a-z0-9]+(-[a-z0-9]+)*$' },
          source: {
            oneOf: [
              {
                type: 'string',
                description: 'Local path to plugin directory'
              },
              {
                type: 'object',
                properties: {
                  source: { type: 'string', enum: ['git'] },
                  url: { type: 'string', format: 'uri' }
                },
                required: ['source', 'url']
              },
              {
                type: 'object',
                properties: {
                  source: { type: 'string', enum: ['github'] },
                  repo: { type: 'string', pattern: '^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$' }
                },
                required: ['source', 'repo']
              }
            ]
          }
        },
        required: ['name', 'source']
      }
    }
  },
  required: ['name', 'owner', 'metadata', 'plugins']
};

const pluginSchema = {
  type: 'object',
  properties: {
    name: { type: 'string', pattern: '^[a-z0-9]+(-[a-z0-9]+)*$' },
    version: { type: 'string', pattern: '^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9]+)?$' },
    description: { type: 'string' },
    author: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        email: { type: 'string', format: 'email' },
        url: { type: 'string', format: 'uri' }
      },
      required: ['name']
    }
  },
  required: ['name', 'version', 'description']
};

// Validation results
let errors = [];
let warnings = [];
let successes = [];

/**
 * Log functions
 */
function logError(message) {
  errors.push(message);
  console.error(`${colors.red}✗ ERROR:${colors.reset} ${message}`);
}

function logWarning(message) {
  warnings.push(message);
  console.warn(`${colors.yellow}⚠ WARNING:${colors.reset} ${message}`);
}

function logSuccess(message) {
  successes.push(message);
  console.log(`${colors.green}✓${colors.reset} ${message}`);
}

function logInfo(message) {
  console.log(`${colors.blue}ℹ${colors.reset} ${message}`);
}

/**
 * Validate JSON file
 */
function validateJSON(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    JSON.parse(content);
    return true;
  } catch (error) {
    logError(`Invalid JSON in ${filePath}: ${error.message}`);
    return false;
  }
}

/**
 * Validate marketplace.json
 */
function validateMarketplace() {
  logInfo('Validating marketplace.json...');
  
  const marketplacePath = path.join(__dirname, '../.claude-plugin/marketplace.json');
  
  if (!fs.existsSync(marketplacePath)) {
    logError('marketplace.json not found at .claude-plugin/marketplace.json');
    return false;
  }
  
  if (!validateJSON(marketplacePath)) {
    return false;
  }
  
  const marketplace = JSON.parse(fs.readFileSync(marketplacePath, 'utf8'));
  
  // Validate against schema
  const validate = ajv.compile(marketplaceSchema);
  const valid = validate(marketplace);
  
  if (!valid) {
    validate.errors.forEach(error => {
      logError(`marketplace.json schema error: ${error.instancePath} ${error.message}`);
    });
    return false;
  }
  
  logSuccess('marketplace.json is valid');
  
  // Check for plugin references
  if (marketplace.plugins.length === 0) {
    logWarning('No plugins listed in marketplace (this is OK for a new marketplace)');
  } else {
    logInfo(`Found ${marketplace.plugins.length} plugin(s) referenced`);
  }
  
  return true;
}

/**
 * Validate plugin.json files
 */
async function validatePlugins() {
  logInfo('Validating plugin.json files...');
  
  const pluginFiles = await glob('**/.claude-plugin/plugin.json', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });
  
  if (pluginFiles.length === 0) {
    logWarning('No plugin.json files found');
    return true;
  }
  
  let allValid = true;
  
  for (const file of pluginFiles) {
    const fullPath = path.join(__dirname, '..', file);
    
    if (!validateJSON(fullPath)) {
      allValid = false;
      continue;
    }
    
    const plugin = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
    
    // Validate against schema
    const validate = ajv.compile(pluginSchema);
    const valid = validate(plugin);
    
    if (!valid) {
      validate.errors.forEach(error => {
        logError(`${file} schema error: ${error.instancePath} ${error.message}`);
      });
      allValid = false;
    } else {
      logSuccess(`${file} is valid`);
    }
    
    // Check for recommended fields
    if (!plugin.author) {
      logWarning(`${file}: Missing 'author' field (recommended)`);
    }
    if (!plugin.repository) {
      logWarning(`${file}: Missing 'repository' field (recommended)`);
    }
    if (!plugin.license) {
      logWarning(`${file}: Missing 'license' field (recommended)`);
    }
  }
  
  return allValid;
}

/**
 * Validate hooks.json files
 */
async function validateHooks() {
  logInfo('Validating hooks.json files...');
  
  const hooksFiles = await glob('**/hooks/hooks.json', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });
  
  if (hooksFiles.length === 0) {
    logInfo('No hooks.json files found (optional)');
    return true;
  }
  
  let allValid = true;
  
  for (const file of hooksFiles) {
    const fullPath = path.join(__dirname, '..', file);
    
    if (!validateJSON(fullPath)) {
      allValid = false;
      continue;
    }
    
    const hooks = JSON.parse(fs.readFileSync(fullPath, 'utf8'));

    if (!hooks.hooks || typeof hooks.hooks !== 'object') {
      logError(`${file}: 'hooks' must be an object`);
      allValid = false;
      continue;
    }

    let totalHooks = 0;
    const validEvents = [
      'PreToolUse', 'PostToolUse', 'PermissionRequest', 'Notification',
      'UserPromptSubmit', 'Stop', 'SubagentStop', 'PreCompact',
      'SessionStart', 'SessionEnd'
    ];

    for (const [eventName, eventHandlers] of Object.entries(hooks.hooks)) {
      if (!validEvents.includes(eventName)) {
        logWarning(`${file}: Unknown event type '${eventName}'`);
      }

      if (!Array.isArray(eventHandlers)) {
        logError(`${file}: Event '${eventName}' handlers must be an array`);
        allValid = false;
        continue;
      }

      eventHandlers.forEach((handler, index) => {
        if (!handler.hooks || !Array.isArray(handler.hooks)) {
          logError(`${file}: Event '${eventName}' handler at index ${index} missing 'hooks' array`);
          allValid = false;
        } else {
          totalHooks += handler.hooks.length;
        }
      });
    }

    if (allValid) {
      logSuccess(`${file} is valid (${totalHooks} hook(s))`);
    }
  }
  
  return allValid;
}

/**
 * Validate MCP configuration files
 */
async function validateMCP() {
  logInfo('Validating .mcp.json files...');
  
  const mcpFiles = await glob('**/.mcp.json', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });
  
  if (mcpFiles.length === 0) {
    logInfo('No .mcp.json files found (optional)');
    return true;
  }
  
  let allValid = true;
  
  for (const file of mcpFiles) {
    const fullPath = path.join(__dirname, '..', file);
    
    if (!validateJSON(fullPath)) {
      allValid = false;
      continue;
    }
    
    const mcp = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
    
    // Basic validation
    if (!mcp.mcpServers || typeof mcp.mcpServers !== 'object') {
      logError(`${file}: 'mcpServers' must be an object`);
      allValid = false;
      continue;
    }
    
    const serverCount = Object.keys(mcp.mcpServers).length;
    logSuccess(`${file} is valid (${serverCount} MCP server(s))`);
  }
  
  return allValid;
}

/**
 * Main validation function
 */
async function main() {
  console.log(`\n${colors.cyan}=== Claude Code Plugin Marketplace Validation ===${colors.reset}\n`);
  
  const marketplaceValid = validateMarketplace();
  const pluginsValid = await validatePlugins();
  const hooksValid = await validateHooks();
  const mcpValid = await validateMCP();
  
  // Summary
  console.log(`\n${colors.cyan}=== Validation Summary ===${colors.reset}\n`);
  console.log(`${colors.green}✓ Successes: ${successes.length}${colors.reset}`);
  console.log(`${colors.yellow}⚠ Warnings: ${warnings.length}${colors.reset}`);
  console.log(`${colors.red}✗ Errors: ${errors.length}${colors.reset}\n`);
  
  if (errors.length > 0) {
    console.error(`${colors.red}Validation failed with ${errors.length} error(s)${colors.reset}`);
    process.exit(1);
  } else if (warnings.length > 0) {
    console.log(`${colors.yellow}Validation passed with ${warnings.length} warning(s)${colors.reset}`);
    process.exit(0);
  } else {
    console.log(`${colors.green}✓ All validations passed!${colors.reset}`);
    process.exit(0);
  }
}

// Run validation
main().catch(error => {
  console.error(`${colors.red}Validation script error: ${error.message}${colors.reset}`);
  console.error(error.stack);
  process.exit(1);
});


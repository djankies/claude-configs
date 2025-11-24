#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const VALID_EVENTS = [
  'PreToolUse', 'PermissionRequest', 'PostToolUse', 'UserPromptSubmit',
  'Notification', 'Stop', 'SubagentStop', 'SessionStart', 'SessionEnd', 'PreCompact'
];

function validatePluginManifest(filePath) {
  const errors = [];
  const warnings = [];

  if (!fs.existsSync(filePath)) {
    return { valid: false, errors: [`File not found: ${filePath}`], warnings: [] };
  }

  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    return { valid: false, errors: [`Invalid JSON: ${e.message}`], warnings: [] };
  }

  if (!manifest.name) {
    errors.push('Missing required field: name');
  } else if (typeof manifest.name !== 'string') {
    errors.push('Field "name" must be a string');
  } else if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(manifest.name)) {
    errors.push(`Field "name" must be kebab-case: got "${manifest.name}"`);
  }

  if (manifest.version !== undefined) {
    if (typeof manifest.version !== 'string') {
      errors.push('Field "version" must be a string');
    } else if (!/^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$/.test(manifest.version)) {
      errors.push(`Field "version" must be semver: got "${manifest.version}"`);
    }
  }

  if (manifest.description !== undefined && typeof manifest.description !== 'string') {
    errors.push('Field "description" must be a string');
  }

  if (manifest.author !== undefined) {
    if (typeof manifest.author !== 'object' || manifest.author === null) {
      errors.push('Field "author" must be an object');
    } else {
      if (manifest.author.name !== undefined && typeof manifest.author.name !== 'string') {
        errors.push('Field "author.name" must be a string');
      }
      if (manifest.author.email !== undefined && typeof manifest.author.email !== 'string') {
        errors.push('Field "author.email" must be a string');
      }
      if (manifest.author.url !== undefined && typeof manifest.author.url !== 'string') {
        errors.push('Field "author.url" must be a string');
      }
    }
  }

  ['homepage', 'repository', 'license'].forEach(field => {
    if (manifest[field] !== undefined && typeof manifest[field] !== 'string') {
      errors.push(`Field "${field}" must be a string`);
    }
  });

  if (manifest.keywords !== undefined) {
    if (!Array.isArray(manifest.keywords)) {
      errors.push('Field "keywords" must be an array');
    } else if (!manifest.keywords.every(k => typeof k === 'string')) {
      errors.push('Field "keywords" must contain only strings');
    }
  }

  ['commands', 'agents'].forEach(field => {
    if (manifest[field] !== undefined) {
      const val = manifest[field];
      if (typeof val !== 'string' && !Array.isArray(val)) {
        errors.push(`Field "${field}" must be a string or array`);
      } else if (Array.isArray(val) && !val.every(p => typeof p === 'string')) {
        errors.push(`Field "${field}" array must contain only strings`);
      } else {
        const paths = Array.isArray(val) ? val : [val];
        paths.forEach(p => {
          if (!p.startsWith('./')) {
            warnings.push(`Path "${p}" in "${field}" should start with "./" (relative path)`);
          }
        });
      }
    }
  });

  ['hooks', 'mcpServers'].forEach(field => {
    if (manifest[field] !== undefined) {
      const val = manifest[field];
      if (typeof val !== 'string' && (typeof val !== 'object' || val === null)) {
        errors.push(`Field "${field}" must be a string path or inline object`);
      } else if (typeof val === 'string' && !val.startsWith('./')) {
        warnings.push(`Path "${val}" in "${field}" should start with "./" (relative path)`);
      }
    }
  });

  if (typeof manifest.hooks === 'object' && manifest.hooks !== null && manifest.hooks.hooks) {
    const hooksObj = manifest.hooks.hooks;
    Object.keys(hooksObj).forEach(event => {
      if (!VALID_EVENTS.includes(event)) {
        errors.push(`Unknown hook event: "${event}". Valid: ${VALID_EVENTS.join(', ')}`);
      }
    });
  }

  const nodeFields = ['main', 'engines', 'dependencies', 'devDependencies', 'scripts'];
  nodeFields.forEach(field => {
    if (manifest[field] !== undefined) {
      warnings.push(`Field "${field}" is a Node.js field and will be ignored by Claude Code`);
    }
  });

  return { valid: errors.length === 0, errors, warnings };
}

function main() {
  const filePath = process.argv[2];

  if (!filePath) {
    console.log('USAGE: validate-plugin-manifest.js <path-to-plugin.json>');
    process.exit(1);
  }

  const result = validatePluginManifest(path.resolve(filePath));

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

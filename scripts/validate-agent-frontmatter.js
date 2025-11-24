#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const VALID_MODELS = ['haiku', 'sonnet', 'opus', 'inherit'];
const VALID_PERMISSION_MODES = ['default', 'acceptEdits', 'bypassPermissions', 'plan', 'ignore'];

function extractFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return null;

  const yaml = match[1];
  const frontmatter = {};

  yaml.split('\n').forEach(line => {
    const colonIndex = line.indexOf(':');
    if (colonIndex > 0) {
      const key = line.slice(0, colonIndex).trim();
      const value = line.slice(colonIndex + 1).trim();
      frontmatter[key] = value.replace(/^["']|["']$/g, '');
    }
  });

  return frontmatter;
}

function validateAgentFrontmatter(filePath) {
  const errors = [];
  const warnings = [];

  if (!fs.existsSync(filePath)) {
    return { valid: false, errors: [`File not found: ${filePath}`], warnings: [] };
  }

  const content = fs.readFileSync(filePath, 'utf8');

  if (!content.startsWith('---')) {
    return { valid: false, errors: ['Missing frontmatter (file must start with ---)'], warnings: [] };
  }

  const frontmatter = extractFrontmatter(content);
  if (!frontmatter) {
    return { valid: false, errors: ['Invalid frontmatter format (missing closing ---)'], warnings: [] };
  }

  if (!frontmatter.name) {
    errors.push('Missing required field: name');
  } else {
    const name = frontmatter.name;

    if (typeof name !== 'string') {
      errors.push('Field "name" must be a string');
    } else if (!/^[a-z]+(-[a-z]+)*$/.test(name)) {
      errors.push(`Field "name" must use lowercase letters and hyphens only: got "${name}"`);
    }
  }

  if (!frontmatter.description) {
    errors.push('Missing required field: description');
  } else if (typeof frontmatter.description !== 'string') {
    errors.push('Field "description" must be a string');
  }

  if (frontmatter.tools !== undefined) {
    const tools = frontmatter.tools;
    if (typeof tools !== 'string') {
      errors.push('Field "tools" must be a comma-separated string');
    }
  }

  if (frontmatter.model !== undefined) {
    const model = frontmatter.model;
    if (!VALID_MODELS.includes(model)) {
      errors.push(`Field "model" must be one of: ${VALID_MODELS.join(', ')}. Got "${model}"`);
    }
  }

  if (frontmatter.permissionMode !== undefined) {
    const mode = frontmatter.permissionMode;
    if (!VALID_PERMISSION_MODES.includes(mode)) {
      errors.push(`Field "permissionMode" must be one of: ${VALID_PERMISSION_MODES.join(', ')}. Got "${mode}"`);
    }
  }

  if (frontmatter.skills !== undefined) {
    const skills = frontmatter.skills;
    if (typeof skills !== 'string') {
      errors.push('Field "skills" must be a comma-separated string');
    }
  }

  const validFields = ['name', 'description', 'tools', 'model', 'permissionMode', 'skills'];
  Object.keys(frontmatter).forEach(key => {
    if (!validFields.includes(key)) {
      warnings.push(`Unknown frontmatter field: "${key}"`);
    }
  });

  return { valid: errors.length === 0, errors, warnings };
}

function main() {
  const filePath = process.argv[2];

  if (!filePath) {
    console.log('USAGE: validate-agent-frontmatter.js <path-to-agent.md>');
    process.exit(1);
  }

  const result = validateAgentFrontmatter(path.resolve(filePath));

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

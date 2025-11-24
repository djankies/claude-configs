#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const RESERVED_WORDS = ['anthropic', 'claude'];
const VALID_MODELS = ['haiku', 'sonnet', 'opus'];
const MAX_NAME_LENGTH = 64;
const MAX_DESCRIPTION_LENGTH = 1024;

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

function validateSkillFrontmatter(filePath) {
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
    } else {
      if (name.length > MAX_NAME_LENGTH) {
        errors.push(`Field "name" exceeds ${MAX_NAME_LENGTH} characters: ${name.length}`);
      }

      if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(name)) {
        errors.push(`Field "name" must be kebab-case (lowercase, hyphens): got "${name}"`);
      }

      RESERVED_WORDS.forEach(word => {
        if (name.toLowerCase().includes(word)) {
          errors.push(`Field "name" contains reserved word: "${word}"`);
        }
      });

      const gerundPattern = /ing(-|$)/;
      if (!gerundPattern.test(name)) {
        warnings.push(`Field "name" should use gerund form (verb + -ing): got "${name}"`);
      }
    }
  }

  if (!frontmatter.description) {
    errors.push('Missing required field: description');
  } else {
    const desc = frontmatter.description;

    if (desc.length > MAX_DESCRIPTION_LENGTH) {
      errors.push(`Field "description" exceeds ${MAX_DESCRIPTION_LENGTH} characters: ${desc.length}`);
    }

    if (/<[^>]+>/.test(desc)) {
      errors.push('Field "description" must not contain XML tags');
    }

    const hasAction = /\b(does|provides|creates|generates|validates|reviews|analyzes|processes)\b/i.test(desc);
    const hasTrigger = /\b(use when|use for|use if|when)\b/i.test(desc);

    if (!hasAction && !hasTrigger) {
      warnings.push('Field "description" should follow format: "Does X. Use when Y."');
    }
  }

  if (frontmatter['allowed-tools'] !== undefined) {
    const tools = frontmatter['allowed-tools'];
    if (typeof tools !== 'string') {
      errors.push('Field "allowed-tools" must be a string');
    }
  }

  if (frontmatter.version !== undefined) {
    const version = frontmatter.version;
    if (!/^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$/.test(version)) {
      warnings.push(`Field "version" should be semver: got "${version}"`);
    }
  }

  if (frontmatter.model !== undefined) {
    const model = frontmatter.model;
    if (!VALID_MODELS.includes(model)) {
      errors.push(`Field "model" must be one of: ${VALID_MODELS.join(', ')}. Got "${model}"`);
    }
  }

  const lines = content.split('\n').length;
  if (lines > 500) {
    warnings.push(`SKILL.md exceeds 500 lines (${lines} lines). Consider using references/ for detailed content`);
  }

  return { valid: errors.length === 0, errors, warnings };
}

function main() {
  const filePath = process.argv[2];

  if (!filePath) {
    console.log('USAGE: validate-skill-frontmatter.js <path-to-SKILL.md>');
    process.exit(1);
  }

  const result = validateSkillFrontmatter(path.resolve(filePath));

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

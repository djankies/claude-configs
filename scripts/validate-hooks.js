#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const VALID_EVENTS = [
  'PreToolUse', 'PermissionRequest', 'PostToolUse', 'UserPromptSubmit',
  'Notification', 'Stop', 'SubagentStop', 'SessionStart', 'SessionEnd', 'PreCompact'
];

const EVENTS_WITH_OPTIONAL_MATCHER = [
  'UserPromptSubmit', 'Stop', 'SubagentStop', 'PreCompact', 'SessionStart', 'SessionEnd'
];

const VALID_HOOK_TYPES = ['command', 'prompt'];

const PROMPT_SUPPORTED_EVENTS = [
  'Stop', 'SubagentStop', 'UserPromptSubmit', 'PreToolUse', 'PermissionRequest'
];

function validateHooks(filePath) {
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

  if (!config.hooks) {
    return { valid: false, errors: ['Missing required field: hooks'], warnings: [] };
  }

  if (typeof config.hooks !== 'object' || config.hooks === null || Array.isArray(config.hooks)) {
    return { valid: false, errors: ['Field "hooks" must be an object'], warnings: [] };
  }

  Object.entries(config.hooks).forEach(([eventName, matchers]) => {
    const eventPath = `hooks.${eventName}`;

    if (!VALID_EVENTS.includes(eventName)) {
      errors.push(`Unknown event "${eventName}". Valid: ${VALID_EVENTS.join(', ')}`);
      return;
    }

    if (!Array.isArray(matchers)) {
      errors.push(`${eventPath} must be an array`);
      return;
    }

    matchers.forEach((matcher, mi) => {
      const matcherPath = `${eventPath}[${mi}]`;

      if (typeof matcher !== 'object' || matcher === null) {
        errors.push(`${matcherPath} must be an object`);
        return;
      }

      if (matcher.matcher !== undefined) {
        if (typeof matcher.matcher !== 'string') {
          errors.push(`${matcherPath}.matcher must be a string`);
        }
      } else if (!EVENTS_WITH_OPTIONAL_MATCHER.includes(eventName)) {
        warnings.push(`${matcherPath}.matcher is recommended for ${eventName} event`);
      }

      if (!matcher.hooks) {
        errors.push(`${matcherPath}.hooks is required`);
        return;
      }

      if (!Array.isArray(matcher.hooks)) {
        errors.push(`${matcherPath}.hooks must be an array`);
        return;
      }

      matcher.hooks.forEach((hook, hi) => {
        const hookPath = `${matcherPath}.hooks[${hi}]`;

        if (typeof hook !== 'object' || hook === null) {
          errors.push(`${hookPath} must be an object`);
          return;
        }

        if (!hook.type) {
          errors.push(`${hookPath}.type is required`);
        } else if (!VALID_HOOK_TYPES.includes(hook.type)) {
          errors.push(`${hookPath}.type must be "command" or "prompt", got "${hook.type}"`);
        } else if (hook.type === 'command') {
          if (!hook.command) {
            errors.push(`${hookPath}.command is required when type is "command"`);
          } else if (typeof hook.command !== 'string') {
            errors.push(`${hookPath}.command must be a string`);
          }
          if (hook.prompt !== undefined) {
            warnings.push(`${hookPath}.prompt is ignored when type is "command"`);
          }
        } else if (hook.type === 'prompt') {
          if (!hook.prompt) {
            errors.push(`${hookPath}.prompt is required when type is "prompt"`);
          } else if (typeof hook.prompt !== 'string') {
            errors.push(`${hookPath}.prompt must be a string`);
          }
          if (hook.command !== undefined) {
            warnings.push(`${hookPath}.command is ignored when type is "prompt"`);
          }
          if (!PROMPT_SUPPORTED_EVENTS.includes(eventName)) {
            errors.push(`${hookPath}: prompt type not supported for ${eventName}. Supported: ${PROMPT_SUPPORTED_EVENTS.join(', ')}`);
          }
        }

        if (hook.timeout !== undefined) {
          if (typeof hook.timeout !== 'number' || hook.timeout <= 0) {
            errors.push(`${hookPath}.timeout must be a positive number`);
          }
        }

        if (hook.description !== undefined && typeof hook.description !== 'string') {
          errors.push(`${hookPath}.description must be a string`);
        }
      });
    });
  });

  return { valid: errors.length === 0, errors, warnings };
}

function main() {
  const filePath = process.argv[2];

  if (!filePath) {
    console.log('USAGE: validate-hooks.js <path-to-hooks.json>');
    process.exit(1);
  }

  const result = validateHooks(path.resolve(filePath));

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

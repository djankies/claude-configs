#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function validatePluginStructure(pluginPath) {
  const errors = [];
  const warnings = [];

  const absPath = path.resolve(pluginPath);

  if (!fs.existsSync(absPath)) {
    return { valid: false, errors: [`Plugin directory not found: ${absPath}`], warnings: [] };
  }

  if (!fs.statSync(absPath).isDirectory()) {
    return { valid: false, errors: [`Path is not a directory: ${absPath}`], warnings: [] };
  }

  const pluginJsonPath = path.join(absPath, '.claude-plugin', 'plugin.json');
  if (!fs.existsSync(pluginJsonPath)) {
    errors.push('Missing required file: .claude-plugin/plugin.json');
  }

  const claudePluginDir = path.join(absPath, '.claude-plugin');
  if (fs.existsSync(claudePluginDir)) {
    const invalidDirs = ['commands', 'skills', 'agents', 'hooks'];
    invalidDirs.forEach(dir => {
      const invalidPath = path.join(claudePluginDir, dir);
      if (fs.existsSync(invalidPath)) {
        errors.push(`Component directory "${dir}" must be at plugin root, not inside .claude-plugin/`);
      }
    });
  }

  const skillsDir = path.join(absPath, 'skills');
  if (fs.existsSync(skillsDir) && fs.statSync(skillsDir).isDirectory()) {
    const skillSubdirs = fs.readdirSync(skillsDir).filter(item => {
      const itemPath = path.join(skillsDir, item);
      return fs.statSync(itemPath).isDirectory();
    });

    skillSubdirs.forEach(skillDir => {
      const skillMdPath = path.join(skillsDir, skillDir, 'SKILL.md');
      if (!fs.existsSync(skillMdPath)) {
        errors.push(`Missing SKILL.md in skills/${skillDir}/`);
      }
    });
  }

  const commandsDir = path.join(absPath, 'commands');
  if (fs.existsSync(commandsDir) && fs.statSync(commandsDir).isDirectory()) {
    const commandFiles = fs.readdirSync(commandsDir).filter(f => f.endsWith('.md'));
    if (commandFiles.length === 0) {
      warnings.push('commands/ directory exists but contains no .md files');
    }
  }

  const agentsDir = path.join(absPath, 'agents');
  if (fs.existsSync(agentsDir) && fs.statSync(agentsDir).isDirectory()) {
    const agentFiles = fs.readdirSync(agentsDir).filter(f => f.endsWith('.md'));
    if (agentFiles.length === 0) {
      warnings.push('agents/ directory exists but contains no .md files');
    }
  }

  const hooksDir = path.join(absPath, 'hooks');
  if (fs.existsSync(hooksDir) && fs.statSync(hooksDir).isDirectory()) {
    const hooksJsonPath = path.join(hooksDir, 'hooks.json');
    if (!fs.existsSync(hooksJsonPath)) {
      errors.push('hooks/ directory exists but missing hooks.json');
    }
  }

  const mcpJsonPath = path.join(absPath, '.mcp.json');
  if (fs.existsSync(pluginJsonPath)) {
    try {
      const manifest = JSON.parse(fs.readFileSync(pluginJsonPath, 'utf8'));

      const checkPath = (fieldName, fieldValue) => {
        if (!fieldValue) return;
        const paths = Array.isArray(fieldValue) ? fieldValue : [fieldValue];
        paths.forEach(p => {
          if (typeof p === 'string') {
            const resolved = p.startsWith('./') ? path.join(absPath, p.slice(2)) : path.join(absPath, p);
            if (!fs.existsSync(resolved)) {
              errors.push(`Path in plugin.json "${fieldName}" does not exist: ${p}`);
            }
          }
        });
      };

      checkPath('commands', manifest.commands);
      checkPath('agents', manifest.agents);

      if (typeof manifest.hooks === 'string') {
        checkPath('hooks', manifest.hooks);
      }

      if (typeof manifest.mcpServers === 'string') {
        checkPath('mcpServers', manifest.mcpServers);
      }
    } catch (e) {
      errors.push(`Failed to parse plugin.json: ${e.message}`);
    }
  }

  return { valid: errors.length === 0, errors, warnings };
}

function main() {
  const args = process.argv.slice(2);
  let pluginPath = null;
  let outputFormat = 'json';

  for (const arg of args) {
    if (arg === '--summary') {
      outputFormat = 'summary';
    } else if (arg === '--json') {
      outputFormat = 'json';
    } else if (arg === '-h' || arg === '--help') {
      console.log('USAGE: validate-plugin-structure.js [OPTIONS] <plugin-directory>');
      console.log('\nOptions:');
      console.log('  --summary    Output one-line summary');
      console.log('  --json       Output full JSON (default)');
      console.log('\nValidates:');
      console.log('  - .claude-plugin/plugin.json exists');
      console.log('  - Component directories at plugin root (not inside .claude-plugin/)');
      console.log('  - Each skills/*/ contains SKILL.md');
      console.log('  - Paths referenced in plugin.json exist');
      process.exit(0);
    } else if (!pluginPath) {
      pluginPath = arg;
    }
  }

  if (!pluginPath) {
    console.error('ERROR: Plugin directory required');
    process.exit(2);
  }

  const result = validatePluginStructure(pluginPath);
  const pluginName = path.basename(path.resolve(pluginPath));
  const errorCount = result.errors.length;
  const warnCount = result.warnings.length;

  if (outputFormat === 'summary') {
    if (result.valid) {
      console.log(`✅ ${pluginName.padEnd(40)} errors=0 warnings=${warnCount}`);
    } else {
      console.log(`❌ ${pluginName.padEnd(40)} errors=${errorCount} warnings=${warnCount}`);
    }
  } else {
    console.log(JSON.stringify({
      review_type: 'structure',
      plugin: pluginName,
      issues: [
        ...result.errors.map(e => ({ severity: 'error', description: e })),
        ...result.warnings.map(w => ({ severity: 'warning', description: w }))
      ],
      compliant: result.valid
    }, null, 2));
  }

  process.exit(result.valid ? 0 : 1);
}

main();

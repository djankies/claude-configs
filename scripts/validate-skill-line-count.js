#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const MAX_LINES = 500;
const WARN_THRESHOLD = 300;

function validateSkillLineCount(skillPath) {
  const errors = [];
  const warnings = [];

  const absPath = path.resolve(skillPath);

  if (!fs.existsSync(absPath)) {
    return { valid: false, errors: [`File not found: ${absPath}`], warnings: [], lineCount: 0 };
  }

  const content = fs.readFileSync(absPath, 'utf8');
  const lines = content.split('\n');
  const lineCount = lines.length;

  if (lineCount > MAX_LINES) {
    errors.push(`SKILL.md exceeds ${MAX_LINES} lines (${lineCount} lines). Extract detailed content to references/`);
  } else if (lineCount > WARN_THRESHOLD) {
    const skillDir = path.dirname(absPath);
    const referencesDir = path.join(skillDir, 'references');

    if (!fs.existsSync(referencesDir)) {
      warnings.push(`SKILL.md has ${lineCount} lines (>${WARN_THRESHOLD}). Consider using references/ for detailed content`);
    }
  }

  return { valid: errors.length === 0, errors, warnings, lineCount };
}

function validatePluginSkills(pluginPath) {
  const absPath = path.resolve(pluginPath);
  const skillsDir = path.join(absPath, 'skills');

  if (!fs.existsSync(skillsDir)) {
    return {
      review_type: 'skill_line_count',
      plugin: path.basename(absPath),
      skills: [],
      issues: [],
      compliant: true
    };
  }

  const skills = [];
  const issues = [];

  const skillSubdirs = fs.readdirSync(skillsDir).filter(item => {
    const itemPath = path.join(skillsDir, item);
    return fs.statSync(itemPath).isDirectory();
  });

  skillSubdirs.forEach(skillDir => {
    const skillMdPath = path.join(skillsDir, skillDir, 'SKILL.md');

    if (fs.existsSync(skillMdPath)) {
      const result = validateSkillLineCount(skillMdPath);

      skills.push({
        name: skillDir,
        path: `skills/${skillDir}/SKILL.md`,
        lineCount: result.lineCount,
        compliant: result.valid
      });

      result.errors.forEach(e => {
        issues.push({
          severity: 'error',
          file: `skills/${skillDir}/SKILL.md`,
          description: e
        });
      });

      result.warnings.forEach(w => {
        issues.push({
          severity: 'warning',
          file: `skills/${skillDir}/SKILL.md`,
          description: w
        });
      });
    }
  });

  const compliant = issues.filter(i => i.severity === 'error').length === 0;

  return {
    review_type: 'skill_line_count',
    plugin: path.basename(absPath),
    skills,
    issues,
    compliant
  };
}

function main() {
  const args = process.argv.slice(2);
  let inputPath = null;
  let outputFormat = 'json';

  for (const arg of args) {
    if (arg === '--summary') {
      outputFormat = 'summary';
    } else if (arg === '--json') {
      outputFormat = 'json';
    } else if (arg === '-h' || arg === '--help') {
      console.log('USAGE: validate-skill-line-count.js [OPTIONS] <path>');
      console.log('\nOptions:');
      console.log('  --summary    Output one-line summary');
      console.log('  --json       Output full JSON (default)');
      console.log('\nPath can be:');
      console.log('  - Plugin directory: validates all skills/*/SKILL.md');
      console.log('  - Single SKILL.md file: validates that file only');
      console.log('\nLimits:');
      console.log(`  - Error: >${MAX_LINES} lines`);
      console.log(`  - Warning: >${WARN_THRESHOLD} lines without references/`);
      process.exit(0);
    } else if (!inputPath) {
      inputPath = arg;
    }
  }

  if (!inputPath) {
    console.error('ERROR: Path required');
    process.exit(2);
  }

  const absPath = path.resolve(inputPath);

  if (!fs.existsSync(absPath)) {
    console.error(`ERROR: Path not found: ${absPath}`);
    process.exit(2);
  }

  let result;

  if (fs.statSync(absPath).isDirectory()) {
    result = validatePluginSkills(absPath);
  } else {
    const singleResult = validateSkillLineCount(absPath);
    result = {
      review_type: 'skill_line_count',
      file: inputPath,
      lineCount: singleResult.lineCount,
      issues: [
        ...singleResult.errors.map(e => ({ severity: 'error', description: e })),
        ...singleResult.warnings.map(w => ({ severity: 'warning', description: w }))
      ],
      compliant: singleResult.valid
    };
  }

  if (outputFormat === 'summary') {
    const name = result.plugin || path.basename(inputPath);
    const skillCount = result.skills ? result.skills.length : 1;
    const errorCount = result.issues.filter(i => i.severity === 'error').length;
    const overLimit = result.skills ? result.skills.filter(s => !s.compliant).map(s => s.name) : [];

    if (result.compliant) {
      console.log(`✅ ${name.padEnd(40)} skills=${skillCount} over_limit=0`);
    } else {
      console.log(`❌ ${name.padEnd(40)} skills=${skillCount} over_limit=${overLimit.length} [${overLimit.join(', ')}]`);
    }
  } else {
    console.log(JSON.stringify(result, null, 2));
  }

  process.exit(result.compliant ? 0 : 1);
}

main();

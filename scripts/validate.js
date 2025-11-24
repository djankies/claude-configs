#!/usr/bin/env node

/**
 * Validation script for Claude Code Plugin Marketplace
 *
 * This script validates:
 * - marketplace.json structure and required fields
 * - plugin.json files in all plugins
 * - Skills directory structure (skills subdirectories with SKILL.md)
 * - Commands directory structure (commands with .md files)
 * - Agents directory structure (agents with .md files)
 * - Component directory placement (must be at plugin root)
 * - hooks.json files
 * - .mcp.json MCP server configurations
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
  additionalProperties: false,
  properties: {
    name: {
      type: 'string',
      pattern: '^[a-z0-9]+(-[a-z0-9]+)*$', // kebab-case
      description: 'Marketplace name in kebab-case'
    },
    owner: {
      type: 'object',
      additionalProperties: false,
      properties: {
        name: { type: 'string' },
        email: { type: 'string', format: 'email' }
      },
      required: ['name', 'email']
    },
    metadata: {
      type: 'object',
      additionalProperties: false,
      properties: {
        description: { type: 'string' },
        version: { type: 'string', pattern: '^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9]+)?$' },
        pluginRoot: { type: 'string' }
      }
    },
    plugins: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
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
                  source: { type: 'string', enum: ['git', 'url'] },
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
          },
          version: { type: 'string', pattern: '^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9]+)?$' },
          description: { type: 'string' },
          author: {
            type: 'object',
            additionalProperties: false,
            properties: {
              name: { type: 'string' },
              email: { type: 'string', format: 'email' },
              url: { type: 'string', format: 'uri' }
            },
            required: ['name']
          },
          homepage: { type: 'string', format: 'uri' },
          repository: { type: 'string' },
          license: { type: 'string' },
          keywords: { type: 'array', items: { type: 'string' } },
          category: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } },
          strict: { type: 'boolean' },
          commands: {
            oneOf: [
              { type: 'string' },
              { type: 'array', items: { type: 'string' } }
            ]
          },
          agents: {
            oneOf: [
              { type: 'string' },
              { type: 'array', items: { type: 'string' } }
            ]
          },
          hooks: {
            oneOf: [
              { type: 'string' },
              { type: 'object' }
            ]
          },
          mcpServers: {
            oneOf: [
              { type: 'string' },
              { type: 'object' }
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
  additionalProperties: false,
  properties: {
    name: { type: 'string', pattern: '^[a-z0-9]+(-[a-z0-9]+)*$' },
    version: { type: 'string', pattern: '^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9]+)?$' },
    description: { type: 'string' },
    author: {
      type: 'object',
      additionalProperties: false,
      properties: {
        name: { type: 'string' },
        email: { type: 'string', format: 'email' },
        url: { type: 'string', format: 'uri' }
      },
      required: ['name']
    },
    homepage: { type: 'string', format: 'uri' },
    repository: { type: 'string' },
    license: { type: 'string' },
    keywords: { type: 'array', items: { type: 'string' } },
    commands: {
      oneOf: [
        { type: 'string' },
        { type: 'array', items: { type: 'string' } }
      ]
    },
    agents: {
      oneOf: [
        { type: 'string' },
        { type: 'array', items: { type: 'string' } }
      ]
    },
    hooks: {
      oneOf: [
        { type: 'string' },
        { type: 'object' }
      ]
    },
    mcpServers: {
      oneOf: [
        { type: 'string' },
        { type: 'object' }
      ]
    }
  },
  required: ['name']
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
    const pluginDir = path.dirname(path.dirname(fullPath));
    const pluginDirName = path.basename(pluginDir);
    const isTemplate = pluginDirName === 'plugin-template';

    if (!validateJSON(fullPath)) {
      allValid = false;
      continue;
    }

    const plugin = JSON.parse(fs.readFileSync(fullPath, 'utf8'));

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

    if (!plugin.version) {
      logWarning(`${file}: Missing 'version' field (recommended)`);
    }
    if (!plugin.description) {
      logWarning(`${file}: Missing 'description' field (recommended)`);
    }
    if (!plugin.author) {
      logWarning(`${file}: Missing 'author' field (recommended)`);
    }
    if (!plugin.repository) {
      logWarning(`${file}: Missing 'repository' field (recommended)`);
    }
    if (!plugin.license) {
      logWarning(`${file}: Missing 'license' field (recommended)`);
    }

    if (plugin.commands === './commands' || plugin.commands === 'commands') {
      logWarning(`${file}: Redundant 'commands' path (commands/ is auto-discovered)`);
    }
    if (plugin.agents === './agents' || plugin.agents === 'agents') {
      logWarning(`${file}: Redundant 'agents' path (agents/ is auto-discovered)`);
    }
    if (plugin.skills === './skills' || plugin.skills === 'skills') {
      logWarning(`${file}: Redundant 'skills' path (skills/ is auto-discovered)`);
    }
    if (plugin.hooks === './hooks/hooks.json' || plugin.hooks === 'hooks/hooks.json') {
      logWarning(`${file}: Redundant 'hooks' path (hooks/hooks.json is auto-discovered)`);
    }

    if (!isTemplate) {
      const validatePath = (pathValue, fieldName) => {
        if (typeof pathValue === 'string') {
          if (!pathValue.startsWith('./')) {
            logWarning(`${file}: ${fieldName} path should start with './' (got '${pathValue}')`);
          }
          const fullRefPath = path.join(pluginDir, pathValue);
          if (!fs.existsSync(fullRefPath)) {
            logError(`${file}: ${fieldName} path '${pathValue}' does not exist`);
            allValid = false;
          }
        } else if (Array.isArray(pathValue)) {
          pathValue.forEach((p, idx) => {
            if (!p.startsWith('./')) {
              logWarning(`${file}: ${fieldName}[${idx}] path should start with './' (got '${p}')`);
            }
            const fullRefPath = path.join(pluginDir, p);
            if (!fs.existsSync(fullRefPath)) {
              logError(`${file}: ${fieldName}[${idx}] path '${p}' does not exist`);
              allValid = false;
            }
          });
        }
      };

      if (plugin.commands) validatePath(plugin.commands, 'commands');
      if (plugin.agents) validatePath(plugin.agents, 'agents');
      if (plugin.hooks && typeof plugin.hooks === 'string') validatePath(plugin.hooks, 'hooks');
      if (plugin.mcpServers && typeof plugin.mcpServers === 'string') validatePath(plugin.mcpServers, 'mcpServers');
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
 * Validate skill name format (lowercase, hyphen-separated, gerund form)
 */
function validateSkillNameFormat(name, context) {
  const kebabCasePattern = /^[a-z0-9]+(-[a-z0-9]+)*$/;

  if (!kebabCasePattern.test(name)) {
    logError(`${context}: Skill name '${name}' must be lowercase and hyphen-separated`);
    return false;
  }

  const gerundPattern = /^[a-z]+ing(-|$)/;
  if (!gerundPattern.test(name)) {
    logError(`${context}: Skill name '${name}' must begin with a verb in gerund form (verb + -ing)`);
    return false;
  }

  return true;
}

/**
 * Validate skills directory structure
 */
async function validateSkills() {
  logInfo('Validating skills/ directories...');

  const skillDirs = await glob('**/skills/*/', {
    ignore: ['node_modules/**', '.git/**', 'plugin-template/skills/**'],
    cwd: path.join(__dirname, '..')
  });

  if (skillDirs.length === 0) {
    logInfo('No skills/ directories found (optional)');
    return true;
  }

  let allValid = true;
  let totalSkills = 0;
  const existingSkills = new Set();

  for (const skillDir of skillDirs) {
    const skillMdPath = path.join(__dirname, '..', skillDir, 'SKILL.md');
    const dirName = path.basename(skillDir.replace(/\/$/, ''));

    if (!validateSkillNameFormat(dirName, skillDir)) {
      allValid = false;
    }

    if (!fs.existsSync(skillMdPath)) {
      logWarning(`${skillDir}: Missing SKILL.md file (skills should contain SKILL.md)`);
      allValid = false;
    } else {
      totalSkills++;
      existingSkills.add(dirName);

      const content = fs.readFileSync(skillMdPath, 'utf8');
      const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);

      if (!frontmatterMatch) {
        logWarning(`${skillDir}SKILL.md: Missing frontmatter (should have name and description)`);
      } else {
        const frontmatter = frontmatterMatch[1];
        const nameMatch = frontmatter.match(/^name:\s*(.+)$/m);
        const hasDescription = /^description:\s*.+$/m.test(frontmatter);

        if (!nameMatch) {
          logWarning(`${skillDir}SKILL.md: Missing 'name' in frontmatter`);
        } else {
          const frontmatterName = nameMatch[1].trim();

          if (!validateSkillNameFormat(frontmatterName, `${skillDir}SKILL.md`)) {
            allValid = false;
          }

          if (frontmatterName !== dirName) {
            logError(`${skillDir}SKILL.md: Frontmatter name '${frontmatterName}' does not match directory name '${dirName}'`);
            allValid = false;
          }
        }

        if (!hasDescription) {
          logWarning(`${skillDir}SKILL.md: Missing 'description' in frontmatter`);
        }
      }
    }
  }

  if (totalSkills > 0) {
    logSuccess(`Found ${totalSkills} valid skill(s)`);
  }

  return { allValid, existingSkills };
}

/**
 * Validate skill references in shell scripts
 */
async function validateSkillReferences(existingSkills) {
  logInfo('Validating skill references in .sh scripts...');

  const shellScripts = await glob('**/*.sh', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });

  if (shellScripts.length === 0) {
    logInfo('No .sh scripts found (optional)');
    return true;
  }

  let allValid = true;
  let totalReferences = 0;

  const skillReferencePattern = /skills\/([a-z0-9-]+)/g;

  for (const scriptPath of shellScripts) {
    const fullPath = path.join(__dirname, '..', scriptPath);
    const content = fs.readFileSync(fullPath, 'utf8');
    const matches = [...content.matchAll(skillReferencePattern)];

    if (matches.length === 0) {
      continue;
    }

    for (const match of matches) {
      const referencedSkill = match[1];
      totalReferences++;

      if (!validateSkillNameFormat(referencedSkill, `${scriptPath}:${match.index}`)) {
        allValid = false;
      }

      if (!existingSkills.has(referencedSkill)) {
        logError(`${scriptPath}: References non-existent skill '${referencedSkill}'`);
        allValid = false;
      }
    }
  }

  if (totalReferences > 0) {
    logSuccess(`Validated ${totalReferences} skill reference(s) in shell scripts`);
  } else {
    logInfo('No skill references found in shell scripts');
  }

  return allValid;
}

/**
 * Validate commands directory structure
 */
async function validateCommands() {
  logInfo('Validating commands/ directories...');

  const commandDirs = await glob('**/commands/', {
    ignore: ['node_modules/**', '.git/**', '.claude/commands/'],
    cwd: path.join(__dirname, '..')
  });

  if (commandDirs.length === 0) {
    logInfo('No commands/ directories found (optional)');
    return true;
  }

  let totalCommands = 0;

  for (const commandDir of commandDirs) {
    const fullPath = path.join(__dirname, '..', commandDir);
    const commandFiles = await glob('*.md', { cwd: fullPath });

    if (commandFiles.length === 0) {
      logWarning(`${commandDir}: Directory exists but contains no .md files`);
    } else {
      totalCommands += commandFiles.length;
    }
  }

  if (totalCommands > 0) {
    logSuccess(`Found ${totalCommands} command file(s)`);
  }

  return true;
}

/**
 * Validate agents directory structure
 */
async function validateAgents() {
  logInfo('Validating agents/ directories...');

  const agentDirs = await glob('**/agents/', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });

  if (agentDirs.length === 0) {
    logInfo('No agents/ directories found (optional)');
    return true;
  }

  let totalAgents = 0;

  for (const agentDir of agentDirs) {
    const fullPath = path.join(__dirname, '..', agentDir);
    const agentFiles = await glob('*.md', { cwd: fullPath });

    if (agentFiles.length === 0) {
      logWarning(`${agentDir}: Directory exists but contains no .md files`);
    } else {
      totalAgents += agentFiles.length;
    }
  }

  if (totalAgents > 0) {
    logSuccess(`Found ${totalAgents} agent file(s)`);
  }

  return true;
}

/**
 * Validate directory placement
 */
async function validateDirectoryPlacement() {
  logInfo('Validating directory placement...');

  const misplacedDirs = await glob('.claude-plugin/{commands,agents,skills,hooks}/', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });

  if (misplacedDirs.length > 0) {
    misplacedDirs.forEach(dir => {
      logError(`${dir}: Component directories must be at plugin root, not inside .claude-plugin/`);
    });
    return false;
  }

  logSuccess('All component directories are correctly placed');
  return true;
}

/**
 * Validate plugin directory structure
 */
async function validatePluginDirectoryStructure() {
  logInfo('Validating plugin directory structures...');

  const pluginFiles = await glob('**/.claude-plugin/plugin.json', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });

  if (pluginFiles.length === 0) {
    logInfo('No plugins found');
    return true;
  }

  const allowedDirs = new Set([
    '.claude-plugin',
    'commands',
    'agents',
    'hooks',
    'knowledge',
    'scripts',
    'skills',
    'stress-test',
    'test-cases',
    'research',
    'node_modules'
  ]);

  let allValid = true;

  for (const file of pluginFiles) {
    const pluginDir = path.dirname(path.dirname(path.join(__dirname, '..', file)));
    const pluginDirName = path.basename(pluginDir);
    const isTemplate = pluginDirName === 'plugin-template';

    if (isTemplate) {
      continue;
    }

    const claudePluginPath = path.join(pluginDir, '.claude-plugin');
    if (!fs.existsSync(claudePluginPath)) {
      logError(`${pluginDirName}: Missing required .claude-plugin directory`);
      allValid = false;
      continue;
    }

    const entries = fs.readdirSync(pluginDir, { withFileTypes: true });
    const dirs = entries.filter(e => e.isDirectory()).map(e => e.name);

    for (const dir of dirs) {
      if (!allowedDirs.has(dir)) {
        logError(`${pluginDirName}: Unexpected directory '${dir}' (allowed: ${Array.from(allowedDirs).join(', ')})`);
        allValid = false;
      }
    }

    if (allValid) {
      logSuccess(`${pluginDirName}: Directory structure is valid`);
    }
  }

  return allValid;
}

/**
 * Validate knowledge directory structure
 */
async function validateKnowledge() {
  logInfo('Validating knowledge/ directories...');

  const pluginFiles = await glob('**/.claude-plugin/plugin.json', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });

  if (pluginFiles.length === 0) {
    return true;
  }

  let allValid = true;
  let totalKnowledgeDocs = 0;

  for (const file of pluginFiles) {
    const pluginDir = path.dirname(path.dirname(path.join(__dirname, '..', file)));
    const pluginDirName = path.basename(pluginDir);
    const isTemplate = pluginDirName === 'plugin-template';

    if (isTemplate) {
      continue;
    }

    const plugin = JSON.parse(fs.readFileSync(path.join(pluginDir, '.claude-plugin', 'plugin.json'), 'utf8'));
    const pluginName = plugin.name;

    const knowledgeDir = path.join(pluginDir, 'knowledge');

    if (!fs.existsSync(knowledgeDir)) {
      logWarning(`${pluginDirName}: Missing knowledge/ directory`);
      continue;
    }

    const knowledgeFiles = fs.readdirSync(knowledgeDir).filter(f => f.endsWith('.md'));

    if (knowledgeFiles.length === 0) {
      logWarning(`${pluginDirName}: knowledge/ directory exists but contains no .md files`);
      continue;
    }

    const expectedPattern = `${pluginName}-comprehensive.md`;
    const hasComprehensive = knowledgeFiles.some(f => f === expectedPattern);

    if (!hasComprehensive) {
      logError(`${pluginDirName}: knowledge/ directory must contain '${expectedPattern}'`);
      allValid = false;
    } else {
      totalKnowledgeDocs++;
      logSuccess(`${pluginDirName}: Found required ${expectedPattern}`);
    }
  }

  if (totalKnowledgeDocs > 0) {
    logSuccess(`Validated ${totalKnowledgeDocs} knowledge document(s)`);
  }

  return allValid;
}

/**
 * Detect orphaned plugins (plugins with plugin.json but not in marketplace.json)
 */
async function detectOrphanedPlugins() {
  logInfo('Checking for orphaned plugins...');

  const marketplacePath = path.join(__dirname, '../.claude-plugin/marketplace.json');

  if (!fs.existsSync(marketplacePath)) {
    return true;
  }

  const marketplace = JSON.parse(fs.readFileSync(marketplacePath, 'utf8'));
  const registeredPlugins = new Set(marketplace.plugins.map(p => p.name));

  const pluginFiles = await glob('**/.claude-plugin/plugin.json', {
    ignore: ['node_modules/**', '.git/**'],
    cwd: path.join(__dirname, '..')
  });

  const orphanedPlugins = [];

  for (const file of pluginFiles) {
    const fullPath = path.join(__dirname, '..', file);
    const plugin = JSON.parse(fs.readFileSync(fullPath, 'utf8'));

    if (!registeredPlugins.has(plugin.name)) {
      const pluginDirName = path.basename(path.dirname(path.dirname(fullPath)));
      if (pluginDirName !== 'plugin-template') {
        orphanedPlugins.push(plugin.name);
      }
    }
  }

  if (orphanedPlugins.length > 0) {
    orphanedPlugins.forEach(name => {
      logWarning(`Plugin '${name}' has plugin.json but is not listed in marketplace.json`);
    });
  } else {
    logSuccess('All plugins are registered in marketplace.json');
  }

  return true;
}

/**
 * Main validation function
 */
async function main() {
  console.log(`\n${colors.cyan}=== Claude Code Plugin Marketplace Validation ===${colors.reset}\n`);

  const marketplaceValid = validateMarketplace();
  const pluginsValid = await validatePlugins();
  const skillsResult = await validateSkills();
  const skillsValid = typeof skillsResult === 'object' ? skillsResult.allValid : skillsResult;
  const existingSkills = typeof skillsResult === 'object' ? skillsResult.existingSkills : new Set();
  const skillReferencesValid = await validateSkillReferences(existingSkills);
  const commandsValid = await validateCommands();
  const agentsValid = await validateAgents();
  const placementValid = await validateDirectoryPlacement();
  const hooksValid = await validateHooks();
  const mcpValid = await validateMCP();
  const directoryStructureValid = await validatePluginDirectoryStructure();
  const knowledgeValid = await validateKnowledge();
  const orphanedValid = await detectOrphanedPlugins();

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


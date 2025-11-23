#!/usr/bin/env node

const { ESLint } = require('eslint');
const fs = require('fs');
const path = require('path');

const validateHooksRules = async (filePath) => {
  if (!fs.existsSync(filePath)) {
    console.error(JSON.stringify({ error: 'FILE_NOT_FOUND', path: filePath }));
    process.exit(1);
  }

  const fileContent = fs.readFileSync(filePath, 'utf-8');
  const ext = path.extname(filePath);

  if (!['.js', '.jsx', '.ts', '.tsx'].includes(ext)) {
    console.log(JSON.stringify({ valid: true, violations: [] }));
    process.exit(0);
  }

  if (!fileContent.includes('use') || !/\b(useState|useEffect|useContext|useReducer|useCallback|useMemo|useRef|useLayoutEffect|useImperativeHandle|useDebugValue|useDeferredValue|useTransition|useId|useSyncExternalStore|useInsertionEffect|useOptimistic|useActionState|useFormStatus|use)\s*\(/.test(fileContent)) {
    console.log(JSON.stringify({ valid: true, violations: [] }));
    process.exit(0);
  }

  const reactHooksPlugin = require('eslint-plugin-react-hooks');
  const tsParser = require('@typescript-eslint/parser');
  const babelParser = require('@babel/eslint-parser');

  const config = [
    {
      files: ['**/*.{js,jsx,ts,tsx}'],
      languageOptions: {
        parser: ext.match(/\.tsx?$/) ? tsParser : babelParser,
        parserOptions: {
          ecmaVersion: 2024,
          sourceType: 'module',
          ecmaFeatures: {
            jsx: true,
          },
          requireConfigFile: false,
          babelOptions: {
            presets: ['@babel/preset-react'],
          },
        },
      },
      plugins: {
        'react-hooks': reactHooksPlugin,
      },
      rules: {
        'react-hooks/rules-of-hooks': 'error',
        'react-hooks/exhaustive-deps': 'warn',
      },
    },
  ];

  const eslint = new ESLint({
    overrideConfigFile: true,
    overrideConfig: config,
  });

  try {
    const results = await eslint.lintText(fileContent, {
      filePath: path.basename(filePath),
    });
    const result = results[0];

    if (!result) {
      console.log(JSON.stringify({ valid: true, violations: [] }));
      process.exit(0);
    }

    const hooksViolations = result.messages.filter(
      (msg) => msg.ruleId === 'react-hooks/rules-of-hooks'
    );

    const depsWarnings = result.messages.filter(
      (msg) => msg.ruleId === 'react-hooks/exhaustive-deps'
    );

    if (hooksViolations.length === 0 && depsWarnings.length === 0) {
      console.log(JSON.stringify({ valid: true, violations: [] }));
      process.exit(0);
    }

    const violations = hooksViolations.map((msg) => ({
      type: 'error',
      line: msg.line,
      column: msg.column,
      message: msg.message,
      ruleId: msg.ruleId,
    }));

    const warnings = depsWarnings.map((msg) => ({
      type: 'warning',
      line: msg.line,
      column: msg.column,
      message: msg.message,
      ruleId: msg.ruleId,
    }));

    console.log(
      JSON.stringify({
        valid: hooksViolations.length === 0,
        violations,
        warnings,
        totalErrors: hooksViolations.length,
        totalWarnings: depsWarnings.length,
      })
    );

    process.exit(hooksViolations.length > 0 ? 1 : 0);
  } catch (error) {
    console.error(
      JSON.stringify({
        error: 'PARSE_ERROR',
        message: error.message,
        stack: error.stack,
      })
    );
    process.exit(1);
  }
};

const filePath = process.argv[2];

if (!filePath) {
  console.error(JSON.stringify({ error: 'MISSING_FILE_PATH' }));
  process.exit(1);
}

validateHooksRules(filePath);

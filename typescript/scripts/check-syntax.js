#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const checkSyntax = (code, filePath) => {
  const ext = path.extname(filePath);
  const isTypeScript = ext === '.ts' || ext === '.tsx';

  try {
    if (isTypeScript) {
      const ts = require('typescript');

      const sourceFile = ts.createSourceFile(
        path.basename(filePath),
        code,
        ts.ScriptTarget.Latest,
        true,
        ext === '.tsx' ? ts.ScriptKind.TSX : ts.ScriptKind.TS
      );

      const diagnostics = sourceFile.parseDiagnostics;

      if (diagnostics && diagnostics.length > 0) {
        const firstError = diagnostics[0];
        const { line } = sourceFile.getLineAndCharacterOfPosition(firstError.start);
        const message = ts.flattenDiagnosticMessageText(firstError.messageText, '\n');

        return {
          hasSyntaxError: true,
          errorMessage: message,
          line: line + 1,
        };
      }
    } else {
      const acorn = require('acorn');
      const acornJsx = require('acorn-jsx');

      const parser = acorn.Parser.extend(acornJsx());

      parser.parse(code, {
        ecmaVersion: 2024,
        sourceType: 'module',
        locations: true,
      });
    }

    return { hasSyntaxError: false };
  } catch (error) {
    return {
      hasSyntaxError: true,
      errorMessage: error.message,
      line: error.loc ? error.loc.line : 'unknown',
    };
  }
};

try {
  const input = JSON.parse(fs.readFileSync(0, 'utf-8'));
  const toolName = input.tool_name;
  const toolInput = input.tool_input || {};

  let code = '';
  let filePath = toolInput.file_path || 'unknown.js';

  if (toolName === 'Write') {
    code = toolInput.content || '';
  } else if (toolName === 'Edit') {
    const oldString = toolInput.old_string || '';
    const newString = toolInput.new_string || '';

    if (fs.existsSync(filePath)) {
      const currentContent = fs.readFileSync(filePath, 'utf-8');
      code = currentContent.replace(oldString, newString);
    } else {
      code = newString;
    }
  }

  const result = checkSyntax(code, filePath);
  console.log(JSON.stringify(result));
  process.exit(0);
} catch (error) {
  console.error(JSON.stringify({
    hasSyntaxError: false,
    error: error.message,
  }));
  process.exit(0);
}

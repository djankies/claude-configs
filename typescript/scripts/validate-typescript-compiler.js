#!/usr/bin/env node

const ts = require('typescript');
const fs = require('fs');
const path = require('path');

const validateTypeScript = (filePath) => {
  if (!fs.existsSync(filePath)) {
    console.error(JSON.stringify({ error: 'FILE_NOT_FOUND', path: filePath }));
    process.exit(1);
  }

  const fileContent = fs.readFileSync(filePath, 'utf-8');
  const ext = path.extname(filePath);

  if (!['.ts', '.tsx'].includes(ext)) {
    console.log(JSON.stringify({ valid: true, errors: [], warnings: [] }));
    process.exit(0);
  }

  const compilerOptions = {
    target: ts.ScriptTarget.ES2020,
    module: ts.ModuleKind.ESNext,
    lib: ['lib.es2020.d.ts', 'lib.dom.d.ts'],
    jsx: ext === '.tsx' ? ts.JsxEmit.React : undefined,
    strict: true,
    esModuleInterop: true,
    skipLibCheck: true,
    forceConsistentCasingInFileNames: true,
    resolveJsonModule: true,
    moduleResolution: ts.ModuleResolutionKind.NodeJs,
    allowSyntheticDefaultImports: true,
    noUnusedLocals: true,
    noUnusedParameters: true,
    noImplicitReturns: true,
    noFallthroughCasesInSwitch: true,
  };

  const fileName = path.basename(filePath);
  const sourceFile = ts.createSourceFile(
    fileName,
    fileContent,
    ts.ScriptTarget.ES2020,
    true
  );

  const host = ts.createCompilerHost(compilerOptions);

  host.getSourceFile = (name) => {
    if (name === fileName) {
      return sourceFile;
    }
    return undefined;
  };

  host.writeFile = () => {};
  host.getCurrentDirectory = () => path.dirname(filePath);
  host.getCanonicalFileName = (fileName) => fileName;
  host.useCaseSensitiveFileNames = () => true;
  host.getNewLine = () => '\n';

  const program = ts.createProgram([fileName], compilerOptions, host);
  const diagnostics = ts.getPreEmitDiagnostics(program);

  const errors = [];
  const warnings = [];

  diagnostics.forEach((diagnostic) => {
    if (diagnostic.file && diagnostic.start !== undefined) {
      const { line, character } = diagnostic.file.getLineAndCharacterOfPosition(
        diagnostic.start
      );

      const message = ts.flattenDiagnosticMessageText(
        diagnostic.messageText,
        '\n'
      );

      const issue = {
        line: line + 1,
        column: character + 1,
        message: message,
        code: diagnostic.code,
      };

      if (diagnostic.category === ts.DiagnosticCategory.Error) {
        errors.push(issue);
      } else if (diagnostic.category === ts.DiagnosticCategory.Warning) {
        warnings.push(issue);
      }
    }
  });

  const result = {
    valid: errors.length === 0 && warnings.length === 0,
    errors: errors,
    warnings: warnings,
    totalErrors: errors.length,
    totalWarnings: warnings.length,
  };

  console.log(JSON.stringify(result));
  process.exit(0);
};

const filePath = process.argv[2];
if (!filePath) {
  console.error(JSON.stringify({ error: 'NO_FILE_PATH' }));
  process.exit(1);
}

validateTypeScript(filePath);

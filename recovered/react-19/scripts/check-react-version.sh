#!/bin/bash

if [ ! -f "package.json" ]; then
  echo "⚠️  No package.json found. React 19 plugin activated but cannot verify React version."
  exit 0
fi

REACT_VERSION=$(grep -o '"react": *"[^"]*"' package.json | grep -o '[0-9][^"]*' | head -1)

if [ -z "$REACT_VERSION" ]; then
  echo "⚠️  React not found in package.json. React 19 plugin activated."
  exit 0
fi

MAJOR_VERSION=$(echo "$REACT_VERSION" | grep -o '^[0-9]*' | head -1)

if [ "$MAJOR_VERSION" -lt 19 ]; then
  echo "⚠️  React version $REACT_VERSION detected. This plugin is optimized for React 19."
  echo "   Some patterns (use hook, useActionState, ref-as-prop) require React 19."
  echo "   Consider upgrading: npm install react@19 react-dom@19"
elif [ "$MAJOR_VERSION" -eq 19 ]; then
  echo "✓ React 19 detected ($REACT_VERSION). React 19 plugin activated."
  echo "  Skills available: hooks, components, forms, state, performance, testing"
  echo "  Documentation: research/react-19-comprehensive.md"
else
  echo "✓ React $REACT_VERSION detected. React 19 plugin activated."
fi

if [ -f ".react-19-plugin/validation-rules.json" ]; then
  echo "  Validation rules loaded."
fi

exit 0

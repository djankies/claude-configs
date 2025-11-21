#!/usr/bin/env bash

set -eo pipefail

check_tool() {
    local tool=$1
    local bin_name=${2:-$tool}

    if command -v "$bin_name" &> /dev/null; then
        return 0
    elif [ -f "node_modules/.bin/$bin_name" ]; then
        return 0
    elif [ "$tool" = "eslint" ] || [ "$tool" = "typescript" ]; then
        if command -v npx &> /dev/null; then
            return 0
        fi
    fi

    return 1
}

echo "INSTALLED:"
check_tool "git" && echo "git"
check_tool "eslint" && echo "eslint"
check_tool "typescript" "tsc" && echo "typescript"
check_tool "jq" && echo "jq"
check_tool "depcheck" && echo "depcheck"
check_tool "tree" && echo "tree"
check_tool "knip" && echo "knip"
check_tool "ts-prune" && echo "ts-prune"
check_tool "lizard" && echo "lizard"
check_tool "semgrep" && echo "semgrep"
check_tool "jsinspect" && echo "jsinspect"

echo "MISSING:"
check_tool "eslint" || echo "eslint|JavaScript/TypeScript linter for code quality|npm install -D eslint|Essential"
check_tool "typescript" "tsc" || echo "typescript|Type checking with tsc command|npm install -D typescript|Essential"
check_tool "jq" || echo "jq|JSON processor for scripts|brew install jq|Essential"
check_tool "depcheck" || echo "depcheck|Find unused dependencies|npm install -g depcheck|Recommended"
check_tool "tree" || echo "tree|Display directory structure|brew install tree|Nice to have"
check_tool "knip" || echo "knip|Find unused code/exports/deps (comprehensive)|npm install -D knip|Recommended"
check_tool "ts-prune" || echo "ts-prune|Find unused exports (simpler)|npm install -D ts-prune|Recommended"
check_tool "lizard" || echo "lizard|Code complexity and duplication analysis|pip install lizard|Recommended"
check_tool "semgrep" || echo "semgrep|Security scanning and vulnerability detection|pip install semgrep|Recommended"
check_tool "jsinspect" || echo "jsinspect|Duplicate code detection|npm install -g jsinspect|Recommended"

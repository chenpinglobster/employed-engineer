#!/usr/bin/env bash
# smoke.sh - Minimal healthcheck for Node.js/TypeScript projects
# Should pass on a clean, properly configured repo

set -euo pipefail

echo "🔥 Smoke Test - Node.js/TypeScript"
echo "=================================="

# Check Node.js
echo "📦 Node.js version:"
node --version

# Check package manager
if [[ -f "pnpm-lock.yaml" ]]; then
    echo "📦 Package manager: pnpm"
    pnpm --version
elif [[ -f "yarn.lock" ]]; then
    echo "📦 Package manager: yarn"
    yarn --version
elif [[ -f "bun.lockb" ]]; then
    echo "📦 Package manager: bun"
    bun --version
else
    echo "📦 Package manager: npm"
    npm --version
fi

# Check if dependencies are installed
if [[ ! -d "node_modules" ]]; then
    echo "⚠️ node_modules not found, installing..."
    if [[ -f "pnpm-lock.yaml" ]]; then
        pnpm install
    elif [[ -f "yarn.lock" ]]; then
        yarn install
    elif [[ -f "bun.lockb" ]]; then
        bun install
    else
        npm install
    fi
fi

# TypeScript check (if applicable)
if [[ -f "tsconfig.json" ]]; then
    echo "📝 TypeScript detected, checking config..."
    npx tsc --version
fi

# Try to run lint (non-fatal)
if npm run --if-present lint &>/dev/null; then
    echo "✅ Lint passed"
else
    echo "⚠️ Lint not configured or failed (non-fatal for smoke)"
fi

echo ""
echo "✅ Smoke test passed!"

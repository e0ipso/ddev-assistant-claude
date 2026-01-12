#!/bin/bash
# Install Claude Code CLI

set -e

echo "Installing Claude Code..."

npm config set prefix /usr/local
npm install -g @anthropic-ai/claude-code || true

if command -v claude &> /dev/null; then
    echo "✓ Claude Code installed: $(claude --version)"
else
    echo "⚠ Claude installation had issues, but continuing..."
fi

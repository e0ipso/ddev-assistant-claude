#!/bin/bash
set -ex

# Check if Claude Code is already installed
if command -v claude &> /dev/null; then
    echo "Claude Code is already installed: $(claude --version)"
    exit 0
fi

# Install Claude Code CLI using official installer
echo "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

# Verify installation
if command -v claude &> /dev/null; then
    echo "✓ Claude Code installed successfully: $(claude --version)"
else
    echo "✗ Failed to install Claude Code CLI"
    exit 1
fi

#!/bin/bash
set -e

# Check if Claude Code is already installed
if command -v claude &> /dev/null; then
    echo "Claude Code is already installed: $(claude --version)"
    exit 0
fi

# Install Claude Code CLI using the official installer
echo "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

# Add common installation paths to PATH for the current script session
export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"

# Verify installation
if command -v claude &> /dev/null; then
    echo "✓ Claude Code installed successfully: $(claude --version)"
else
    echo "✗ Failed to install Claude Code CLI"
    exit 1
fi

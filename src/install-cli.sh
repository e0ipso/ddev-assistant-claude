#!/bin/bash
set -ex

# Ensure npm is available
if ! command -v npm &> /dev/null; then
    echo "✗ npm not found. Skipping Claude CLI installation."
    exit 0
fi

# Check if Claude Code is already installed
if command -v claude &> /dev/null; then
    echo "Claude Code is already installed: $(claude --version)"
    exit 0
fi

# Install Claude Code CLI globally
echo "Installing @anthropic-ai/claude-code..."
# Try installing without sudo first, then with sudo if it fails
npm install -g @anthropic-ai/claude-code || sudo npm install -g @anthropic-ai/claude-code

# Verify installation
if command -v claude &> /dev/null; then
    echo "✓ Claude Code installed successfully: $(claude --version)"
else
    # Check if it was installed in a common global path that might not be in PATH yet
    if [ -f "$HOME/.npm-global/bin/claude" ]; then
        export PATH="$PATH:$HOME/.npm-global/bin"
        echo "✓ Claude Code found in $HOME/.npm-global/bin"
    elif [ -f "/usr/local/bin/claude" ]; then
        echo "✓ Claude Code found in /usr/local/bin"
    else
        echo "✗ Failed to install Claude Code CLI"
        exit 1
    fi
fi

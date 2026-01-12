#!/bin/bash
set -ex

# Check if Claude Code is already installed
if command -v claude &> /dev/null; then
    echo "Claude Code is already installed: $(claude --version)"
    exit 0
fi

# Install Claude Code CLI using official installer
echo "Installing Claude Code..."

# Download the installer and capture both stdout and stderr
INSTALLER_OUTPUT=$(mktemp)
INSTALLER_ERRORS=$(mktemp)

if curl -fSL https://claude.ai/install.sh -o "$INSTALLER_OUTPUT" 2>"$INSTALLER_ERRORS"; then
    echo "Installer downloaded successfully"
    # Execute the installer with output
    if bash "$INSTALLER_OUTPUT" 2>&1; then
        echo "Installer executed successfully"
    else
        echo "⚠ Installer execution had errors (continuing with diagnostics)"
        cat "$INSTALLER_OUTPUT" | head -20
    fi
    rm "$INSTALLER_OUTPUT"
else
    echo "⚠ Failed to download installer from https://claude.ai/install.sh"
    cat "$INSTALLER_ERRORS"
    rm "$INSTALLER_OUTPUT" "$INSTALLER_ERRORS"
fi

# Verify installation
if command -v claude &> /dev/null; then
    echo "✓ Claude Code installed successfully: $(claude --version)"
    exit 0
else
    echo "✗ Failed to install Claude Code CLI"
    echo "Debugging information:"
    echo "PATH: $PATH"
    echo "Looking for claude in common locations..."
    for dir in /usr/local/bin /usr/bin /bin ~/.local/bin ~/.npm-global/bin; do
        if [ -x "$dir/claude" ]; then
            echo "  Found: $dir/claude"
            export PATH="$PATH:$dir"
            if command -v claude &> /dev/null; then
                echo "✓ Claude found at $dir after PATH update"
                exit 0
            fi
        fi
    done
    exit 1
fi

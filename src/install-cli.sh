#!/bin/bash
set -ex

# Log all output to a file for debugging
LOG_FILE="/tmp/claude-install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1
echo "=== Claude CLI Installation started at $(date) ==="

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
    echo "Installation log saved to: $LOG_FILE"
    exit 0
else
    echo "✗ Failed to install Claude Code CLI"
    echo "Debugging information:"
    echo "PATH: $PATH"
    echo ""
    echo "=== Searching for claude binary in common locations ==="
    for dir in /usr/local/bin /usr/bin /bin ~/.local/bin ~/.npm-global/bin /opt/claude/bin; do
        echo "Checking $dir:"
        if [ -d "$dir" ]; then
            ls -la "$dir" | grep -i claude || echo "  (no claude found)"
        else
            echo "  (directory doesn't exist)"
        fi
    done

    echo ""
    echo "=== Installation log output ==="
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    else
        echo "Log file not found at $LOG_FILE"
    fi

    echo ""
    echo "=== npm config ==="
    npm config list || echo "Failed to get npm config"

    exit 1
fi

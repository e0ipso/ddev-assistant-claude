#!/bin/bash
set -ex

# Log all output to a file for debugging
LOG_FILE="/tmp/claude-install.log"

{
    echo "=== Claude CLI Installation started at $(date) ==="
    echo "User: $(id)"
    echo "PWD: $(pwd)"
    echo "PATH: $PATH"
    echo "Available tools:"
    command -v bash && echo "  ✓ bash" || echo "  ✗ bash"
    command -v curl && echo "  ✓ curl" || echo "  ✗ curl NOT FOUND"
    command -v npm && echo "  ✓ npm" || echo "  ✗ npm NOT FOUND"
    command -v node && echo "  ✓ node" || echo "  ✗ node NOT FOUND"
    echo "---"

    # Check if Claude Code is already installed
    if command -v claude &> /dev/null; then
        echo "Claude Code is already installed: $(claude --version)"
        exit 0
    fi

    # Install Claude Code CLI using official installer with fallback to npm
    echo "Installing Claude Code..."

    # Try official installer first
    INSTALLER_OUTPUT=$(mktemp)
    INSTALLER_ERRORS=$(mktemp)
    INSTALL_SUCCESS=false

    echo "Attempting to download official installer from https://claude.ai/install.sh..."
    if curl -v -fSL https://claude.ai/install.sh -o "$INSTALLER_OUTPUT" 2>"$INSTALLER_ERRORS"; then
        echo "Installer downloaded successfully ($(wc -c < "$INSTALLER_OUTPUT") bytes)"
        # Execute the installer with output
        if bash "$INSTALLER_OUTPUT" 2>&1; then
            echo "Official installer executed successfully"
            INSTALL_SUCCESS=true
        else
            echo "⚠ Official installer execution had errors"
            echo "First 30 lines of installer:"
            head -30 "$INSTALLER_OUTPUT"
        fi
    else
        echo "⚠ Failed to download official installer"
        echo "Error output:"
        head -20 "$INSTALLER_ERRORS"
    fi

    rm -f "$INSTALLER_OUTPUT" "$INSTALLER_ERRORS"

    # Fallback: try npm if official installer didn't work
    if [ "$INSTALL_SUCCESS" = false ] && command -v npm &> /dev/null; then
        echo ""
        echo "Falling back to npm installation..."
        npm config set prefix /usr/local
        if npm install -g @anthropic-ai/claude-code; then
            echo "npm installation successful"
            INSTALL_SUCCESS=true
        else
            echo "npm installation also failed"
        fi
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

} | tee -a "$LOG_FILE"

#!/bin/bash
set -ex

echo "Installing ddev-assistant-claude addon..."

# Source the addon helper scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install CLI tool
echo "Step 1: Installing Claude Code CLI..."
bash "$SCRIPT_DIR/src/install-cli.sh"

# Initialize AI Task Manager
echo "Step 2: Initializing AI Task Manager..."
bash "$SCRIPT_DIR/src/setup-ai-task-manager.sh"

# Configure MCP servers
echo "Step 3: Configuring MCP servers..."
bash "$SCRIPT_DIR/src/setup-mcp-servers.sh"

echo "✓ ddev-assistant-claude addon installation complete!"
echo ""
echo "Verify installation with:"
echo "  ddev exec claude --version"
echo "  ddev exec ls -la .ai/task-manager/"
echo "  ddev exec claude mcp list"

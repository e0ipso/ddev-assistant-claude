#!/bin/bash
set -e

echo "Installing Claude Code addon..."

# Get the addon directory (parent of .ddev)
ADDON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

# Install CLI tool
echo "Step 1: Installing Claude Code CLI..."
bash "$ADDON_DIR/src/install-cli.sh"

# Initialize AI Task Manager
echo "Step 2: Initializing AI Task Manager..."
bash "$ADDON_DIR/src/setup-ai-task-manager.sh"

# Configure MCP servers
echo "Step 3: Configuring MCP servers..."
bash "$ADDON_DIR/src/setup-mcp-servers.sh"

echo "✓ ddev-assistant-claude addon installation complete!"

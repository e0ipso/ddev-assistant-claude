#!/bin/bash
set -e

echo "Installing ddev-assistant-claude addon..."

# Install CLI tool
echo "Step 1: Installing Claude Code CLI..."
ddev exec bash src/install-cli.sh

# Initialize AI Task Manager
echo "Step 2: Initializing AI Task Manager..."
ddev exec bash src/setup-ai-task-manager.sh

# Configure MCP servers
echo "Step 3: Configuring MCP servers..."
ddev exec bash src/setup-mcp-servers.sh

echo "✓ ddev-assistant-claude addon installation complete!"
echo ""
echo "Verify installation with:"
echo "  ddev exec claude --version"
echo "  ddev exec ls -la .ai/task-manager/"
echo "  ddev exec claude mcp list"

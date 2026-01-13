#!/bin/bash
set -e

echo "ddev-assistant-claude addon configuration installed."
echo "Please run 'ddev restart' to complete the installation and setup of Claude Code."
echo ""
echo "After restart, you can verify the installation with:"
echo "  ddev exec claude --version"
echo "  ddev exec ls -la .ai/task-manager/"
echo "  ddev exec claude mcp list"

#!/bin/bash
#ddev-nodisplay
#ddev-description: Fix ownership of Claude configuration directory

set -e

echo "Fixing ownership of Claude configuration directory..."

if [ -d "$HOME/.claude" ]; then
    sudo chown -R $(id -u):$(id -g) "$HOME/.claude" 2>/dev/null || true
    echo "✓ Claude config directory ownership fixed"
fi

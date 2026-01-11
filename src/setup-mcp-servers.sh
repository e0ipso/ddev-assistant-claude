#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_CONFIG="$SCRIPT_DIR/../mcp/config.json"
PROJECT_CONFIG=".ddev/mcp-config/claude.json"

echo "Configuring MCP servers for Claude..."

# Function to add an MCP server
add_mcp_server() {
    local name="$1"
    local command="$2"
    local env_json="$3"

    echo "  Adding MCP server: $name"

    # Parse environment variables from JSON and pass to claude mcp add
    if [ -n "$env_json" ]; then
        # Extract environment variables and apply them
        eval "$(echo "$env_json" | jq -r 'to_entries | .[] | "export \(.key)=\(.value)"' 2>/dev/null || true)"
    fi

    if claude mcp add "$name" "$command" 2>/dev/null || true; then
        echo "    ✓ $name configured"
    fi
}

# Read addon config and configure MCP servers
if [ -f "$ADDON_CONFIG" ]; then
    echo "Applying addon MCP configuration..."

    # Use jq to iterate through MCP servers in the config
    jq -r '.mcp_servers[] | select(.enabled == true) | "\(.name):\(.command):\(.environment | tojson)"' "$ADDON_CONFIG" 2>/dev/null | while IFS=: read -r name command env_json; do
        add_mcp_server "$name" "$command" "$env_json"
    done || true
fi

# Allow project-level configuration to extend/override
if [ -f "$PROJECT_CONFIG" ]; then
    echo "Applying project-level MCP configuration..."

    jq -r '.mcp_servers[] | select(.enabled == true) | "\(.name):\(.command):\(.environment | tojson)"' "$PROJECT_CONFIG" 2>/dev/null | while IFS=: read -r name command env_json; do
        add_mcp_server "$name" "$command" "$env_json"
    done || true
fi

echo "✓ MCP servers configured"

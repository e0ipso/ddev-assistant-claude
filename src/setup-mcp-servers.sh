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

    local cmd_args=("mcp" "add" "$name")
    
    # Parse environment variables from JSON and pass to claude mcp add
    if [ -n "$env_json" ] && [ "$env_json" != "null" ]; then
        # Extract environment variables for both eval and --env flags
        local exports=$(echo "$env_json" | jq -r 'select(type == "object") | to_entries | .[] | "export \(.key)=\(.value | @sh)"' 2>/dev/null || true)
        if [ -n "$exports" ]; then
            eval "$exports"
        fi
        
        # Prepare --env flags safely using an array
        while IFS= read -r line; do
            [ -n "$line" ] && cmd_args+=("--env" "$line")
        done < <(echo "$env_json" | jq -r 'select(type == "object") | to_entries | .[] | "\(.key)=\(.value)"' 2>/dev/null || true)
    fi

    # Add the separator and the command (split into arguments)
    cmd_args+=("--")
    
    # Split command into arguments safely
    read -ra command_parts <<< "$command"
    cmd_args+=("${command_parts[@]}")

    echo "  Adding MCP server: $name"
    if claude "${cmd_args[@]}" 2>/dev/null || true; then
        echo "    ✓ $name configured"
    fi
}

# Function to process config file
process_config() {
    local config_file="$1"
    if [ ! -f "$config_file" ]; then
        return
    fi

    echo "Applying configuration from $config_file..."
    
    # Get the number of servers
    local count=$(jq '.mcp_servers | length' "$config_file" 2>/dev/null || echo 0)
    
    for ((i=0; i<count; i++)); do
        local enabled=$(jq -r ".mcp_servers[$i].enabled" "$config_file")
        if [ "$enabled" != "true" ]; then
            continue
        fi
        
        local name=$(jq -r ".mcp_servers[$i].name" "$config_file")
        local command=$(jq -r ".mcp_servers[$i].command" "$config_file")
        local env_json=$(jq -c ".mcp_servers[$i].environment" "$config_file")
        
        add_mcp_server "$name" "$command" "$env_json"
    done
}

# Read addon config
process_config "$ADDON_CONFIG"

# Allow project-level configuration to extend/override
process_config "$PROJECT_CONFIG"

echo "✓ MCP servers configured"

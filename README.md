# ddev-assistant-claude

DDEV addon for Claude Code assistant with AI Task Manager integration and MCP server support.

## Installation

```bash
ddev add-ons install ddev-assistant-claude
```

## What This Addon Does

- Installs Claude Code CLI using the official installer
- Initializes AI Task Manager for Claude
- Configures MCP servers (Puppeteer by default)

## Quick Start

After installation, verify the setup:

```bash
ddev exec claude --version
ddev exec ls -la .ai/task-manager/
ddev exec claude mcp list
```

## Configuration

### Custom MCP Servers

To add custom MCP servers, create `.ddev/mcp-config/claude.json`:

```json
{
  "mcp_servers": [
    {
      "name": "my-server",
      "enabled": true,
      "command": "npx -y @myorg/my-mcp-server",
      "environment": {
        "ENV_VAR": "value"
      }
    }
  ]
}
```

## Troubleshooting

### Claude CLI not found
```bash
ddev restart
ddev exec which claude
```

### AI Task Manager not initialized
```bash
ddev exec ddev claude-init
```

### MCP servers not configured
```bash
ddev exec claude mcp list
```

## Documentation

- [Claude Code](https://code.claude.com/)
- [AI Task Manager](https://mateuaguilo.com/ai-task-manager/)
- [DDEV Addons](https://docs.ddev.com/en/stable/users/extend/creating-add-ons/)

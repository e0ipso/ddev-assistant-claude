[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/e0ipso/ddev-assistant-claude/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/e0ipso/ddev-assistant-claude/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/e0ipso/ddev-assistant-claude)](https://github.com/e0ipso/ddev-assistant-claude/commits)
[![release](https://img.shields.io/github/v/release/e0ipso/ddev-assistant-claude)](https://github.com/e0ipso/ddev-assistant-claude/releases/latest)

# DDEV Claude Code

## Overview

This DDEV add-on installs [Claude Code](https://claude.ai/code) inside the DDEV web container and automatically shares your host Claude configuration — including `CLAUDE.md`, `settings.json`, skills, hooks, and commands — with no additional setup required.

Once installed, running `claude` inside `ddev ssh` or `ddev exec` uses the same global configuration as your host machine.

## Requirements

- DDEV >= v1.24.0
- A Claude Code installation on the host (for configuration sharing)

## Installation

```bash
ddev add-on get e0ipso/ddev-assistant-claude
ddev restart
```

After installation, commit the `.ddev` directory to version control.

## What it does

- **Installs Claude Code** into the container at `~/.local/bin/claude`, owned by the web user (not root)
- **Mounts host config files** read-only into the container:
  - `~/.claude/CLAUDE.md` — project and global instructions
  - `~/.claude/settings.json` — Claude Code settings
  - `~/.claude/skills/` — custom skills
  - `~/.claude/hooks/` — event hooks
  - `~/.claude/commands/` — custom slash commands
- **Configures `$PATH`** so `claude` is accessible in both interactive shells (`ddev ssh`) and non-interactive commands (`ddev exec`)

## Usage

```bash
# Open a shell with Claude Code available
ddev ssh
claude

# Run Claude Code non-interactively
ddev exec claude --version
```

## Credits

**Contributed and maintained by [@e0ipso](https://github.com/e0ipso)**

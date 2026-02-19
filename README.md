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

## Why not FreelyGive/ddev-claude-code?

[FreelyGive/ddev-claude-code](https://github.com/FreelyGive/ddev-claude-code) is another DDEV add-on for Claude Code. It's a fine project — here's why this one exists separately:

| | This add-on | FreelyGive/ddev-claude-code |
|---|---|---|
| **Config approach** | Mounts your host `~/.claude/` files read-only — zero setup if you already use Claude on the host | Stores config per-project in `.ddev/claude-code/` via symlinks; requires interactive setup on first run |
| **Security** | Read-only bind-mounts prevent the container from modifying host config | Symlinks allow the container to write to config files |
| **Install method** | Official Anthropic installer (`claude.ai/install.sh`) | `npm install -g @anthropic-ai/claude-code` |
| **Binary ownership** | Explicitly copies to `~/.local/bin/claude` owned by the web user | npm global install runs as root during Docker build |
| **Mount safety** | Pre-start hook creates stub paths so Docker doesn't silently create directories instead of files | No equivalent safeguard |
| **Tests / CI** | BATS integration tests, GitHub Actions CI matrix (DDEV stable + HEAD), daily scheduled runs | No tests or CI visible in the repository |

This add-on does one thing: install Claude Code into your DDEV container and share your existing host configuration. Nothing else.

## Credits

**Contributed and maintained by [@e0ipso](https://github.com/e0ipso)**

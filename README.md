[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/e0ipso/ddev-assistant-claude/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/e0ipso/ddev-assistant-claude/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/e0ipso/ddev-assistant-claude)](https://github.com/e0ipso/ddev-assistant-claude/commits)
[![release](https://img.shields.io/github/v/release/e0ipso/ddev-assistant-claude)](https://github.com/e0ipso/ddev-assistant-claude/releases/latest)

# DDEV Claude Code

## Overview

This DDEV add-on installs [Claude Code](https://claude.ai/code) inside the DDEV web container and automatically shares your host Claude configuration — including `CLAUDE.md`, `settings.json`, skills, hooks, and commands — with no additional setup required.

Once installed, running `claude` inside `ddev ssh` or `ddev exec` uses a writable copy of your host global configuration.

## Requirements

- DDEV >= v1.24.10
- A Claude Code installation on the host (for configuration sharing)

## Installation

```bash
ddev add-on get e0ipso/ddev-assistant-claude
ddev restart
```

After installation, commit the `.ddev` directory to version control.

## What it does

- **Installs Claude Code** into the container at `/usr/local/bin/claude`, on `$PATH` for every shell
- **Seeds host configuration** on start: your host `~/.claude/` tree is mounted read-only under `~/.cred-seed/claude/`, then mirrored into the writable container `~/.claude/` directory on every restart:
  - `~/.claude/CLAUDE.md` — project and global instructions
  - `~/.claude/settings.json` — Claude Code settings
  - `~/.claude/skills/` — custom skills
  - `~/.claude/hooks/` — event hooks
  - `~/.claude/commands/` — custom slash commands
- **Mirrors host authentication** on restart: `~/.claude/.credentials.json` is part of the same seeded tree, so credentials and config are refreshed from the host whenever the container starts
- **Available everywhere** — `claude` is on `$PATH` for both interactive shells (`ddev ssh`) and non-interactive commands (`ddev exec`)

## Secret scanning

This add-on depends on [Lullabot/ddev-gitleaks](https://github.com/Lullabot/ddev-gitleaks), which DDEV installs automatically alongside it. That add-on adds a non-blocking `post-start` scan of the container environment and project `.env` files, warning (with redacted values) when likely secrets or API keys are present.

DDEV propagates global `web_environment` into every project, so a secret set globally — or one living in a project `.env` — becomes readable by Claude Code running in the web container. The scan surfaces that exposure so you can decide whether to proceed; it never blocks `ddev start`.

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
| **Config approach** | Seeds a writable container `~/.claude/` from your host config on restart — zero setup if you already use Claude on the host | Stores config per-project in `.ddev/claude-code/` via symlinks; requires interactive setup on first run |
| **Security** | The host seed is read-only, so the container cannot modify host config | Symlinks allow the container to write to config files |
| **Install method** | Official Anthropic installer (`claude.ai/install.sh`) | `npm install -g @anthropic-ai/claude-code` |
| **Install location** | Standalone binary at `/usr/local/bin/claude`, on `$PATH` for every shell, no per-start hooks | npm global install runs as root during Docker build |
| **Mount safety** | Pre-start hook ensures the host config directory exists before Docker mounts it | No equivalent safeguard |
| **Tests / CI** | BATS integration tests, GitHub Actions CI matrix (DDEV stable + HEAD), daily scheduled runs | No tests or CI visible in the repository |

This add-on does one thing: install Claude Code into your DDEV container and share your existing host configuration. Nothing else.

## Credits

**Contributed and maintained by [@e0ipso](https://github.com/e0ipso)**

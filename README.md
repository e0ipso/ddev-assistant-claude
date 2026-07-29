[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/e0ipso/ddev-assistant-claude/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/e0ipso/ddev-assistant-claude/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/e0ipso/ddev-assistant-claude)](https://github.com/e0ipso/ddev-assistant-claude/commits)
[![release](https://img.shields.io/github/v/release/e0ipso/ddev-assistant-claude)](https://github.com/e0ipso/ddev-assistant-claude/releases/latest)

# DDEV Claude Code

## Overview

This DDEV add-on installs [Claude Code](https://claude.ai/code) inside the DDEV web container and gives it a persistent, project-scoped configuration — seeded once from your host Claude configuration (`CLAUDE.md`, `settings.json`, skills, hooks, commands, credentials, account/session identity), then fully independent of the host afterward.

Once installed, running `claude` inside `ddev ssh` or `ddev exec` uses a writable, project-local `~/.claude` and `~/.claude.json` that survive `ddev restart` and `ddev poweroff` — conversation history, sessions, login state, and any in-container changes persist just like they would on a host install.

## Requirements

- DDEV >= v1.24.0
- A Claude Code installation on the host (for configuration sharing)

## Installation

```bash
ddev add-on get e0ipso/ddev-assistant-claude
ddev restart
```

After installation, commit the `.ddev` directory to version control. `ddev add-on get` automatically adds `/.ddev/claude-code/` to your `.gitignore` — **do not remove that entry**, it holds live per-developer credentials (see [Security](#security)).

## What it does

- **Installs Claude Code** into the container at `/usr/local/bin/claude`, on `$PATH` for every shell
- **Seeds host configuration once**: the first time the add-on starts with no existing project store, your host `~/.claude/` tree (CLAUDE.md, settings.json, skills, hooks, commands, credentials) *and* your host `~/.claude.json` (account/session identity, project trust state) are copied into a project-local, persistent store at `.ddev/claude-code/.claude/` and `.ddev/claude-code/.claude.json` on the host
- **Persists across restarts**: that project-local store is bind-mounted read-write into the container and symlinked to `~/.claude` and `~/.claude.json`, so conversation history, sessions, login state, and any other in-container changes are written straight to host disk and survive `ddev restart`/`ddev poweroff` — nothing is copied-and-discarded on every start, and you're not forced to re-authenticate after every restart
- **Never touches your real host `~/.claude`/`~/.claude.json` again** after the initial seed — the project store is independent per-project, so containers can't drift the config you use natively on the host, and one project's Claude state never leaks into another's
- **Available everywhere** — `claude` is on `$PATH` for both interactive shells (`ddev ssh`) and non-interactive commands (`ddev exec`)

## Security

`.ddev/claude-code/.claude/` and `.ddev/claude-code/.claude.json` contain live OAuth credentials (`.credentials.json`) and account/session identity once seeded. Installation adds a `/.ddev/claude-code/` entry to your project's `.gitignore` automatically; if you're upgrading from an older version of this add-on, add it yourself before committing:

```gitignore
/.ddev/claude-code/
```

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
| **Config approach** | Seeds a persistent, project-scoped `.ddev/claude-code/` store from your host config once, automatically — zero setup if you already use Claude on the host | Stores config per-project in `.ddev/claude-code/` via symlinks; requires interactive setup on first run |
| **Security / isolation** | After the initial seed, the container never touches your real host `~/.claude` again — each project's Claude state is independent, so containers can't drift your host config or leak between projects | Symlinks into a project-local store; similar isolation once set up |
| **Install method** | Official Anthropic installer (`claude.ai/install.sh`) | `npm install -g @anthropic-ai/claude-code` |
| **Install location** | Standalone binary at `/usr/local/bin/claude`, on `$PATH` for every shell, no per-start hooks | npm global install runs as root during Docker build |
| **Mount safety** | Pre-start hook ensures the host config directory exists before Docker mounts it | No equivalent safeguard |
| **Tests / CI** | BATS integration tests, GitHub Actions CI matrix (DDEV stable + HEAD), daily scheduled runs | No tests or CI visible in the repository |

This add-on does one thing: install Claude Code into your DDEV container and share your existing host configuration. Nothing else.

## Credits

**Contributed and maintained by [@e0ipso](https://github.com/e0ipso)**

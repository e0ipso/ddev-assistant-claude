# AGENTS.md

## Project Overview

**ddev-assistant-claude** is a DDEV add-on that installs Claude Code into the DDEV web container and shares the host user's Claude configuration (CLAUDE.md, settings.json, skills, hooks, commands) into the container without any additional setup.

- **DDEV version requirement**: >= v1.24.0
- **Repository**: `e0ipso/ddev-assistant-claude`

## Architecture

- `install.yaml` — DDEV add-on manifest; declares project files and version constraints
- `config.assistant-claude.yaml` — DDEV hooks: **pre-start** (`exec-host`) creates stub host paths for Claude config files so Docker bind-mounts them as files (not directories); **post-start** (`exec`) copies the binary to `~/.local/bin/claude` and writes PATH configuration for both interactive (`ddev ssh`) and non-interactive (`ddev exec`) shells
- `docker-compose.assistant-claude.yaml` — Bind-mounts the host user's `~/.claude/` config files (CLAUDE.md, settings.json, skills, hooks, commands) read-only into the same path inside the web container so the in-container `claude` shares the host configuration
- `web-build/Dockerfile.assistant-claude` — Downloads Claude Code via `https://claude.ai/install.sh` and pre-installs it at `/usr/local/lib/claude/claude` (outside the DDEV-mounted user home); sets `BASH_ENV=/etc/bash.env` so that `$HOME/.local/bin` is prepended to `$PATH` for non-interactive shells (`ddev exec`)
- `.devcontainer/` — Local development container (Node.js 22, bats, shellcheck, Claude Code)
- `tests/test.bats` — BATS integration tests
- `.github/workflows/tests.yml` — CI using `ddev/github-action-add-on-test@v2`, matrix: DDEV `stable` + `HEAD`

## Testing

Tests use [BATS](https://bats-core.readthedocs.io/) (Bash Automated Testing System) with bats-assert, bats-file, and bats-support libraries.

```bash
# Run all tests
bats ./tests/test.bats

# Exclude release tests (for local development)
bats ./tests/test.bats --filter-tags '!release'

# Debug mode
bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure
```

Tests spin up a temporary DDEV project (`test-ddev-assistant-claude`), install the add-on, and verify:
1. `ddev launch` works
2. `~/.local/bin/claude` exists inside the container and is not owned by `root`
3. `claude --version` is accessible via `$PATH` (which includes `~/.local/bin`)
4. `~/.claude/CLAUDE.md` is accessible in the container (mount working)

The `install from release` test (tagged `@release`) installs from GitHub releases; skip it locally with `--filter-tags '!release'`.

## Development Notes

- **BATS tests must be run on the host machine**, not inside the devcontainer — they require DDEV, which manages Docker containers and cannot run inside a container itself
- This is primarily a shell/Docker project — no application-level package manager for the main code
- The `test_env/` directory contains npm-managed bats dependencies (gitignored)
- Commits use conventional commit format (e.g., `feat:`, `fix:`)
- CI runs on PRs, pushes to main, and daily at 08:25 UTC
- `.gitattributes` excludes tests, `.github/`, and docs from release archives


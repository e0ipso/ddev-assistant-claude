# AGENTS.md

## Project Overview

**ddev-assistant-claude** is a DDEV add-on that integrates Claude Code into DDEV development environments. It installs the Claude Code binary into the DDEV web container and initializes the `@e0ipso/ai-task-manager` on first start.

- **DDEV version requirement**: >= v1.24.0
- **Repository**: `e0ipso/ddev-assistant-claude`

## Architecture

- `install.yaml` — DDEV add-on manifest; declares project files and version constraints
- `config.assistant-claude.yaml` — DDEV post-start hooks: (1) copies the pre-installed Claude binary from `/usr/local/lib/claude/claude` to `~/.local/bin/claude` on first start (so it is user-owned and survives on the DDEV home volume); (2) runs `npx @e0ipso/ai-task-manager init --assistants claude` on first start (creates `.ai/task-manager/.init-metadata.json` marker)
- `web-build/Dockerfile.assistant-claude` — Downloads Claude Code via `https://claude.ai/install.sh` and pre-installs it at `/usr/local/lib/claude/claude` (outside the DDEV-mounted user home); sets `BASH_ENV=/etc/bash.env` so that `$HOME/.local/bin` is prepended to `$PATH` for every bash session (both non-interactive `ddev exec` calls and login shells via `/etc/profile.d/`)
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
4. AI Task Manager initialization marker file exists

The `install from release` test (tagged `@release`) installs from GitHub releases; skip it locally with `--filter-tags '!release'`.

## Development Notes

- **BATS tests must be run on the host machine**, not inside the devcontainer — they require DDEV, which manages Docker containers and cannot run inside a container itself
- This is primarily a shell/Docker project — no application-level package manager for the main code
- The `test_env/` directory contains npm-managed bats dependencies (gitignored)
- Commits use conventional commit format (e.g., `feat:`, `fix:`)
- CI runs on PRs, pushes to main, and daily at 08:25 UTC
- `.gitattributes` excludes tests, `.github/`, and docs from release archives


# AGENTS.md

## Project Overview

**ddev-assistant-claude** is a DDEV add-on that installs Claude Code into the DDEV web container and seeds the host user's Claude configuration (CLAUDE.md, settings.json, skills, hooks, commands, credentials) into the container without any additional setup. The host `~/.claude/` directory is mounted read-only under `~/.cred-seed/claude/` and mirrored into the writable in-container `~/.claude/` on every start.

- **DDEV version requirement**: >= v1.24.0
- **Repository**: `e0ipso/ddev-assistant-claude`

## Architecture

- `install.yaml` — DDEV add-on manifest; declares project files and version constraints
- `config.assistant-claude.yaml` — DDEV hooks: **pre-start** (`exec-host`) ensures the host user's `~/.claude/` directory exists; **post-start** (`exec`) deletes stale in-container `~/.claude/` content, copies the read-only seed into a writable runtime `~/.claude/`, fixes ownership, and locks down credential permissions
- `docker-compose.assistant-claude.yaml` — Bind-mounts the host user's `~/.claude/` directory read-only under `~/.cred-seed/claude/`; the container never live-mounts individual config files into `~/.claude/`
- `web-build/Dockerfile.assistant-claude` — Downloads Claude Code via `https://claude.ai/install.sh` and installs the standalone binary at `/usr/local/bin/claude`, which is on `$PATH` for every shell type and lives in the image layer (outside the home directory DDEV recreates on each restart), so no per-start copy hook is needed
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
2. `claude` resolves on `$PATH` and `claude --version` works via non-interactive `ddev exec`
3. `~/.claude` is owned by the web user (not `root`)
4. Host config mounts under `~/.cred-seed/claude/` and mirrors into writable `~/.claude/`
5. Container-only `~/.claude/` files are deleted on restart because the host seed is authoritative

The `install from release` test (tagged `@release`) installs from GitHub releases; skip it locally with `--filter-tags '!release'`.

## Development Notes

- **BATS tests must be run on the host machine**, not inside the devcontainer — they require DDEV, which manages Docker containers and cannot run inside a container itself
- This is primarily a shell/Docker project — no application-level package manager for the main code
- The `test_env/` directory contains npm-managed bats dependencies (gitignored)
- Commits use conventional commit format (e.g., `feat:`, `fix:`)
- CI runs on PRs, pushes to main, and daily at 08:25 UTC
- `.gitattributes` excludes tests, `.github/`, and docs from release archives

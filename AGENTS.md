# AGENTS.md

## Project Overview

**ddev-assistant-claude** is a DDEV add-on that installs Claude Code into the DDEV web container and gives it a persistent, project-scoped `~/.claude/` — seeded once from the host user's Claude configuration (CLAUDE.md, settings.json, skills, hooks, commands, credentials), then bind-mounted read-write for the lifetime of the project. Because it's a live mount rather than a copy-on-start, conversation history and other in-container writes survive `ddev restart`/`ddev poweroff` instead of being discarded, and the container never touches the host's real `~/.claude` again after the initial seed.

- **DDEV version requirement**: >= v1.24.0
- **Repository**: `e0ipso/ddev-assistant-claude`

## Architecture

- `install.yaml` — DDEV add-on manifest; declares project files and version constraints
- `config.assistant-claude.yaml` — DDEV hooks: **pre-start** (`exec-host`) seeds `.ddev/claude-code/.claude/` from the host user's `~/.claude/` the first time only (skipped if the project store already exists); **post-start** (`exec`) fixes ownership on the mounted store, locks down credential permissions, and symlinks the container's `~/.claude` to the store (must run in-container so `$HOME` resolves to the container's home, not the host's)
- `docker-compose.assistant-claude.yaml` — Bind-mounts the project-local `.ddev/claude-code/.claude/` directory read-write to a fixed container path (`/home/.claude-project-store`); fixed rather than `$HOME`-relative because `$HOME` is interpolated on the host at compose-render time and can differ from the container's `$HOME` (e.g. macOS)
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
4. Host config is seeded once into the project-local `.ddev/claude-code/.claude/` store, which is symlinked as the container's `~/.claude/`
5. Container-only `~/.claude/` files **survive** `ddev restart` because the project store is a live bind mount, not a copy that gets overwritten

The `install from release` test (tagged `@release`) installs from GitHub releases; skip it locally with `--filter-tags '!release'`.

## Development Notes

- **BATS tests must be run on the host machine**, not inside the devcontainer — they require DDEV, which manages Docker containers and cannot run inside a container itself
- This is primarily a shell/Docker project — no application-level package manager for the main code
- The `test_env/` directory contains npm-managed bats dependencies (gitignored)
- Commits use conventional commit format (e.g., `feat:`, `fix:`)
- CI runs on PRs, pushes to main, and daily at 08:25 UTC
- `.gitattributes` excludes tests, `.github/`, and docs from release archives

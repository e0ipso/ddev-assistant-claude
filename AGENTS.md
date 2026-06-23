# AGENTS.md

## Project Overview

**ddev-assistant-claude** is a DDEV add-on that installs Claude Code into the DDEV web container and shares the host user's Claude configuration (CLAUDE.md, settings.json, skills, hooks, commands) into the container without any additional setup.

- **DDEV version requirement**: >= v1.24.0
- **Repository**: `e0ipso/ddev-assistant-claude`

## Architecture

- `install.yaml` — DDEV add-on manifest; declares project files and version constraints
- `config.assistant-claude.yaml` — DDEV hooks: **pre-start** (`exec-host`) creates stub host paths for every Claude config file/dir mounted by the compose file so Docker bind-mounts them as the correct type (files vs directories); **post-start** (`exec`) fixes ownership of `~/.claude` (the bind-mount creates the parent as root) and runs the gitleaks secret-scan warning hook
- `docker-compose.assistant-claude.yaml` — Bind-mounts the host user's `~/.claude/` config files (CLAUDE.md, settings.json, skills, hooks, commands) read-only into the same path inside the web container so the in-container `claude` shares the host configuration
- `web-build/Dockerfile.assistant-claude` — Downloads Claude Code via `https://claude.ai/install.sh` and installs the standalone binary at `/usr/local/bin/claude`, which is on `$PATH` for every shell type and lives in the image layer (outside the home directory DDEV recreates on each restart), so no per-start copy hook is needed. Also installs the pinned, arch-aware `gitleaks` secret scanner to `/usr/local/bin/gitleaks` and `COPY`s in the scan wrapper + config
- `web-build/gitleaks-scan.sh` — Post-start hook script (installed as `/usr/local/bin/gitleaks-scan`). **Warns, never blocks**: scans the container environment and project `.env`-style files under `$DDEV_APPROOT` with gitleaks (redacted), and prints guidance to review Claude commands and avoid `--dangerously-skip-permissions`/auto-accept when secrets are present. Always exits 0 so it can't abort `ddev start`
- `web-build/gitleaks.toml` — gitleaks config (installed at `/etc/gitleaks/gitleaks.toml`); extends the default ruleset and allowlists benign DDEV env vars by name prefix to avoid false positives on a clean baseline
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
4. `~/.claude/CLAUDE.md` is accessible in the container (mount working)
5. `gitleaks` and `gitleaks-scan` resolve on `$PATH`, a clean project produces no warning, and an injected env var + `.env` secret are detected with their values redacted (and the hook still exits 0)

The `install from release` test (tagged `@release`) installs from GitHub releases; skip it locally with `--filter-tags '!release'`.

## Development Notes

- **BATS tests must be run on the host machine**, not inside the devcontainer — they require DDEV, which manages Docker containers and cannot run inside a container itself
- This is primarily a shell/Docker project — no application-level package manager for the main code
- The `test_env/` directory contains npm-managed bats dependencies (gitignored)
- Commits use conventional commit format (e.g., `feat:`, `fix:`)
- CI runs on PRs, pushes to main, and daily at 08:25 UTC
- `.gitattributes` excludes tests, `.github/`, and docs from release archives


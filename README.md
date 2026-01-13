[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/e0ipso/ddev-assistant-claude/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/e0ipso/ddev-assistant-claude/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/e0ipso/ddev-assistant-claude)](https://github.com/e0ipso/ddev-assistant-claude/commits)
[![release](https://img.shields.io/github/v/release/e0ipso/ddev-assistant-claude)](https://github.com/e0ipso/ddev-assistant-claude/releases/latest)

# DDEV Assistant Claude

## Overview

This add-on integrates Assistant Claude into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get e0ipso/ddev-assistant-claude
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Assistant Claude |
| `ddev logs -s assistant-claude` | Check Assistant Claude logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.assistant-claude --assistant-claude-docker-image="ddev/ddev-utilities:latest"
ddev add-on get e0ipso/ddev-assistant-claude
ddev restart
```

Make sure to commit the `.ddev/.env.assistant-claude` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `ASSISTANT_CLAUDE_DOCKER_IMAGE` | `--assistant-claude-docker-image` | `ddev/ddev-utilities:latest` |

## Credits

**Contributed and maintained by [@e0ipso](https://github.com/e0ipso)**

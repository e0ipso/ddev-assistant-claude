#!/usr/bin/env bash
#ddev-generated
# Warn (never block) if the container environment or project .env files contain
# secrets/API keys. Runs as a DDEV post-start hook and MUST always exit 0 so it
# can never abort `ddev start`.
set -uo pipefail

CONFIG="/etc/gitleaks/gitleaks.toml"
CFG=()
[ -f "$CONFIG" ] && CFG=(-c "$CONFIG")

found=0

# 1) Scan the container environment. --redact keeps secret values out of output.
#    gitleaks exits 1 when it finds leaks; capture that without failing the hook.
if ! env | gitleaks stdin --no-banner --redact -v "${CFG[@]}"; then
  found=1
fi

# 2) Scan dotenv-style files in the project root. .env files are usually
#    gitignored, so use filesystem (stdin) scanning rather than a git-based scan.
#    Prune heavy/irrelevant directories and skip committed template files.
APPROOT="${DDEV_APPROOT:-/var/www/html}"
if [ -d "$APPROOT" ]; then
  while IFS= read -r f; do
    case "$(basename "$f")" in
      .env.example|.env.dist|.env.sample|.env.template) continue ;;
    esac
    rel="${f#"$APPROOT"/}"
    if ! gitleaks stdin --no-banner --redact -v "${CFG[@]}" < "$f"; then
      echo "  ^ findings above are from project file: $rel" >&2
      found=1
    fi
  done < <(find "$APPROOT" -maxdepth 4 \
      \( -name vendor -o -name node_modules -o -name .git \) -prune -o \
      -type f \( -name '.env' -o -name '.env.*' \) -print 2>/dev/null)
fi

[ "$found" -eq 0 ] && exit 0

cat >&2 <<'WARN'

============================================================================
  WARNING

  gitleaks detected what look like secrets or API keys in this container's
  environment and/or project .env files. These are often propagated from
  your GLOBAL DDEV config (e.g. TERMINUS_MACHINE_TOKEN).

  Claude Code in this container can READ and USE these values.
  Before continuing:
    * Review every Claude command/skill/hook you run here.
    * Do NOT use --dangerously-skip-permissions or auto-accept / "yolo"
      modes while real secrets are present.
    * Consider unsetting secrets for projects where Claude Code is active.
============================================================================

WARN
exit 0

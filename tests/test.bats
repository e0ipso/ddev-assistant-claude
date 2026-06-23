#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=e0ipso/ddev-assistant-claude

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats:${DIR}/test_env/bats_libs"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # Do something useful here that verifies the add-on

  # You can check for specific information in headers:
  # run curl -sfI https://${PROJNAME}.ddev.site
  # assert_output --partial "HTTP/2 200"
  # assert_output --partial "test_header"

  # Or check if some command gives expected output:
  DDEV_DEBUG=true run ddev launch
  assert_success
  assert_output --partial "FULLURL https://${PROJNAME}.ddev.site"

  # Verify claude is on PATH and accessible via non-interactive `ddev exec`
  run ddev exec "command -v claude"
  assert_success
  assert_output --partial "claude"

  run ddev exec "claude --version"
  assert_success

  # Verify ~/.claude is owned by the web user (not root)
  run ddev exec "stat -c '%U' ~/.claude"
  assert_success
  refute_output "root"

  # Verify Claude Code host config is mounted as a regular file (the pre-start hook
  # ensures the host path exists as a file; without it Docker would bind-mount a
  # directory there instead)
  run ddev exec "test -f ~/.claude/CLAUDE.md"
  assert_success

  # Verify gitleaks (secret scanner) and the scan wrapper are installed on PATH
  run ddev exec "command -v gitleaks"
  assert_success
  assert_output --partial "gitleaks"

  run ddev exec "gitleaks version"
  assert_success

  run ddev exec "command -v gitleaks-scan"
  assert_success

  # Negative baseline: a clean project must produce no leaks, so the wrapper
  # exits 0 and prints no warning. This also guards against false positives from
  # DDEV's own environment variables (see web-build/gitleaks.toml allowlist).
  # "Before continuing" is a phrase unique to the warning banner.
  run ddev exec "gitleaks-scan"
  assert_success
  refute_output --partial "Before continuing"

}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

@test "secret scan warns on env var and .env file, redacted, never blocks" {
  set -eu -o pipefail
  echo "# secret-scan detection test for project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success

  # High-entropy fake secrets. The env var name contains the gitleaks keyword
  # "TOKEN" and the .env line contains "SECRET_KEY" so the generic-api-key rule
  # (keyword + entropy >= 3.5) fires deterministically. Fixed literals (not
  # $RANDOM) keep CI deterministic.
  SECRET_ENV="a1b2c3d4e5f6g7h8i9j0klmnop"
  SECRET_FILE="z9y8x7w6v5u4t3s2r1q0ponmlk"

  # (a) inject a global-style web environment variable
  run ddev config --web-environment-add="TERMINUS_MACHINE_TOKEN=${SECRET_ENV}"
  assert_success
  run ddev restart -y
  assert_success

  # (b) drop a project .env file at the approot (bind-mounted live into the
  #     container, so the scan can read it)
  printf 'API_SECRET_KEY=%s\n' "${SECRET_FILE}" > "${TESTDIR}/.env"

  # The wrapper must warn, redact both plaintext values, and still exit 0 so it
  # never aborts `ddev start`. bats merges stderr into $output, so the warning
  # (written to stderr) is visible to assert_output.
  run ddev exec "gitleaks-scan"
  assert_success
  assert_output --partial "Before continuing"
  refute_output --partial "${SECRET_ENV}"
  refute_output --partial "${SECRET_FILE}"

  rm -f "${TESTDIR}/.env"
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

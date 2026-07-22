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
  export TEST_MARKER="$(basename "${TESTDIR}")"
  export TEST_HOST_CLAUDE_COMMAND="${HOME}/.claude/commands/${TEST_MARKER}.md"
  export TEST_HOST_CLAUDE_CREDENTIALS="${HOME}/.claude/.credentials.json"
  export TEST_CREATED_CLAUDE_CREDENTIALS=false
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

prepare_host_claude_credentials() {
  mkdir -p "${HOME}/.claude"
  if [ ! -e "${TEST_HOST_CLAUDE_CREDENTIALS}" ] && [ ! -L "${TEST_HOST_CLAUDE_CREDENTIALS}" ]; then
    printf '{"ddev_assistant_claude_test":"%s"}\n' "${TEST_MARKER}" >"${TEST_HOST_CLAUDE_CREDENTIALS}"
    export TEST_CREATED_CLAUDE_CREDENTIALS=true
  fi
}

prepare_host_claude_config() {
  prepare_host_claude_credentials
  mkdir -p "${HOME}/.claude/commands"
  printf 'seeded command from %s\n' "${TEST_MARKER}" >"${TEST_HOST_CLAUDE_COMMAND}"
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

  # Verify Claude Code runtime config exists and is writable by the web user.
  run ddev exec "test -d ~/.claude && test -w ~/.claude"
  assert_success

  # Verify host credentials are mounted read-only under /home/.cred-seed/
  run ddev exec "test -f /home/.cred-seed/claude/.credentials.json"
  assert_success

  # Verify credentials are seeded into the writable runtime path on start
  run ddev exec "test -f ~/.claude/.credentials.json"
  assert_success

}

seed_mirror_checks() {
  # Verify host config is mounted only in the seed area and copied into the
  # writable runtime path.
  run ddev exec "test -f /home/.cred-seed/claude/commands/${TEST_MARKER}.md"
  assert_success

  run ddev exec "test -f ~/.claude/commands/${TEST_MARKER}.md"
  assert_success

  run ddev exec "grep -F 'seeded command from ${TEST_MARKER}' /home/.cred-seed/claude/commands/${TEST_MARKER}.md"
  assert_success

  # Verify restart-time mirroring deletes container-only files.
  run ddev exec "mkdir -p ~/.claude/commands && touch ~/.claude/commands/container-only-${TEST_MARKER}.md"
  assert_success

  run ddev restart -y
  assert_success

  run ddev exec "test ! -e ~/.claude/commands/container-only-${TEST_MARKER}.md"
  assert_success
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  rm -f "${TEST_HOST_CLAUDE_COMMAND}"
  if [ "${TEST_CREATED_CLAUDE_CREDENTIALS}" = true ]; then
    rm -f "${TEST_HOST_CLAUDE_CREDENTIALS}"
  fi
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
  prepare_host_claude_config
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
  seed_mirror_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  prepare_host_claude_credentials
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

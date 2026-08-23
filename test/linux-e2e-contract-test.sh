#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FULL_E2E="$ROOT_DIR/test/e2e/linux-full.sh"
RUNTIME_E2E="$ROOT_DIR/test/e2e/linux-runtime.sh"

failures=0

run_test() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

test_full_e2e_uses_runtime_acceptance() {
  [[ -x "$RUNTIME_E2E" ]] || return 1
  grep -Fq 'linux-runtime.sh' "$FULL_E2E" || return 1
  ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$FULL_E2E"
}

test_full_e2e_repeats_setup_and_acceptance() {
  [[ "$(grep -Fc '"$ROOT_DIR/setup.sh"' "$FULL_E2E")" -ge 2 ]] || return 1
  grep -Fq 'second setup.sh failed' "$FULL_E2E" || return 1
  grep -Fq 'idempotence' "$FULL_E2E"
}

test_runtime_uses_a_fresh_login_zsh() {
  grep -Fq 'sudo -iu' "$RUNTIME_E2E" || return 1
  grep -Fq 'zsh -lic' "$RUNTIME_E2E" || return 1
  grep -Fq 'login-shell.stderr' "$RUNTIME_E2E" || return 1
  ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$RUNTIME_E2E"
}

test_runtime_exercises_neovim_plugins() {
  grep -Fq 'Lazy! restore' "$RUNTIME_E2E" || return 1
  grep -Fq "require('hop')" "$RUNTIME_E2E" || return 1
  grep -Fq "require('mason')" "$RUNTIME_E2E" || return 1
  grep -Fq "require('lspconfig')" "$RUNTIME_E2E" || return 1
  grep -Fq 'MAC_SETUP_NVIM_BOOTSTRAP=1' "$RUNTIME_E2E" || return 1
  grep -Fq 'sample.go' "$RUNTIME_E2E"
}

test_runtime_exercises_agent_config_loaders() {
  grep -Fq 'opencode debug config' "$RUNTIME_E2E" || return 1
  grep -Fq 'opencode debug skill' "$RUNTIME_E2E" || return 1
  grep -Fq 'codex features list' "$RUNTIME_E2E" || return 1
  grep -Fq 'modules/agents.sh" --audit' "$RUNTIME_E2E"
}

test_runtime_checks_required_commands() {
  local command
  for command in zsh nvim tree-sitter go gopls node bun opencode codex; do
    grep -Fq "$command" "$RUNTIME_E2E" || return 1
  done
}

run_test full-e2e-uses-runtime-acceptance test_full_e2e_uses_runtime_acceptance
run_test full-e2e-repeats-setup-and-acceptance test_full_e2e_repeats_setup_and_acceptance
run_test runtime-uses-a-fresh-login-zsh test_runtime_uses_a_fresh_login_zsh
run_test runtime-exercises-neovim-plugins test_runtime_exercises_neovim_plugins
run_test runtime-exercises-agent-config-loaders test_runtime_exercises_agent_config_loaders
run_test runtime-checks-required-commands test_runtime_checks_required_commands

if [[ "$failures" -ne 0 ]]; then
  printf 'FAIL Linux E2E contract tests (%d failures)\n' "$failures" >&2
  exit 1
fi

printf 'PASS Linux E2E contract tests (6 cases)\n'

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXPECTED_PLATFORM="${1:?expected platform is required}"
PHASE="${2:-first}"
ACCOUNT="$(id -un)"
ARTIFACT_DIR="$HOME/.cache/mac-setup-e2e/$EXPECTED_PLATFORM/$PHASE"
REQUIRED_COMMANDS="zsh nvim tree-sitter go gopls node bun opencode codex rg fd tmux"
printf -v quoted_root '%q' "$ROOT_DIR"
printf -v quoted_required_commands '%q' "$REQUIRED_COMMANDS"

mkdir -p "$ARTIFACT_DIR"

fail() {
  printf 'FAIL %s runtime E2E (%s): %s\n' "$EXPECTED_PLATFORM" "$PHASE" "$1" >&2
  exit 1
}

show_artifact() {
  local path="$1"
  [[ -s "$path" ]] || return 0
  printf '%s\n' "--- $path ---" >&2
  sed -n '1,240p' "$path" >&2
}

run_login_capture() {
  local label="$1"
  local timeout_seconds="$2"
  local command="$3"
  local stdout_path="$ARTIFACT_DIR/$label.stdout"
  local stderr_path="$ARTIFACT_DIR/$label.stderr"

  if ! timeout "$timeout_seconds" sudo -iu "$ACCOUNT" \
    env TERM=xterm-256color zsh -lic "$command" \
    >"$stdout_path" 2>"$stderr_path"; then
    show_artifact "$stdout_path"
    show_artifact "$stderr_path"
    fail "$label failed in a fresh login Zsh"
  fi
}

reject_runtime_diagnostics() {
  local label="$1"
  shift
  local path
  for path in "$@"; do
    [[ -s "$path" ]] || continue
    if grep -Eiq \
      '(^|[^[:alpha:]])(error detected|stack traceback|clone failed|fatal:|E[0-9]{3}:)' \
      "$path"; then
      show_artifact "$path"
      fail "$label emitted a runtime error diagnostic"
    fi
  done
}

printf 'E2E %s login Zsh (%s)\n' "$EXPECTED_PLATFORM" "$PHASE"
run_login_capture login-shell 120 \
  "$quoted_root/test/e2e/linux-login.zsh $quoted_required_commands"
if ! grep -Fq 'LOGIN_ZSH_OK' "$ARTIFACT_DIR/login-shell.stdout"; then
  show_artifact "$ARTIFACT_DIR/login-shell.stdout"
  show_artifact "$ARTIFACT_DIR/login-shell.stderr"
  fail 'login Zsh did not complete its command discovery checks'
fi
if [[ -s "$ARTIFACT_DIR/login-shell.stderr" ]]; then
  show_artifact "$ARTIFACT_DIR/login-shell.stderr"
  fail 'login Zsh emitted diagnostics during startup'
fi

expected_opencode_version="$({
  # shellcheck source=../../lib/runtime-manifest.sh
  source "$ROOT_DIR/lib/runtime-manifest.sh"
  node_manifest_version "$ROOT_DIR" npm opencode-ai
})"
expected_codex_version="$({
  # shellcheck source=../../lib/runtime-manifest.sh
  source "$ROOT_DIR/lib/runtime-manifest.sh"
  node_manifest_version "$ROOT_DIR" npm @openai/codex
})"

run_login_capture agent-versions 120 \
  '[[ "$(opencode --version)" == '"$expected_opencode_version"' ]] &&
   [[ "$(codex --version)" == "codex-cli '"$expected_codex_version"'" ]]'

printf 'E2E %s Neovim plugins and parsers (%s)\n' "$EXPECTED_PLATFORM" "$PHASE"
run_login_capture nvim-lazy-restore 900 \
  'nvim --headless "+Lazy! restore" +qa'
reject_runtime_diagnostics nvim-lazy-restore \
  "$ARTIFACT_DIR/nvim-lazy-restore.stdout" "$ARTIFACT_DIR/nvim-lazy-restore.stderr"

run_login_capture nvim-plugin-load 600 \
  "MAC_SETUP_NVIM_BOOTSTRAP=1 nvim --headless
   \"+lua assert(require('hop'))\"
   \"+lua assert(require('mason'))\"
   \"+lua assert(require('lspconfig'))\"
   \"+lua assert(require('nvim-treesitter'))\"
   \"+lua assert(vim.fn.exepath('tree-sitter') == vim.fn.expand('~/.local/bin/tree-sitter'))\"
   \"+lua assert(vim.fn.exepath('gopls') == vim.fn.expand('~/.local/bin/gopls'))\"
   +qa"
reject_runtime_diagnostics nvim-plugin-load \
  "$ARTIFACT_DIR/nvim-plugin-load.stdout" "$ARTIFACT_DIR/nvim-plugin-load.stderr"

sample_dir="$HOME/.cache/mac-setup-e2e/samples"
mkdir -p "$sample_dir"
printf '%s\n' 'module example.com/macsetupe2e' >"$sample_dir/go.mod"
printf '%s\n' 'package main' 'func main() {}' >"$sample_dir/sample.go"
run_login_capture nvim-gopls 180 \
  'nvim --headless "$HOME/.cache/mac-setup-e2e/samples/sample.go"
   "+lua assert(vim.wait(30000, function() return #vim.lsp.get_clients({ name = '\''gopls'\'' }) > 0 end), '\''gopls did not attach'\'')"
   +qa'
reject_runtime_diagnostics nvim-gopls \
  "$ARTIFACT_DIR/nvim-gopls.stdout" "$ARTIFACT_DIR/nvim-gopls.stderr"

printf 'E2E %s Agent configuration loaders (%s)\n' "$EXPECTED_PLATFORM" "$PHASE"
run_login_capture opencode-config 180 \
  'opencode debug config'
run_login_capture opencode-skills 180 \
  'opencode debug skill'
grep -Fq 'mac-setup' "$ARTIFACT_DIR/opencode-skills.stdout" ||
  fail 'OpenCode did not discover the shared mac-setup skill'
run_login_capture codex-config 180 \
  'codex features list'

bash "$ROOT_DIR/modules/agents.sh" --audit >"$ARTIFACT_DIR/agents-audit.stdout" \
  2>"$ARTIFACT_DIR/agents-audit.stderr" || {
  show_artifact "$ARTIFACT_DIR/agents-audit.stdout"
  show_artifact "$ARTIFACT_DIR/agents-audit.stderr"
  fail 'Agent configuration audit failed'
}

printf 'PASS %s runtime E2E (%s)\n' "$EXPECTED_PLATFORM" "$PHASE"

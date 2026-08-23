#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

run_test() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name" >&2
    return 1
  fi
}

test_manifest_pins_go_and_gopls() {
  # shellcheck source=../lib/runtime-manifest.sh
  source "$ROOT_DIR/lib/runtime-manifest.sh"

  validate_editor_manifest "$ROOT_DIR" || return 1
  [[ "$(editor_manifest_version "$ROOT_DIR" runtime go)" == "1.26.3" ]] || return 1
  [[ "$(editor_manifest_version "$ROOT_DIR" go gopls)" == "0.23.0" ]]
}

test_installer_publishes_managed_go_and_gopls() {
  local home="$TEMP_ROOT/editor.home"
  local go_root="$TEMP_ROOT/go-root"
  local fake_mise="$TEMP_ROOT/mise"
  local trace="$TEMP_ROOT/mise.trace"
  mkdir -p "$home" "$go_root/bin"

  printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$MISE_TRACE"' \
    'case "${1:-}:${2:-}" in' \
    '  install:go@1.26.3) exit 0 ;;' \
    '  where:go@1.26.3) printf "%s\n" "$FAKE_GO_ROOT"; exit 0 ;;' \
    '  exec:go@1.26.3)' \
    '    mkdir -p "$GOBIN"' \
    '    printf "%s\n" "#!/usr/bin/env bash" "printf \"%s\\n\" \"golang.org/x/tools/gopls v0.23.0\"" >"$GOBIN/gopls"' \
    '    chmod +x "$GOBIN/gopls"' \
    '    exit 0' \
    '    ;;' \
    'esac' \
    'exit 1' >"$fake_mise"
  chmod +x "$fake_mise"

  printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "go version go1.26.3 linux/amd64"' >"$go_root/bin/go"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$go_root/bin/gofmt"
  chmod +x "$go_root/bin/go" "$go_root/bin/gofmt"

  HOME="$home" MISE_TRACE="$trace" FAKE_GO_ROOT="$go_root" FAKE_MISE="$fake_mise" \
    ROOT_DIR="$ROOT_DIR" bash -c '
      source "$ROOT_DIR/lib/utils.sh"
      install_mise() { :; }
      resolve_mise_executable() { printf "%s\n" "$FAKE_MISE"; }
      install_editor_toolchain
    ' || return 1

  [[ -L "$home/.local/bin/go" ]] || return 1
  [[ -L "$home/.local/bin/gofmt" ]] || return 1
  [[ -L "$home/.local/bin/gopls" ]] || return 1
  [[ "$("$home/.local/bin/go" version)" == "go version go1.26.3 linux/amd64" ]] || return 1
  [[ "$("$home/.local/bin/gopls" version)" == "golang.org/x/tools/gopls v0.23.0" ]] ||
    return 1
  grep -Fxq 'install go@1.26.3' "$trace" || return 1
  grep -Fq \
    'exec go@1.26.3 -- go install golang.org/x/tools/gopls@v0.23.0' "$trace"
}

test_neovim_uses_managed_user_tools() {
  local globals="$ROOT_DIR/config/nvim/lua/global-var.lua"
  local lsp="$ROOT_DIR/config/nvim/lua/plugins/lsp.lua"

  grep -Fq 'vim.env.HOME .. "/.local/bin:" .. vim.env.PATH' "$globals" || return 1
  grep -Fq "vim.fn.expand('~/.local/bin/gopls')" "$lsp" || return 1
  ! grep -Eq "ensure_installed[[:space:]]*=[^{]*\{[^}]*'gopls'" "$lsp"
}

test_vim_module_installs_editor_toolchain() {
  grep -Fq 'install_editor_toolchain' "$ROOT_DIR/modules/vim.sh"
}

run_test manifest-pins-go-and-gopls test_manifest_pins_go_and_gopls
run_test installer-publishes-managed-go-and-gopls \
  test_installer_publishes_managed_go_and_gopls
run_test neovim-uses-managed-user-tools test_neovim_uses_managed_user_tools
run_test vim-module-installs-editor-toolchain test_vim_module_installs_editor_toolchain

printf 'PASS editor toolchain tests (4 cases)\n'

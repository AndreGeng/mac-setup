#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
XDG_STATE_HOME="$TEMP_ROOT/state" XDG_CACHE_HOME="$TEMP_ROOT/cache" \
  NVIM_LOG_FILE="$TEMP_ROOT/nvim.log" MAC_SETUP_TEST_ROOT="$ROOT_DIR" \
  nvim --headless -u NONE -i NONE -l "$ROOT_DIR/test/nvim-rust-test.lua"

ROOT_DIR="$ROOT_DIR" TEMP_ROOT="$TEMP_ROOT" bash <<'BASH'
set -euo pipefail
source "$ROOT_DIR/lib/utils.sh"
installed=false
rustup() {
  case "$1" in
  show) printf '%s\n' '1.97.1-test (default)' ;;
  component)
    if [[ "$2" == list ]]; then
      if [[ "$installed" == true ]]; then
        printf '%s\n' rust-analyzer-test rust-src rustfmt-test clippy-test
      fi
    else
      [[ "$*" == 'component add --toolchain 1.97.1-test rust-analyzer rust-src rustfmt clippy' ]]
      installed=true
    fi
    ;;
  run) [[ "$installed" == true ]] ;;
  esac
}
! rust_editor_components_match
install_rust_editor_components
rust_editor_components_match
# No installation is needed on the second run.
rustup_original=$(declare -f rustup)
eval "${rustup_original/rustup ()/fake_rustup ()}"
rustup() {
  [[ "$1 $2" != 'component add' ]] || return 1
  fake_rustup "$@"
}
install_rust_editor_components
BASH

ROOT_DIR="$ROOT_DIR" bash <<'BASH'
set -euo pipefail
source "$ROOT_DIR/lib/mac-setup/engine.sh"
plan_tools() { :; }
plan_configs() { :; }
neovim_runtime_matches() { return 0; }
tree_sitter_runtime_matches() { return 0; }
go_runtime_matches() { return 0; }
gopls_runtime_matches() { return 0; }
rust_editor_toolchain() { printf '%s\n' "$test_toolchain"; }
rust_editor_components_match() { return 1; }
test_toolchain=1.97.1-test
FEATURE_RUST=true
plan_target editor.nvim false
[[ "${PLAN_CHANGE_RESOURCES[*]}" == rust-tools@1.97.1-test ]]
[[ "$(first_missing_approval)" == network ]]
first_plan="$PLAN_ID"
test_toolchain=1.96.0-test
plan_target editor.nvim false
[[ "$PLAN_ID" != "$first_plan" ]]
FEATURE_RUST=false
plan_target editor.nvim false
[[ ${#PLAN_CHANGE_RESOURCES[@]} == 0 ]]
printf 'PASS Rust plans require network approval and bind the selected toolchain\n'
BASH

if [[ "${1:-}" == --integration ]]; then
  mkdir -p "$TEMP_ROOT/project/src"
  printf '[package]\nname = "nvim-rust-test"\nversion = "0.1.0"\nedition = "2021"\n' \
    >"$TEMP_ROOT/project/Cargo.toml"
  printf 'pub struct Thing;\nimpl Thing { pub fn answer(&self) -> u32 { 42 } }\n' \
    >"$TEMP_ROOT/project/src/helper.rs"
  printf 'mod helper;\nfn main(){let _ = helper::Thing.answer();}\n' \
    >"$TEMP_ROOT/project/src/main.rs"
  RUST_TEST_DIR="$TEMP_ROOT/project" MAC_SETUP_TEST_ROOT="$ROOT_DIR" \
    CARGO_NET_OFFLINE=true XDG_STATE_HOME="$TEMP_ROOT/state" \
    XDG_CACHE_HOME="$TEMP_ROOT/cache" NVIM_LOG_FILE="$TEMP_ROOT/nvim.log" \
    nvim --headless -u NONE -i NONE -l "$ROOT_DIR/test/nvim-rust-integration.lua"
fi

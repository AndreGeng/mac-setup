#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
XDG_STATE_HOME="$TEMP_ROOT/state" XDG_CACHE_HOME="$TEMP_ROOT/cache" \
  MAC_SETUP_TEST_ROOT="$ROOT_DIR" NVIM_LOG_FILE="$TEMP_ROOT/nvim.log" \
  nvim --headless -u NONE -i NONE -l "$ROOT_DIR/test/nvim-go-test.lua"

if [[ "${1:-}" == "--integration" ]]; then
  # Existing tools only; no downloads or changes to the installed configuration.
  CONFORM_TEST_PATH="${CONFORM_TEST_PATH:-$HOME/.local/share/nvim/lazy/conform.nvim}"
  [[ -f "$CONFORM_TEST_PATH/lua/conform/init.lua" ]] || {
    printf 'FAIL set CONFORM_TEST_PATH to an existing conform.nvim checkout\n' >&2
    exit 1
  }
  command -v gopls >/dev/null
  mkdir -p "$TEMP_ROOT/project"
  printf 'module example.com/nvimtest\n\ngo 1.26.0\n' >"$TEMP_ROOT/project/go.mod"
  printf 'package main\nimport "os"\nfunc main(){fmt.Println("hello")}\n' \
    >"$TEMP_ROOT/project/main.go"
  GO_TEST_DIR="$TEMP_ROOT/project" GOPROXY=off GOTOOLCHAIN=local GOWORK=off \
    CONFORM_TEST_PATH="$CONFORM_TEST_PATH" MAC_SETUP_TEST_ROOT="$ROOT_DIR" \
    XDG_STATE_HOME="$TEMP_ROOT/state" XDG_CACHE_HOME="$TEMP_ROOT/cache" \
    NVIM_LOG_FILE="$TEMP_ROOT/nvim.log" \
    nvim --headless -u NONE -i NONE -l "$ROOT_DIR/test/nvim-go-integration.lua"
fi

#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

export REX_NAVIGATION_SCRIPT="$REPO_ROOT/config/rex/vim-navigation.vim"
export REX_NAVIGATION_TEST_LOG="$TEST_DIR/argv"
export REX_NAVIGATION_TEST_ERRORS="$TEST_DIR/errors"
export REX_SESSION='session:rex-navigation-test'
export REX_SERVER='unix:///tmp/rex navigation test.sock'
export REX_BIN_DIR="$TEST_DIR/rex bin"
export NVIM_LOG_FILE="$TEST_DIR/nvim.log"
mkdir -p "$REX_BIN_DIR"
cat > "$REX_BIN_DIR/rex" <<'FAKE_REX'
#!/bin/sh
printf '%s\n' "$@" >> "$REX_NAVIGATION_TEST_LOG"
FAKE_REX
chmod +x "$REX_BIN_DIR/rex"

editors=0
for editor in vim nvim; do
  if ! command -v "$editor" >/dev/null 2>&1; then
    continue
  fi
  : > "$REX_NAVIGATION_TEST_LOG"
  : > "$REX_NAVIGATION_TEST_ERRORS"
  if [[ "$editor" == nvim ]]; then
    command_line=(nvim --headless -u NONE -i NONE -n)
  else
    command_line=(vim -Nu NONE -i NONE -n -es)
  fi
  if ! "${command_line[@]}" -S "$REPO_ROOT/test/rex-navigation-test.vim"; then
    cat "$REX_NAVIGATION_TEST_ERRORS" >&2
    exit 1
  fi
  printf '%s navigation checks passed.\n' "$editor"
  editors=$((editors + 1))
done

if ((editors == 0)); then
  printf '%s\n' 'Vim or Neovim is required for navigation checks.' >&2
  exit 1
fi

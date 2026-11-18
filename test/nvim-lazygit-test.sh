#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

TEST_ROOT="$ROOT_DIR" TEST_TMP="$TEMP_ROOT" HOME="$TEMP_ROOT/home" \
  XDG_DATA_HOME="$TEMP_ROOT/data" XDG_STATE_HOME="$TEMP_ROOT/state" \
  XDG_CONFIG_HOME="$TEMP_ROOT/config" XDG_CACHE_HOME="$TEMP_ROOT/cache" \
  nvim --headless -u NONE -i NONE -l "$ROOT_DIR/test/nvim-lazygit-test.lua"

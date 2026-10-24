#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
printf 'fn transpose(value: i32) -> i32 { value }\nfn main() {\n    let _ = transpose(42);\n}\n' \
  >"$TEMP_ROOT/test.rs"
# Full installed plugin configuration, with temporary state and no fixture writes.
RUST_STANDALONE_FILE="${RUST_STANDALONE_FILE:-$TEMP_ROOT/test.rs}" \
  XDG_STATE_HOME="$TEMP_ROOT/state" XDG_CACHE_HOME="$TEMP_ROOT/cache" \
  NVIM_LOG_FILE="$TEMP_ROOT/nvim.log" MAC_SETUP_TEST_ROOT="$ROOT_DIR" \
  CARGO_NET_OFFLINE=true \
  nvim --headless -i NONE "${RUST_STANDALONE_FILE:-$TEMP_ROOT/test.rs}" \
  '+lua local ok, err = pcall(dofile, vim.env.MAC_SETUP_TEST_ROOT .. "/test/nvim-rust-standalone.lua"); if not ok then print(err); vim.cmd("cquit") end' \
  +qa

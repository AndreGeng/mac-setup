#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
TEST_SCRIPT=nvim-rust-standalone.lua
if [[ "${1:-}" == --diagnostics ]]; then
  TEST_SCRIPT=nvim-rust-diagnostics.lua
  printf 'fn main() {\n    let names = vec![String::from("Goose")];\n    let long_names: Vec<String> = names.iter().filter(|name| name.len() > 2).collect();\n    println!("{:?}", long_names);\n}\n' \
    >"$TEMP_ROOT/test.rs"
else
  printf 'fn transpose(value: i32) -> i32 { value }\nfn main() {\n    let _ = transpose(42);\n}\n' \
    >"$TEMP_ROOT/test.rs"
fi
# Full installed plugin configuration, with temporary state and no fixture writes.
RUST_STANDALONE_FILE="${RUST_STANDALONE_FILE:-$TEMP_ROOT/test.rs}" \
  XDG_STATE_HOME="$TEMP_ROOT/state" XDG_CACHE_HOME="$TEMP_ROOT/cache" \
  NVIM_LOG_FILE="$TEMP_ROOT/nvim.log" MAC_SETUP_TEST_ROOT="$ROOT_DIR" \
  RUST_TEST_SCRIPT="$ROOT_DIR/test/$TEST_SCRIPT" \
  RUST_TEST_FIXTURE="$TEMP_ROOT/test.rs" \
  CARGO_NET_OFFLINE=true \
  nvim --headless -i NONE "${RUST_STANDALONE_FILE:-$TEMP_ROOT/test.rs}" \
  '+lua local ok, err = pcall(dofile, vim.env.RUST_TEST_SCRIPT); if not ok then print(err); vim.cmd("cquit") end' \
  +qa

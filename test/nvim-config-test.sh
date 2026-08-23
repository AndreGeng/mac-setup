#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOP_SPEC="$ROOT_DIR/config/nvim/lua/plugins/hop.lua"
LAZY_LOCK="$ROOT_DIR/config/nvim/lazy-lock.json"

assert_contains() {
  local expected="$1"
  local file="$2"
  local description="$3"

  if ! grep -Fq "$expected" "$file"; then
    printf 'FAIL %s\n' "$description" >&2
    return 1
  fi
}

assert_contains "'smoka7/hop.nvim'" "$HOP_SPEC" \
  'Hop uses the maintained public repository'
assert_contains "version = 'v2.7.2'" "$HOP_SPEC" \
  'Hop uses the expected stable release'

if grep -Fq "'phaazon/hop.nvim'" "$HOP_SPEC"; then
  printf 'FAIL Hop still references the deleted upstream repository\n' >&2
  exit 1
fi

python3 - "$LAZY_LOCK" <<'PY'
import json
import pathlib
import sys

lock = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
hop = lock.get("hop.nvim")
if hop != {
    "branch": "master",
    "commit": "08ddca799089ab96a6d1763db0b8adc5320bf050",
}:
    raise SystemExit(f"unexpected hop.nvim lock entry: {hop!r}")
PY

printf 'PASS Neovim plugin configuration tests\n'

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXPECTED_PLATFORM="${1:?expected platform is required}"

fail() {
  printf 'FAIL %s full setup E2E: %s\n' "$EXPECTED_PLATFORM" "$1" >&2
  exit 1
}

"$ROOT_DIR/setup.sh" || fail 'setup.sh failed'

"$ROOT_DIR/test/e2e/linux-runtime.sh" "$EXPECTED_PLATFORM" first ||
  fail 'first runtime acceptance failed'

managed_state_digest() {
  sha256sum \
    "$HOME/.bashrc" \
    "$HOME/.config/opencode/opencode.json" \
    "$HOME/.config/opencode/AGENTS.md" \
    "$HOME/.codex/config.toml" \
    "$HOME/.codex/hooks.json" |
    sha256sum | awk '{print $1}'
}

before_digest="$(managed_state_digest)"
printf 'E2E %s idempotence: run setup.sh a second time\n' "$EXPECTED_PLATFORM"
"$ROOT_DIR/setup.sh" || fail 'second setup.sh failed during idempotence validation'
after_digest="$(managed_state_digest)"
[[ "$after_digest" == "$before_digest" ]] ||
  fail 'second setup changed stable shell or Agent configuration'

"$ROOT_DIR/test/e2e/linux-runtime.sh" "$EXPECTED_PLATFORM" second ||
  fail 'second runtime acceptance failed'

printf 'PASS %s full setup E2E\n' "$EXPECTED_PLATFORM"

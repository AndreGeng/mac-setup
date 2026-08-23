#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXPECTED_PLATFORM="${1:?expected platform is required}"

fail() {
  printf 'FAIL %s full setup E2E: %s\n' "$EXPECTED_PLATFORM" "$1" >&2
  exit 1
}

"$ROOT_DIR/setup.sh" || fail 'setup.sh failed'

export PATH="$HOME/.local/bin:$PATH"

actual_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
expected_shell="$(command -v zsh)"
[[ "$actual_shell" == "$expected_shell" ]] ||
  fail "login shell is $actual_shell instead of $expected_shell"

[[ -L "$HOME/.local/bin/opencode" ]] || fail 'managed OpenCode command link is missing'
[[ -L "$HOME/.local/bin/codex" ]] || fail 'managed Codex command link is missing'
[[ -L "$HOME/.local/bin/node" ]] || fail 'managed Node runtime link is missing'
[[ -L "$HOME/.local/bin/bun" ]] || fail 'managed Bun runtime link is missing'
command -v node >/dev/null 2>&1 || fail 'Node is unavailable through ~/.local/bin'
command -v bun >/dev/null 2>&1 || fail 'Bun is unavailable through ~/.local/bin'
command -v opencode >/dev/null 2>&1 || fail 'OpenCode is unavailable through ~/.local/bin'
command -v codex >/dev/null 2>&1 || fail 'Codex is unavailable through ~/.local/bin'
[[ "$(opencode --version)" == 1.18.20 ]] || fail 'OpenCode version does not match the manifest'
[[ "$(codex --version)" == 'codex-cli 0.149.0' ]] ||
  fail 'Codex version does not match the manifest'

[[ -f "$HOME/.config/opencode/opencode.json" ]] || fail 'OpenCode config is missing'
[[ -f "$HOME/.config/opencode/AGENTS.md" ]] || fail 'OpenCode agent instructions are missing'
[[ -f "$HOME/.codex/config.toml" ]] || fail 'Codex config is missing'
[[ -f "$HOME/.codex/hooks.json" ]] || fail 'Codex hooks are missing'
[[ -L "$HOME/.agents/skills/mac-setup" ]] || fail 'shared mac-setup skill is missing'

bash "$ROOT_DIR/modules/agents.sh" --audit >/dev/null || fail 'Agent config audit failed'

printf 'PASS %s full setup E2E\n' "$EXPECTED_PLATFORM"

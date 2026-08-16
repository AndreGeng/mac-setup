#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TEMP_HOME"' EXIT

run_module() {
  env -u MIFY_API_URL -u MIFY_API_ANTHROPIC_URL \
    HOME="$TEMP_HOME" bash "$ROOT_DIR/modules/agents.sh"
}

run_module

test -f "$TEMP_HOME/.config/opencode/opencode.json"
test -f "$TEMP_HOME/.config/opencode/AGENTS.md"
test -L "$TEMP_HOME/.config/opencode/plugins/workmux-status.ts"
test -f "$TEMP_HOME/.claude/settings.json"
test -f "$TEMP_HOME/.claude/CLAUDE.md"
test -f "$TEMP_HOME/.codex/config.toml"
test -f "$TEMP_HOME/.codex/hooks.json"
test -f "$TEMP_HOME/.pi/agent/settings.json"
test -L "$TEMP_HOME/.pi/agent/extensions/workmux-status.ts"
test ! -e "$TEMP_HOME/.pi/agent/models.json"
test -L "$TEMP_HOME/.agents/skills/dispatch"
test -L "$TEMP_HOME/.codex/skills/dispatch-team"
test -L "$TEMP_HOME/.pi/agent/skills/dispatch-team"

HOME="$TEMP_HOME" \
  MIFY_API_URL="https://openai.example.invalid" \
  MIFY_API_ANTHROPIC_URL="https://anthropic.example.invalid" \
  bash "$ROOT_DIR/modules/agents.sh"
test -f "$TEMP_HOME/.pi/agent/models.json"
grep -q 'https://openai.example.invalid' "$TEMP_HOME/.pi/agent/models.json"

printf '{"local":true}\n' >"$TEMP_HOME/.claude/settings.json"
run_module
grep -q '"local":true' "$TEMP_HOME/.claude/settings.json"

HOME="$TEMP_HOME" MAC_SETUP_FORCE_AGENT_CONFIG=1 bash "$ROOT_DIR/modules/agents.sh"
grep -q 'skipDangerousModePermissionPrompt' "$TEMP_HOME/.claude/settings.json"
test "$(find "$TEMP_HOME/.claude" -name 'settings.json.bak.*' | wc -l | tr -d ' ')" -eq 1
grep -q '"local":true' "$TEMP_HOME/.claude/settings.json.bak."*

HOME="$TEMP_HOME" MAC_SETUP_FORCE_AGENT_CONFIG=1 bash "$ROOT_DIR/modules/agents.sh"
test "$(find "$TEMP_HOME/.claude" -name 'settings.json.bak.*' | wc -l | tr -d ' ')" -eq 2

if grep -R -E '(mcp__[A-Za-z0-9_-]{20,}|/Users/[A-Za-z0-9._-]+/)' \
  "$TEMP_HOME/.config/opencode" "$TEMP_HOME/.claude" "$TEMP_HOME/.codex" "$TEMP_HOME/.pi"; then
  printf '%s\n' 'agent templates contain sensitive values' >&2
  exit 1
fi

printf '%s\n' 'PASS agent configuration migration'

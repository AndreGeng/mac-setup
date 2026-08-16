#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
NO_JQ_BIN="$TEMP_ROOT/no-jq-bin"
trap 'rm -rf "$TEMP_ROOT"' EXIT

mkdir -p "$NO_JQ_BIN"
for command_name in cat chmod cmp cp date dirname grep id ln mkdir mktemp mv pwd readlink rm stat; do
  ln -s "$(command -v "$command_name")" "$NO_JQ_BIN/$command_name"
done

new_home() {
  local name="$1"
  local home="$TEMP_ROOT/$name"

  mkdir -p "$home"
  printf '%s\n' "$home"
}

run_module() {
  local home="$1"
  shift
  env -u MIFY_API_URL -u MIFY_API_ANTHROPIC_URL \
    HOME="$home" bash "$ROOT_DIR/modules/agents.sh" "$@"
}

run_module_quiet() {
  run_module "$@" >/dev/null
}

run_module_without_jq() {
  local home="$1"
  shift
  env -u MIFY_API_URL -u MIFY_API_ANTHROPIC_URL \
    PATH="$NO_JQ_BIN" HOME="$home" /bin/bash "$ROOT_DIR/modules/agents.sh" "$@"
}

expect_fail() {
  local output="$1"
  shift

  if "$@" >"$output" 2>&1; then
    printf 'FAIL: expected command to fail: %s\n' "$*" >&2
    exit 1
  fi
}

home="$(new_home install)"
expect_fail "$TEMP_ROOT/audit-before.out" run_module "$home" --audit
grep -q 'AUDIT FAIL' "$TEMP_ROOT/audit-before.out"
grep -q '.config/opencode/opencode.json' "$TEMP_ROOT/audit-before.out"
grep -q '.claude/settings.json' "$TEMP_ROOT/audit-before.out"
grep -q '.codex/config.toml' "$TEMP_ROOT/audit-before.out"
grep -q '.pi/agent/settings.json' "$TEMP_ROOT/audit-before.out"

run_module_quiet "$home" --apply

test -f "$home/.config/opencode/opencode.json"
test -f "$home/.config/opencode/AGENTS.md"
test -L "$home/.config/opencode/plugins/workmux-status.ts"
test -f "$home/.claude/settings.json"
test -f "$home/.claude/CLAUDE.md"
test -f "$home/.codex/config.toml"
test -f "$home/.codex/hooks.json"
test -f "$home/.pi/agent/settings.json"
test -L "$home/.pi/agent/extensions/workmux-status.ts"
test ! -e "$home/.pi/agent/models.json"
test -L "$home/.agents/skills/dispatch"
test -L "$home/.agents/skills/dispatch-team"
test ! -e "$home/.codex/skills/dispatch"
test ! -e "$home/.pi/agent/skills/dispatch-team"
run_module_quiet "$home" --audit

home="$(new_home sourced)"
env -u MIFY_API_URL -u MIFY_API_ANTHROPIC_URL HOME="$home" \
  bash -c 'source "$1"; printf "%s\n" sourced-sentinel' \
  _ "$ROOT_DIR/modules/agents.sh" >"$TEMP_ROOT/sourced.out"
grep -q 'sourced-sentinel' "$TEMP_ROOT/sourced.out"
test -f "$home/.config/opencode/opencode.json"

expect_fail "$TEMP_ROOT/audit-no-jq.out" \
  run_module_without_jq "$home" --audit --only opencode
grep -q 'missing-parser' "$TEMP_ROOT/audit-no-jq.out"
expect_fail "$TEMP_ROOT/force-no-jq.out" \
  run_module_without_jq "$home" --apply --only opencode --force
grep -q 'missing-parser' "$TEMP_ROOT/force-no-jq.out"
test ! -e "$home/.config/opencode/opencode.json.bak."*

rm "$home/.config/opencode/plugins/workmux-status.ts"
printf 'drift\n' >"$home/.config/opencode/plugins/workmux-status.ts"
expect_fail "$TEMP_ROOT/audit-drift.out" run_module "$home" --audit --only opencode
grep -q 'managed-link' "$TEMP_ROOT/audit-drift.out"
expect_fail "$TEMP_ROOT/apply-drift.out" \
  run_module "$home" --apply --only opencode
test ! -L "$home/.config/opencode/plugins/workmux-status.ts"
grep -q 'managed-link-conflict' "$TEMP_ROOT/apply-drift.out"
run_module_quiet "$home" --apply --only opencode --repair-links
test -L "$home/.config/opencode/plugins/workmux-status.ts"
test -f "$home/.config/opencode/plugins/workmux-status.ts.bak."*
run_module_quiet "$home" --audit --only opencode

HOME="$home" \
  MIFY_API_URL="https://openai.example.invalid" \
  MIFY_API_ANTHROPIC_URL="https://anthropic.example.invalid" \
  bash "$ROOT_DIR/modules/agents.sh" --apply --only pi >/dev/null
test -f "$home/.pi/agent/models.json"
test "$(jq -r '.providers["mify-openai"].baseUrl' \
  "$home/.pi/agent/models.json")" = "https://openai.example.invalid"
test "$(jq -r '.providers.anthropic.baseUrl' \
  "$home/.pi/agent/models.json")" = "https://anthropic.example.invalid"
test "$(jq -r '.providers.openai // empty' \
  "$home/.pi/agent/models.json")" = ""
! grep -q '__MIFY_API_' "$home/.pi/agent/models.json"

home="$(new_home only)"
run_module_quiet "$home" --apply --only codex
test -f "$home/.codex/config.toml"
test ! -e "$home/.config/opencode/opencode.json"
test ! -e "$home/.claude/settings.json"
test ! -e "$home/.pi/agent/settings.json"
run_module_quiet "$home" --audit --only codex

home="$(new_home preserve)"
run_module_quiet "$home" --apply --only claude
printf '{"local":true}\n' >"$home/.claude/settings.json"
run_module_quiet "$home" --apply --only claude
grep -q '"local":true' "$home/.claude/settings.json"

run_module_quiet "$home" --apply --only claude --force
test -f "$home/.claude/settings.json.bak."*
test ! -e "$home/.claude/settings.json.bak."*.1
grep -q '"local":true' "$home/.claude/settings.json.bak."*

home="$(new_home secret)"
mkdir -p "$home/.claude"
printf '{"env":{"ANTHROPIC_API_KEY":"test-secret-value"}}\n' \
  >"$home/.claude/settings.json"
expect_fail "$TEMP_ROOT/force-secret.out" \
  run_module "$home" --apply --only claude --force
grep -q 'sensitive-config' "$TEMP_ROOT/force-secret.out"
if grep -q 'test-secret-value' "$TEMP_ROOT/force-secret.out"; then
  printf '%s\n' 'FAIL: force rejection leaked the secret value' >&2
  exit 1
fi
test ! -e "$home/.claude/settings.json.bak."*
test ! -e "$home/.claude/CLAUDE.md"

home="$(new_home env-secret)"
mkdir -p "$home/.config"
printf 'MIFY_API_TEAM_KEY=test-secret-value\n' \
  >"$home/.config/agent-env.example"
expect_fail "$TEMP_ROOT/force-env-secret.out" \
  run_module "$home" --apply --only shared --force
grep -q 'sensitive-config' "$TEMP_ROOT/force-env-secret.out"
if grep -q 'test-secret-value' "$TEMP_ROOT/force-env-secret.out"; then
  printf '%s\n' 'FAIL: env rejection leaked the secret value' >&2
  exit 1
fi
test ! -e "$home/.config/agent-env.example.bak."*

home="$(new_home invalid-json)"
mkdir -p "$home/.config/opencode"
printf '{invalid json\n' >"$home/.config/opencode/opencode.json"
printf 'keep this file\n' >"$home/.config/opencode/AGENTS.md"
expect_fail "$TEMP_ROOT/invalid-json.out" \
  run_module "$home" --apply --only opencode --force
grep -q 'invalid-config' "$TEMP_ROOT/invalid-json.out"
grep -q 'keep this file' "$home/.config/opencode/AGENTS.md"
test ! -e "$home/.config/opencode/AGENTS.md.bak."*

home="$(new_home jsonc-secret)"
mkdir -p "$home/.config/opencode"
printf '{"apiKey":"jsonc-secret-value"}\n' \
  >"$home/.config/opencode/dcp.jsonc"
expect_fail "$TEMP_ROOT/jsonc-secret.out" \
  run_module "$home" --apply --only opencode --force
grep -q 'sensitive-config' "$TEMP_ROOT/jsonc-secret.out"
if grep -q 'jsonc-secret-value' "$TEMP_ROOT/jsonc-secret.out"; then
  printf '%s\n' 'FAIL: JSONC scan leaked the secret value' >&2
  exit 1
fi

home="$(new_home toml-secret)"
mkdir -p "$home/.codex"
printf '%s\n' '[mcp_servers.example]' \
  'http_headers = { Authorization = "Bearer toml-secret-value" }' \
  >"$home/.codex/config.toml"
expect_fail "$TEMP_ROOT/toml-secret.out" \
  run_module "$home" --apply --only codex --force
grep -q 'sensitive-config' "$TEMP_ROOT/toml-secret.out"
if grep -q 'toml-secret-value' "$TEMP_ROOT/toml-secret.out"; then
  printf '%s\n' 'FAIL: TOML scan leaked the secret value' >&2
  exit 1
fi

home="$(new_home backup-secret)"
run_module_quiet "$home" --apply --only opencode
printf '{"url":"https://example.invalid/mcp?token=backup-secret-value"}\n' \
  >"$home/.config/opencode/opencode.json.tui-migration.bak"
chmod 600 "$home/.config/opencode/opencode.json.tui-migration.bak"
expect_fail "$TEMP_ROOT/backup-secret.out" \
  run_module "$home" --audit --only opencode
grep -q 'sensitive-config' "$TEMP_ROOT/backup-secret.out"
if grep -q 'backup-secret-value' "$TEMP_ROOT/backup-secret.out"; then
  printf '%s\n' 'FAIL: backup audit leaked the secret value' >&2
  exit 1
fi

if grep -RqE '(mcp__[A-Za-z0-9_-]{20,}|/Users/[A-Za-z0-9._-]+/)' \
  "$TEMP_ROOT/install/.config/opencode" "$TEMP_ROOT/install/.claude" \
  "$TEMP_ROOT/install/.codex" "$TEMP_ROOT/install/.pi"; then
  printf '%s\n' 'agent templates contain sensitive values' >&2
  exit 1
fi

test "$(jq -r '.permission.external_directory' \
  "$ROOT_DIR/config/opencode/opencode.json")" = "ask"
test "$(jq -r '.permission.bash["git reset --hard*"]' \
  "$ROOT_DIR/config/opencode/opencode.json")" = "deny"
test "$(jq -r '.permission.bash["git push*"]' \
  "$ROOT_DIR/config/opencode/opencode.json")" = "deny"
test "$(jq -r '.permission.bash["rm -fr *"]' \
  "$ROOT_DIR/config/opencode/opencode.json")" = "deny"
! grep -q '@latest' "$ROOT_DIR/config/opencode/opencode.json"
! grep -q 'skipDangerousModePermissionPrompt' \
  "$ROOT_DIR/config/claude/settings.json"
! grep -q 'skipAutoPermissionPrompt' "$ROOT_DIR/config/claude/settings.json"
grep -q 'network_access = false' "$ROOT_DIR/config/codex/config.toml"
grep -q '"mify-openai"' "$ROOT_DIR/config/pi/models.template.json"

printf '%s\n' 'PASS agent configuration management'

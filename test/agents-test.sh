#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
NO_JQ_BIN="$TEMP_ROOT/no-jq-bin"
NO_BUN_BIN="$TEMP_ROOT/no-bun-bin"
FAKE_REME_PYTHON="$TEMP_ROOT/fake-reme-python"
REME_TEST_LOG="$TEMP_ROOT/reme-install.log"
trap 'rm -rf "$TEMP_ROOT"' EXIT

mkdir -p "$NO_JQ_BIN"
for command_name in cat chmod cmp cp date dirname grep id ln mkdir mktemp mv pwd readlink rm stat; do
  ln -s "$(command -v "$command_name")" "$NO_JQ_BIN/$command_name"
done

mkdir -p "$NO_BUN_BIN"
for command_name in cat chmod cmp cp date dirname grep id jq ln mkdir mktemp mv pwd python3 \
  readlink rm stat; do
  ln -s "$(command -v "$command_name")" "$NO_BUN_BIN/$command_name"
done

cat >"$FAKE_REME_PYTHON" <<'EOF'
#!/bin/bash
set -euo pipefail

if [[ "${1:-}" == "-m" && "${2:-}" == "venv" ]]; then
  venv="$3"
  mkdir -p "$venv/bin"
  cp "$0" "$venv/bin/python"
  chmod +x "$venv/bin/python"
  exit 0
fi

if [[ "${1:-}" == "-m" && "${2:-}" == "pip" ]]; then
  printf '%s\n' "$*" >>"$REME_TEST_LOG"
  touch "$(dirname "$(dirname "$0")")/.reme-version-0.4.1.7"
  printf '#!%s\nexit 0\n' "$(dirname "$0")/python" >"$(dirname "$0")/reme"
  chmod +x "$(dirname "$0")/reme"
  exit 0
fi

if [[ "${1:-}" == "-c" ]]; then
  if [[ "$2" == *"sys.version_info"* ]]; then
    exit 0
  fi
  version_root="$(dirname "$(dirname "$0")")"
  if [[ -f "$version_root/.reme-version-0.4.1.7" ]]; then
    printf '%s\n' '0.4.1.7'
    exit 0
  fi
  printf '%s\n' '0.0.0'
  exit 0
fi

if [[ "${1:-}" == "-" && "${2:-}" == "generate" ]]; then
  config_path="$3"
  mkdir -p "$(dirname "$config_path")"
  cat >"$config_path" <<'YAML'
service:
  backend: cli
  web_enabled: false
jobs:
  auto_memory:
    backend: base
  daily_list:
    backend: base
  daily_write:
    backend: base
  delete:
    backend: base
  edit:
    backend: base
  frontmatter_read:
    backend: base
  frontmatter_update:
    backend: base
  list:
    backend: base
  load:
    backend: base
  move:
    backend: base
  read:
    backend: base
  save:
    backend: base
  stat:
    backend: base
  write:
    backend: base
components: {}
YAML
  exit 0
fi

if [[ "${1:-}" == "-" && "${2:-}" == "generate-global" ]]; then
  config_path="$3"
  workspace_path="$4"
  mkdir -p "$(dirname "$config_path")"
  cat >"$config_path" <<YAML
workspace_dir: $workspace_path
service:
  backend: http
  host: 127.0.0.1
  port: 2333
  web_enabled: false
  jobs:
    - app_config
    - auto_memory
    - health_check
    - search
    - version
jobs:
  index_update_loop:
    backend: background
    enable_serve: false
  digest_watch_loop:
    backend: background
    enable_serve: false
  dream_cron:
    backend: cron
    cron: "0 23 * * *"
    enable_serve: false
  optimize_index_cron:
    backend: cron
    cron: "0 2 * * *"
    enable_serve: false
  auto_memory:
    backend: base
    enable_serve: true
  search:
    backend: base
    enable_serve: true
components: {}
YAML
  exit 0
fi

if [[ "${1:-}" == "-" && "${2:-}" == "audit" ]]; then
  config_path="$3"
  grep -q '^  auto_memory:' "$config_path"
  if grep -Eq '(cron|background|auto_dream|dream_cron|auto_resource|daily_dir:[[:space:]]*digest)' \
    "$config_path"; then
    exit 1
  fi
  exit 0
fi

if [[ "${1:-}" == "-" && "${2:-}" == "audit-global" ]]; then
  config_path="$3"
  workspace_path="$4"
  grep -q "^workspace_dir: $workspace_path$" "$config_path"
  grep -q '^  host: 127.0.0.1$' "$config_path"
  grep -q '^  web_enabled: false$' "$config_path"
  grep -q '^  dream_cron:' "$config_path"
  grep -q '^    cron: "0 23 \* \* \*"$' "$config_path"
  grep -q '^  optimize_index_cron:' "$config_path"
  grep -q '^    - search$' "$config_path"
  if grep -Eq '(host: 0\.0\.0\.0|web_enabled: true|cron: "0 0 \* \* \*"|resource_watch_loop)' \
    "$config_path"; then
    exit 1
  fi
  exit 0
fi

if [[ "${1:-}" == "-" && "${2:-}" == "sensitive" ]]; then
  config_path="$3"
  if grep -Eq '^[[:space:]]*(api[_-]?key|token|secret|password):[[:space:]]*[^$[:space:]]' \
    "$config_path"; then
    exit 0
  fi
  exit 1
fi

if [[ "${1:-}" == "-" && "${2:-}" == "stop-global" ]]; then
  exit 0
fi

exit 1
EOF
chmod +x "$FAKE_REME_PYTHON"

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
    MAC_SETUP_REME_PYTHON="$FAKE_REME_PYTHON" REME_TEST_LOG="$REME_TEST_LOG" \
    HOME="$home" bash "$ROOT_DIR/modules/agents.sh" "$@"
}

run_module_quiet() {
  run_module "$@" >/dev/null
}

run_module_without_jq() {
  local home="$1"
  shift
  env -u MIFY_API_URL -u MIFY_API_ANTHROPIC_URL \
    MAC_SETUP_REME_PYTHON="$FAKE_REME_PYTHON" REME_TEST_LOG="$REME_TEST_LOG" \
    PATH="$NO_JQ_BIN" HOME="$home" /bin/bash "$ROOT_DIR/modules/agents.sh" "$@"
}

run_module_without_bun() {
  local home="$1"
  shift
  env -u MIFY_API_URL -u MIFY_API_ANTHROPIC_URL \
    MAC_SETUP_REME_PYTHON="$FAKE_REME_PYTHON" REME_TEST_LOG="$REME_TEST_LOG" \
    PATH="$NO_BUN_BIN" HOME="$home" /bin/bash "$ROOT_DIR/modules/agents.sh" "$@"
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

expect_fail "$TEMP_ROOT/audit-no-bun.out" run_module_without_bun "$home" --audit --only codex
grep -q 'bun-runtime' "$TEMP_ROOT/audit-no-bun.out"

test -f "$home/.config/opencode/opencode.json"
test -f "$home/.config/opencode/AGENTS.md"
test -L "$home/.config/opencode/plugins/workmux-status.ts"
test -L "$home/.config/opencode/plugins/reme-memory.ts"
test -L "$home/.config/agents/reme-memory-bridge.ts"
test -L "$home/.local/share/mac-setup/reme/venv"
test "$(readlink "$home/.local/share/mac-setup/reme/venv")" = \
  "$home/.local/share/mac-setup/reme/venv-0.4.1.7"
test -x "$home/.local/share/mac-setup/reme/venv/bin/reme"
test -f "$home/.config/reme/opencode-candidate.yaml"
test -f "$home/.config/reme/opencode-global.yaml"
test -L "$home/.config/reme/start-global-service.sh"
test -L "$home/.config/reme/run-project-capture.py"
test -x "$home/.config/reme/start-global-service.sh"
test -d "$home/.local/share/mac-setup/reme/global"
test "$(stat -f '%Lp' "$home/.config/reme/opencode-candidate.yaml" 2>/dev/null ||
  stat -c '%a' "$home/.config/reme/opencode-candidate.yaml")" = "600"
test "$(stat -f '%Lp' "$home/.config/reme/opencode-global.yaml" 2>/dev/null ||
  stat -c '%a' "$home/.config/reme/opencode-global.yaml")" = "600"
test "$(stat -f '%Lp' "$home/.local/share/mac-setup/reme/global" 2>/dev/null ||
  stat -c '%a' "$home/.local/share/mac-setup/reme/global")" = "700"
grep -q '^  host: 127.0.0.1$' "$home/.config/reme/opencode-global.yaml"
grep -q '^  web_enabled: false$' "$home/.config/reme/opencode-global.yaml"
grep -q '^  dream_cron:' "$home/.config/reme/opencode-global.yaml"
grep -q '^    cron: "0 23 \* \* \*"$' "$home/.config/reme/opencode-global.yaml"
grep -q '^    - search$' "$home/.config/reme/opencode-global.yaml"
grep -qF 'reme-ai[core]==0.4.1.7' "$REME_TEST_LOG"
test "$(wc -l <"$REME_TEST_LOG" | tr -d ' ')" = "1"
test -f "$home/.claude/settings.json"
test -f "$home/.claude/CLAUDE.md"
test -f "$home/.codex/config.toml"
test -f "$home/.codex/hooks.json"
test -f "$home/.pi/agent/settings.json"
test -L "$home/.pi/agent/extensions/workmux-status.ts"
test -L "$home/.pi/agent/extensions/reme-memory.ts"
test ! -e "$home/.pi/agent/models.json"
test -L "$home/.agents/skills/dispatch"
test -L "$home/.agents/skills/dispatch-team"
test ! -e "$home/.codex/skills/dispatch"
test ! -e "$home/.pi/agent/skills/dispatch-team"
run_module_quiet "$home" --apply --only opencode
test "$(wc -l <"$REME_TEST_LOG" | tr -d ' ')" = "1"
run_module_quiet "$home" --audit

cp "$home/.config/reme/opencode-global.yaml" "$TEMP_ROOT/opencode-global.safe.yaml"
printf '%s\n' 'service:' '  host: 0.0.0.0' \
  >>"$home/.config/reme/opencode-global.yaml"
expect_fail "$TEMP_ROOT/audit-reme-global-host.out" \
  run_module "$home" --audit --only opencode
grep -q 'reme-global-policy' "$TEMP_ROOT/audit-reme-global-host.out"
cp "$TEMP_ROOT/opencode-global.safe.yaml" "$home/.config/reme/opencode-global.yaml"
run_module_quiet "$home" --audit --only opencode

printf '%s\n' '  resource_watch_loop:' '    backend: background' \
  >>"$home/.config/reme/opencode-global.yaml"
expect_fail "$TEMP_ROOT/audit-reme-global-resource.out" \
  run_module "$home" --audit --only opencode
grep -q 'reme-global-policy' "$TEMP_ROOT/audit-reme-global-resource.out"
cp "$TEMP_ROOT/opencode-global.safe.yaml" "$home/.config/reme/opencode-global.yaml"
run_module_quiet "$home" --audit --only opencode

printf '%s\n' '  dream_cron: cron' >>"$home/.config/reme/opencode-candidate.yaml"
expect_fail "$TEMP_ROOT/audit-reme-policy.out" \
  run_module "$home" --audit --only opencode
grep -q 'reme-config-policy' "$TEMP_ROOT/audit-reme-policy.out"
run_module_quiet "$home" --apply --only opencode
run_module_quiet "$home" --audit --only opencode

printf '%s\n' 'daily_dir: digest' >>"$home/.config/reme/opencode-candidate.yaml"
expect_fail "$TEMP_ROOT/audit-reme-directory.out" \
  run_module "$home" --audit --only opencode
grep -q 'reme-config-policy' "$TEMP_ROOT/audit-reme-directory.out"
run_module_quiet "$home" --apply --only opencode

printf '%s\n' 'credential:' '  api_key: literal-secret-value-12345' \
  >>"$home/.config/reme/opencode-candidate.yaml"
expect_fail "$TEMP_ROOT/audit-reme-secret.out" \
  run_module "$home" --audit --only opencode
grep -q 'sensitive-config' "$TEMP_ROOT/audit-reme-secret.out"
if grep -q 'literal-secret-value-12345' "$TEMP_ROOT/audit-reme-secret.out"; then
  printf '%s\n' 'FAIL: ReMe audit leaked the secret value' >&2
  exit 1
fi
expect_fail "$TEMP_ROOT/apply-reme-secret.out" \
  run_module "$home" --apply --only opencode
grep -q 'sensitive-config' "$TEMP_ROOT/apply-reme-secret.out"
grep -q 'literal-secret-value-12345' "$home/.config/reme/opencode-candidate.yaml"
if grep -q 'literal-secret-value-12345' "$TEMP_ROOT/apply-reme-secret.out"; then
  printf '%s\n' 'FAIL: ReMe apply leaked the secret value' >&2
  exit 1
fi
rm "$home/.config/reme/opencode-candidate.yaml"
run_module_quiet "$home" --apply --only opencode

rm "$home/.local/share/mac-setup/reme/venv/.reme-version-0.4.1.7"
expect_fail "$TEMP_ROOT/audit-reme-version.out" \
  run_module "$home" --audit --only opencode
grep -q 'reme-version' "$TEMP_ROOT/audit-reme-version.out"
run_module_quiet "$home" --apply --only opencode
test "$(wc -l <"$REME_TEST_LOG" | tr -d ' ')" = "2"

home="$(new_home sourced)"
env -u MIFY_API_URL -u MIFY_API_ANTHROPIC_URL HOME="$home" \
  MAC_SETUP_REME_PYTHON="$FAKE_REME_PYTHON" REME_TEST_LOG="$REME_TEST_LOG" \
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

rm "$home/.config/opencode/plugins/reme-memory.ts"
printf 'drift\n' >"$home/.config/opencode/plugins/reme-memory.ts"
expect_fail "$TEMP_ROOT/audit-reme-link.out" run_module "$home" --audit --only opencode
grep -q 'managed-link' "$TEMP_ROOT/audit-reme-link.out"
expect_fail "$TEMP_ROOT/apply-reme-link.out" \
  run_module "$home" --apply --only opencode
grep -q 'managed-link-conflict' "$TEMP_ROOT/apply-reme-link.out"
run_module_quiet "$home" --apply --only opencode --repair-links
test -L "$home/.config/opencode/plugins/reme-memory.ts"
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
test -L "$home/.local/share/mac-setup/reme/venv"
test -f "$home/.config/reme/opencode-candidate.yaml"
test -f "$home/.config/reme/opencode-global.yaml"
test -L "$home/.config/reme/start-global-service.sh"
test -L "$home/.config/reme/run-project-capture.py"
test -L "$home/.config/agents/reme-memory-bridge.ts"
test ! -e "$home/.config/opencode/opencode.json"
test ! -e "$home/.claude/settings.json"
test ! -e "$home/.pi/agent/settings.json"
run_module_quiet "$home" --audit --only codex

rm "$home/.config/agents/reme-memory-bridge.ts"
printf '%s\n' 'locally owned bridge' >"$home/.config/agents/reme-memory-bridge.ts"
expect_fail "$TEMP_ROOT/audit-codex-bridge.out" run_module "$home" --audit --only codex
grep -q 'managed-link' "$TEMP_ROOT/audit-codex-bridge.out"
expect_fail "$TEMP_ROOT/apply-codex-bridge.out" run_module "$home" --apply --only codex
grep -q 'managed-link-conflict' "$TEMP_ROOT/apply-codex-bridge.out"

home="$(new_home remove-reme)"
run_module_quiet "$home" --apply --only opencode
run_module_quiet "$home" --apply --only pi
mkdir -p "$home/project/.reme/daily"
printf '%s\n' 'keep candidate memory' >"$home/project/.reme/daily/keep.md"
mkdir -p "$home/.local/share/mac-setup/reme/global/daily"
printf '%s\n' 'keep global memory' \
  >"$home/.local/share/mac-setup/reme/global/daily/keep.md"
mkdir -p "$home/.local/state/mac-setup/reme-hooks" "$home/.local/state/other-owner"
printf '%s\n' '{"stage":"capture","success":true}' \
  >"$home/.local/state/mac-setup/reme-hooks/status.json"
printf '%s\n' 'preserve unrelated state' >"$home/.local/state/other-owner/keep"
run_module_quiet "$home" --remove-reme
test ! -e "$home/.config/opencode/plugins/reme-memory.ts"
test ! -e "$home/.config/agents/reme-memory-bridge.ts"
test ! -e "$home/.pi/agent/extensions/reme-memory.ts"
test ! -e "$home/.config/reme/opencode-candidate.yaml"
test ! -e "$home/.config/reme/opencode-global.yaml"
test ! -e "$home/.config/reme/start-global-service.sh"
test ! -e "$home/.config/reme/run-project-capture.py"
test ! -e "$home/.local/share/mac-setup/reme/venv"
test ! -e "$home/.local/state/mac-setup/reme-hooks"
test -f "$home/.local/state/other-owner/keep"
test -L "$home/.config/opencode/plugins/workmux-status.ts"
test -L "$home/.pi/agent/extensions/workmux-status.ts"
test -f "$home/project/.reme/daily/keep.md"
test -f "$home/.local/share/mac-setup/reme/global/daily/keep.md"

run_module_quiet "$home" --apply --only opencode
rm "$home/.config/opencode/plugins/reme-memory.ts"
printf '%s\n' 'locally owned plugin' >"$home/.config/opencode/plugins/reme-memory.ts"
expect_fail "$TEMP_ROOT/remove-reme-conflict.out" \
  run_module "$home" --remove-reme --only opencode
grep -q 'managed-link-conflict' "$TEMP_ROOT/remove-reme-conflict.out"
test -d "$home/.local/share/mac-setup/reme/venv"
test -f "$home/.config/reme/opencode-candidate.yaml"
grep -q 'locally owned plugin' "$home/.config/opencode/plugins/reme-memory.ts"

home="$(new_home reme-layout)"
run_module_quiet "$home" --apply --only opencode
install_count="$(wc -l <"$REME_TEST_LOG" | tr -d ' ')"
rm "$home/.local/share/mac-setup/reme/venv"
cp -R "$home/.local/share/mac-setup/reme/venv-0.4.1.7" \
  "$home/.local/share/mac-setup/reme/venv"
run_module_quiet "$home" --apply --only opencode
test -L "$home/.local/share/mac-setup/reme/venv"
test "$(wc -l <"$REME_TEST_LOG" | tr -d ' ')" = "$((install_count + 1))"

printf '%s\n' '#!/bin/bash' 'exit 0' \
  >"$home/.local/share/mac-setup/reme/venv-0.4.1.7/bin/reme"
chmod +x "$home/.local/share/mac-setup/reme/venv-0.4.1.7/bin/reme"
expect_fail "$TEMP_ROOT/audit-reme-shebang.out" \
  run_module "$home" --audit --only opencode
grep -q 'reme-install' "$TEMP_ROOT/audit-reme-shebang.out"

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

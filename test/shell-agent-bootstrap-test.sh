#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

pass_count=0
fail_count=0

run_test() {
  local name="$1"
  shift

  if "$@"; then
    printf 'PASS %s\n' "$name"
    pass_count=$((pass_count + 1))
  else
    printf 'FAIL %s\n' "$name" >&2
    fail_count=$((fail_count + 1))
  fi
}

write_command() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$path"
  chmod +x "$path"
}

test_zsh_module_ensures_login_shell() {
  local home="$TEMP_ROOT/zsh.home"
  local fake_bin="$TEMP_ROOT/zsh.bin"
  local output="$TEMP_ROOT/zsh.out"
  mkdir -p "$home/.local/share/zinit/zinit.git/.git" "$fake_bin"
  : >"$home/.local/share/zinit/zinit.git/zinit.zsh"
  write_command "$fake_bin/zsh"

  HOME="$home" PATH="$fake_bin:/usr/bin:/bin" ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/utils.sh"
    log() { :; }
    fix_zsh_permissions() { :; }
    pkg_install() { :; }
    is_macos() { return 1; }
    ensure_zsh_default_shell() { printf "%s\n" "$1"; }
    source "$ROOT_DIR/modules/zsh.sh"
  ' >"$output" || return 1

  [[ "$(<"$output")" == "$(realpath "$fake_bin/zsh")" ]]
}

test_zsh_executable_uses_canonical_path() {
  local root="$TEMP_ROOT/zsh-canonical"
  mkdir -p "$root/usr/bin"
  write_command "$root/usr/bin/zsh"
  ln -s "$root/usr/bin" "$root/usr/sbin"

  local resolved
  resolved="$(PATH="$root/usr/sbin:/usr/bin:/bin" ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/utils.sh"
    resolve_zsh_executable
  ')" || return 1
  [[ "$resolved" == "$(realpath "$root/usr/bin/zsh")" ]]
}

test_node_manifest_declares_agent_commands() {
  local output package_output
  output="$(ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/runtime-manifest.sh"
    node_manifest_command_records "$ROOT_DIR"
  ')" || return 1
  package_output="$(ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/runtime-manifest.sh"
    node_manifest_records "$ROOT_DIR" npm
  ')" || return 1

  grep -Fxq 'opencode-ai|1.18.20|opencode' <<<"$output" || return 1
  grep -Fxq '@openai/codex|0.149.0|codex' <<<"$output" || return 1
  grep -Fxq 'opencode-ai|1.18.20' <<<"$package_output" || return 1
  grep -Fxq '@openai/codex|0.149.0' <<<"$package_output"
}

test_node_module_publishes_agent_commands() {
  local home="$TEMP_ROOT/node.home"
  local node_root="$TEMP_ROOT/node.runtime"
  local bun_root="$TEMP_ROOT/bun.runtime"
  local fake_mise="$TEMP_ROOT/mise"
  mkdir -p "$home" "$node_root/bin" "$bun_root/bin"
  write_command "$node_root/bin/node"
  write_command "$node_root/bin/npm"
  write_command "$node_root/bin/opencode"
  write_command "$node_root/bin/codex"
  write_command "$bun_root/bin/bun"
  printf '%s\n' '#!/usr/bin/env bash' \
    'case "$*" in' \
    '  "where node@22.23.2") printf "%s\n" "$NODE_ROOT" ;;' \
    '  "where bun@1.3.7") printf "%s\n" "$BUN_ROOT" ;;' \
    '  "use -g node@22.23.2"|"use -g bun@1.3.7") exit 0 ;;' \
    '  *) exit 1 ;;' \
    'esac' >"$fake_mise"
  chmod +x "$fake_mise"

  ROOT_DIR="$ROOT_DIR" HOME="$home" NODE_ROOT="$node_root" BUN_ROOT="$bun_root" \
    FAKE_MISE="$fake_mise" PATH="/usr/bin:/bin" bash -c '
      source "$ROOT_DIR/lib/utils.sh"
      log() { :; }
      install_mise() { :; }
      resolve_mise_executable() { printf "%s\n" "$FAKE_MISE"; }
      source "$ROOT_DIR/modules/nodejs.sh"
    ' >/dev/null 2>&1 || return 1

  [[ -L "$home/.local/bin/node" ]] || return 1
  [[ "$(readlink "$home/.local/bin/node")" == "$node_root/bin/node" ]] || return 1
  [[ -L "$home/.local/bin/bun" ]] || return 1
  [[ "$(readlink "$home/.local/bin/bun")" == "$bun_root/bin/bun" ]] || return 1
  [[ -L "$home/.local/bin/opencode" ]] || return 1
  [[ "$(readlink "$home/.local/bin/opencode")" == "$node_root/bin/opencode" ]] || return 1
  [[ -L "$home/.local/bin/codex" ]] || return 1
  [[ "$(readlink "$home/.local/bin/codex")" == "$node_root/bin/codex" ]]
}

test_shell_plan_requires_default_shell_change() {
  ROOT_DIR="$ROOT_DIR" HOME="$TEMP_ROOT/plan.home" bash -c '
    source "$ROOT_DIR/lib/mac-setup/engine.sh"
    detect_platform() { printf "%s\n" arch; }
    resolve_zsh_executable() { printf "%s\n" /usr/bin/zsh; }
    current_login_shell() { printf "%s\n" /bin/bash; }
    plan_target shell.zsh false
    for index in "${!PLAN_CHANGE_TYPES[@]}"; do
      [[ "${PLAN_CHANGE_TYPES[$index]}" == SET_LOGIN_SHELL &&
        "${PLAN_CHANGE_RESOURCES[$index]}" == /usr/bin/zsh ]] && found=true
    done
    [[ "${found:-false}" == true ]] || exit 1
    approval_is_allowed sudo "${PLAN_APPROVAL_TYPES[@]}"
  ' >/dev/null 2>&1
}

run_test zsh-module-ensures-login-shell test_zsh_module_ensures_login_shell
run_test zsh-executable-uses-canonical-path test_zsh_executable_uses_canonical_path
run_test node-manifest-declares-agent-commands test_node_manifest_declares_agent_commands
run_test node-module-publishes-agent-commands test_node_module_publishes_agent_commands
run_test shell-plan-requires-default-shell-change \
  test_shell_plan_requires_default_shell_change

if ((fail_count > 0)); then
  printf 'FAIL shell/agent bootstrap tests (%d passed, %d failed)\n' \
    "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS shell/agent bootstrap tests (%d cases)\n' "$pass_count"

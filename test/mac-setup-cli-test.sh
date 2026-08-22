#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/bin/mac-setup"
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

json_assert() {
  local path="$1"
  local expression="$2"
  python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle)
if not eval(
    sys.argv[2],
    {"__builtins__": {}},
    {"value": value, "set": set, "all": all, "len": len, "sum": sum},
):
    raise SystemExit(1)
' "$path" "$expression"
}

json_value() {
  local path="$1"
  local key="$2"
  python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle)
for key in sys.argv[2].split("."):
    value = value[key]
print(value)
' "$path" "$key"
}

write_fake_command() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$path"
  chmod +x "$path"
}

write_fake_linux_uname() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' '#!/usr/bin/env bash' \
    'case "${1:-}" in' \
    '  -s) printf "%s\n" Linux ;;' \
    '  -m) printf "%s\n" x86_64 ;;' \
    '  *) printf "%s\n" Linux ;;' \
    'esac' >"$path"
  chmod +x "$path"
}

cli_env() {
  local home="$1"
  local state="$2"
  local fake_bin="$3"
  shift 3
  env OSTYPE="${MAC_SETUP_TEST_OSTYPE:-$OSTYPE}" HOME="$home" XDG_STATE_HOME="$state" \
    PATH="$fake_bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$CLI" "$@"
}

test_lists_agent_discoverable_capabilities() {
  local output="$TEMP_ROOT/list.json"
  "$CLI" list --format json >"$output" || return 1
  json_assert "$output" 'value["schemaVersion"] == "1"' || return 1
  json_assert "$output" 'value["operation"] == "list"' || return 1
  json_assert "$output" \
    'set(item["id"] for item in value["capabilities"]) == {"editor.nvim", "shell.zsh", "terminal.tmux"}'
  json_assert "$output" \
    'set(item["id"] for item in value["profiles"]) == {"profile.terminal"}' || return 1
  json_assert "$output" \
    'value["profiles"][0]["members"] == ["shell.zsh", "editor.nvim"]'
}

test_describes_terminal_profile_with_ordered_members() {
  local output="$TEMP_ROOT/describe-profile.json"
  "$CLI" describe terminal --format json >"$output" || return 1
  json_assert "$output" 'value["profile"]["id"] == "profile.terminal"' || return 1
  json_assert "$output" 'value["profile"]["aliases"] == ["terminal"]' || return 1
  json_assert "$output" \
    'value["profile"]["members"] == ["shell.zsh", "editor.nvim"]'
}

test_human_list_includes_terminal_profile() {
  local output="$TEMP_ROOT/list.txt"
  "$CLI" list >"$output" || return 1
  grep -qx 'editor.nvim' "$output" || return 1
  grep -qx 'shell.zsh' "$output" || return 1
  grep -qx 'profile.terminal' "$output"
}

test_describes_alias_with_stable_canonical_id() {
  local output="$TEMP_ROOT/describe.json"
  "$CLI" describe vim --format json >"$output" || return 1
  json_assert "$output" 'value["capability"]["id"] == "editor.nvim"' || return 1
  json_assert "$output" '"python-provider" in value["capability"]["optionalFeatures"]' ||
    return 1
  json_assert "$output" 'value["capability"]["configPolicy"] == "replace"'
}

test_describes_tmux_alias_with_stable_canonical_id() {
  local output="$TEMP_ROOT/describe-tmux.json"
  "$CLI" describe tmux --format json >"$output" || return 1
  json_assert "$output" 'value["capability"]["id"] == "terminal.tmux"' || return 1
  json_assert "$output" 'value["capability"]["aliases"] == ["tmux"]' || return 1
  json_assert "$output" 'value["capability"]["configPolicy"] == "replace"'
}

test_unknown_capability_has_structured_error() {
  local output="$TEMP_ROOT/unknown.json"
  "$CLI" describe unknown --format json >"$output" 2>/dev/null
  local status=$?
  [[ $status -ne 0 ]] || return 1
  [[ $status -eq 2 ]] || return 1
  json_assert "$output" 'value["status"] == "FAILED"' || return 1
  json_assert "$output" 'value["error"]["code"] == "UNKNOWN_CAPABILITY"'
}

test_plan_is_read_only_and_declares_approvals() {
  local home="$TEMP_ROOT/plan-home"
  local state="$TEMP_ROOT/plan-state"
  local fake_bin="$TEMP_ROOT/plan-bin"
  local output="$TEMP_ROOT/plan.json"
  mkdir -p "$home/.config/nvim" "$fake_bin"
  printf '%s\n' existing >"$home/.config/nvim/local.lua"

  cli_env "$home" "$state" "$fake_bin" plan vim --format json >"$output" || return 1
  [[ ! -e "$state" ]] || return 1
  [[ -f "$home/.config/nvim/local.lua" ]] || return 1
  json_assert "$output" 'value["operation"] == "plan"' || return 1
  json_assert "$output" 'value["capability"] == "editor.nvim"' || return 1
  json_assert "$output" 'value["status"] == "CHANGES_REQUIRED"' || return 1
  json_assert "$output" \
    '"network" in set(item["type"] for item in value["requiredApprovals"])' || return 1
  json_assert "$output" \
    '"replace-config" in set(item["type"] for item in value["requiredApprovals"])'
}

test_apply_refuses_missing_approval_without_mutation() {
  local home="$TEMP_ROOT/blocked-home"
  local state="$TEMP_ROOT/blocked-state"
  local fake_bin="$TEMP_ROOT/blocked-bin"
  local plan="$TEMP_ROOT/blocked-plan.json"
  local output="$TEMP_ROOT/blocked-apply.json"
  mkdir -p "$home/.config/nvim" "$fake_bin"
  printf '%s\n' existing >"$home/.config/nvim/local.lua"

  cli_env "$home" "$state" "$fake_bin" plan vim --format json >"$plan" || return 1
  local plan_id
  plan_id="$(json_value "$plan" planId)" || return 1
  cli_env "$home" "$state" "$fake_bin" apply vim \
    --plan-id "$plan_id" --non-interactive --format json >"$output" 2>/dev/null
  local status=$?
  [[ $status -ne 0 ]] || return 1
  [[ $status -eq 20 ]] || return 1
  [[ -f "$home/.config/nvim/local.lua" ]] || return 1
  json_assert "$output" 'value["status"] == "BLOCKED"' || return 1
  json_assert "$output" 'value["error"]["code"] == "APPROVAL_REQUIRED"'
}

test_vim_apply_and_verify_complete_agent_workflow() {
  local home="$TEMP_ROOT/vim-home"
  local state="$TEMP_ROOT/vim-state"
  local fake_bin="$TEMP_ROOT/vim-bin"
  local plan="$TEMP_ROOT/vim-plan.json"
  local apply="$TEMP_ROOT/vim-apply.json"
  local verify="$TEMP_ROOT/vim-verify.json"
  mkdir -p "$home/.config/nvim" "$fake_bin"
  printf '%s\n' existing >"$home/.config/nvim/local.lua"
  write_fake_command "$fake_bin/nvim"
  write_fake_command "$fake_bin/rg"
  write_fake_command "$fake_bin/fd"

  cli_env "$home" "$state" "$fake_bin" plan vim --format json >"$plan" || return 1
  local plan_id
  plan_id="$(json_value "$plan" planId)" || return 1
  cli_env "$home" "$state" "$fake_bin" apply vim \
    --plan-id "$plan_id" --allow replace-config --non-interactive --format json \
    >"$apply" || return 1

  [[ -L "$home/.config/nvim" ]] || return 1
  [[ "$(readlink "$home/.config/nvim")" == "$ROOT_DIR/config/nvim" ]] || return 1
  json_assert "$apply" 'value["status"] == "SUCCESS"' || return 1
  [[ -f "$state/mac-setup/latest-run.json" ]] || return 1

  cli_env "$home" "$state" "$fake_bin" verify vim --format json >"$verify" || return 1
  json_assert "$verify" 'value["status"] == "COMPLIANT"' || return 1
  json_assert "$verify" 'all(item["status"] == "PASS" for item in value["checks"])'
}

test_zsh_apply_and_verify_complete_agent_workflow() {
  local home="$TEMP_ROOT/zsh-home"
  local state="$TEMP_ROOT/zsh-state"
  local fake_bin="$TEMP_ROOT/zsh-bin"
  local plan="$TEMP_ROOT/zsh-plan.json"
  local apply="$TEMP_ROOT/zsh-apply.json"
  local verify="$TEMP_ROOT/zsh-verify.json"
  mkdir -p "$home/.local/share/zinit/.git" "$fake_bin"
  write_fake_command "$fake_bin/zsh"

  cli_env "$home" "$state" "$fake_bin" plan zsh --format json >"$plan" || return 1
  local plan_id
  plan_id="$(json_value "$plan" planId)" || return 1
  cli_env "$home" "$state" "$fake_bin" apply zsh \
    --plan-id "$plan_id" --non-interactive --format json >"$apply" || return 1

  [[ -L "$home/.zshrc" ]] || return 1
  [[ -L "$home/.p10k.zsh" ]] || return 1
  [[ -L "$home/.config/.zsh-utils" ]] || return 1
  json_assert "$apply" 'value["status"] == "SUCCESS"' || return 1

  cli_env "$home" "$state" "$fake_bin" verify zsh --format json >"$verify" || return 1
  json_assert "$verify" 'value["status"] == "COMPLIANT"'
}

test_tmux_plan_is_read_only_and_declares_approvals() {
  local home="$TEMP_ROOT/tmux-plan-home"
  local state="$TEMP_ROOT/tmux-plan-state"
  local fake_bin="$TEMP_ROOT/tmux-plan-bin"
  local output="$TEMP_ROOT/tmux-plan.json"
  mkdir -p "$home" "$fake_bin"
  printf '%s\n' existing >"$home/.tmux.conf"

  cli_env "$home" "$state" "$fake_bin" plan tmux --format json >"$output" || return 1
  [[ ! -e "$state" ]] || return 1
  [[ "$(cat "$home/.tmux.conf")" == existing ]] || return 1
  json_assert "$output" 'value["capability"] == "terminal.tmux"' || return 1
  json_assert "$output" \
    'len([item for item in value["changes"] if item["resource"].endswith("/.tmux.conf")]) == 1' ||
    return 1
  json_assert "$output" \
    '"network" in set(item["type"] for item in value["requiredApprovals"])' || return 1
  json_assert "$output" \
    '"replace-config" in set(item["type"] for item in value["requiredApprovals"])'
}

test_tmux_apply_and_verify_complete_agent_workflow() {
  local home="$TEMP_ROOT/tmux-home"
  local state="$TEMP_ROOT/tmux-state"
  local fake_bin="$TEMP_ROOT/tmux-bin"
  local plan="$TEMP_ROOT/tmux-plan-apply.json"
  local apply="$TEMP_ROOT/tmux-apply.json"
  local verify="$TEMP_ROOT/tmux-verify.json"
  mkdir -p "$home/.tmux/plugins/tpm/.git" "$fake_bin"
  write_fake_command "$fake_bin/tmux"
  write_fake_command "$fake_bin/git"
  write_fake_command "$fake_bin/bc"

  cli_env "$home" "$state" "$fake_bin" plan tmux --format json >"$plan" || return 1
  local plan_id
  plan_id="$(json_value "$plan" planId)" || return 1
  cli_env "$home" "$state" "$fake_bin" apply tmux \
    --plan-id "$plan_id" --non-interactive --format json >"$apply" || return 1

  [[ -L "$home/.tmux.conf" ]] || return 1
  [[ "$(readlink "$home/.tmux.conf")" == "$ROOT_DIR/config/.tmux.conf" ]] || return 1
  json_assert "$apply" 'value["status"] == "SUCCESS"' || return 1
  cli_env "$home" "$state" "$fake_bin" verify tmux --format json >"$verify" || return 1
  json_assert "$verify" 'value["status"] == "COMPLIANT"' || return 1
  json_assert "$verify" \
    'set(item["member"] for item in value["checks"]) == {"terminal.tmux"}'
}

test_tmux_verify_rejects_loader_diagnostics() {
  local home="$TEMP_ROOT/tmux-diagnostic-home"
  local state="$TEMP_ROOT/tmux-diagnostic-state"
  local fake_bin="$TEMP_ROOT/tmux-diagnostic-bin"
  local output="$TEMP_ROOT/tmux-diagnostic-verify.json"
  mkdir -p "$home/.tmux/plugins/tpm/.git" "$fake_bin"
  ln -s "$ROOT_DIR/config/.tmux.conf" "$home/.tmux.conf"
  write_fake_command "$fake_bin/git"
  write_fake_command "$fake_bin/bc"
  printf '%s\n' '#!/usr/bin/env bash' \
    'case " $* " in' \
    '  *" source-file "*) printf "%s\n" "bad tmux config" >&2 ;;' \
    'esac' \
    'exit 0' >"$fake_bin/tmux"
  chmod +x "$fake_bin/tmux"

  cli_env "$home" "$state" "$fake_bin" verify tmux --format json >"$output" 2>/dev/null
  local status=$?
  [[ $status -eq 10 ]] || return 1
  json_assert "$output" 'value["status"] == "DRIFT"' || return 1
  json_assert "$output" \
    'len([item for item in value["checks"] if item["id"] == "tmux-config-load" and item["status"] == "FAIL"]) == 1'
}

test_tmux_module_installs_declared_runtime_dependencies() {
  local home="$TEMP_ROOT/tmux-module-home"
  local fake_bin="$TEMP_ROOT/tmux-module-bin"
  local output="$TEMP_ROOT/tmux-module-packages.txt"
  mkdir -p "$home/.tmux/plugins/tpm/.git" "$fake_bin"

  env HOME="$home" PATH="$fake_bin" /bin/bash -c '
    log() { :; }
    pkg_install() { printf "%s\n" "$1"; }
    is_macos() { return 1; }
    source "$1/modules/tmux.sh"
  ' _ "$ROOT_DIR" >"$output" || return 1

  grep -qx tmux "$output" || return 1
  grep -qx git "$output" || return 1
  grep -qx bc "$output"
}

test_tmux_config_guards_macos_clipboard_helpers() {
  local config="$ROOT_DIR/config/.tmux.conf"
  grep -q "if-shell 'command -v reattach-to-user-namespace" "$config" || return 1
  grep -q "if-shell 'command -v pbcopy" "$config" || return 1
  ! grep -q '^set -g default-command "reattach-to-user-namespace' "$config"
}

test_terminal_profile_plan_aggregates_changes_and_approvals() {
  local home="$TEMP_ROOT/profile-plan-home"
  local state="$TEMP_ROOT/profile-plan-state"
  local fake_bin="$TEMP_ROOT/profile-plan-bin"
  local output="$TEMP_ROOT/profile-plan.json"
  mkdir -p "$home/.config/nvim" "$fake_bin"
  printf '%s\n' existing >"$home/.config/nvim/local.lua"

  cli_env "$home" "$state" "$fake_bin" plan terminal --format json >"$output" || return 1
  [[ ! -e "$state" ]] || return 1
  json_assert "$output" 'value["capability"] == "profile.terminal"' || return 1
  json_assert "$output" \
    'value["members"] == ["shell.zsh", "editor.nvim"]' || return 1
  json_assert "$output" \
    'set(item["resource"] for item in value["changes"]) >= {"zinit", "nvim"}' || return 1
  json_assert "$output" \
    'len([item for item in value["changes"] if item["resource"].endswith("/.zshrc")]) == 1' ||
    return 1
  json_assert "$output" \
    'len([item for item in value["changes"] if item["resource"].endswith("/.config/nvim")]) == 1' ||
    return 1
  json_assert "$output" \
    'sum(item["type"] == "network" for item in value["requiredApprovals"]) == 1' ||
    return 1
  json_assert "$output" \
    'sum(item["type"] == "replace-config" for item in value["requiredApprovals"]) == 1'
}

test_terminal_profile_apply_and_verify_complete_agent_workflow() {
  local home="$TEMP_ROOT/profile-home"
  local state="$TEMP_ROOT/profile-state"
  local fake_bin="$TEMP_ROOT/profile-bin"
  local plan="$TEMP_ROOT/profile-plan-apply.json"
  local apply="$TEMP_ROOT/profile-apply.json"
  local verify="$TEMP_ROOT/profile-verify.json"
  mkdir -p "$home/.local/share/zinit/.git" "$fake_bin"
  write_fake_command "$fake_bin/zsh"
  write_fake_command "$fake_bin/nvim"
  write_fake_command "$fake_bin/rg"
  write_fake_command "$fake_bin/fd"

  cli_env "$home" "$state" "$fake_bin" plan terminal --format json >"$plan" || return 1
  local plan_id
  plan_id="$(json_value "$plan" planId)" || return 1
  cli_env "$home" "$state" "$fake_bin" apply terminal \
    --plan-id "$plan_id" --non-interactive --format json >"$apply" || return 1

  [[ -L "$home/.zshrc" ]] || return 1
  [[ -L "$home/.config/nvim" ]] || return 1
  json_assert "$apply" 'value["capability"] == "profile.terminal"' || return 1
  json_assert "$apply" 'value["members"] == ["shell.zsh", "editor.nvim"]' || return 1
  json_assert "$apply" 'value["status"] == "SUCCESS"' || return 1

  cli_env "$home" "$state" "$fake_bin" verify terminal --format json >"$verify" || return 1
  json_assert "$verify" 'value["status"] == "COMPLIANT"' || return 1
  json_assert "$verify" \
    'set(item["member"] for item in value["checks"]) == {"shell.zsh", "editor.nvim"}'
}

test_apply_uses_an_exclusive_lock() {
  local home="$TEMP_ROOT/lock-home"
  local state="$TEMP_ROOT/lock-state"
  local fake_bin="$TEMP_ROOT/lock-bin"
  local plan="$TEMP_ROOT/lock-plan.json"
  local output="$TEMP_ROOT/lock-apply.json"
  mkdir -p "$home/.local/share/zinit/.git" "$fake_bin" "$state/mac-setup/apply.lock"
  write_fake_command "$fake_bin/zsh"

  cli_env "$home" "$state" "$fake_bin" plan zsh --format json >"$plan" || return 1
  local plan_id
  plan_id="$(json_value "$plan" planId)" || return 1
  cli_env "$home" "$state" "$fake_bin" apply zsh \
    --plan-id "$plan_id" --non-interactive --format json >"$output" 2>/dev/null
  local status=$?
  [[ $status -ne 0 ]] || return 1
  [[ $status -eq 75 ]] || return 1
  json_assert "$output" 'value["error"]["code"] == "CONCURRENT_RUN"'
}

test_non_interactive_apply_never_prompts_for_sudo() {
  local home="$TEMP_ROOT/sudo-home"
  local state="$TEMP_ROOT/sudo-state"
  local fake_bin="$TEMP_ROOT/sudo-bin"
  local plan="$TEMP_ROOT/sudo-plan.json"
  local output="$TEMP_ROOT/sudo-apply.json"
  mkdir -p "$home" "$fake_bin"
  write_fake_linux_uname "$fake_bin/uname"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$fake_bin/sudo"
  chmod +x "$fake_bin/sudo"

  MAC_SETUP_TEST_OSTYPE=linux-gnu \
    cli_env "$home" "$state" "$fake_bin" plan vim --format json >"$plan" || return 1
  json_assert "$plan" \
    '"sudo" in set(item["type"] for item in value["requiredApprovals"])' || return 1
  local plan_id
  plan_id="$(json_value "$plan" planId)" || return 1
  MAC_SETUP_TEST_OSTYPE=linux-gnu \
    cli_env "$home" "$state" "$fake_bin" apply vim --plan-id "$plan_id" \
    --allow network --allow sudo --non-interactive --format json >"$output" 2>/dev/null
  local status=$?
  [[ $status -eq 20 ]] || return 1
  [[ ! -e "$home/.config/nvim" ]] || return 1
  json_assert "$output" 'value["error"]["code"] == "SUDO_AUTH_REQUIRED"'
}

test_shared_agent_skill_documents_safe_operator_flow() {
  local skill="$ROOT_DIR/config/agents/skills/mac-setup/SKILL.md"
  [[ -f "$skill" ]] || return 1
  grep -q 'mac-setup plan' "$skill" || return 1
  grep -q 'mac-setup apply' "$skill" || return 1
  grep -q 'mac-setup verify' "$skill" || return 1
  grep -q 'profile.terminal' "$skill" || return 1
  grep -q 'terminal.tmux' "$skill" || return 1
  grep -q 'Operator mode' "$skill"
}

run_test lists-agent-discoverable-capabilities test_lists_agent_discoverable_capabilities
run_test describes-terminal-profile-with-ordered-members \
  test_describes_terminal_profile_with_ordered_members
run_test human-list-includes-terminal-profile test_human_list_includes_terminal_profile
run_test describes-alias-with-stable-canonical-id \
  test_describes_alias_with_stable_canonical_id
run_test describes-tmux-alias-with-stable-canonical-id \
  test_describes_tmux_alias_with_stable_canonical_id
run_test unknown-capability-has-structured-error \
  test_unknown_capability_has_structured_error
run_test plan-is-read-only-and-declares-approvals \
  test_plan_is_read_only_and_declares_approvals
run_test apply-refuses-missing-approval-without-mutation \
  test_apply_refuses_missing_approval_without_mutation
run_test vim-apply-and-verify-complete-agent-workflow \
  test_vim_apply_and_verify_complete_agent_workflow
run_test zsh-apply-and-verify-complete-agent-workflow \
  test_zsh_apply_and_verify_complete_agent_workflow
run_test tmux-plan-is-read-only-and-declares-approvals \
  test_tmux_plan_is_read_only_and_declares_approvals
run_test tmux-apply-and-verify-complete-agent-workflow \
  test_tmux_apply_and_verify_complete_agent_workflow
run_test tmux-verify-rejects-loader-diagnostics \
  test_tmux_verify_rejects_loader_diagnostics
run_test tmux-module-installs-declared-runtime-dependencies \
  test_tmux_module_installs_declared_runtime_dependencies
run_test tmux-config-guards-macos-clipboard-helpers \
  test_tmux_config_guards_macos_clipboard_helpers
run_test terminal-profile-plan-aggregates-changes-and-approvals \
  test_terminal_profile_plan_aggregates_changes_and_approvals
run_test terminal-profile-apply-and-verify-complete-agent-workflow \
  test_terminal_profile_apply_and_verify_complete_agent_workflow
run_test apply-uses-an-exclusive-lock test_apply_uses_an_exclusive_lock
run_test non-interactive-apply-never-prompts-for-sudo \
  test_non_interactive_apply_never_prompts_for_sudo
run_test shared-agent-skill-documents-safe-operator-flow \
  test_shared_agent_skill_documents_safe_operator_flow

if ((fail_count > 0)); then
  printf 'FAIL mac-setup CLI tests (%d passed, %d failed)\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS mac-setup CLI tests (%d cases)\n' "$pass_count"

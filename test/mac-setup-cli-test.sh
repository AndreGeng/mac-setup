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
if not eval(sys.argv[2], {"__builtins__": {}}, {"value": value}):
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

cli_env() {
  local home="$1"
  local state="$2"
  local fake_bin="$3"
  shift 3
  HOME="$home" XDG_STATE_HOME="$state" \
    PATH="$fake_bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$CLI" "$@"
}

test_lists_agent_discoverable_capabilities() {
  local output="$TEMP_ROOT/list.json"
  "$CLI" list --format json >"$output" || return 1
  json_assert "$output" 'value["schemaVersion"] == "1"' || return 1
  json_assert "$output" 'value["operation"] == "list"' || return 1
  json_assert "$output" \
    'set(item["id"] for item in value["capabilities"]) == {"editor.nvim", "shell.zsh"}'
}

test_describes_alias_with_stable_canonical_id() {
  local output="$TEMP_ROOT/describe.json"
  "$CLI" describe vim --format json >"$output" || return 1
  json_assert "$output" 'value["capability"]["id"] == "editor.nvim"' || return 1
  json_assert "$output" '"python-provider" in value["capability"]["optionalFeatures"]' ||
    return 1
  json_assert "$output" 'value["capability"]["configPolicy"] == "replace"'
}

test_unknown_capability_has_structured_error() {
  local output="$TEMP_ROOT/unknown.json"
  if "$CLI" describe unknown --format json >"$output" 2>/dev/null; then
    return 1
  fi
  local status=$?
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
  if cli_env "$home" "$state" "$fake_bin" apply vim \
    --plan-id "$plan_id" --non-interactive --format json >"$output" 2>/dev/null; then
    return 1
  fi
  local status=$?
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
  if cli_env "$home" "$state" "$fake_bin" apply zsh \
    --plan-id "$plan_id" --non-interactive --format json >"$output" 2>/dev/null; then
    return 1
  fi
  local status=$?
  [[ $status -eq 75 ]] || return 1
  json_assert "$output" 'value["error"]["code"] == "CONCURRENT_RUN"'
}

test_shared_agent_skill_documents_safe_operator_flow() {
  local skill="$ROOT_DIR/config/agents/skills/mac-setup/SKILL.md"
  [[ -f "$skill" ]] || return 1
  grep -q 'mac-setup plan' "$skill" || return 1
  grep -q 'mac-setup apply' "$skill" || return 1
  grep -q 'mac-setup verify' "$skill" || return 1
  grep -q 'Operator mode' "$skill"
}

run_test lists-agent-discoverable-capabilities test_lists_agent_discoverable_capabilities
run_test describes-alias-with-stable-canonical-id \
  test_describes_alias_with_stable_canonical_id
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
run_test apply-uses-an-exclusive-lock test_apply_uses_an_exclusive_lock
run_test shared-agent-skill-documents-safe-operator-flow \
  test_shared_agent_skill_documents_safe_operator_flow

if ((fail_count > 0)); then
  printf 'FAIL mac-setup CLI tests (%d passed, %d failed)\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS mac-setup CLI tests (%d cases)\n' "$pass_count"

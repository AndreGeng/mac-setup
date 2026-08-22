#!/usr/bin/env bash

MAC_SETUP_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAC_SETUP_REPO_ROOT="$(cd "$MAC_SETUP_LIB_DIR/.." && pwd)"

source "$MAC_SETUP_LIB_DIR/platform.sh"
source "$MAC_SETUP_LIB_DIR/package.sh"
source "$MAC_SETUP_LIB_DIR/utils.sh"
source "$MAC_SETUP_LIB_DIR/mac-setup/json.sh"
source "$MAC_SETUP_LIB_DIR/mac-setup/capabilities.sh"

PLAN_CHANGE_TYPES=()
PLAN_CHANGE_RESOURCES=()
PLAN_CHANGE_DESCRIPTIONS=()
PLAN_APPROVAL_TYPES=()
PLAN_APPROVAL_REASONS=()
PLAN_APPROVAL_TARGETS=()
VERIFY_IDS=()
VERIFY_STATUSES=()
VERIFY_DETAILS=()
PLAN_ID=""
PLAN_STATUS="COMPLIANT"
PLAN_CAPABILITY=""
PLAN_FEATURE_PYTHON=false

reset_plan() {
  PLAN_CHANGE_TYPES=()
  PLAN_CHANGE_RESOURCES=()
  PLAN_CHANGE_DESCRIPTIONS=()
  PLAN_APPROVAL_TYPES=()
  PLAN_APPROVAL_REASONS=()
  PLAN_APPROVAL_TARGETS=()
  PLAN_ID=""
  PLAN_STATUS="COMPLIANT"
}

add_plan_change() {
  PLAN_CHANGE_TYPES+=("$1")
  PLAN_CHANGE_RESOURCES+=("$2")
  PLAN_CHANGE_DESCRIPTIONS+=("$3")
  PLAN_STATUS="CHANGES_REQUIRED"
}

add_plan_approval() {
  local type="$1"
  local reason="$2"
  local target="${3:-}"
  local existing

  for existing in "${PLAN_APPROVAL_TYPES[@]:-}"; do
    [[ "$existing" == "$type" ]] && return 0
  done
  PLAN_APPROVAL_TYPES+=("$type")
  PLAN_APPROVAL_REASONS+=("$reason")
  PLAN_APPROVAL_TARGETS+=("$target")
}

platform_needs_sudo_for_packages() {
  is_linux && [[ $EUID -ne 0 ]]
}

config_is_managed() {
  local source_path="$1"
  local target_path="$2"
  [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]
}

plan_configs() {
  local capability="$1"
  local record source_path target_path

  while IFS='|' read -r source_path target_path; do
    [[ -n "$source_path" && -n "$target_path" ]] || continue
    if config_is_managed "$source_path" "$target_path"; then
      continue
    fi
    if [[ -e "$target_path" || -L "$target_path" ]]; then
      add_plan_change REPLACE_CONFIG "$target_path" \
        "Replace the existing path with the repository-managed configuration."
      add_plan_approval replace-config \
        "An existing configuration path will be backed up and replaced." "$target_path"
    else
      add_plan_change CREATE_CONFIG "$target_path" \
        "Publish the repository-managed configuration."
    fi
  done < <(capability_config_records "$capability" "$MAC_SETUP_REPO_ROOT" "$HOME")
}

plan_tools() {
  local capability="$1"
  local record command_name package_name

  while IFS='|' read -r command_name package_name; do
    [[ -n "$command_name" ]] || continue
    if ! command -v "$command_name" >/dev/null 2>&1; then
      add_plan_change INSTALL_TOOL "$command_name" "Install package $package_name."
      add_plan_approval network "Missing tools must be downloaded from their package source."
      if platform_needs_sudo_for_packages; then
        add_plan_approval sudo "The platform package manager requires elevated privileges."
      fi
    fi
  done < <(capability_tools "$capability")
}

zsh_permissions_need_sudo() {
  local path
  for path in /usr/local/share/zsh /usr/local/share/zsh/site-functions; do
    [[ -d "$path" && ! -w "$path" ]] && return 0
  done
  return 1
}

plan_capability() {
  local capability="$1"
  local feature_python="${2:-false}"
  local platform repo_revision plan_material index

  reset_plan
  PLAN_CAPABILITY="$capability"
  PLAN_FEATURE_PYTHON="$feature_python"
  plan_tools "$capability"

  case "$capability" in
  editor.nvim)
    if [[ "$feature_python" == "true" &&
      ! -x "$HOME/.local/share/neovim/neovim3/bin/python" ]]; then
      add_plan_change CONFIGURE_FEATURE python-provider \
        'Install Python 3.11, pynvim, and neovim-remote.'
      add_plan_approval network 'The optional Neovim Python provider requires downloads.'
    fi
    ;;
  shell.zsh)
    if [[ ! -d "$HOME/.local/share/zinit/.git" ]]; then
      add_plan_change INSTALL_GIT_REPOSITORY zinit 'Install the Zsh plugin manager.'
      add_plan_approval network 'Zinit must be downloaded from its upstream repository.'
    fi
    if plan_needs_install_module && zsh_permissions_need_sudo; then
      add_plan_approval sudo 'Unwritable Zsh completion directories require permission repair.'
    fi
    ;;
  esac

  plan_configs "$capability"
  platform="$(detect_platform)"
  repo_revision="$(git -C "$MAC_SETUP_REPO_ROOT" rev-parse HEAD 2>/dev/null || printf unknown)"
  plan_material="$capability|$feature_python|$platform|$repo_revision|$PLAN_STATUS"
  for ((index = 0; index < ${#PLAN_CHANGE_TYPES[@]}; index++)); do
    plan_material="$plan_material|${PLAN_CHANGE_TYPES[$index]}|${PLAN_CHANGE_RESOURCES[$index]}"
  done
  for ((index = 0; index < ${#PLAN_APPROVAL_TYPES[@]}; index++)); do
    plan_material="$plan_material|approval:${PLAN_APPROVAL_TYPES[$index]}"
  done
  PLAN_ID="plan-$(printf '%s' "$plan_material" | cksum | awk '{print $1}')"
}

emit_capability_aliases_json() {
  local capability="$1"
  local alias first=true
  printf '['
  while IFS= read -r alias; do
    [[ -n "$alias" ]] || continue
    [[ "$first" == "true" ]] || printf ','
    json_string "$alias"
    first=false
  done < <(capability_aliases "$capability")
  printf ']'
}

emit_string_lines_json() {
  local first=true value
  printf '['
  while IFS= read -r value; do
    [[ -n "$value" ]] || continue
    [[ "$first" == "true" ]] || printf ','
    json_string "$value"
    first=false
  done
  printf ']'
}

emit_list_json() {
  local capability first=true
  printf '{"schemaVersion":"1","operation":"list","status":"SUCCESS","capabilities":['
  while IFS= read -r capability; do
    [[ "$first" == "true" ]] || printf ','
    printf '{"id":'
    json_string "$capability"
    printf ',"aliases":'
    emit_capability_aliases_json "$capability"
    printf ',"description":'
    json_string "$(capability_description "$capability")"
    printf '}'
    first=false
  done < <(capability_ids)
  printf ']}\n'
}

emit_describe_json() {
  local capability="$1"
  printf '{"schemaVersion":"1","operation":"describe","status":"SUCCESS","capability":{"id":'
  json_string "$capability"
  printf ',"aliases":'
  emit_capability_aliases_json "$capability"
  printf ',"description":'
  json_string "$(capability_description "$capability")"
  printf ',"optionalFeatures":'
  capability_optional_features "$capability" | emit_string_lines_json
  printf ',"configPolicy":"replace"}}\n'
}

emit_plan_changes_json() {
  local index
  printf '['
  for ((index = 0; index < ${#PLAN_CHANGE_TYPES[@]}; index++)); do
    ((index == 0)) || printf ','
    printf '{"type":'
    json_string "${PLAN_CHANGE_TYPES[$index]}"
    printf ',"resource":'
    json_string "${PLAN_CHANGE_RESOURCES[$index]}"
    printf ',"description":'
    json_string "${PLAN_CHANGE_DESCRIPTIONS[$index]}"
    printf '}'
  done
  printf ']'
}

emit_plan_approvals_json() {
  local index
  printf '['
  for ((index = 0; index < ${#PLAN_APPROVAL_TYPES[@]}; index++)); do
    ((index == 0)) || printf ','
    printf '{"type":'
    json_string "${PLAN_APPROVAL_TYPES[$index]}"
    printf ',"reason":'
    json_string "${PLAN_APPROVAL_REASONS[$index]}"
    if [[ -n "${PLAN_APPROVAL_TARGETS[$index]}" ]]; then
      printf ',"target":'
      json_string "${PLAN_APPROVAL_TARGETS[$index]}"
    fi
    printf '}'
  done
  printf ']'
}

emit_plan_json() {
  printf '{"schemaVersion":"1","operation":"plan","status":'
  json_string "$PLAN_STATUS"
  printf ',"capability":'
  json_string "$PLAN_CAPABILITY"
  printf ',"planId":'
  json_string "$PLAN_ID"
  printf ',"changes":'
  emit_plan_changes_json
  printf ',"requiredApprovals":'
  emit_plan_approvals_json
  printf '}\n'
}

emit_plan_human() {
  local index
  printf 'Capability: %s\nStatus: %s\nPlan: %s\n' \
    "$PLAN_CAPABILITY" "$PLAN_STATUS" "$PLAN_ID"
  for ((index = 0; index < ${#PLAN_CHANGE_TYPES[@]}; index++)); do
    printf '  - %s %s: %s\n' "${PLAN_CHANGE_TYPES[$index]}" \
      "${PLAN_CHANGE_RESOURCES[$index]}" "${PLAN_CHANGE_DESCRIPTIONS[$index]}"
  done
  for ((index = 0; index < ${#PLAN_APPROVAL_TYPES[@]}; index++)); do
    printf '  approval: %s — %s\n' "${PLAN_APPROVAL_TYPES[$index]}" \
      "${PLAN_APPROVAL_REASONS[$index]}"
  done
}

approval_is_allowed() {
  local requested="$1"
  shift
  local allowed
  for allowed in "$@"; do
    [[ "$allowed" == "$requested" ]] && return 0
  done
  return 1
}

plan_requires_approval() {
  local requested="$1"
  local approval
  for approval in "${PLAN_APPROVAL_TYPES[@]:-}"; do
    [[ "$approval" == "$requested" ]] && return 0
  done
  return 1
}

first_missing_approval() {
  local index
  shift 0
  for ((index = 0; index < ${#PLAN_APPROVAL_TYPES[@]}; index++)); do
    if ! approval_is_allowed "${PLAN_APPROVAL_TYPES[$index]}" "$@"; then
      printf '%s\n' "${PLAN_APPROVAL_TYPES[$index]}"
      return 0
    fi
  done
  return 1
}

plan_needs_install_module() {
  local type
  for type in "${PLAN_CHANGE_TYPES[@]:-}"; do
    case "$type" in
    INSTALL_TOOL | INSTALL_GIT_REPOSITORY | CONFIGURE_FEATURE) return 0 ;;
    esac
  done
  return 1
}

run_capability_module() {
  local capability="$1"
  local feature_python="$2"
  local module
  module="$(capability_module "$capability")"

  (
    export MAC_SETUP_SKIP_NVIM_CONFIG=1
    if [[ "$capability" == "editor.nvim" && "$feature_python" != "true" ]]; then
      export MAC_SETUP_SKIP_NVIM_PYTHON=1
    else
      unset MAC_SETUP_SKIP_NVIM_PYTHON || true
    fi
    source "$MAC_SETUP_REPO_ROOT/modules/$module.sh"
  )
}

publish_capability_configs() {
  local capability="$1"
  local source_path target_path
  while IFS='|' read -r source_path target_path; do
    [[ -n "$source_path" && -n "$target_path" ]] || continue
    config_is_managed "$source_path" "$target_path" && continue
    symlink_config "$source_path" "$target_path" || return 1
  done < <(capability_config_records "$capability" "$MAC_SETUP_REPO_ROOT" "$HOME")
}

reset_verify() {
  VERIFY_IDS=()
  VERIFY_STATUSES=()
  VERIFY_DETAILS=()
}

add_verify_check() {
  VERIFY_IDS+=("$1")
  VERIFY_STATUSES+=("$2")
  VERIFY_DETAILS+=("$3")
}

verify_command() {
  local id="$1"
  local command_name="$2"
  local path
  path="$(command -v "$command_name" 2>/dev/null || true)"
  if [[ -n "$path" ]]; then
    add_verify_check "$id" PASS "$path"
  else
    add_verify_check "$id" FAIL "$command_name is unavailable"
  fi
}

verify_configs() {
  local capability="$1"
  local source_path target_path id
  while IFS='|' read -r source_path target_path; do
    [[ -n "$source_path" && -n "$target_path" ]] || continue
    id="config-$(basename "$target_path")"
    if config_is_managed "$source_path" "$target_path"; then
      add_verify_check "$id" PASS "$target_path -> $source_path"
    else
      add_verify_check "$id" FAIL "$target_path is not managed by mac-setup"
    fi
  done < <(capability_config_records "$capability" "$MAC_SETUP_REPO_ROOT" "$HOME")
}

build_verify() {
  local capability="$1"
  local feature_python="${2:-false}"
  reset_verify

  case "$capability" in
  editor.nvim)
    verify_command nvim-executable nvim
    verify_command ripgrep-executable rg
    verify_command fd-executable fd
    verify_configs "$capability"
    if command -v nvim >/dev/null 2>&1 && nvim --headless --clean +qa >/dev/null 2>&1; then
      add_verify_check nvim-headless-start PASS 'Neovim starts in clean headless mode.'
    else
      add_verify_check nvim-headless-start FAIL 'Neovim failed to start in clean headless mode.'
    fi
    if [[ "$feature_python" == "true" ]]; then
      if [[ -x "$HOME/.local/share/neovim/neovim3/bin/python" ]]; then
        add_verify_check python-provider PASS 'Neovim Python provider environment exists.'
      else
        add_verify_check python-provider FAIL 'Neovim Python provider environment is missing.'
      fi
    fi
    ;;
  shell.zsh)
    verify_command zsh-executable zsh
    if [[ -d "$HOME/.local/share/zinit/.git" ]]; then
      add_verify_check zinit-repository PASS "$HOME/.local/share/zinit"
    else
      add_verify_check zinit-repository FAIL 'Zinit repository is missing.'
    fi
    verify_configs "$capability"
    if command -v zsh >/dev/null 2>&1 && zsh -n "$HOME/.zshrc" >/dev/null 2>&1; then
      add_verify_check zsh-config-syntax PASS 'The managed .zshrc parses successfully.'
    else
      add_verify_check zsh-config-syntax FAIL 'The managed .zshrc failed syntax validation.'
    fi
    ;;
  esac
}

verify_status() {
  local status
  for status in "${VERIFY_STATUSES[@]:-}"; do
    [[ "$status" == "FAIL" ]] && {
      printf '%s\n' DRIFT
      return 0
    }
  done
  printf '%s\n' COMPLIANT
}

emit_verify_checks_json() {
  local index
  printf '['
  for ((index = 0; index < ${#VERIFY_IDS[@]}; index++)); do
    ((index == 0)) || printf ','
    printf '{"id":'
    json_string "${VERIFY_IDS[$index]}"
    printf ',"status":'
    json_string "${VERIFY_STATUSES[$index]}"
    printf ',"details":'
    json_string "${VERIFY_DETAILS[$index]}"
    printf '}'
  done
  printf ']'
}

emit_verify_json() {
  local capability="$1"
  local status
  status="$(verify_status)"
  printf '{"schemaVersion":"1","operation":"verify","capability":'
  json_string "$capability"
  printf ',"status":'
  json_string "$status"
  printf ',"checks":'
  emit_verify_checks_json
  printf '}\n'
}

emit_apply_json() {
  local capability="$1"
  local plan_id="$2"
  local run_id="$3"
  local status="$4"
  printf '{"schemaVersion":"1","operation":"apply","capability":'
  json_string "$capability"
  printf ',"planId":'
  json_string "$plan_id"
  printf ',"runId":'
  json_string "$run_id"
  printf ',"status":'
  json_string "$status"
  printf ',"checks":'
  emit_verify_checks_json
  printf '}\n'
}

write_apply_report() {
  local capability="$1"
  local plan_id="$2"
  local run_id="$3"
  local status="$4"
  local state_root="$5"
  local report="$state_root/runs/$run_id.json"
  mkdir -p "$state_root/runs"
  emit_apply_json "$capability" "$plan_id" "$run_id" "$status" >"$report"
  cp "$report" "$state_root/latest-run.json"
  printf '%s\n' "$report"
}

emit_doctor_json() {
  local platform package_manager="none" git_status="MISSING" status="READY"
  platform="$(detect_platform)"
  command -v git >/dev/null 2>&1 && git_status="PASS"
  if command -v brew >/dev/null 2>&1; then
    package_manager=brew
  elif command -v apt >/dev/null 2>&1; then
    package_manager=apt
  elif command -v dnf >/dev/null 2>&1; then
    package_manager=dnf
  elif command -v pacman >/dev/null 2>&1; then
    package_manager=pacman
  fi
  [[ "$git_status" == PASS && "$package_manager" != none ]] || status="DEGRADED"

  printf '{"schemaVersion":"1","operation":"doctor","status":'
  json_string "$status"
  printf ',"platform":'
  json_string "$platform"
  printf ',"repoRoot":'
  json_string "$MAC_SETUP_REPO_ROOT"
  printf ',"checks":{"git":'
  json_string "$git_status"
  printf ',"packageManager":'
  json_string "$package_manager"
  printf '}}\n'
}

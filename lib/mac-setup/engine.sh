#!/usr/bin/env bash

MAC_SETUP_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAC_SETUP_REPO_ROOT="$(cd "$MAC_SETUP_LIB_DIR/.." && pwd)"

source "$MAC_SETUP_LIB_DIR/platform.sh"
source "$MAC_SETUP_LIB_DIR/package.sh"
source "$MAC_SETUP_LIB_DIR/utils.sh"
source "$MAC_SETUP_LIB_DIR/mac-setup/json.sh"
source "$MAC_SETUP_LIB_DIR/mac-setup/capabilities.sh"
source "$MAC_SETUP_LIB_DIR/runtime-manifest.sh"
source "$MAC_SETUP_LIB_DIR/bootstrap-manifest.sh"

PLAN_CHANGE_TYPES=()
PLAN_CHANGE_RESOURCES=()
PLAN_CHANGE_DESCRIPTIONS=()
PLAN_CHANGE_MEMBERS=()
PLAN_APPROVAL_TYPES=()
PLAN_APPROVAL_REASONS=()
PLAN_APPROVAL_TARGETS=()
VERIFY_IDS=()
VERIFY_STATUSES=()
VERIFY_DETAILS=()
VERIFY_MEMBERS=()
PLAN_ID=""
PLAN_STATUS="COMPLIANT"
PLAN_CAPABILITY=""
PLAN_FEATURE_PYTHON=false
PLAN_CURRENT_MEMBER=""
VERIFY_CURRENT_MEMBER=""
PLAN_MEMBERS=()

reset_plan() {
  PLAN_CHANGE_TYPES=()
  PLAN_CHANGE_RESOURCES=()
  PLAN_CHANGE_DESCRIPTIONS=()
  PLAN_CHANGE_MEMBERS=()
  PLAN_APPROVAL_TYPES=()
  PLAN_APPROVAL_REASONS=()
  PLAN_APPROVAL_TARGETS=()
  PLAN_ID=""
  PLAN_STATUS="COMPLIANT"
  PLAN_MEMBERS=()
}

add_plan_change() {
  PLAN_CHANGE_TYPES+=("$1")
  PLAN_CHANGE_RESOURCES+=("$2")
  PLAN_CHANGE_DESCRIPTIONS+=("$3")
  PLAN_CHANGE_MEMBERS+=("$PLAN_CURRENT_MEMBER")
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

node_mise_executable() {
  resolve_mise_executable 2>/dev/null
}

node_mise_matches_bootstrap() {
  local expected_version mise_bin
  expected_version="$(mise_bootstrap_version "$MAC_SETUP_REPO_ROOT")" || return 1
  mise_bin="$(node_mise_executable)" || return 1
  mise_executable_matches "$mise_bin" "$expected_version"
}

node_runtime_root() {
  local name="$1"
  local version="$2"
  local mise_bin
  mise_bin="$(node_mise_executable)" || return 1
  "$mise_bin" where "${name}@${version}" 2>/dev/null
}

node_runtime_matches() {
  local name="$1"
  local version="$2"
  local runtime_root output executable
  runtime_root="$(node_runtime_root "$name" "$version")" || return 1
  executable="$runtime_root/bin/$name"
  [[ -f "$executable" && -x "$executable" ]] || return 1
  output="$("$executable" --version 2>/dev/null)" || return 1
  [[ "${output#v}" == "$version" ]]
}

node_npm_package_matches() {
  local package_name="$1"
  local package_version="$2"
  local node_version node_root npm_bin
  node_version="$(node_manifest_version "$MAC_SETUP_REPO_ROOT" runtime node)" || return 1
  node_root="$(node_runtime_root node "$node_version")" || return 1
  npm_bin="$node_root/bin/npm"
  [[ -f "$npm_bin" && -x "$npm_bin" ]] || return 1
  PATH="$node_root/bin:$PATH" \
    "$npm_bin" list -g --depth=0 "${package_name}@${package_version}" >/dev/null 2>&1
}

plan_member_changes() {
  local capability="$1"
  local feature_python="${2:-false}"

  PLAN_CURRENT_MEMBER="$capability"
  plan_tools "$capability"

  case "$capability" in
  editor.nvim)
    local neovim_version tree_sitter_version go_version gopls_version
    neovim_version="$(neovim_bootstrap_version "$MAC_SETUP_REPO_ROOT")" || return 1
    tree_sitter_version="$(tree_sitter_bootstrap_version "$MAC_SETUP_REPO_ROOT")" || return 1
    go_version="$(editor_manifest_version "$MAC_SETUP_REPO_ROOT" runtime go)" || return 1
    gopls_version="$(editor_manifest_version "$MAC_SETUP_REPO_ROOT" go gopls)" || return 1
    if ! neovim_runtime_matches "$MAC_SETUP_REPO_ROOT"; then
      add_plan_change CONFIGURE_RUNTIME "neovim@${neovim_version}" \
        'Install the exact Neovim release declared by the repository.'
      add_plan_approval network 'Neovim must be downloaded from its official release.'
    fi
    if ! tree_sitter_runtime_matches "$MAC_SETUP_REPO_ROOT"; then
      add_plan_change CONFIGURE_RUNTIME "tree-sitter@${tree_sitter_version}" \
        'Install the exact tree-sitter CLI required by nvim-treesitter.'
      add_plan_approval network 'tree-sitter CLI must be downloaded from its official release.'
    fi
    if ! go_runtime_matches "$MAC_SETUP_REPO_ROOT"; then
      add_plan_change CONFIGURE_RUNTIME "go@${go_version}" \
        'Install the exact Go runtime required by the editor toolchain.'
      add_plan_approval network 'The declared Go runtime must be downloaded.'
    fi
    if ! gopls_runtime_matches "$MAC_SETUP_REPO_ROOT"; then
      add_plan_change CONFIGURE_RUNTIME "gopls@${gopls_version}" \
        'Install the exact gopls language server declared by the repository.'
      add_plan_approval network 'The declared gopls version must be downloaded.'
    fi
    if [[ "$feature_python" == "true" &&
      ! -x "$HOME/.local/share/neovim/neovim3/bin/python" ]]; then
      add_plan_change CONFIGURE_FEATURE python-provider \
        'Install Python 3.11, pynvim, and neovim-remote.'
      add_plan_approval network 'The optional Neovim Python provider requires downloads.'
    fi
    ;;
  shell.zsh)
    local zsh_path=""
    zsh_path="$(resolve_zsh_executable 2>/dev/null)" || true
    if ! zinit_install_is_valid; then
      add_plan_change INSTALL_GIT_REPOSITORY zinit 'Install the Zsh plugin manager.'
      add_plan_approval network 'Zinit must be downloaded from its upstream repository.'
    fi
    if plan_member_needs_install_module "$capability" && zsh_permissions_need_sudo; then
      add_plan_approval sudo 'Unwritable Zsh completion directories require permission repair.'
    fi
    if [[ -z "$zsh_path" ]] || ! zsh_is_default_shell "$zsh_path"; then
      add_plan_change SET_LOGIN_SHELL "${zsh_path:-zsh}" \
        'Set Zsh as the account login shell for new terminal sessions.'
      add_plan_approval sudo 'Changing the account login shell requires administrator approval.'
    fi
    ;;
  terminal.tmux)
    if [[ ! -d "$HOME/.tmux/plugins/tpm/.git" ]]; then
      add_plan_change INSTALL_GIT_REPOSITORY tpm 'Install the Tmux Plugin Manager.'
      add_plan_approval network 'TPM must be downloaded from its upstream repository.'
    fi
    ;;
  runtime.node)
    local mise_version
    mise_version="$(mise_bootstrap_version "$MAC_SETUP_REPO_ROOT")" || return 1
    if ! node_mise_matches_bootstrap; then
      add_plan_change CONFIGURE_BOOTSTRAP "mise@${mise_version}" \
        'Install the exact mise bootstrap version declared by the repository.'
      add_plan_approval network 'mise and the declared runtimes must be downloaded.'
    fi
    local runtime_name runtime_version
    while IFS='|' read -r runtime_name runtime_version; do
      if ! node_runtime_matches "$runtime_name" "$runtime_version"; then
        add_plan_change CONFIGURE_RUNTIME "${runtime_name}@${runtime_version}" \
          'Install the exact runtime version declared by the repository.'
        add_plan_approval network 'Declared runtime versions must be downloaded.'
      fi
    done < <(node_manifest_records "$MAC_SETUP_REPO_ROOT" runtime)
    local package_name package_version
    while IFS='|' read -r package_name package_version; do
      if ! node_npm_package_matches "$package_name" "$package_version"; then
        add_plan_change INSTALL_NPM_PACKAGE "${package_name}@${package_version}" \
          'Install the exact global npm package declared by the repository.'
        add_plan_approval network 'Declared npm packages must be downloaded.'
      fi
    done < <(node_manifest_records "$MAC_SETUP_REPO_ROOT" npm)
    if ! node_runtime_command_matches "$MAC_SETUP_REPO_ROOT" node; then
      add_plan_change PUBLISH_COMMAND "$HOME/.local/bin/node" \
        'Publish the pinned Node runtime for npm command shebangs and non-interactive agents.'
      [[ ! -e "$HOME/.local/bin/node" ]] ||
        add_plan_approval replace-config \
          'A conflicting user command must be backed up before publishing the managed command.' \
          "$HOME/.local/bin/node"
    fi
    if ! runtime_manifest_command_matches "$MAC_SETUP_REPO_ROOT" bun bun; then
      add_plan_change PUBLISH_COMMAND "$HOME/.local/bin/bun" \
        'Publish the pinned Bun runtime for ReMe hooks and non-interactive agents.'
      [[ ! -e "$HOME/.local/bin/bun" ]] ||
        add_plan_approval replace-config \
          'A conflicting user command must be backed up before publishing the managed command.' \
          "$HOME/.local/bin/bun"
    fi
    local command_name
    while IFS='|' read -r package_name package_version command_name; do
      if ! node_manifest_command_matches "$MAC_SETUP_REPO_ROOT" "$command_name"; then
        add_plan_change PUBLISH_COMMAND "$HOME/.local/bin/$command_name" \
          "Publish ${package_name}@${package_version} for shells that have not activated mise."
        [[ ! -e "$HOME/.local/bin/$command_name" ]] ||
          add_plan_approval replace-config \
            'A conflicting user command must be backed up before publishing the managed command.' \
            "$HOME/.local/bin/$command_name"
      fi
    done < <(node_manifest_command_records "$MAC_SETUP_REPO_ROOT")
    ;;
  esac

  plan_configs "$capability"
}

plan_target() {
  local target="$1"
  local feature_python="${2:-false}"
  local platform repo_revision plan_material index member

  reset_plan
  PLAN_CAPABILITY="$target"
  PLAN_FEATURE_PYTHON="$feature_python"
  while IFS= read -r member; do
    [[ -n "$member" ]] || continue
    PLAN_MEMBERS+=("$member")
    plan_member_changes "$member" "$feature_python"
  done < <(target_members "$target")

  platform="$(detect_platform)"
  repo_revision="$(git -C "$MAC_SETUP_REPO_ROOT" rev-parse HEAD 2>/dev/null || printf unknown)"
  plan_material="$target|$feature_python|$platform|$repo_revision|$PLAN_STATUS"
  for ((index = 0; index < ${#PLAN_CHANGE_TYPES[@]}; index++)); do
    plan_material="$plan_material|${PLAN_CHANGE_MEMBERS[$index]}|${PLAN_CHANGE_TYPES[$index]}"
    plan_material="$plan_material|${PLAN_CHANGE_RESOURCES[$index]}"
  done
  for ((index = 0; index < ${#PLAN_APPROVAL_TYPES[@]}; index++)); do
    plan_material="$plan_material|approval:${PLAN_APPROVAL_TYPES[$index]}"
  done
  PLAN_ID="plan-$(printf '%s' "$plan_material" | cksum | awk '{print $1}')"
}

plan_capability() {
  plan_target "$@"
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

emit_profile_aliases_json() {
  local profile="$1"
  profile_aliases "$profile" | emit_string_lines_json
}

emit_target_members_json() {
  local target="$1"
  target_members "$target" | emit_string_lines_json
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
  local capability profile first=true
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
  printf '],"profiles":['
  first=true
  while IFS= read -r profile; do
    [[ "$first" == "true" ]] || printf ','
    printf '{"id":'
    json_string "$profile"
    printf ',"aliases":'
    emit_profile_aliases_json "$profile"
    printf ',"description":'
    json_string "$(profile_description "$profile")"
    printf ',"members":'
    emit_target_members_json "$profile"
    printf '}'
    first=false
  done < <(profile_ids)
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
  printf ',"configPolicy":'
  json_string "$(capability_config_policy "$capability")"
  printf '}}\n'
}

emit_describe_profile_json() {
  local profile="$1"
  printf '{"schemaVersion":"1","operation":"describe","status":"SUCCESS","profile":{"id":'
  json_string "$profile"
  printf ',"aliases":'
  emit_profile_aliases_json "$profile"
  printf ',"description":'
  json_string "$(profile_description "$profile")"
  printf ',"members":'
  emit_target_members_json "$profile"
  printf ',"optionalFeatures":'
  target_members "$profile" | while IFS= read -r member; do
    capability_optional_features "$member"
  done | awk 'NF && !seen[$0]++' | emit_string_lines_json
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
    printf ',"member":'
    json_string "${PLAN_CHANGE_MEMBERS[$index]}"
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
  printf ',"members":'
  emit_target_members_json "$PLAN_CAPABILITY"
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

change_requires_module() {
  case "$1" in
  INSTALL_TOOL | INSTALL_GIT_REPOSITORY | CONFIGURE_BOOTSTRAP | CONFIGURE_FEATURE | \
    CONFIGURE_RUNTIME | INSTALL_NPM_PACKAGE | PUBLISH_COMMAND | SET_LOGIN_SHELL)
    return 0
    ;;
  *) return 1 ;;
  esac
}

plan_needs_install_module() {
  local type
  for type in "${PLAN_CHANGE_TYPES[@]:-}"; do
    change_requires_module "$type" && return 0
  done
  return 1
}

plan_member_needs_install_module() {
  local member="$1"
  local index
  for ((index = 0; index < ${#PLAN_CHANGE_TYPES[@]}; index++)); do
    [[ "${PLAN_CHANGE_MEMBERS[$index]}" == "$member" ]] || continue
    change_requires_module "${PLAN_CHANGE_TYPES[$index]}" && return 0
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

run_target_modules() {
  local target="$1"
  local feature_python="$2"
  local member
  while IFS= read -r member; do
    [[ -n "$member" ]] || continue
    plan_member_needs_install_module "$member" || continue
    run_capability_module "$member" "$feature_python" || return 1
  done < <(target_members "$target")
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

publish_target_configs() {
  local target="$1"
  local member
  while IFS= read -r member; do
    [[ -n "$member" ]] || continue
    publish_capability_configs "$member" || return 1
  done < <(target_members "$target")
}

reset_verify() {
  VERIFY_IDS=()
  VERIFY_STATUSES=()
  VERIFY_DETAILS=()
  VERIFY_MEMBERS=()
}

add_verify_check() {
  VERIFY_IDS+=("$1")
  VERIFY_STATUSES+=("$2")
  VERIFY_DETAILS+=("$3")
  VERIFY_MEMBERS+=("$VERIFY_CURRENT_MEMBER")
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

build_verify_member() {
  local capability="$1"
  local feature_python="${2:-false}"

  VERIFY_CURRENT_MEMBER="$capability"
  case "$capability" in
  editor.nvim)
    local neovim_version tree_sitter_version go_version gopls_version
    local nvim_path tree_sitter_path go_path gopls_path
    neovim_version="$(neovim_bootstrap_version "$MAC_SETUP_REPO_ROOT")" || true
    tree_sitter_version="$(tree_sitter_bootstrap_version "$MAC_SETUP_REPO_ROOT")" || true
    go_version="$(editor_manifest_version "$MAC_SETUP_REPO_ROOT" runtime go)" || true
    gopls_version="$(editor_manifest_version "$MAC_SETUP_REPO_ROOT" go gopls)" || true
    nvim_path="$(resolve_neovim_executable 2>/dev/null)" || true
    tree_sitter_path="$(resolve_tree_sitter_executable 2>/dev/null)" || true
    go_path="$(resolve_managed_go_executable 2>/dev/null)" || true
    gopls_path="$(resolve_managed_gopls_executable 2>/dev/null)" || true
    verify_command nvim-executable nvim
    verify_command tree-sitter-executable tree-sitter
    verify_command go-executable go
    verify_command gopls-executable gopls
    verify_command ripgrep-executable rg
    verify_command fd-executable fd
    verify_configs "$capability"
    if [[ -n "$nvim_path" && -n "$neovim_version" ]] &&
      neovim_executable_matches "$nvim_path" "$neovim_version"; then
      add_verify_check nvim-version PASS "neovim@${neovim_version} ($nvim_path)"
    else
      add_verify_check nvim-version FAIL "neovim@${neovim_version} is unavailable."
    fi
    if [[ -n "$tree_sitter_path" && -n "$tree_sitter_version" ]] &&
      tree_sitter_executable_matches "$tree_sitter_path" "$tree_sitter_version"; then
      add_verify_check tree-sitter-version PASS \
        "tree-sitter@${tree_sitter_version} ($tree_sitter_path)"
    else
      add_verify_check tree-sitter-version FAIL \
        "tree-sitter@${tree_sitter_version} is unavailable."
    fi
    if [[ -n "$go_path" && -n "$go_version" ]] &&
      go_executable_matches "$go_path" "$go_version"; then
      add_verify_check go-version PASS "go@${go_version} ($go_path)"
    else
      add_verify_check go-version FAIL "go@${go_version} is unavailable."
    fi
    if [[ -n "$gopls_path" && -n "$gopls_version" ]] &&
      gopls_executable_matches "$gopls_path" "$gopls_version"; then
      add_verify_check gopls-version PASS "gopls@${gopls_version} ($gopls_path)"
    else
      add_verify_check gopls-version FAIL "gopls@${gopls_version} is unavailable."
    fi
    if [[ -n "$nvim_path" ]] &&
      MAC_SETUP_NVIM_VERIFY=1 "$nvim_path" --headless +qa >/dev/null 2>&1; then
      add_verify_check nvim-config-load PASS 'Neovim loads the managed core configuration.'
    else
      add_verify_check nvim-config-load FAIL 'Neovim failed to load the managed core configuration.'
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
    local zinit_dir zsh_path=""
    zinit_dir="$(zinit_install_dir)"
    zsh_path="$(resolve_zsh_executable 2>/dev/null)" || true
    verify_command zsh-executable zsh
    if [[ -n "$zsh_path" ]] && zsh_is_default_shell "$zsh_path"; then
      add_verify_check default-shell PASS "$zsh_path"
    else
      add_verify_check default-shell FAIL 'Zsh is not the account login shell.'
    fi
    if zinit_install_is_valid; then
      add_verify_check zinit-repository PASS "$zinit_dir"
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
  terminal.tmux)
    verify_command tmux-executable tmux
    verify_command git-executable git
    verify_command bc-executable bc
    if [[ -d "$HOME/.tmux/plugins/tpm/.git" ]]; then
      add_verify_check tpm-repository PASS "$HOME/.tmux/plugins/tpm"
    else
      add_verify_check tpm-repository FAIL 'The TPM repository is missing.'
    fi
    verify_configs "$capability"
    local socket_name="mac-setup-verify-$$"
    local tmux_log=""
    local tmux_status=1
    tmux_log="$(mktemp "${TMPDIR:-/tmp}/mac-setup-tmux-verify.XXXXXX")" || true
    if [[ -n "$tmux_log" ]] && command -v tmux >/dev/null 2>&1; then
      tmux_status=0
      tmux -f /dev/null -L "$socket_name" start-server \; \
        source-file "$HOME/.tmux.conf" >/dev/null 2>"$tmux_log" || tmux_status=$?
    fi
    if [[ $tmux_status -eq 0 && -n "$tmux_log" && ! -s "$tmux_log" ]]; then
      add_verify_check tmux-config-load PASS 'Tmux loads the managed configuration.'
    else
      add_verify_check tmux-config-load FAIL 'Tmux failed to load the managed configuration.'
    fi
    tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true
    [[ -z "$tmux_log" ]] || rm -f "$tmux_log"
    ;;
  runtime.node)
    local mise_path="" mise_version=""
    mise_version="$(mise_bootstrap_version "$MAC_SETUP_REPO_ROOT")" || true
    mise_path="$(node_mise_executable)" || true
    if [[ -n "$mise_path" && -n "$mise_version" ]] &&
      mise_executable_matches "$mise_path" "$mise_version"; then
      add_verify_check mise-version PASS "mise@${mise_version} ($mise_path)"
    else
      add_verify_check mise-version FAIL "mise@${mise_version} is unavailable."
    fi
    local runtime_name runtime_version
    while IFS='|' read -r runtime_name runtime_version; do
      if node_runtime_matches "$runtime_name" "$runtime_version"; then
        add_verify_check "runtime-$runtime_name" PASS "${runtime_name}@${runtime_version}"
      else
        add_verify_check "runtime-$runtime_name" FAIL \
          "${runtime_name}@${runtime_version} is unavailable."
      fi
    done < <(node_manifest_records "$MAC_SETUP_REPO_ROOT" runtime)
    local package_name package_version check_id
    while IFS='|' read -r package_name package_version; do
      check_id="npm-$(printf '%s' "$package_name" | tr '@/.' '----')"
      if node_npm_package_matches "$package_name" "$package_version"; then
        add_verify_check "$check_id" PASS "${package_name}@${package_version}"
      else
        add_verify_check "$check_id" FAIL "${package_name}@${package_version} is unavailable."
      fi
    done < <(node_manifest_records "$MAC_SETUP_REPO_ROOT" npm)
    if node_runtime_command_matches "$MAC_SETUP_REPO_ROOT" node; then
      add_verify_check runtime-command-node PASS "$HOME/.local/bin/node"
    else
      add_verify_check runtime-command-node FAIL \
        "$HOME/.local/bin/node is not the managed pinned Node runtime."
    fi
    if runtime_manifest_command_matches "$MAC_SETUP_REPO_ROOT" bun bun; then
      add_verify_check runtime-command-bun PASS "$HOME/.local/bin/bun"
    else
      add_verify_check runtime-command-bun FAIL \
        "$HOME/.local/bin/bun is not the managed pinned Bun runtime."
    fi
    local command_name
    while IFS='|' read -r package_name package_version command_name; do
      check_id="agent-command-$command_name"
      if node_manifest_command_matches "$MAC_SETUP_REPO_ROOT" "$command_name"; then
        add_verify_check "$check_id" PASS "$HOME/.local/bin/$command_name"
      else
        add_verify_check "$check_id" FAIL \
          "$HOME/.local/bin/$command_name is not the managed ${package_name} command."
      fi
    done < <(node_manifest_command_records "$MAC_SETUP_REPO_ROOT")
    ;;
  esac
}

build_verify() {
  local target="$1"
  local feature_python="${2:-false}"
  local member
  reset_verify
  while IFS= read -r member; do
    [[ -n "$member" ]] || continue
    build_verify_member "$member" "$feature_python"
  done < <(target_members "$target")
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
    printf ',"member":'
    json_string "${VERIFY_MEMBERS[$index]}"
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
  printf ',"members":'
  emit_target_members_json "$capability"
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
  printf ',"members":'
  emit_target_members_json "$capability"
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

#!/usr/bin/env bash

capability_ids() {
  printf '%s\n' editor.nvim shell.zsh terminal.tmux runtime.node
}

profile_ids() {
  printf '%s\n' profile.terminal
}

target_ids() {
  capability_ids
  profile_ids
}

canonical_capability() {
  case "$1" in
  vim | nvim | neovim | editor.nvim)
    printf '%s\n' editor.nvim
    ;;
  zsh | shell | shell.zsh)
    printf '%s\n' shell.zsh
    ;;
  tmux | terminal.tmux)
    printf '%s\n' terminal.tmux
    ;;
  node | nodejs | runtime.node)
    printf '%s\n' runtime.node
    ;;
  *)
    return 1
    ;;
  esac
}

canonical_profile() {
  case "$1" in
  terminal | profile.terminal)
    printf '%s\n' profile.terminal
    ;;
  *)
    return 1
    ;;
  esac
}

canonical_target() {
  canonical_capability "$1" 2>/dev/null || canonical_profile "$1"
}

target_kind() {
  case "$1" in
  profile.*) printf '%s\n' profile ;;
  *) printf '%s\n' capability ;;
  esac
}

target_members() {
  case "$1" in
  profile.terminal) printf '%s\n' shell.zsh editor.nvim ;;
  *) printf '%s\n' "$1" ;;
  esac
}

target_has_member() {
  local target="$1"
  local requested="$2"
  local member
  while IFS= read -r member; do
    [[ "$member" == "$requested" ]] && return 0
  done < <(target_members "$target")
  return 1
}

capability_aliases() {
  case "$1" in
  editor.nvim) printf '%s\n' vim nvim neovim ;;
  shell.zsh) printf '%s\n' zsh shell ;;
  terminal.tmux) printf '%s\n' tmux ;;
  runtime.node) printf '%s\n' node nodejs ;;
  esac
}

profile_aliases() {
  case "$1" in
  profile.terminal) printf '%s\n' terminal ;;
  esac
}

capability_description() {
  case "$1" in
  editor.nvim) printf '%s\n' 'Install and configure the Neovim development environment.' ;;
  shell.zsh) printf '%s\n' 'Install Zsh, Zinit, and the repository-owned shell configuration.' ;;
  terminal.tmux) printf '%s\n' 'Install Tmux, TPM, and the repository-owned Tmux configuration.' ;;
  runtime.node) printf '%s\n' 'Install pinned Node.js, Bun, and global npm development tools.' ;;
  esac
}

profile_description() {
  case "$1" in
  profile.terminal)
    printf '%s\n' 'Configure the complete Zsh and Neovim terminal development environment.'
    ;;
  esac
}

capability_module() {
  case "$1" in
  editor.nvim) printf '%s\n' vim ;;
  shell.zsh) printf '%s\n' zsh ;;
  terminal.tmux) printf '%s\n' tmux ;;
  runtime.node) printf '%s\n' nodejs ;;
  esac
}

capability_tools() {
  case "$1" in
  editor.nvim)
    printf '%s\n' 'rg|ripgrep' 'fd|fd' 'curl|curl' 'tar|tar' 'unzip|unzip'
    if is_linux; then
      printf '%s\n' 'cc|c-compiler'
    fi
    ;;
  shell.zsh)
    printf '%s\n' 'zsh|zsh'
    ;;
  terminal.tmux)
    printf '%s\n' 'tmux|tmux' 'git|git' 'bc|bc'
    ;;
  esac
}

capability_optional_features() {
  case "$1" in
  editor.nvim) printf '%s\n' python-provider ;;
  shell.zsh | terminal.tmux | runtime.node) return 0 ;;
  esac
}

capability_config_policy() {
  case "$1" in
  runtime.node) printf '%s\n' none ;;
  *) printf '%s\n' replace ;;
  esac
}

capability_config_records() {
  local capability="$1"
  local repo_root="$2"
  local home_dir="$3"

  case "$capability" in
  editor.nvim)
    printf '%s|%s\n' "$repo_root/config/nvim" "$home_dir/.config/nvim"
    ;;
  shell.zsh)
    printf '%s|%s\n' "$repo_root/config/.zshrc" "$home_dir/.zshrc"
    printf '%s|%s\n' "$repo_root/config/.p10k.zsh" "$home_dir/.p10k.zsh"
    printf '%s|%s\n' "$repo_root/config/.zsh-utils" "$home_dir/.config/.zsh-utils"
    ;;
  terminal.tmux)
    printf '%s|%s\n' "$repo_root/config/.tmux.conf" "$home_dir/.tmux.conf"
    ;;
  esac
}

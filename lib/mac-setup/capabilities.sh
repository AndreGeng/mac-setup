#!/usr/bin/env bash

capability_ids() {
  printf '%s\n' editor.nvim shell.zsh
}

canonical_capability() {
  case "$1" in
  vim | nvim | neovim | editor.nvim)
    printf '%s\n' editor.nvim
    ;;
  zsh | shell | shell.zsh)
    printf '%s\n' shell.zsh
    ;;
  *)
    return 1
    ;;
  esac
}

capability_aliases() {
  case "$1" in
  editor.nvim) printf '%s\n' vim nvim neovim ;;
  shell.zsh) printf '%s\n' zsh shell ;;
  esac
}

capability_description() {
  case "$1" in
  editor.nvim) printf '%s\n' 'Install and configure the Neovim development environment.' ;;
  shell.zsh) printf '%s\n' 'Install Zsh, Zinit, and the repository-owned shell configuration.' ;;
  esac
}

capability_module() {
  case "$1" in
  editor.nvim) printf '%s\n' vim ;;
  shell.zsh) printf '%s\n' zsh ;;
  esac
}

capability_tools() {
  case "$1" in
  editor.nvim)
    printf '%s\n' 'nvim|neovim' 'rg|ripgrep' 'fd|fd'
    ;;
  shell.zsh)
    printf '%s\n' 'zsh|zsh'
    ;;
  esac
}

capability_optional_features() {
  case "$1" in
  editor.nvim) printf '%s\n' python-provider ;;
  shell.zsh) return 0 ;;
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
  esac
}

#!/usr/bin/env bash

install_zsh() {
  log "=== 安装 Zsh ===" "$GREEN"
  
  # 安装 zsh
  if ! command -v zsh &>/dev/null; then
    pkg_install zsh || return 1
  else
    log "zsh 已安装，跳过" "$YELLOW"
  fi
  
  # 安装 zinit
  local zinit_dir="$HOME/.local/share/zinit"
  if [[ ! -d "$zinit_dir" ]]; then
    log "安装 zinit..." "$GREEN"
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)" -- -d "$zinit_dir"
  else
    log "zinit 已安装，跳过" "$YELLOW"
  fi
  
  # macOS 专属：zsh-completions
  if is_macos; then
    pkg_install zsh-completions || true
  fi
}

install_zsh

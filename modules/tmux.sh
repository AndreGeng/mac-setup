#!/usr/bin/env bash

install_tmux() {
  log "=== 安装 Tmux ===" "$GREEN"
  
  pkg_install tmux || return 1
  
  # macOS 专属：剪贴板支持
  if is_macos; then
    pkg_install reattach-to-user-namespace || true
  fi
  
  # TPM 插件管理器
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    log "安装 TPM..." "$GREEN"
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  else
    log "TPM 已安装，跳过" "$YELLOW"
  fi
}

install_tmux

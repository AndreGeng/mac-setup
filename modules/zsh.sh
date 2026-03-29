#!/usr/bin/env bash

install_zsh() {
  log "=== 安装 Zsh ===" "$GREEN"

  # 安装 zsh
  if ! command -v zsh &>/dev/null; then
    pkg_install zsh || return 1
  else
    log "zsh 已安装，跳过" "$YELLOW"
  fi

  # 安装 zinit（用户级安装）
  local zinit_dir="$HOME/.local/share/zinit"
  if [[ ! -d "$zinit_dir" ]]; then
    log "安装 zinit 到用户目录..." "$GREEN"
    # 确保目录存在
    mkdir -p "$(dirname "$zinit_dir")"
    # 只 clone 到用户目录，不安装系统级文件
    if [[ ! -d "$zinit_dir/.git" ]]; then
      git clone https://github.com/zdharma-continuum/zinit.git "$zinit_dir" 2>/dev/null || {
        log "zinit clone 失败，跳过" "$YELLOW"
      }
    fi
  else
    log "zinit 已安装，跳过" "$YELLOW"
  fi

  # macOS 专属：zsh-completions（可选）
  if is_macos; then
    pkg_install zsh-completions || log "zsh-completions 安装失败，跳过" "$YELLOW"
  fi
}

install_zsh

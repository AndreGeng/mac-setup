#!/usr/bin/env bash
#
# 模块：Zsh + zinit；可选 zsh-completions（macOS）。
# 由 setup.sh / setup-lite.sh --with-zsh source 本文件；需已加载 lib（log、pkg_install、fix_zsh_permissions 等）。
#

install_zsh() {
  log "=== 安装 Zsh ===" "$GREEN"

  # 修复 zsh 目录权限（避免后续安装问题）
  fix_zsh_permissions

  # 安装 zsh
  if ! command -v zsh &>/dev/null; then
    pkg_install zsh || return 1
  else
    log "zsh 已安装，跳过" "$YELLOW"
  fi

  # 安装 zinit（用户级安装）
  local zinit_dir
  zinit_dir="$(zinit_install_dir)"
  if zinit_install_is_valid; then
    log "zinit 已安装，跳过" "$YELLOW"
  elif [[ -e "$zinit_dir" ]]; then
    log "zinit 安装不完整，请先处理: $zinit_dir" "$RED"
    return 1
  else
    log "安装 zinit 到用户目录..." "$GREEN"
    mkdir -p "$(dirname "$zinit_dir")"
    git clone https://github.com/zdharma-continuum/zinit.git "$zinit_dir" 2>/dev/null || {
      log "zinit clone 失败" "$RED"
      return 1
    }
    if ! zinit_install_is_valid; then
      log "zinit 安装结果不完整: $zinit_dir" "$RED"
      return 1
    fi
  fi

  # macOS 专属：zsh-completions（可选）
  if is_macos; then
    pkg_install zsh-completions || log "zsh-completions 安装失败，跳过" "$YELLOW"
  fi
}

install_zsh

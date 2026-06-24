#!/usr/bin/env bash
#
# 模块：Herdr agent multiplexer；macOS 优先 Homebrew，其他平台回退官方安装脚本。
#

install_herdr() {
  log "=== 安装 Herdr ===" "$GREEN"

  if command -v herdr &>/dev/null; then
    log "herdr 已安装，跳过" "$YELLOW"
    return 0
  fi

  if is_macos && command -v brew &>/dev/null; then
    pkg_install herdr || return 1
  else
    curl -fsSL https://herdr.dev/install.sh | sh
  fi

  if command -v herdr &>/dev/null; then
    log "Herdr 安装成功" "$GREEN"
  else
    log "Herdr 安装失败" "$RED"
    return 1
  fi
}

install_herdr

#!/usr/bin/env bash

install_cli_tools() {
  log "=== 安装 CLI 工具 ===" "$GREEN"

  # 通用工具列表
  local tools=(
    "lazygit"
    "the_silver_searcher"
    "git-delta"
    "ast-grep"
    "shfmt"
  )

  for tool in "${tools[@]}"; do
    local cmd_name="${tool%%-*}"
    if ! command -v "$cmd_name" &>/dev/null && ! command -v "$tool" &>/dev/null; then
      pkg_install "$tool" || log "跳过 $tool (可能需要 root)" "$YELLOW"
    else
      log "$tool 已安装，跳过" "$YELLOW"
    fi
  done

  # fzf 单独处理（因为依赖 go，在旧版 macOS 上可能失败）
  install_fzf_safe
}

install_fzf_safe() {
  if command -v fzf &>/dev/null; then
    log "fzf 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 fzf..." "$GREEN"

  # 方法1: Homebrew（可能失败，因为依赖 go）
  if pkg_install fzf 2>/dev/null; then
    log "fzf 安装成功" "$GREEN"
    return 0
  fi

  log "Homebrew 安装 fzf 失败，尝试下载二进制..." "$YELLOW"

  # 方法2: 直接下载二进制
  local arch
  arch=$(uname -m)
  local version="0.44.1"
  local url="https://github.com/junegunn/fzf/releases/download/${version}/fzf-${version}-darwin_${arch}.zip"

  if curl -fLo "/tmp/fzf.zip" "$url"; then
    mkdir -p /tmp/fzf_extract
    unzip -o /tmp/fzf.zip -d /tmp/fzf_extract
    chmod +x /tmp/fzf_extract/fzf
    # 尝试安装到用户目录
    mkdir -p "$HOME/.local/bin"
    mv /tmp/fzf_extract/fzf "$HOME/.local/bin/fzf"
    rm -rf /tmp/fzf.zip /tmp/fzf_extract
    export PATH="$HOME/.local/bin:$PATH"
    log "fzf 安装成功" "$GREEN"
  else
    log "fzf 下载失败，跳过" "$YELLOW"
    return 1
  fi
}

install_cli_tools

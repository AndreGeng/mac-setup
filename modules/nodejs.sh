#!/usr/bin/env bash

install_mise() {
  export PATH="$HOME/.local/bin:$PATH"

  if command -v mise &>/dev/null || [[ -f "$HOME/.local/bin/mise" ]]; then
    log "mise 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 mise..." "$GREEN"

  local arch
  local os
  local version="2026.3.17"

  arch=$(uname -m)
  os=$(uname -s | tr '[:upper:]' '[:lower:]')

  case "$os" in
  darwin) os="macos" ;;
  linux) ;;
  *)
    log "不支持的操作系统: $os" "$RED"
    return 1
    ;;
  esac

  case "$arch" in
  x86_64) arch="x64" ;;
  arm64 | aarch64) arch="arm64" ;;
  *)
    log "不支持的架构: $arch" "$RED"
    return 1
    ;;
  esac

  local filename="mise-${version}-${os}-${arch}.tar.gz"
  local url="https://github.com/jdx/mise/releases/download/v${version}/${filename}"
  local dest="/tmp/mise.tar.gz"

  if curl -fLo "$dest" "$url"; then
    mkdir -p "$HOME/.local/bin"
    tar -xzf "$dest" -C /tmp
    mv /tmp/mise "$HOME/.local/bin/mise"
    chmod +x "$HOME/.local/bin/mise"
    rm -f "$dest"
    log "mise 安装成功" "$GREEN"
  else
    log "mise 下载失败" "$YELLOW"
    return 1
  fi
}

install_nodejs() {
  log "=== 安装 Node.js ===" "$GREEN"

  # 安装 mise（独立模块）
  install_mise

  # 确保 PATH 包含 mise
  export PATH="$HOME/.local/bin:$PATH"

  # 加载 mise
  eval "$($HOME/.local/bin/mise activate bash 2>/dev/null || mise activate bash 2>/dev/null || true)"

  # 安装 Node.js LTS
  log "安装 Node.js LTS..." "$GREEN"
  mise use -g node@lts

  # 全局 npm 包
  local npm_packages=(
    "js-beautify"
    "prettier"
    "typescript"
    "bash-language-server"
    "typescript-language-server"
    "@olrtg/emmet-language-server"
    "eslint_d"
    "vscode-langservers-extracted"
  )

  for pkg in "${npm_packages[@]}"; do
    if ! npm list -g "$pkg" &>/dev/null 2>&1; then
      log "安装 npm 包: $pkg" "$GREEN"
      npm install -g "$pkg"
    else
      log "npm 包 $pkg 已安装，跳过" "$YELLOW"
    fi
  done
}

install_nodejs

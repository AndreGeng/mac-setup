#!/usr/bin/env bash

install_nodejs() {
  log "=== 安装 Node.js ===" "$GREEN"

  # 确保 mise 已安装
  if ! command -v mise &>/dev/null; then
    log "安装 mise..." "$GREEN"
    curl --proto '=https' --tlsv1.2 -sSf https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  else
    log "mise 已安装，跳过" "$YELLOW"
  fi

  # 加载 mise
  eval "$(mise activate bash 2>/dev/null || mise activate zsh 2>/dev/null || true)"

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

#!/usr/bin/env bash

install_mise() {
  export PATH="$HOME/.local/bin:$PATH"

  if command -v mise &>/dev/null || [[ -f "$HOME/.local/bin/mise" ]]; then
    log "mise 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 mise..." "$GREEN"

  if curl --proto '=https' --tlsv1.2 -sSf https://mise.run | sh; then
    log "mise 安装成功" "$GREEN"
  else
    log "mise 安装失败，跳过" "$YELLOW"
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

#!/usr/bin/env bash
#
# 模块：mise 全局 Node LTS + 一组全局 npm 包（格式化、LSP 等）。
#
if ! declare -F install_mise &>/dev/null; then
  _MOD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  # shellcheck source=../lib/utils.sh
  source "${_MOD_ROOT}/lib/utils.sh"
fi

install_nodejs() {
  log "=== 安装 Node.js ===" "$GREEN"

  # 安装 mise（独立模块）
  install_mise

  # 确保 PATH 包含 mise
  export PATH="$HOME/.local/bin:$PATH"

  local _mise_bin
  if ! _mise_bin="$(resolve_mise_executable 2>/dev/null)"; then
    log "未找到 mise 可执行文件，无法安装 Node.js" "$RED"
    return 1
  fi
  # mise 往当前 shell 注入 shims PATH；eval 执行其打印出的 export 语句
  eval "$("$_mise_bin" activate bash 2>/dev/null || true)"

  # 安装 Node.js LTS
  log "安装 Node.js LTS..." "$GREEN"
  "$_mise_bin" use -g node@lts

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

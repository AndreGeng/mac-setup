#!/usr/bin/env bash

install_mise() {
  export PATH="$HOME/.local/bin:$PATH"

  if command -v mise &>/dev/null || [[ -f "$HOME/.local/bin/mise" ]]; then
    log "mise 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 mise..." "$GREEN"

  # 尝试官方安装脚本
  if curl --proto '=https' --tlsv1.2 -sSf https://mise.run | sh 2>/dev/null; then
    log "mise 安装成功" "$GREEN"
    return 0
  fi

  # 如果官方脚本失败，尝试 pip 安装
  log "官方脚本安装失败，尝试 pip 安装..." "$YELLOW"
  if command -v pip &>/dev/null; then
    pip install mise 2>/dev/null && return 0
  fi

  # 如果 pip 也失败，尝试 npm 安装
  if command -v npm &>/dev/null; then
    npm install -g @mise/plugin 2>/dev/null && return 0
  fi

  log "mise 安装失败，请手动安装: https://mise.run" "$RED"
  log "或运行: curl https://mise.run | sh" "$YELLOW"
  return 1
}

install_neovim() {
  log "=== 安装 Neovim ===" "$GREEN"

  # 安装 mise（独立模块）
  install_mise

  # 基础依赖
  local deps=("neovim" "ripgrep")
  for dep in "${deps[@]}"; do
    pkg_install "$dep" || log "跳过 $dep" "$YELLOW"
  done

  # fzf 和 fd 单独处理
  install_fzf_safe
  install_fd_safe

  # 确保 ~/.local/bin 在 PATH 中
  export PATH="$HOME/.local/bin:$PATH"

  # 加载 mise
  eval "$($HOME/.local/bin/mise activate bash 2>/dev/null || mise activate bash 2>/dev/null || true)"

  # Python 环境
  setup_python_env
}

install_fzf_safe() {
  # 检查多个可能的安装位置
  if command -v fzf &>/dev/null || [[ -f /opt/homebrew/bin/fzf ]] || [[ -f /usr/local/bin/fzf ]] || [[ -f "$HOME/.local/bin/fzf" ]]; then
    log "fzf 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 fzf..." "$GREEN"

  # 直接下载二进制
  local arch
  arch=$(uname -m)
  local version="0.44.1"
  local url="https://github.com/junegunn/fzf/releases/download/${version}/fzf-${version}-darwin_${arch}.zip"

  if curl -fLo "/tmp/fzf.zip" "$url"; then
    mkdir -p /tmp/fzf_extract
    unzip -o /tmp/fzf.zip -d /tmp/fzf_extract
    chmod +x /tmp/fzf_extract/fzf
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

install_fd_safe() {
  if command -v fd &>/dev/null; then
    log "fd 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 fd..." "$GREEN"
  pkg_install fd || log "fd 安装失败，跳过" "$YELLOW"
}

setup_python_env() {
  log "配置 Python 环境..." "$GREEN"

  unset ALL_PROXY

  # 确保 PATH 包含 mise
  export PATH="$HOME/.local/bin:$PATH"

  local venv_dir="$HOME/.local/share/neovim"
  local python3_version="3.11"
  local mise_cmd="$HOME/.local/bin/mise"

  mkdir -p "$venv_dir"

  # 安装 Python
  if ! $mise_cmd ls python 2>/dev/null | grep -q "$python3_version"; then
    log "安装 Python $python3_version..." "$GREEN"
    $mise_cmd install python@$python3_version
  fi

  # 创建虚拟环境
  local venv_path="$venv_dir/neovim3"
  if [[ ! -d "$venv_path" ]]; then
    log "创建 Python 虚拟环境..." "$GREEN"
    $mise_cmd exec python@$python3_version -- python -m venv "$venv_path"
  fi

  # 安装 pynvim
  if ! "$venv_path/bin/pip" show pynvim &>/dev/null; then
    log "安装 pynvim..." "$GREEN"
    "$venv_path/bin/pip" install pynvim
  fi

  # 安装 neovim-remote
  if ! "$venv_path/bin/pip" show neovim-remote &>/dev/null; then
    log "安装 neovim-remote..." "$GREEN"
    "$venv_path/bin/pip" install neovim-remote
  fi
}

install_neovim

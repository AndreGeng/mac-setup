#!/usr/bin/env bash

install_neovim() {
  log "=== 安装 Neovim ===" "$GREEN"

  # 基础依赖
  local deps=("neovim" "ripgrep" "fzf")
  for dep in "${deps[@]}"; do
    pkg_install "$dep" || log "跳过 $dep" "$YELLOW"
  done

  # fd 在不同平台包名不同
  if is_linux; then
    pkg_install "fd-find" || true
  else
    pkg_install "fd" || true
  fi

  # 安装 mise（如果不存在）
  if ! command -v mise &>/dev/null; then
    log "安装 mise..." "$GREEN"
    curl --proto '=https' --tlsv1.2 -sSf https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  else
    log "mise 已安装，跳过" "$YELLOW"
  fi

  # 加载 mise
  eval "$(mise activate bash 2>/dev/null || mise activate zsh 2>/dev/null || true)"

  # Python 环境
  setup_python_env
}

setup_python_env() {
  log "配置 Python 环境..." "$GREEN"

  unset ALL_PROXY

  local venv_dir="$HOME/.local/share/neovim"
  local python3_version="3.11"

  mkdir -p "$venv_dir"

  # 安装 Python
  if ! mise ls python 2>/dev/null | grep -q "$python3_version"; then
    log "安装 Python $python3_version..." "$GREEN"
    mise install python@$python3_version
  fi

  # 创建虚拟环境
  local venv_path="$venv_dir/neovim3"
  if [[ ! -d "$venv_path" ]]; then
    log "创建 Python 虚拟环境..." "$GREEN"
    mise exec python@$python3_version -- python -m venv "$venv_path"
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

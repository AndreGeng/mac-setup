#!/usr/bin/env bash

install_mise_binary() {
  local arch
  local os
  local version="2024.12.13"

  arch=$(uname -m)
  os=$(uname -s | tr '[:upper:]' '[:lower:]')

  case "$os" in
  darwin) os="macos" ;;
  linux) os="linux" ;;
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

  log "下载 mise..." "$GREEN"
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

  # 确保 ~/.local/bin 在 PATH 中
  export PATH="$HOME/.local/bin:$PATH"

  # 安装 mise（如果不存在）
  if ! command -v mise &>/dev/null && [[ ! -f "$HOME/.local/bin/mise" ]]; then
    log "安装 mise..." "$GREEN"
    install_mise_binary
  else
    log "mise 已安装，跳过" "$YELLOW"
  fi

  # 加载 mise（使用绝对路径或 PATH 中的 mise）
  eval "$($HOME/.local/bin/mise activate bash 2>/dev/null || mise activate bash 2>/dev/null || true)"

  # Python 环境
  setup_python_env
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

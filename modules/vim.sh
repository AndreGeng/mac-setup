#!/usr/bin/env bash
if ! declare -F install_mise &>/dev/null; then
  _MOD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  # shellcheck source=../lib/utils.sh
  source "${_MOD_ROOT}/lib/utils.sh"
fi

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
  # install_fzf_safe
  install_fd_safe

  # 确保 ~/.local/bin 在 PATH 中
  export PATH="$HOME/.local/bin:$PATH"

  # 加载 mise（使用解析出的真实二进制，避免 ~/.local/bin/mise 为目录时报错）
  local _mise_bin
  if _mise_bin="$(resolve_mise_executable 2>/dev/null)"; then
    eval "$("$_mise_bin" activate bash 2>/dev/null || true)"
  fi

  # Python 环境
  setup_python_env

  # 复制 nvim 配置
  local nvim_config_src
  nvim_config_src="$(cd "$(dirname "$0")/../config/nvim" && pwd)"
  mkdir -p "$HOME/.config/nvim"
  log "复制 nvim 配置..." "$GREEN"
  cp -rf "$nvim_config_src"/* "$HOME/.config/nvim/"
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
  local mise_cmd

  if ! mise_cmd="$(resolve_mise_executable 2>/dev/null)"; then
    log "未找到 mise 可执行文件。若存在目录 ~/.local/bin/mise，请删除后重试安装 mise。" "$RED"
    return 1
  fi

  mkdir -p "$venv_dir"

  # 安装 Python
  if ! "$mise_cmd" ls python 2>/dev/null | grep -q "$python3_version"; then
    log "安装 Python $python3_version..." "$GREEN"
    "$mise_cmd" install python@"$python3_version"
  fi

  # 创建虚拟环境
  local venv_path="$venv_dir/neovim3"
  if [[ ! -d "$venv_path" ]]; then
    log "创建 Python 虚拟环境..." "$GREEN"
    "$mise_cmd" exec python@"$python3_version" -- python -m venv "$venv_path"
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

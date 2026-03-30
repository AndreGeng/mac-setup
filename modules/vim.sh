#!/usr/bin/env bash
#
# 模块：Neovim、ripgrep、fd，以及可选的 mise + Python venv（pynvim、neovim-remote）。
# 单独跑本文件时会自载 lib/utils.sh；完整 setup 已由入口脚本加载 lib。
#
if ! declare -F install_mise &>/dev/null; then
  _MOD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  # shellcheck source=../lib/utils.sh
  source "${_MOD_ROOT}/lib/utils.sh"
fi

install_neovim() {
  log "=== 安装 Neovim ===" "$GREEN"

  # setup-lite 默认设置 MAC_SETUP_SKIP_NVIM_PYTHON=1：不装 mise(仅vim)/venv/nvr；nodejs 模块仍会装 mise
  if [[ "${MAC_SETUP_SKIP_NVIM_PYTHON:-}" != "1" ]]; then
    install_mise
  fi

  local deps=("neovim" "ripgrep")
  for dep in "${deps[@]}"; do
    pkg_install "$dep" || log "跳过 $dep" "$YELLOW"
  done

  # install_fzf_safe 已省略；fzf 由 cli-tools 安装
  install_fd_safe

  export PATH="$HOME/.local/bin:$PATH"

  if [[ "${MAC_SETUP_SKIP_NVIM_PYTHON:-}" != "1" ]]; then
    local _mise_bin
    if _mise_bin="$(resolve_mise_executable 2>/dev/null)"; then
      eval "$("$_mise_bin" activate bash 2>/dev/null || true)"
    fi
    setup_python_env
  else
    log "跳过 setup_python_env（无 pynvim/nvr venv；由 setup-lite 默认开启）" "$YELLOW"
  fi

  # 复制 nvim 配置
  local nvim_config_src
  nvim_config_src="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config/nvim" && pwd)"

  # 确保 HOME 正确
  local target_home="${HOME:-/root}"

  local nvim_config_dest="$target_home/.config/nvim"
  local config_dir="$target_home/.config"

  # 确保 .config 目录存在
  mkdir -p "$config_dir"

  # 处理已存在的 nvim（可能是软链接或目录）
  if [[ -e "$nvim_config_dest" ]]; then
    log "nvim 配置已存在，删除后重新复制..." "$YELLOW"
    rm -rf "$nvim_config_dest" 2>/dev/null || true
  fi

  log "复制 nvim 配置到 $nvim_config_dest..." "$GREEN"
  cp -rf "$nvim_config_src" "$nvim_config_dest"
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

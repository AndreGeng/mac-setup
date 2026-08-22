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

  # setup 的 sync 模块和 Agent-facing capability 都有统一配置发布者；仅在单独执行
  # vim 模块时保留历史上的复制行为。
  if [[ "${MAC_SETUP_SKIP_NVIM_CONFIG:-0}" != "1" ]]; then
    local nvim_config_src
    local target_home="${HOME:-/root}"
    local nvim_config_dest="$target_home/.config/nvim"
    nvim_config_src="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config/nvim" && pwd)"

    mkdir -p "$target_home/.config"
    if [[ -e "$nvim_config_dest" || -L "$nvim_config_dest" ]]; then
      log "nvim 配置已存在，删除后重新复制..." "$YELLOW"
      rm -rf "$nvim_config_dest" 2>/dev/null || true
    fi
    log "复制 nvim 配置到 $nvim_config_dest..." "$GREEN"
    cp -rf "$nvim_config_src" "$nvim_config_dest"
  fi
}

install_fd_safe() {
  local local_bin="${HOME:-/root}/.local/bin"
  local fd_path fdfind_path
  export PATH="$local_bin:$PATH"

  if command -v fd &>/dev/null; then
    log "fd 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 fd..." "$GREEN"
  pkg_install fd || {
    log "fd 安装失败" "$RED"
    return 1
  }

  if command -v fd &>/dev/null; then
    return 0
  fi

  fdfind_path="$(command -v fdfind 2>/dev/null || true)"
  if [[ -z "$fdfind_path" ]]; then
    log "fd 安装完成但没有可用的 fd/fdfind 命令" "$RED"
    return 1
  fi

  fd_path="$local_bin/fd"
  mkdir -p "$local_bin"
  if [[ -e "$fd_path" || -L "$fd_path" ]]; then
    if [[ -L "$fd_path" && "$(readlink "$fd_path")" == "$fdfind_path" ]]; then
      return 0
    fi
    log "无法发布 fd 兼容命令，目标路径已存在: $fd_path" "$RED"
    return 1
  fi
  ln -s "$fdfind_path" "$fd_path"
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

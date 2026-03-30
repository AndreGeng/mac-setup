#!/usr/bin/env bash
#
# 被 setup 与各模块 source 的通用工具：日志、软链、mise 安装与路径解析等。
#

# 终端 ANSI 颜色（NC = no color，用于 log 结尾重置样式）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# $1 消息 $2 可选颜色，默认绿色
log() {
  local msg="$1"
  local color="${2:-$GREEN}"
  echo -e "${color}${msg}${NC}"
}

# 获取脚本根目录
get_script_root() {
  local script_path="${BASH_SOURCE[0]}"
  local script_dir="$(cd "$(dirname "$script_path")" 2>/dev/null && pwd)"
  echo "$script_dir"
}

# 创建符号链接
symlink_config() {
  local src="$1"
  local dest="$2"
  local backup="${3:-true}"

  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]] && [[ "$backup" == "true" ]]; then
    mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  log "链接: $dest -> $src" "$GREEN"
}

# 跨平台 realpath
get_realpath() {
  local path="$1"
  if command -v realpath &>/dev/null; then
    realpath "$path"
  elif command -v grealpath &>/dev/null; then
    grealpath "$path"
  else
    # macOS fallback
    local dir="$(cd "$(dirname "$path")" 2>/dev/null && pwd)"
    echo "$dir/$(basename "$path")"
  fi
}

# 修复 zsh 相关目录权限
fix_zsh_permissions() {
  local zsh_dirs=(
    "/usr/local/share/zsh"
    "/usr/local/share/zsh/site-functions"
  )

  local SUDO=""
  if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    SUDO="sudo"
  fi

  for dir in "${zsh_dirs[@]}"; do
    if [[ -d "$dir" ]] && [[ ! -w "$dir" ]]; then
      log "修复目录权限: $dir" "$YELLOW"
      $SUDO chown -R "$(whoami)" "$dir" 2>/dev/null || true
      chmod -R u+w "$dir" 2>/dev/null || true
    fi
  done
}

# 解析可用的 mise 可执行文件路径（必须是常规文件）。
# 注意：目录 ~/.local/bin/mise 在 Unix 上也可能带 +x，用 -x 会误判为「已安装」。
resolve_mise_executable() {
  local home_dir="${HOME:-/root}"
  export PATH="$home_dir/.local/bin:$home_dir/bin:/usr/local/bin:/usr/bin:$PATH"
  local c
  c="$(command -v mise 2>/dev/null || true)"
  if [[ -n "$c" && -f "$c" && -x "$c" ]]; then
    printf '%s\n' "$c"
    return 0
  fi
  local p
  for p in "$home_dir/.local/bin/mise" "$home_dir/bin/mise" /usr/local/bin/mise /usr/bin/mise; do
    if [[ -f "$p" && -x "$p" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

# 若 ~/.local/bin/mise 误为目录，移除以便安装真实二进制
cleanup_mise_path_if_directory() {
  local home_dir="${HOME:-/root}"
  local p="${home_dir}/.local/bin/mise"
  if [[ -d "$p" ]]; then
    log "发现 $p 为目录（应为 mise 可执行文件），正在移除..." "$YELLOW"
    rm -rf "$p"
  fi
}

# 安装 mise（直接下载二进制）
install_mise() {
  local home_dir="${HOME:-/root}"
  local local_bin="$home_dir/.local/bin"
  export PATH="$local_bin:$home_dir/bin:$PATH"

  # 清理可能的错误目录
  cleanup_mise_path_if_directory

  if resolve_mise_executable &>/dev/null; then
    log "mise 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 mise..." "$GREEN"
  cleanup_mise_path_if_directory

  # 检测系统和架构
  local arch
  local os
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

  # 获取最新版本
  local version
  version=$(curl -sSL "https://api.github.com/repos/jdx/mise/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/' || echo "")

  if [[ -z "$version" ]]; then
    log "无法获取 mise 版本，尝试安装脚本..." "$YELLOW"
    # 备用：使用安装脚本
    if curl --proto '=https' --tlsv1.2 -sSf https://mise.run | sh -s -- -y; then
      log "mise 安装成功" "$GREEN"
      return 0
    fi
    log "mise 安装失败，请手动安装: https://mise.run" "$RED"
    return 1
  fi

  local filename="mise-v${version}-${os}-${arch}.tar.gz"
  local url="https://github.com/jdx/mise/releases/download/v${version}/${filename}"
  local tmp_dir="/tmp/mise-install"

  mkdir -p "$tmp_dir"

  log "下载 mise v${version}..." "$GREEN"
  if curl -fLo "$tmp_dir/mise.tar.gz" "$url"; then
    tar -xzf "$tmp_dir/mise.tar.gz" -C "$tmp_dir"
    mkdir -p "$local_bin"
    mv "$tmp_dir/mise" "$local_bin/mise"
    chmod +x "$local_bin/mise"
    rm -rf "$tmp_dir"
    log "mise 安装成功" "$GREEN"
    return 0
  else
    rm -rf "$tmp_dir"
    log "下载失败，尝试安装脚本..." "$YELLOW"
    if curl --proto '=https' --tlsv1.2 -sSf https://mise.run | sh -s -- -y; then
      log "mise 安装成功" "$GREEN"
      return 0
    fi
    log "mise 安装失败，请手动安装: https://mise.run" "$RED"
    return 1
  fi
}

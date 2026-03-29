#!/usr/bin/env bash

# 颜色常量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 日志函数
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

  for dir in "${zsh_dirs[@]}"; do
    if [[ -d "$dir" ]] && [[ ! -w "$dir" ]]; then
      log "修复目录权限: $dir" "$YELLOW"
      sudo chown -R "$(whoami)" "$dir" 2>/dev/null || true
      chmod -R u+w "$dir" 2>/dev/null || true
    fi
  done
}

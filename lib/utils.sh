#!/usr/bin/env bash
#
# 被 setup 与各模块 source 的通用工具：日志、软链、mise 安装与路径解析等。
#

UTILS_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$UTILS_REPO_ROOT/lib/bootstrap-manifest.sh"

# 终端 ANSI 颜色（NC = no color，用于 log 结尾重置样式）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
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
  if [[ "${MAC_SETUP_NO_ROOT:-0}" == "1" ]]; then
    log "跳过 zsh 系统目录权限修复（--no-root）" "$YELLOW"
    return 0
  fi

  local zsh_dirs=(
    "/usr/local/share/zsh"
    "/usr/local/share/zsh/site-functions"
  )

  local sudo_cmd=()
  if [[ $EUID -ne 0 ]]; then
    sudo_cmd=(sudo)
  fi

  for dir in "${zsh_dirs[@]}"; do
    if [[ -d "$dir" ]] && [[ ! -w "$dir" ]]; then
      log "修复目录权限: $dir" "$YELLOW"
      "${sudo_cmd[@]}" chown -R "$(whoami)" "$dir" 2>/dev/null || true
      "${sudo_cmd[@]}" chmod -R u+w "$dir" 2>/dev/null || true
    fi
  done
}

# Zinit's canonical user-level installation, shared by install/plan/verify.
zinit_install_dir() {
  printf '%s\n' "${HOME:-/root}/.local/share/zinit/zinit.git"
}

zinit_install_is_valid() {
  local zinit_dir
  zinit_dir="$(zinit_install_dir)"
  [[ -d "$zinit_dir/.git" && -f "$zinit_dir/zinit.zsh" ]]
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

mise_executable_version() {
  local executable="$1"
  local output
  [[ -f "$executable" && -x "$executable" ]] || return 1
  output="$("$executable" --version 2>/dev/null)" || return 1
  output="${output%% *}"
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  printf '%s\n' "$output"
}

mise_executable_matches() {
  local executable="$1"
  local expected_version="$2"
  local actual_version
  actual_version="$(mise_executable_version "$executable")" || return 1
  [[ "$actual_version" == "$expected_version" ]]
}

file_sha256() {
  local path="$1"
  local output
  if command -v sha256sum >/dev/null 2>&1; then
    output="$(sha256sum "$path")" || return 1
  elif command -v shasum >/dev/null 2>&1; then
    output="$(shasum -a 256 "$path")" || return 1
  else
    return 1
  fi
  output="${output%% *}"
  [[ "$output" =~ ^[0-9a-fA-F]{64}$ ]] || return 1
  printf '%s\n' "$output" | tr '[:upper:]' '[:lower:]'
}

verify_file_sha256() {
  local path="$1"
  local expected="$2"
  local actual
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || return 1
  actual="$(file_sha256 "$path")" || return 1
  [[ "$actual" == "$expected" ]]
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
  local repo_root="$UTILS_REPO_ROOT"
  export PATH="$local_bin:$home_dir/bin:$PATH"

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

  local record version filename expected_sha256
  if ! record="$(mise_bootstrap_record "$repo_root" "$os" "$arch")"; then
    log "mise bootstrap manifest 无效或不支持当前平台" "$RED"
    return 1
  fi
  IFS='|' read -r version filename expected_sha256 <<<"$record"

  local current_mise=""
  current_mise="$(resolve_mise_executable 2>/dev/null)" || true
  if [[ -n "$current_mise" ]] && mise_executable_matches "$current_mise" "$version"; then
    log "mise v${version} 已安装，跳过" "$YELLOW"
    return 0
  fi

  if [[ -n "$current_mise" ]]; then
    log "mise 版本偏离，更新到 v${version}..." "$GREEN"
  else
    log "安装 mise v${version}..." "$GREEN"
  fi
  cleanup_mise_path_if_directory

  local url="https://github.com/jdx/mise/releases/download/v${version}/${filename}"
  local tmp_dir archive extract_dir extracted_mise install_tmp
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/mise-install.XXXXXX")"
  archive="$tmp_dir/$filename"
  extract_dir="$tmp_dir/extract"
  extracted_mise="$extract_dir/mise/bin/mise"

  log "下载 mise v${version}..." "$GREEN"
  if ! curl --proto '=https' --tlsv1.2 -fL -o "$archive" "$url"; then
    rm -rf "$tmp_dir"
    log "mise 下载失败；未修改现有安装" "$RED"
    return 1
  fi
  if ! verify_file_sha256 "$archive" "$expected_sha256"; then
    rm -rf "$tmp_dir"
    log "mise 下载文件 SHA-256 校验失败；未解压或修改现有安装" "$RED"
    return 1
  fi

  mkdir -p "$extract_dir"
  if ! tar -xzf "$archive" -C "$extract_dir" || [[ ! -f "$extracted_mise" ]]; then
    rm -rf "$tmp_dir"
    log "mise 归档解压失败；未修改现有安装" "$RED"
    return 1
  fi

  mkdir -p "$local_bin"
  install_tmp="$(mktemp "$local_bin/.mise.new.XXXXXX")" || {
    rm -rf "$tmp_dir"
    return 1
  }
  if ! cp "$extracted_mise" "$install_tmp" || ! chmod 0755 "$install_tmp" ||
    ! mv -f "$install_tmp" "$local_bin/mise"; then
    rm -f "$install_tmp"
    rm -rf "$tmp_dir"
    log "mise 安装失败；现有安装未被完整替换" "$RED"
    return 1
  fi

  rm -rf "$tmp_dir"
  log "mise v${version} 安装成功" "$GREEN"
  return 0
}

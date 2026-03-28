#!/usr/bin/env bash

# 包名映射表：通用名 -> 平台特定名
declare -A PKG_MAP=(
  ["openssl:ubuntu"]="libssl-dev"
  ["zlib:ubuntu"]="zlib1g-dev"
  ["xz:ubuntu"]="xz-utils"
  ["fd-find:ubuntu"]="fd-find"
  ["fd-find:macos"]="fd"
)

pkg_map_name() {
  local pkg="$1"
  local platform="${2:-$(detect_platform)}"
  echo "${PKG_MAP[$pkg:$platform]:-$pkg}"
}

pkg_install() {
  local pkg="$1"
  local platform=$(detect_platform)
  local mapped_pkg=$(pkg_map_name "$pkg" "$platform")
  
  if pkg_exists "$mapped_pkg"; then
    log "$mapped_pkg 已安装，跳过" "$YELLOW"
    return 0
  fi
  
  log "安装 $mapped_pkg..." "$GREEN"
  
  case "$platform" in
    macos)
      brew install "$mapped_pkg"
      ;;
    ubuntu|fedora|arch|linux)
      if ! can_sudo; then
        log "需要 sudo 权限安装 $mapped_pkg" "$RED"
        return 1
      fi
      _pkg_install_linux "$mapped_pkg"
      ;;
    *)
      log "不支持的平台: $platform" "$RED"
      return 1
      ;;
  esac
}

_pkg_install_linux() {
  local pkg="$1"
  if command -v apt &>/dev/null; then
    sudo apt install -y "$pkg"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$pkg"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$pkg"
  else
    log "未找到支持的包管理器" "$RED"
    return 1
  fi
}

pkg_exists() {
  local pkg="$1"
  local platform=$(detect_platform)
  
  case "$platform" in
    macos)
      brew list "$pkg" &>/dev/null
      ;;
    ubuntu)
      dpkg -l "$pkg" &>/dev/null 2>&1
      ;;
    fedora)
      rpm -q "$pkg" &>/dev/null 2>&1
      ;;
    arch)
      pacman -Qi "$pkg" &>/dev/null 2>&1
      ;;
    *)
      command -v "$pkg" &>/dev/null
      ;;
  esac
}

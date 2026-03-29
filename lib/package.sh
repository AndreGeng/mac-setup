#!/usr/bin/env bash

# 修复 macOS Homebrew 镜像源问题
fix_brew_mirror() {
  if ! is_macos || ! command -v brew &>/dev/null; then
    return 0
  fi

  # 国内镜像源（按优先级排列）
  local BREW_TUNA="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew"
  local BOTTLE_TUNA="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
  local BREW_TEAC="https://mirrors.cloud.tencent.com/homebrew"
  local BOTTLE_TEAC="https://mirrors.cloud.tencent.com/homebrew-bottles"

  # 检查当前源
  local current_remote
  current_remote=$(git -C "$(brew --repo)" remote get-url origin 2>/dev/null || echo "")

  # 如果已经是清华源且可用，跳过
  if echo "$current_remote" | grep -q "tuna.tsinghua"; then
    export HOMEBREW_BOTTLE_DOMAIN="$BOTTLE_TUNA"
    return 0
  fi

  log "设置 Homebrew 清华镜像源..." "$GREEN"

  # 切换到清华源
  git -C "$(brew --repo)" remote set-url origin "$BREW_TUNA/brew.git" 2>/dev/null || true
  git -C "$(brew --repo homebrew/core)" remote set-url origin "$BREW_TUNA/homebrew-core.git" 2>/dev/null || true
  git -C "$(brew --repo homebrew/cask)" remote set-url origin "$BREW_TUNA/homebrew-cask.git" 2>/dev/null || true

  # 设置 bottle 镜像
  export HOMEBREW_BOTTLE_DOMAIN="$BOTTLE_TUNA"

  log "已设置清华源 (备用: 腾讯云)" "$GREEN"
}

pkg_map_name() {
  local pkg="$1"
  local platform="${2:-$(detect_platform)}"

  case "$pkg:$platform" in
  openssl:ubuntu) echo "libssl-dev" ;;
  zlib:ubuntu) echo "zlib1g-dev" ;;
  xz:ubuntu) echo "xz-utils" ;;
  fd-find:ubuntu) echo "fd-find" ;;
  fd-find:macos) echo "fd" ;;
  fd:ubuntu) echo "fd-find" ;;
  *) echo "$pkg" ;;
  esac
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
  ubuntu | fedora | arch | linux)
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
  local SUDO=""

  # 如果不是 root 用户且需要 sudo
  if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    SUDO="sudo"
  fi

  if command -v apt &>/dev/null; then
    $SUDO apt install -y "$pkg"
  elif command -v dnf &>/dev/null; then
    $SUDO dnf install -y "$pkg"
  elif command -v pacman &>/dev/null; then
    $SUDO pacman -S --noconfirm "$pkg"
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
    dpkg -s "$pkg" &>/dev/null 2>&1
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

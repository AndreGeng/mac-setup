#!/usr/bin/env bash
#
# 根据 OSTYPE 与包管理器粗分平台名，供 platforms/ 目录与 pkg_install 分支使用。
# 注意: is_linux 在非 darwin 时均为真（含 WSL 等）；fedora/arch 需有对应包管理器才会细分。
#

detect_platform() {
  case "$OSTYPE" in
  darwin*) echo "macos" ;;
  linux*)
    if command -v apt &>/dev/null; then
      echo "ubuntu"
    elif command -v dnf &>/dev/null; then
      echo "fedora"
    elif command -v pacman &>/dev/null; then
      echo "arch"
    else
      echo "linux"
    fi
    ;;
  *) echo "unknown" ;;
  esac
}

is_macos() { [[ "$(detect_platform)" == "macos" ]]; }
is_linux() {
  case "$(detect_platform)" in
  ubuntu | fedora | arch | linux) return 0 ;;
  *) return 1 ;;
  esac
}

# Linux 发行版先加载通用 linux 层，再加载 ubuntu/fedora/arch 专属层。
platform_script_dirs() {
  local root="$1"
  local platform
  platform=$(detect_platform)

  case "$platform" in
  ubuntu | fedora | arch)
    printf '%s\n' "$root/linux" "$root/$platform"
    ;;
  linux | macos)
    printf '%s\n' "$root/$platform"
    ;;
  esac
}

has_root() {
  [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null
}

# 可无密码 sudo 或已是 root（-n 表示非交互，失败则返回假）
can_sudo() {
  [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null
}

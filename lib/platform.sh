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
# 非 macOS 一律视为 linux 族（含 ubuntu/fedora/arch 等子类）
is_linux() { [[ "$(detect_platform)" != "macos" ]]; }

has_root() {
  [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null
}

# 可无密码 sudo 或已是 root（-n 表示非交互，失败则返回假）
can_sudo() {
  sudo -n true 2>/dev/null || [[ $EUID -eq 0 ]]
}

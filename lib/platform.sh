#!/usr/bin/env bash

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
is_linux() { [[ "$(detect_platform)" != "macos" ]]; }

has_root() {
  [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null
}

can_sudo() {
  sudo -n true 2>/dev/null || [[ $EUID -eq 0 ]]
}

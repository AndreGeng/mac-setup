#!/usr/bin/env bash
#
# macOS：tap cask-fonts 后安装 Hack Nerd Font（终端图标字体）。
#

install_macos_fonts() {
  log "=== 安装 macOS 字体 ===" "$GREEN"
  
  brew tap homebrew/cask-fonts || true
  brew install --cask font-hack-nerd-font || true
}

install_macos_fonts

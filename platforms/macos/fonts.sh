#!/usr/bin/env bash

install_macos_fonts() {
  log "=== 安装 macOS 字体 ===" "$GREEN"
  
  brew tap homebrew/cask-fonts || true
  brew install --cask font-hack-nerd-font || true
}

install_macos_fonts

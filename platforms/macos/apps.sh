#!/usr/bin/env bash

install_macos_apps() {
  log "=== 安装 macOS GUI 应用 ===" "$GREEN"
  
  # 开发工具
  brew install --cask iterm2 || true
  brew install --cask visual-studio-code || true
  brew install --cask ghostty || true
  brew install --cask hammerspoon || true
  
  # 实用工具
  brew install --cask alfred || true
  brew install --cask snipaste || true
  brew install --cask caffeine || true
  brew install --cask appcleaner || true
  
  # 浏览器
  brew install --cask google-chrome || true
  
  # 其他
  brew install --cask notion || true
  brew install --cask drawio || true
  brew install --cask postman || true
}

install_macos_apps

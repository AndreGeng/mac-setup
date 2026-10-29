#!/usr/bin/env bash
#
# macOS 平台脚本（由 setup.sh 在 platforms/macos/ 下 source）：用 brew --cask 安装 GUI 应用。
# 普通 cask 失败继续；Snipaste 由专属模块校验安装并发布配置。
#

install_macos_apps() {
  log "=== 安装 macOS GUI 应用 ===" "$GREEN"

  # 开发工具
  brew install --cask visual-studio-code || true
  brew install --cask ghostty || true
  brew install --cask hammerspoon || true

  # 实用工具
  brew install --cask alfred || true
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/modules/snipaste.sh"
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

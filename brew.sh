#!/bin/bash
# Check for Homebrew,
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

# install GNU coreutils
brewI coreutils
brewI nginx
brewI shfmt

# brew installs

# homebrew cask apps
# develop
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
brew install --cask --force karabiner-elements
brew install --cask --force iterm2
brew install --cask --force hammerspoon
brew install --cask --force visual-studio-code
brew install --cask --force sourcetree
brew install --cask --force gas-mask # host管理
brew install --cask --force shadowsocksx-ng
brew install --cask --force alfred
# brew install --cask docker
# brew install --cask charles
# apps
brew install --cask google-chrome
brew install --cask appcleaner
brew install --cask android-file-transfer
brew install --cask baiduinput
brew install --cask qq
brew install --cask wechat
brew install --cask notion
brew install --cask youdaodict # 有道词典
brew install --cask drawio
brew install --cask postman
brew install --cask keycastr

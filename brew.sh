#!/bin/bash
# Check for Homebrew,
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

brew install jesseduffield/lazygit/lazygit
brewI lazygit
# install GNU coreutils
brewI coreutils
brewI nginx
brewI shfmt
brewI ranger
brewI cmake
brewI mise
brewI ast-grep

# brew installs

# homebrew cask apps
# develop
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
brew install --cask --force karabiner-elements
brew install --cask --force iterm2
brew install --cask --force hammerspoon
brew install --cask --force visual-studio-code
brew install --cask --force shadowsocksx-ng
brew install --cask --force alfred
brew install --cask --force snipaste
brew install --cask --force caffeine
brew install --cask --force ghostty
# brew install --cask docker
# brew install --cask charles
# apps
brew install --cask --force google-chrome
brew install --cask --force appcleaner
brew install --cask --force android-file-transfer
brew install --cask --force android-platform-tools
brew install --cask --force baiduinput
brew install --cask --force qq
brew install --cask --force wechat
brew install --cask --force notion
brew install --cask --force youdaodict # 有道词典
brew install --cask --force drawio
brew install --cask --force postman
brew install --cask --force keycastr

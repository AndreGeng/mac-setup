#!/bin/bash
# Check for Homebrew,
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done

brew tap caskroom/cask
brewInstallIfNotExists nginx

# brew installs

# homebrew cask apps
# develop
brew cask install karabiner-elements --force
brew cask install iterm2 --force
brew cask install hammerspoon --force
brew cask install visual-studio-code --force
brew cask install sourcetree --force
brew cask install gas-mask --force # host管理
brew cask install shadowsocksx-ng --force
brew cask install alfred --force
# brew cask install docker
# brew cask install charles
# apps
brew cask install google-chrome --force
brew cask install evernote --force
brew cask install appcleaner --force
brew cask install android-file-transfer --force
brew cask install baiduinput --force
brew cask install qq --force
brew cask install notion --force
brew cask install youdaodict --force # 有道词典

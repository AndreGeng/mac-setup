# Check for Homebrew,
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done

brew tap caskroom/cask

# brew installs

# homebrew cask apps
# develop
brew cask install karabiner-elements
brew cask install iterm2
brew cask install hammerspoon
brew cask install visual-studio-code
brew cask install sourcetree
brew cask install gas-mask # host管理
brew cask install shadowsocksx-ng
# brew cask install docker
# brew cask install alfred
# brew cask install charles
# apps
brew cask install google-chrome
brew cask install evernote
brew cask install appcleaner
brew cask install android-file-transfer
brew cask install baiduinput
brew cask install qq
brew cask install youdaodict # 有道词典

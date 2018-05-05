# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew tap caskroom/cask

# homebrew cask apps
# apps
brew cask install google-chrome
brew cask install evernote
brew cask install appcleaner
brew cask install android-file-transfer
brew cask install baiduinput
brew cask install qq
brew cask install youdaodict # 有道词典
# develop
brew install zsh zsh-completions
brew cask install iterm2
brew cask install karabiner-elements
brew cask install hammerspoon
brew cask install visual-studio-code
brew cask install sourcetree
brew cask install gas-mask # host管理
brew cask install docker
# brew cask install alfred
# brew cask install charles

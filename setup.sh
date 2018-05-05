sudo -v
# Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# homebrew
./brew.sh
# don't know how to install '*.app' through command lint
# open baiduinput folder for now
open /usr/local/Caskroom/baiduinput/latest
# install&config karabiner-elements
./karabiner.sh
# install&config oh-my-zsh
./oh-my-zsh.sh
# install node with nvm
./nodejs.sh
# vim config
./vim.sh
# sync macconfig
./mac-config.sh

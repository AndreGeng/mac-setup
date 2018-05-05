sudo -v
# Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# homebrew
./brew.sh
# install&config karabiner-elements
./karabiner.sh
# install&config oh-my-zsh
./oh-my-zsh.sh
# install node with nvm
./nodejs.sh
# sync macconfig
./mac-config.sh

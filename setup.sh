#!/usr/bin/env bash
BASE_DIR=$(dirname "$0")
for f in $BASE_DIR/utils/*.sh; do
  source $f
done
# restore mac config
./sync.sh

# install&config oh-my-zsh
./zsh.sh
# vim config
./vim.sh
# tmux config
./tmux.sh
# install node with mise
./nodejs.sh
# homebrew
./brew.sh

# don't know how to install '*.app' through command lint
# open baiduinput folder for now
open /usr/local/Caskroom/baiduinput/latest
# install&config karabiner-elements
./karabiner.sh
log 'mac setup completed' $GREEN

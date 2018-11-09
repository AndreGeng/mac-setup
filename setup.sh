#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done
# restore mac config
./sync.sh
# install&config oh-my-zsh
./oh-my-zsh.sh
# vim config
./vim.sh
# tmux config
./tmux.sh
# install node with nvm
./nodejs.sh
# homebrew
./brew.sh
# alacrity
./alacrity.sh
# don't know how to install '*.app' through command lint
# open baiduinput folder for now
open /usr/local/Caskroom/baiduinput/latest
# install&config karabiner-elements
./karabiner.sh

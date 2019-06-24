#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done
base_dir=$(dirname "$0")
log_dir=$base_dir/logs
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
# alacrity
./alacrity.sh
# homebrew
./brew.sh

# don't know how to install '*.app' through command lint
# open baiduinput folder for now
open /usr/local/Caskroom/baiduinput/latest
# install&config karabiner-elements
./karabiner.sh
log 'mac setup completed' $Green

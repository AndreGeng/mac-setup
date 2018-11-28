#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done

# install realpath util
brewInstallIfNotExists coreutils

rm -rf ~/.config/alacritty
rm -rf ~/.config/karabiner
rm -rf ~/.config/nvim
rm -rf ~/.config/tmuxinator
rm -rf ~/.hammerspoon
rm -f ~/.zshrc
rm -f ~/.tmux.conf
rm -f ~/.ackrc
ln -s $(realpath $(dirname "$0"))/mac-config/alacritty ~/.config
ln -s $(realpath $(dirname "$0"))/mac-config/karabiner ~/.config
ln -s $(realpath $(dirname "$0"))/mac-config/nvim ~/.config
ln -s $(realpath $(dirname "$0"))/mac-config/tmuxinator ~/.config
ln -s $(realpath $(dirname "$0"))/mac-config/.hammerspoon ~
ln -s $(realpath $(dirname "$0"))/mac-config/.zshrc ~
ln -s $(realpath $(dirname "$0"))/mac-config/.tmux.conf ~
ln -s $(realpath $(dirname "$0"))/mac-config/.ackrc ~

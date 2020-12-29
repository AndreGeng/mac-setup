#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

mkdir -p ~/.config
log $(realpath_osx $(dirname "$0"))
mkdir -p ~/fzf-addons && ln -sf $(realpath_osx $(dirname "$0"))/mac-config/fzf-git/fzf-git.sh ~/fzf-addons/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/alacritty ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/karabiner ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/nvim ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/tmuxinator ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.hammerspoon ~/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.zshrc ~/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.tmux.conf ~/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.agignore ~/

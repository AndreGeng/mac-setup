#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

mkdir -p ~/.config
log $(realpath_osx $(dirname "$0"))
mkdir -p ~/fzf-addons && ln -sf $(realpath_osx $(dirname "$0"))/config/fzf-git/fzf-git.sh ~/fzf-addons/
ln -sf $(realpath_osx $(dirname "$0"))/config/alacritty ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/config/karabiner ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/config/ghostty ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/config/ranger ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/config/nvim ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/config/tmuxinator ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/config/.hammerspoon ~/
ln -sf $(realpath_osx $(dirname "$0"))/config/.zsh-utils ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/config/yabai ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/config/.zshrc ~/
ln -sf $(realpath_osx $(dirname "$0"))/config/.p10k.zsh ~/
ln -sf $(realpath_osx $(dirname "$0"))/config/.tmux.conf ~/
ln -sf $(realpath_osx $(dirname "$0"))/config/.agignore ~/
ln -sf $(realpath_osx $(dirname "$0"))/config/lazygit/config.yml ~/Library/Application\ Support/jesseduffield/lazygit/

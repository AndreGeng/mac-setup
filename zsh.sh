#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

# download .zshrc
log 'linking .zshrc start' $GREEN
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.zsh-utils ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.zshrc ~
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.p10k.zsh ~/
log 'linking .zshrc done' $GREEN

brewI zsh
brewI zsh-completions
brewI yarn
brewI svn
# install zinit
log "installing zinit" $GREEN
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

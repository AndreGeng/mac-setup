#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

# download .zshrc
log 'linking .zshrc start' $GREEN
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.zsh-utils ~/.config/
ln -sf $(realpath_osx $(dirname "$0"))/mac-config/.zshrc ~
log 'linking .zshrc done' $GREEN

brewI zsh
brewI zsh-completions
brewI yarn
# install zinit
log "installing zinit" $GREEN
sh -c "$(curl -x http://localhost:1087 -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

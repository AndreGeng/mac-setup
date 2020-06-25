#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

# install realpath util
brewInstallIfNotExists coreutils

# download .zshrc
log 'linking .zshrc' $GREEN
ln -sf $(realpath $(dirname "$0"))/mac-config/.zshrc ~

brewInstallIfNotExists zsh
brewInstallIfNotExists zsh-completions
brewInstallIfNotExists yarn
# install oh-my-zsh
log "installing zinit" $GREEN
sh -c "$(curl -x http://localhost:1087 -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

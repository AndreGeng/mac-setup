#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done

# install realpath util
brewInstallIfNotExists coreutils

# download .zshrc
log 'linking .zshrc' $Green
ln -sf $(realpath $(dirname "$0"))/mac-config/.zshrc ~

brewInstallIfNotExists zsh
brewInstallIfNotExists zsh-completions
brewInstallIfNotExists autojump
brewInstallIfNotExists yarn --without-node
# install oh-my-zsh
log "installing oh-my-zsh" $Green
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# // 安装zsh-syntax-highlighting插件
log 'installing zsh-syntax-highlighting' $Green
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done


brewInstallIfNotExists neovim
brewInstallIfNotExists fd
brewInstallIfNotExists ack
brewInstallIfNotExists openssl
brewInstallIfNotExists xz

log 'install vim-plug' $Green
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# install python3 and neovim python3 provider
log 'install pyenv' $Green
if test ! "$(which pyenv)"; then
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | zsh
fi

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

unset ALL_PROXY
if test ! "$(pyenv versions | grep 'neovim2')"; then
    yes | pyenv install 2.7.11
    pyenv virtualenv -f 2.7.11 neovim2
fi
if test ! "$(pyenv versions | grep 'neovim3')"; then
    yes | pyenv install 3.6.4
    pyenv virtualenv -f 3.6.4 neovim3
fi

pyenv activate neovim2
yes | pip install pynvim
pyenv deactivate neovim2

pyenv activate neovim3
yes | pip install pynvim
pyenv deactivate neovim2

# download nvim config
cp -R $(dirname "$0")/mac-config/nvim ~/.config

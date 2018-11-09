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
log 'install neovim python provider' $Green
if test ! $(exists pyenv); then
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | zsh
fi
if test ! $(pyenv versions | grep '2.7.11$'); then
    pyenv install 2.7.11
fi
if test ! $(pyenv versions | grep '3.6.4$'); then
    pyenv install 3.6.4
fi
if test ! $(pyenv versions | grep '^\s*neovim2'); then
    pyenv virtualenv 2.7.11 neovim2
fi
if test ! $(pyenv versions | grep '^\s*neovim3'); then
    pyenv virtualenv 3.6.4 neovim3
fi
export PYENV_VERSION=2.7.11
CPPFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \ 
pip install neovim
pyenv which python  # Note the path
unset PYENV_VERSION

export PYENV_VERSION=3.6.4
CPPFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \ 
pip install neovim
pyenv which python  # Note the path
unset PYENV_VERSION

# download nvim config
cp -R $(dirname "$0")/mac-config/nvim ~/.config

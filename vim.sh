#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done

brewInstallIfNotExists neovim
brewInstallIfNotExists fd
brewInstallIfNotExists ack

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

pyenv activate neovim2
pip install neovim
pyenv which python  # Note the path

pyenv activate neovim3
pip install neovim
pyenv which python  # Note the path

# download nvim config
curl -o ~/.config/nvim/init.vim https://raw.githubusercontent.com/AndreGeng/MacConfig/master/nvim/init.vim

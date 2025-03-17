#!/usr/bin/env bash
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

brewI neovim
brewI fd
brewI openssl
brewI xz
brewI the_silver_searcher
brewI ripgrep
brewI ack
brewI font-hack-nerd-font
brewI lua-language-server
brewI fzf
brew tap homebrew/cask-fonts

log 'install vim-plug' $GREEN
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# install python3 and neovim python3 provider
log 'install pyenv' $GREEN
if test ! "$(which pyenv)"; then
  curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | zsh
fi

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

unset ALL_PROXY
if test ! "$(pyenv versions | grep 'neovim2')"; then
  yes | (
    v=2.7.18
    mkdir -p ~/.pyenv/cache && cd $_ && curl -L -O "https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz"
    pyenv install "$v"
  )
  pyenv virtualenv -f 2.7.18 neovim2
fi
if test ! "$(pyenv versions | grep 'neovim3')"; then
  yes | (
    v=3.9.1
    mkdir -p ~/.pyenv/cache && cd $_ && curl -L -O "https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz"
    pyenv install "$v"
  )
  pyenv virtualenv -f 3.9.1 neovim3
fi

pyenv activate neovim2
yes | pip install pynvim
pyenv deactivate neovim2

pyenv activate neovim3
yes | pip install pynvim
yes | pip install neovim-remote
pyenv deactivate neovim3

# download nvim config
cp -R $(dirname "$0")/mac-config/nvim ~/.config

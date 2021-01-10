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
brew tap homebrew/cask-fonts
brewI font-hack-nerd-font

log 'install vim-plug' $GREEN
curl -x http://localhost:1087 -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
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
  yes | (v=2.7.18;mkdir -p ~/.pyenv/cache && cd $_ && curl -L -O "https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz";pyenv install "$v")
  pyenv virtualenv -f 2.7.18 neovim2
fi
if test ! "$(pyenv versions | grep 'neovim3')"; then
  yes | (v=3.8.5;mkdir -p ~/.pyenv/cache && cd $_ && curl -L -O "https://npm.taobao.org/mirrors/python/$v/Python-$v.tar.xz";pyenv install "$v")
  pyenv virtualenv -f 3.8.5 neovim3
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

# install Xkbswitch
mkdir -p ~/Documents/playground && cd $_ && git clone https://github.com/myshov/xkbswitch-macosx.git
cp ~/Documents/playground/xkbswitch-macosx/bin/xkbswitch /usr/local/bin
mkdir -p ~/Documents/playground && cd $_ && git clone https://github.com/myshov/libxkbswitch-macosx.git
cp ~/Documents/playground/libxkbswitch-macosx/bin/libxkbswitch.dylib /usr/local/lib

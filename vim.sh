# setup amix/vimrc
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
# install vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# copy vim conifg
curl -L https://gist.github.com/AndreGeng/5bcf9381cb4080deae401941b96f145e/raw > ~/.vimrc
# install python3 and neovim python3 provider
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | zsh
source ~/.zshrc
pyenv install 2.7.11
pyenv install 3.6.4
source ~/.zshrc
pyenv virtualenv 2.7.11 neovim2
pyenv virtualenv 3.6.4 neovim3

pyenv activate neovim2
pip install neovim
pyenv which python  # Note the path

pyenv activate neovim3
pip install neovim
pyenv which python  # Note the path

let g:python_host_prog = '/full/path/to/neovim2/bin/python'
let g:python3_host_prog = '/full/path/to/neovim3/bin/python'


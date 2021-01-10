#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done
# install node with nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | zsh
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME}/.nvm"
echo $NVM_DIR
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# source ~/.zshrc
nvm install --lts
# 采用当前环境下的node(最新的lts版本)为default版本
nvm alias default node
npm install -g js-beautify # vim autoformat json
npm install -g prettier # also for code format
npm install -g typescript
npm install -g javascript-typescript-langserver
sudo ln -s "$(which node)" /usr/local/bin/node

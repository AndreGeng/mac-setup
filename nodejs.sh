# install node with nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | zsh
source ~/.zshrc
nvm install --lts
nvm alias default lts/*
npm install -g js-beautify // vim autoformat json
npm install -g typescript
sudo ln -s "$(which node)" /usr/local/bin/node

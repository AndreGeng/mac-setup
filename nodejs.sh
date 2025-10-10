#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

brewI mise

# 确保mise已加载
eval "$(mise activate zsh)"

mise use -g node@lts
npm install -g js-beautify # vim autoformat json
npm install -g prettier    # also for code format
npm install -g typescript
npm install -g javascript-typescript-langserver
npm install -g bash-language-server
npm install -g typescript-language-server
npm install -g @olrtg/emmet-language-server
npm install -g eslint_d
npm install -g vscode-langservers-extracted
sudo ln -s "$(which node)" /usr/local/bin/node

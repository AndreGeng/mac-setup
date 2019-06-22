#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done
base_dir=$(dirname "$0")
log_dir=$base_dir/logs
# restore mac config
./sync.sh

echo "$PIDS"
trap 'kill $PIDS; exit' SIGINT
# install&config oh-my-zsh
./oh-my-zsh.sh >$log_dir/oh-my-zsh.out 2>&1 &
PIDS+=$!
# vim config
./vim.sh >$log_dir/vim.out 2>&1 &
PIDS+=" $!"
# tmux config
./tmux.sh >$log_dir/tmux.out 2>&1 &
PIDS+=" $!"
# install node with nvm
./nodejs.sh >$log_dir/node.out 2>&1 &
PIDS+=" $!"
# homebrew
./brew.sh >$log_dir/brew.out 2>&1 &
PIDS+=" $!"
# alacrity
./alacrity.sh >$log_dir/alacrity.out 2>&1 &
PIDS+=" $!"

wait $PIDS
# don't know how to install '*.app' through command lint
# open baiduinput folder for now
open /usr/local/Caskroom/baiduinput/latest
# install&config karabiner-elements
./karabiner.sh
log 'mac setup completed' $Green

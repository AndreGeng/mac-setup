#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done

brewInstallIfNotExists tmux

curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install ruby --latest
rvm --default use ruby

brewInstallIfNotExists reattach-to-user-namespace
sudo gem install tmuxinator

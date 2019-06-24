#!/bin/bash
base_dir=$(dirname "$0")
source $base_dir/utils/2.log.sh
source $base_dir/utils/install_homebrew_if_needed.sh
brew cask install shadowsocksx-ng --force


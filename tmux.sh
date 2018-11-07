#!/bin/bash
source $(dirname "$0")/utils/install_homebrew_if_needed.sh
source $(dirname "$0")/utils/brew_package_exists.sh

brewInstallIfNotExists tmux
# TODO: 这里这么写有问题
brewInstallIfNotExists reattach-to-user-namespace --with-wrap-pbcopy-and-pbpaste
#!/bin/bash
# Check to if Homebrew is installed, and install it if it is not

source $(dirname "$0")/utils/command_exists.sh
if exists brew; then
    log "homebrew already exists!" $Green
else
    log "Installing Homebrew Now"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null
fi
export HOMEBREW_FORCE_BREWED_CURL=1

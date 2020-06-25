#!/usr/bin/env bash
# Check to if Homebrew is installed, and install it if it is not

source $(dirname "$0")/utils/command_exists.sh
if exists brew; then
  log "homebrew already exists!" $GREEN
else
  log "Installing Homebrew Now"
  /bin/bash -c "$(curl -x http://localhost:1087 -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi
export HOMEBREW_FORCE_BREWED_CURL=1

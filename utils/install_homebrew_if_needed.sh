#!/usr/bin/env bash
# Check to if Homebrew is installed, and install it if it is not

source $(dirname "$0")/utils/command_exists.sh
if exists brew; then
  log "homebrew already exists!" $GREEN
else
  log "Installing Homebrew Now"
  /bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
fi
export HOMEBREW_FORCE_BREWED_CURL=1

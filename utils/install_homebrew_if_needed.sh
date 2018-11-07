#!/bin/bash
# Check to if Homebrew is installed, and install it if it is not

source $(dirname "$0")/utils/command_exists.sh
if exists brew; then
    echo 'homebrew already exists!'
else
    echo 'Installing Homebrew Now'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null
fi
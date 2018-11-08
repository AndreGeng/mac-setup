#!/bin/bash
source $(dirname "$0")/utils/command_exists.sh

brewInstallIfNotExists()
{
    if brew ls --versions "$1" > /dev/null; then
    # The package is installed
        log "$1 already exist!" $Green 
    else
    # The package is not installed
        log "Installing $1 now!" $Green
        brew install "$@"
    fi
}
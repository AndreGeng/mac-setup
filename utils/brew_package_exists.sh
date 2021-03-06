#!/usr/bin/env bash
source $(dirname "$0")/utils/command_exists.sh

brewI() {
  if brew ls --versions "$1" >/dev/null; then
    # The package is installed
    log "$1 already exist!" $GREEN
  else
    # The package is not installed
    log "Installing $1 now!" $GREEN
    brew install "$@"
  fi
}

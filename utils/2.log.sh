#!/usr/bin/env bash
# $1: message to echo, $2: color var
log() {
  echo -e "${2}$1${COLOR_OFF}"
}

#!/usr/bin/env bash
sudo -v
# Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
while true; do
  sudo -n true
  sleep 30
  kill -0 "$$" || exit
done 2>/dev/null &

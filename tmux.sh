#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done

brewI tmux
brewI mise
brewI reattach-to-user-namespace
brewI tmuxinator

mise use ruby

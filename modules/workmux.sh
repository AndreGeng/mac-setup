#!/usr/bin/env bash
#
# Workmux 模块：安装 workmux（git worktree + tmux 并行开发管理器）
#

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for f in "$SCRIPT_ROOT/../utils"/*.sh; do
  source "$f"
done

if command_exists "workmux"; then
  log "workmux is already installed" "$GREEN"
  log "Current version: $(workmux --version 2>/dev/null || echo 'unknown')" "$CYAN"
else
  log "Installing workmux..." "$YELLOW"

  curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash

  if command_exists "workmux"; then
    log "workmux installed successfully!" "$GREEN"
  else
    log "workmux installation failed" "$RED"
    exit 1
  fi
fi

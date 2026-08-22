#!/usr/bin/env bash
#
# Workmux 模块：安装 workmux（git worktree + tmux 并行开发管理器）
#

WORKMUX_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$WORKMUX_MODULE_DIR/../lib/utils.sh"

if command -v workmux &>/dev/null; then
  log "workmux is already installed" "$GREEN"
  log "Current version: $(workmux --version 2>/dev/null || echo 'unknown')" "$CYAN"
else
  log "Installing workmux..." "$YELLOW"

  curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash

  if command -v workmux &>/dev/null; then
    log "workmux installed successfully!" "$GREEN"
  else
    log "workmux installation failed" "$RED"
    exit 1
  fi
fi

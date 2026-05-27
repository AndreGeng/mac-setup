#!/usr/bin/env bash
#
# OpenCode 模块：安装 OpenCode CLI 并配置
#

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for f in "$SCRIPT_ROOT/../utils"/*.sh; do
  source "$f"
done

if command_exists "opencode"; then
  log "OpenCode is already installed" "$GREEN"
  log "Current version: $(opencode --version 2>/dev/null || echo 'unknown')" "$CYAN"
else
  log "Installing OpenCode..." "$YELLOW"

  if command_exists "brew"; then
    log "Installing OpenCode via Homebrew..." "$YELLOW"
    brew install anomalyco/tap/opencode || {
      log "Homebrew installation failed, trying npm..." "$YELLOW"
      if command_exists "npm"; then
        npm install -g opencode-ai
      else
        log "Neither Homebrew nor npm found." "$RED"
        exit 1
      fi
    }
  elif command_exists "npm"; then
    log "Installing OpenCode via npm..." "$YELLOW"
    npm install -g opencode-ai
  else
    log "Neither Homebrew nor npm found." "$RED"
    exit 1
  fi

  if command_exists "opencode"; then
    log "OpenCode installed successfully!" "$GREEN"
  else
    log "OpenCode installation failed" "$RED"
    exit 1
  fi
fi

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

log "Setting up OpenCode configuration..." "$YELLOW"

cp "$SCRIPT_ROOT/../config/opencode/opencode.json" "$OPENCODE_CONFIG_DIR/opencode.json"

add_opencode_alias() {
  local config_file="$1"
  if [[ -f "$config_file" ]]; then
    if ! grep -q "alias oc=" "$config_file" 2>/dev/null; then
      cat >>"$config_file" <<'ALIAS'

# OpenCode AI Coding Agent Aliases
alias oc="opencode"
alias oc-init="opencode && /init"
alias oc-share="opencode && /share"
ALIAS
      log "Added OpenCode aliases to $config_file" "$GREEN"
    else
      log "OpenCode aliases already exist in $config_file" "$CYAN"
    fi
  fi
}

add_opencode_alias "$HOME/.zshrc"
add_opencode_alias "$HOME/.bashrc"
add_opencode_alias "$HOME/.bash_profile"

if command_exists "npm"; then
  if ! command_exists "bash-language-server"; then
    log "Installing bash-language-server..." "$YELLOW"
    npm install -g bash-language-server
  fi
  if ! command_exists "yaml-language-server"; then
    log "Installing yaml-language-server..." "$YELLOW"
    npm install -g yaml-language-server
  fi
fi

log "OpenCode module completed!" "$GREEN"

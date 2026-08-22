#!/usr/bin/env bash
#
# OpenCode 模块：安装 OpenCode CLI 并配置
#

OPENCODE_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 只加载零副作用函数库；禁止通配 source 旧 utils（其中包含安装和 sudo 顶层代码）。
source "$OPENCODE_MODULE_DIR/../lib/utils.sh"

# A standalone opencode module must discover the repository-pinned npm runtime even when
# the caller's non-interactive shell has not evaluated `mise activate`.
if ! command -v npm &>/dev/null; then
  activate_pinned_node_path "$OPENCODE_MODULE_DIR/.." >/dev/null 2>&1 || true
fi

if command -v opencode &>/dev/null; then
  log "OpenCode is already installed" "$GREEN"
  log "Current version: $(opencode --version 2>/dev/null || echo 'unknown')" "$CYAN"
else
  log "Installing OpenCode..." "$YELLOW"

  if command -v brew &>/dev/null; then
    log "Installing OpenCode via Homebrew..." "$YELLOW"
    brew install anomalyco/tap/opencode || {
      log "Homebrew installation failed, trying npm..." "$YELLOW"
      if command -v npm &>/dev/null; then
        npm install -g opencode-ai
      else
        log "Neither Homebrew nor npm found." "$RED"
        exit 1
      fi
    }
  elif command -v npm &>/dev/null; then
    log "Installing OpenCode via npm..." "$YELLOW"
    npm install -g opencode-ai
  else
    log "Neither Homebrew nor npm found." "$RED"
    exit 1
  fi

  if command -v opencode &>/dev/null; then
    log "OpenCode installed successfully!" "$GREEN"
  else
    log "OpenCode installation failed" "$RED"
    exit 1
  fi
fi

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

log "Setting up OpenCode configuration..." "$YELLOW"

AGENTS_OWNS_CONFIG=false
for selected_module in "${MODULES[@]:-}"; do
  if [[ "$selected_module" == "agents" ]]; then
    AGENTS_OWNS_CONFIG=true
    break
  fi
done

if [[ "$AGENTS_OWNS_CONFIG" == "true" ]]; then
  log "Agent 模块将管理 OpenCode 配置" "$CYAN"
elif [[ ! -e "$OPENCODE_CONFIG_DIR/opencode.json" ]]; then
  cp "$OPENCODE_MODULE_DIR/../config/opencode/opencode.json" \
    "$OPENCODE_CONFIG_DIR/opencode.json"
  log "OpenCode 配置已安装" "$GREEN"
else
  log "保留现有 OpenCode 配置" "$YELLOW"
fi

add_opencode_alias() {
  local config_file="$1"
  if [[ -f "$config_file" ]]; then
    if ! grep -q "alias oc=" "$config_file" 2>/dev/null; then
      cat >>"$config_file" <<'ALIAS'

# OpenCode AI Coding Agent Aliases
alias oc="opencode"
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

if command -v npm &>/dev/null; then
  if ! command -v bash-language-server &>/dev/null; then
    log "Installing bash-language-server..." "$YELLOW"
    npm install -g bash-language-server
  fi
  if ! command -v yaml-language-server &>/dev/null; then
    log "Installing yaml-language-server..." "$YELLOW"
    npm install -g yaml-language-server
  fi
fi

log "OpenCode module completed!" "$GREEN"

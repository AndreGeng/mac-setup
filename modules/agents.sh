#!/usr/bin/env bash
set -e

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_ROOT/.." && pwd)"

source "$REPO_ROOT/lib/utils.sh"

install_agent_template() {
  local src="$1"
  local dest="$2"
  local backup

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "${MAC_SETUP_FORCE_AGENT_CONFIG:-0}" != "1" ]]; then
      log "保留现有 Agent 配置: $dest" "$YELLOW"
      return
    fi
    backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    while [[ -e "$backup" || -L "$backup" ]]; do
      backup="${backup}.1"
    done
    mv "$dest" "$backup"
  fi

  cp "$src" "$dest"
  log "安装 Agent 配置: $dest" "$GREEN"
}

install_managed_link() {
  local src="$1"
  local dest="$2"
  symlink_config "$src" "$dest"
}

render_pi_models() {
  local dest="$HOME/.pi/agent/models.json"

  if [[ -z "${MIFY_API_URL:-}" || -z "${MIFY_API_ANTHROPIC_URL:-}" ]]; then
    log "未设置 MIFY API URL，跳过 Pi 自定义模型配置" "$YELLOW"
    return
  fi
  if ! command -v jq >/dev/null 2>&1; then
    log "未安装 jq，跳过 Pi 自定义模型配置" "$YELLOW"
    return
  fi
  if [[ -e "$dest" && "${MAC_SETUP_FORCE_AGENT_CONFIG:-0}" != "1" ]]; then
    log "保留现有 Agent 配置: $dest" "$YELLOW"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  jq \
    --arg openai_url "$MIFY_API_URL" \
    --arg anthropic_url "$MIFY_API_ANTHROPIC_URL" \
    '.providers.openai.baseUrl = $openai_url | .providers.anthropic.baseUrl = $anthropic_url' \
    "$REPO_ROOT/config/pi/models.template.json" >"$tmp"
  install_agent_template "$tmp" "$dest"
  rm -f "$tmp"
  trap - RETURN
}

install_agent_template "$REPO_ROOT/config/agents/env.example" "$HOME/.config/agent-env.example"

install_agent_template "$REPO_ROOT/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
install_agent_template "$REPO_ROOT/config/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
install_agent_template "$REPO_ROOT/config/opencode/dcp.jsonc" "$HOME/.config/opencode/dcp.jsonc"
install_agent_template "$REPO_ROOT/config/opencode/tui.json" "$HOME/.config/opencode/tui.json"
install_managed_link "$REPO_ROOT/config/opencode/rules/context7.md" "$HOME/.config/opencode/rules/context7.md"
install_managed_link "$REPO_ROOT/config/opencode/plugins/workmux-status.ts" "$HOME/.config/opencode/plugins/workmux-status.ts"

install_agent_template "$REPO_ROOT/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
install_agent_template "$REPO_ROOT/config/claude/settings.json" "$HOME/.claude/settings.json"

install_agent_template "$REPO_ROOT/config/codex/config.toml" "$HOME/.codex/config.toml"
install_agent_template "$REPO_ROOT/config/codex/hooks.json" "$HOME/.codex/hooks.json"

install_agent_template "$REPO_ROOT/config/pi/settings.json" "$HOME/.pi/agent/settings.json"
render_pi_models
install_managed_link "$REPO_ROOT/config/pi/extensions/workmux-status.ts" "$HOME/.pi/agent/extensions/workmux-status.ts"

for skill in dispatch dispatch-team; do
  src="$REPO_ROOT/config/agents/skills/$skill"
  install_managed_link "$src" "$HOME/.agents/skills/$skill"
  install_managed_link "$src" "$HOME/.codex/skills/$skill"
  install_managed_link "$src" "$HOME/.pi/agent/skills/$skill"
done

log "Agent 配置安装完成；第三方 skill 按 config/agents/sources.tsv 重建" "$GREEN"

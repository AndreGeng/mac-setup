#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  bash "${BASH_SOURCE[0]}" --apply
  return $?
fi

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_ROOT/.." && pwd)"

source "$REPO_ROOT/lib/utils.sh"

MODE=""
TARGET="all"
FORCE="${MAC_SETUP_FORCE_AGENT_CONFIG:-0}"
REPAIR_LINKS=false
AUDIT_FAILURES=0
AUDIT_WARNINGS=0

usage() {
  cat <<'EOF'
Usage: agents.sh [--apply | --audit] [--only TARGET] [--force] [--repair-links]

Modes:
  --apply          Install missing templates and repair repository-managed links.
  --audit          Check installation, links, permissions, and sensitive config.

Options:
  --only TARGET    Limit work to shared, opencode, claude, codex, or pi.
  --force          Back up and replace mutable templates during --apply.
  --repair-links   Back up conflicting managed-link paths and recreate links.
  -h, --help       Show this help.

With no mode, --apply is used for backward compatibility. --force refuses to
back up a file that appears to contain a literal credential.
EOF
}

set_mode() {
  local requested="$1"

  if [[ -n "$MODE" && "$MODE" != "$requested" ]]; then
    printf '%s\n' 'Choose only one of --apply or --audit.' >&2
    exit 2
  fi
  MODE="$requested"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --apply)
    set_mode apply
    shift
    ;;
  --audit)
    set_mode audit
    shift
    ;;
  --only)
    [[ $# -ge 2 ]] || {
      printf '%s\n' '--only requires a target.' >&2
      exit 2
    }
    TARGET="$2"
    shift 2
    ;;
  --force)
    FORCE=1
    shift
    ;;
  --repair-links)
    REPAIR_LINKS=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    printf 'Unknown argument: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
  esac
done

MODE="${MODE:-apply}"
case "$TARGET" in
all | shared | opencode | claude | codex | pi) ;;
*)
  printf 'Unknown target: %s\n' "$TARGET" >&2
  exit 2
  ;;
esac

if [[ "$MODE" == "audit" && "$FORCE" == "1" ]]; then
  printf '%s\n' '--force is only valid with --apply.' >&2
  exit 2
fi
if [[ "$MODE" == "audit" && "$REPAIR_LINKS" == "true" ]]; then
  printf '%s\n' '--repair-links is only valid with --apply.' >&2
  exit 2
fi

selected() {
  [[ "$TARGET" == "all" || "$TARGET" == "$1" ]]
}

is_json_path() {
  [[ "$1" == *.json || "$1" == *.json.* || "$1" == *.jsonc || "$1" == *.jsonc.* ]]
}

is_toml_path() {
  [[ "$1" == *.toml || "$1" == *.toml.* ]]
}

text_has_literal_secret_assignment() {
  local path="$1"
  local line
  local key
  local value

  while IFS= read -r line; do
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    if [[ ! "$key" =~ ([Aa][Pp][Ii][_-]?[Kk][Ee][Yy]|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]|[Aa][Uu][Tt][Hh][Oo][Rr][Ii][Zz][Aa][Tt][Ii][Oo][Nn]) ]]; then
      continue
    fi
    value="${line#*=}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    case "$value" in
    "" | \$* | \{env:* | \{file:* | __*) ;;
    *) return 0 ;;
    esac
  done <"$path"
  return 1
}

validate_toml() {
  local path="$1"

  python3 - "$path" >/dev/null 2>&1 <<'PY'
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

with open(sys.argv[1], "rb") as config_file:
    tomllib.load(config_file)
PY
}

toml_parser_available() {
  python3 >/dev/null 2>&1 <<'PY'
try:
    import tomllib
except ModuleNotFoundError:
    import tomli
PY
}

toml_has_sensitive_value() {
  local path="$1"

  python3 - "$path" >/dev/null 2>&1 <<'PY'
import re
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

SENSITIVE_KEY = re.compile(r"api.?key|token|secret|password|authorization", re.I)
SAFE_PREFIXES = ("$", "{env:", "{file:", "__")

with open(sys.argv[1], "rb") as config_file:
    config = tomllib.load(config_file)

def contains_secret(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if SENSITIVE_KEY.search(str(key)) and isinstance(child, str):
                if child and not child.startswith(SAFE_PREFIXES):
                    return True
            if contains_secret(child):
                return True
    elif isinstance(value, list):
        return any(contains_secret(child) for child in value)
    return False

sys.exit(0 if contains_secret(config) else 1)
PY
}

config_has_sensitive_value() {
  local path="$1"
  local url

  [[ -f "$path" ]] || return 1

  if LC_ALL=C grep -Eq 'mcp__[A-Za-z0-9_-]{20,}' "$path"; then
    return 0
  fi
  if LC_ALL=C grep -Eiq 'https?://[^"[:space:]]*(token|key|access_token|bearer)=' "$path"; then
    return 0
  fi

  if is_json_path "$path" && jq -e '
    [
      .. | objects | to_entries[]
      | select(.key | test("api.?key|token|secret|password|authorization"; "i"))
      | .value
      | select(
          type == "string" and length > 0
          and (startswith("{env:") | not)
          and (startswith("{file:") | not)
          and (startswith("$") | not)
        )
    ] | length > 0
  ' "$path" >/dev/null 2>&1; then
    return 0
  fi
  if is_toml_path "$path" && toml_has_sensitive_value "$path"; then
    return 0
  fi
  if ! is_json_path "$path" && ! is_toml_path "$path" &&
    text_has_literal_secret_assignment "$path"; then
    return 0
  fi

  case "$path" in
  */.config/agent-env.example*)
    LC_ALL=C grep -Eq '^[A-Z][A-Z0-9_]*=[^[:space:]]+' "$path" && return 0
    ;;
  */.claude/settings.json*)
    LC_ALL=C grep -Eq '"ANTHROPIC_API_KEY"[[:space:]]*:' "$path" && return 0
    ;;
  */.config/opencode/opencode.json*)
    if command -v jq >/dev/null 2>&1; then
      url="$(jq -r '.mcp["feishu-mcp"].url // empty' "$path" 2>/dev/null || true)"
      if [[ -n "$url" && "$url" != \{env:* && "$url" != \{file:* ]]; then
        return 0
      fi
    fi
    ;;
  esac
  return 1
}

scan_config_safely() {
  local path="$1"

  [[ -f "$path" ]] || return 0
  if is_json_path "$path"; then
    command -v jq >/dev/null 2>&1 || return 2
    jq -e . "$path" >/dev/null 2>&1 || return 3
  elif is_toml_path "$path"; then
    command -v python3 >/dev/null 2>&1 || return 2
    toml_parser_available || return 2
    validate_toml "$path" || return 3
  fi
  config_has_sensitive_value "$path" && return 1
  return 0
}

report_unsafe_config() {
  local path="$1"
  local status="$2"

  case "$status" in
  1) log "ERROR sensitive-config $path" "$RED" ;;
  2) log "ERROR missing-parser $path" "$RED" ;;
  3) log "ERROR invalid-config $path" "$RED" ;;
  *) log "ERROR config-scan $path" "$RED" ;;
  esac
}

preflight_force() {
  local blocked=0
  local path
  local paths=()
  local status

  [[ "$FORCE" == "1" ]] || return 0
  selected shared && paths+=("$HOME/.config/agent-env.example")
  if selected opencode; then
    paths+=(
      "$HOME/.config/opencode/opencode.json"
      "$HOME/.config/opencode/AGENTS.md"
      "$HOME/.config/opencode/dcp.jsonc"
      "$HOME/.config/opencode/tui.json"
    )
  fi
  if selected claude; then
    paths+=("$HOME/.claude/CLAUDE.md" "$HOME/.claude/settings.json")
  fi
  if selected codex; then
    paths+=("$HOME/.codex/config.toml" "$HOME/.codex/hooks.json")
  fi
  if selected pi; then
    paths+=("$HOME/.pi/agent/settings.json" "$HOME/.pi/agent/models.json")
  fi

  for path in "${paths[@]}"; do
    if scan_config_safely "$path"; then
      continue
    else
      status=$?
      report_unsafe_config "$path" "$status"
      blocked=$((blocked + 1))
    fi
  done
  if ((blocked > 0)); then
    log "请先切换并撤销凭据，再执行 --force；未修改任何文件。" "$RED"
    return 1
  fi
}

install_agent_template() {
  local src="$1"
  local dest="$2"
  local mode="${3:-600}"
  local backup=""
  local status
  local tmp

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$FORCE" != "1" ]]; then
      log "保留现有 Agent 配置: $dest" "$YELLOW"
      return
    fi
    if scan_config_safely "$dest"; then
      :
    else
      status=$?
      report_unsafe_config "$dest" "$status"
      log "请先修复配置或迁移凭据，再执行 --force；未创建备份。" "$RED"
      return 1
    fi
  fi

  tmp="$(mktemp "${dest}.tmp.XXXXXX")"
  if ! cp "$src" "$tmp" || ! chmod "$mode" "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    while [[ -e "$backup" || -L "$backup" ]]; do
      backup="${backup}.1"
    done
    mv "$dest" "$backup"
    if ! chmod 600 "$backup"; then
      mv "$backup" "$dest"
      rm -f "$tmp"
      return 1
    fi
  fi
  if ! mv "$tmp" "$dest"; then
    rm -f "$tmp"
    [[ -n "$backup" ]] && mv "$backup" "$dest"
    return 1
  fi
  log "安装 Agent 配置: $dest" "$GREEN"
}

install_managed_link() {
  local src="$1"
  local dest="$2"
  local backup=""
  local status
  local target=""

  if [[ -L "$dest" ]]; then
    target="$(readlink "$dest")"
    if [[ "$target" == "$src" && -e "$dest" ]]; then
      log "链接已是最新: $dest" "$GREEN"
      return
    fi
  elif [[ ! -e "$dest" ]]; then
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    log "链接: $dest -> $src" "$GREEN"
    return
  fi

  if [[ "$REPAIR_LINKS" != "true" ]]; then
    log "ERROR managed-link-conflict $dest" "$RED"
    log "检查该路径的所有者后，使用 --repair-links 显式修复。" "$RED"
    return 1
  fi
  if scan_config_safely "$dest"; then
    :
  else
    status=$?
    report_unsafe_config "$dest" "$status"
    return 1
  fi

  mkdir -p "$(dirname "$dest")"
  backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
  while [[ -e "$backup" || -L "$backup" ]]; do
    backup="${backup}.1"
  done
  mv "$dest" "$backup"
  if ! ln -s "$src" "$dest"; then
    mv "$backup" "$dest"
    return 1
  fi
  log "修复链接: $dest -> ${src}（原路径: ${backup}）" "$GREEN"
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
  if [[ -e "$dest" && "$FORCE" != "1" ]]; then
    log "保留现有 Agent 配置: $dest" "$YELLOW"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  jq \
    --arg openai_url "$MIFY_API_URL" \
    --arg anthropic_url "$MIFY_API_ANTHROPIC_URL" \
    '.providers["mify-openai"].baseUrl = $openai_url
      | .providers.anthropic.baseUrl = $anthropic_url' \
    "$REPO_ROOT/config/pi/models.template.json" >"$tmp"
  install_agent_template "$tmp" "$dest" 600
  rm -f "$tmp"
  trap - RETURN
}

apply_shared() {
  local skill

  install_agent_template \
    "$REPO_ROOT/config/agents/env.example" \
    "$HOME/.config/agent-env.example" 600

  for skill in dispatch dispatch-team; do
    install_managed_link \
      "$REPO_ROOT/config/agents/skills/$skill" \
      "$HOME/.agents/skills/$skill"
  done
}

apply_opencode() {
  install_agent_template \
    "$REPO_ROOT/config/opencode/opencode.json" \
    "$HOME/.config/opencode/opencode.json" 600
  install_agent_template \
    "$REPO_ROOT/config/opencode/AGENTS.md" \
    "$HOME/.config/opencode/AGENTS.md" 644
  install_agent_template \
    "$REPO_ROOT/config/opencode/dcp.jsonc" \
    "$HOME/.config/opencode/dcp.jsonc" 600
  install_agent_template \
    "$REPO_ROOT/config/opencode/tui.json" \
    "$HOME/.config/opencode/tui.json" 600
  install_managed_link \
    "$REPO_ROOT/config/opencode/rules/context7.md" \
    "$HOME/.config/opencode/rules/context7.md"
  install_managed_link \
    "$REPO_ROOT/config/opencode/plugins/workmux-status.ts" \
    "$HOME/.config/opencode/plugins/workmux-status.ts"
}

apply_claude() {
  install_agent_template \
    "$REPO_ROOT/config/claude/CLAUDE.md" \
    "$HOME/.claude/CLAUDE.md" 644
  install_agent_template \
    "$REPO_ROOT/config/claude/settings.json" \
    "$HOME/.claude/settings.json" 600
}

apply_codex() {
  install_agent_template \
    "$REPO_ROOT/config/codex/config.toml" \
    "$HOME/.codex/config.toml" 600
  install_agent_template \
    "$REPO_ROOT/config/codex/hooks.json" \
    "$HOME/.codex/hooks.json" 600
}

apply_pi() {
  install_agent_template \
    "$REPO_ROOT/config/pi/settings.json" \
    "$HOME/.pi/agent/settings.json" 600
  render_pi_models
  install_managed_link \
    "$REPO_ROOT/config/pi/extensions/workmux-status.ts" \
    "$HOME/.pi/agent/extensions/workmux-status.ts"
}

audit_ok() {
  printf 'AUDIT OK   %-18s %s\n' "$1" "$2"
}

audit_warn() {
  printf 'AUDIT WARN %-18s %s\n' "$1" "$2"
  AUDIT_WARNINGS=$((AUDIT_WARNINGS + 1))
}

audit_fail() {
  printf 'AUDIT FAIL %-18s %s\n' "$1" "$2" >&2
  AUDIT_FAILURES=$((AUDIT_FAILURES + 1))
}

audit_template() {
  local src="$1"
  local dest="$2"

  if [[ ! -f "$dest" ]]; then
    audit_fail missing-config "$dest"
    return
  fi
  if cmp -s "$src" "$dest"; then
    audit_ok config "$dest"
  else
    audit_warn template-drift "$dest"
  fi
}

audit_json() {
  local path="$1"

  [[ -f "$path" ]] || return 0
  if ! command -v jq >/dev/null 2>&1; then
    audit_fail missing-parser "$path"
    return 0
  fi
  if jq -e . "$path" >/dev/null 2>&1; then
    audit_ok valid-json "$path"
  else
    audit_fail invalid-json "$path"
  fi
}

audit_mode() {
  local path="$1"
  local mode
  local numeric
  local owner

  [[ -f "$path" ]] || return 0
  if mode="$(stat -f '%Lp' "$path" 2>/dev/null)"; then
    :
  elif mode="$(stat -c '%a' "$path" 2>/dev/null)"; then
    :
  else
    audit_warn file-mode-unknown "$path"
    return
  fi

  numeric=$((8#$mode))
  if ((numeric & 077)); then
    audit_fail file-mode "$path"
  else
    audit_ok file-mode "$path"
  fi
  if owner="$(stat -f '%u' "$path" 2>/dev/null)"; then
    :
  elif owner="$(stat -c '%u' "$path" 2>/dev/null)"; then
    :
  else
    audit_warn file-owner-unknown "$path"
    return
  fi
  if [[ "$owner" != "$(id -u)" || ! -r "$path" || ! -w "$path" ]]; then
    audit_fail file-owner "$path"
  else
    audit_ok file-owner "$path"
  fi
}

audit_sensitive() {
  local path="$1"
  local status

  [[ -f "$path" ]] || return 0
  if scan_config_safely "$path"; then
    audit_ok no-literal-secret "$path"
  else
    status=$?
    case "$status" in
    1) audit_fail sensitive-config "$path" ;;
    2) audit_fail missing-parser "$path" ;;
    3) audit_fail invalid-config "$path" ;;
    *) audit_fail config-scan "$path" ;;
    esac
  fi
}

audit_sensitive_backups() {
  local prefix="$1"
  local path
  local found=false

  shopt -s nullglob
  for path in "$prefix"*.bak*; do
    found=true
    audit_sensitive "$path"
    audit_mode "$path"
  done
  shopt -u nullglob
  [[ "$found" == "true" ]] || return 0
}

audit_managed_link() {
  local src="$1"
  local dest="$2"
  local target

  if [[ ! -L "$dest" ]]; then
    audit_fail managed-link "$dest"
    return
  fi
  target="$(readlink "$dest")"
  if [[ "$target" != "$src" || ! -e "$dest" ]]; then
    audit_fail managed-link "$dest"
    return
  fi
  audit_ok managed-link "$dest"
}

audit_shared() {
  local skill

  audit_template \
    "$REPO_ROOT/config/agents/env.example" \
    "$HOME/.config/agent-env.example"
  audit_mode "$HOME/.config/agent-env.example"
  audit_sensitive "$HOME/.config/agent-env.example"
  audit_sensitive_backups "$HOME/.config/agent-env.example"
  for skill in dispatch dispatch-team; do
    audit_managed_link \
      "$REPO_ROOT/config/agents/skills/$skill" \
      "$HOME/.agents/skills/$skill"
    [[ ! -e "$HOME/.codex/skills/$skill" && ! -L "$HOME/.codex/skills/$skill" ]] ||
      audit_warn duplicate-skill "$HOME/.codex/skills/$skill"
    [[ ! -e "$HOME/.pi/agent/skills/$skill" && ! -L "$HOME/.pi/agent/skills/$skill" ]] ||
      audit_warn duplicate-skill "$HOME/.pi/agent/skills/$skill"
  done
}

audit_opencode() {
  audit_template \
    "$REPO_ROOT/config/opencode/opencode.json" \
    "$HOME/.config/opencode/opencode.json"
  audit_template \
    "$REPO_ROOT/config/opencode/AGENTS.md" \
    "$HOME/.config/opencode/AGENTS.md"
  audit_template \
    "$REPO_ROOT/config/opencode/dcp.jsonc" \
    "$HOME/.config/opencode/dcp.jsonc"
  audit_template \
    "$REPO_ROOT/config/opencode/tui.json" \
    "$HOME/.config/opencode/tui.json"
  audit_json "$HOME/.config/opencode/opencode.json"
  audit_json "$HOME/.config/opencode/dcp.jsonc"
  audit_json "$HOME/.config/opencode/tui.json"
  audit_mode "$HOME/.config/opencode/opencode.json"
  audit_sensitive "$HOME/.config/opencode/opencode.json"
  audit_sensitive "$HOME/.config/opencode/AGENTS.md"
  audit_mode "$HOME/.config/opencode/dcp.jsonc"
  audit_sensitive "$HOME/.config/opencode/dcp.jsonc"
  audit_mode "$HOME/.config/opencode/tui.json"
  audit_sensitive "$HOME/.config/opencode/tui.json"
  audit_sensitive_backups "$HOME/.config/opencode/opencode.json"
  audit_sensitive_backups "$HOME/.config/opencode/AGENTS.md"
  audit_sensitive_backups "$HOME/.config/opencode/dcp.jsonc"
  audit_sensitive_backups "$HOME/.config/opencode/tui.json"
  audit_managed_link \
    "$REPO_ROOT/config/opencode/rules/context7.md" \
    "$HOME/.config/opencode/rules/context7.md"
  audit_managed_link \
    "$REPO_ROOT/config/opencode/plugins/workmux-status.ts" \
    "$HOME/.config/opencode/plugins/workmux-status.ts"
}

audit_claude() {
  audit_template \
    "$REPO_ROOT/config/claude/CLAUDE.md" \
    "$HOME/.claude/CLAUDE.md"
  audit_template \
    "$REPO_ROOT/config/claude/settings.json" \
    "$HOME/.claude/settings.json"
  audit_json "$HOME/.claude/settings.json"
  audit_mode "$HOME/.claude/settings.json"
  audit_sensitive "$HOME/.claude/CLAUDE.md"
  audit_sensitive "$HOME/.claude/settings.json"
  audit_sensitive_backups "$HOME/.claude/CLAUDE.md"
  audit_sensitive_backups "$HOME/.claude/settings.json"
}

audit_codex() {
  audit_template \
    "$REPO_ROOT/config/codex/config.toml" \
    "$HOME/.codex/config.toml"
  audit_template \
    "$REPO_ROOT/config/codex/hooks.json" \
    "$HOME/.codex/hooks.json"
  audit_json "$HOME/.codex/hooks.json"
  audit_mode "$HOME/.codex/config.toml"
  audit_sensitive "$HOME/.codex/config.toml"
  audit_mode "$HOME/.codex/hooks.json"
  audit_sensitive "$HOME/.codex/hooks.json"
  audit_sensitive_backups "$HOME/.codex/config.toml"
  audit_sensitive_backups "$HOME/.codex/hooks.json"
}

audit_pi() {
  audit_template \
    "$REPO_ROOT/config/pi/settings.json" \
    "$HOME/.pi/agent/settings.json"
  audit_json "$HOME/.pi/agent/settings.json"
  audit_mode "$HOME/.pi/agent/settings.json"
  audit_sensitive "$HOME/.pi/agent/settings.json"
  if [[ -f "$HOME/.pi/agent/models.json" ]]; then
    audit_json "$HOME/.pi/agent/models.json"
    audit_mode "$HOME/.pi/agent/models.json"
    audit_sensitive "$HOME/.pi/agent/models.json"
  fi
  audit_sensitive_backups "$HOME/.pi/agent/settings.json"
  audit_sensitive_backups "$HOME/.pi/agent/models.json"
  audit_managed_link \
    "$REPO_ROOT/config/pi/extensions/workmux-status.ts" \
    "$HOME/.pi/agent/extensions/workmux-status.ts"
}

if [[ "$MODE" == "apply" ]]; then
  preflight_force
  selected shared && apply_shared
  selected opencode && apply_opencode
  selected claude && apply_claude
  selected codex && apply_codex
  selected pi && apply_pi
  log "Agent 配置应用完成；运行 --audit 检查本机状态" "$GREEN"
  exit 0
fi

selected shared && audit_shared
selected opencode && audit_opencode
selected claude && audit_claude
selected codex && audit_codex
selected pi && audit_pi

printf 'Agent audit: %d failure(s), %d warning(s).\n' \
  "$AUDIT_FAILURES" "$AUDIT_WARNINGS"
((AUDIT_FAILURES == 0))

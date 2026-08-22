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
REME_VERSION="0.4.1.7"
REME_PYTHON="${MAC_SETUP_REME_PYTHON:-python3}"
REME_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/mac-setup/reme"
REME_VENV="$REME_ROOT/venv"
REME_VERSIONED_VENV="$REME_ROOT/venv-$REME_VERSION"
REME_CONFIG="$HOME/.config/reme/opencode-candidate.yaml"
REME_GLOBAL_CONFIG="$HOME/.config/reme/opencode-global.yaml"
REME_GLOBAL_WORKSPACE="$REME_ROOT/global"
REME_SERVICE_LAUNCHER="$HOME/.config/reme/start-global-service.sh"
REME_PROJECT_RUNNER="$HOME/.config/reme/run-project-capture.py"
REME_HOOK_STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/mac-setup/reme-hooks"

usage() {
  cat <<'EOF'
Usage: agents.sh [--apply | --audit | --remove-reme] [--only TARGET] [options]

Modes:
  --apply          Install missing templates and repair repository-managed links.
  --audit          Check installation, links, permissions, and sensitive config.
  --remove-reme    Remove repository-managed ReMe runtime files and links.

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
  --remove-reme)
    set_mode remove-reme
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

if [[ "$MODE" != "apply" && "$FORCE" == "1" ]]; then
  printf '%s\n' '--force is only valid with --apply.' >&2
  exit 2
fi
if [[ "$MODE" != "apply" && "$REPAIR_LINKS" == "true" ]]; then
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

reme_python_available() {
  if [[ "$REME_PYTHON" == */* ]]; then
    [[ -x "$REME_PYTHON" ]]
  else
    command -v "$REME_PYTHON" >/dev/null 2>&1
  fi
}

reme_installed_version() {
  [[ -x "$REME_VENV/bin/python" ]] || return 1
  "$REME_VENV/bin/python" -c \
    'from importlib.metadata import version; print(version("reme-ai"))' 2>/dev/null
}

reme_executable_ready() {
  local interpreter
  local shebang

  [[ -x "$REME_VENV/bin/reme" ]] || return 1
  IFS= read -r shebang <"$REME_VENV/bin/reme" || return 1
  [[ "$shebang" == '#!'* ]] || return 1
  interpreter="${shebang#\#!}"
  [[ "$interpreter" == "$REME_VERSIONED_VENV/bin/python" && -x "$interpreter" ]]
}

reme_layout_ready() {
  [[ -L "$REME_VENV" ]] &&
    [[ "$(readlink "$REME_VENV" 2>/dev/null || true)" == "$REME_VERSIONED_VENV" ]]
}

reme_config_has_sensitive_value() {
  local path="$1"

  "$REME_VENV/bin/python" - sensitive "$path" <<'PY'
import re
import sys

import yaml

sensitive_url = re.compile(r"https?://[^\s]*(?:token|key|access_token|bearer)=", re.I)
safe_prefixes = ("$", "{env:", "{file:", "__")

try:
    with open(sys.argv[2], encoding="utf-8") as source:
        config = yaml.safe_load(source)
except Exception:
    raise SystemExit(2)


def contains_secret(value):
    if isinstance(value, dict):
        for key, child in value.items():
            key_parts = set(filter(None, re.split(r"[^a-z0-9]+", str(key).lower())))
            sensitive_key = bool(
                key_parts & {"token", "secret", "password", "authorization"}
                or {"api", "key"} <= key_parts
                or {"access", "token"} <= key_parts
                or {"auth", "token"} <= key_parts
            )
            if sensitive_key and isinstance(child, str):
                text = child.strip().strip('"').strip("'")
                if text and not text.startswith(safe_prefixes):
                    return True
            if contains_secret(child):
                return True
    elif isinstance(value, list):
        return any(contains_secret(child) for child in value)
    elif isinstance(value, str):
        return bool(sensitive_url.search(value))
    return False


raise SystemExit(0 if contains_secret(config) else 1)
PY
}

generate_reme_config() {
  local tmp
  local status

  mkdir -p "$(dirname "$REME_CONFIG")"
  if [[ -f "$REME_CONFIG" ]]; then
    if reme_config_has_sensitive_value "$REME_CONFIG"; then
      report_unsafe_config "$REME_CONFIG" 1
      return 1
    else
      status=$?
      if [[ "$status" != "1" ]]; then
        report_unsafe_config "$REME_CONFIG" 3
        return 1
      fi
    fi
  fi

  tmp="$(mktemp "${REME_CONFIG}.tmp.XXXXXX")"
  if ! "$REME_VENV/bin/python" - generate "$tmp" <<'PY'; then
import sys
from importlib.resources import files

import yaml

allowed_jobs = {
    "auto_memory",
    "daily_list",
    "daily_write",
    "edit",
    "frontmatter_update",
    "move",
    "read",
    "write",
}
allowed_components = {
    "agent_wrapper": {"default"},
    "as_llm": {"default"},
    "file_graph": {"default"},
    "file_store": {"default"},
    "keyword_index": {"default"},
    "tokenizer": {"default"},
}

with files("reme.config").joinpath("default.yaml").open(encoding="utf-8") as source:
    config = yaml.safe_load(source)

missing_jobs = allowed_jobs - set(config["jobs"])
if missing_jobs:
    raise SystemExit(f"Pinned ReMe config is missing jobs: {sorted(missing_jobs)}")

config["service"] = {"backend": "cli", "web_enabled": False}
config["jobs"] = {name: config["jobs"][name] for name in sorted(allowed_jobs)}
config["components"] = {
    group: {
        name: config["components"][group][name]
        for name in sorted(names)
    }
    for group, names in allowed_components.items()
}
config["enable_logo"] = False
config["log_to_console"] = False
config["log_to_file"] = False

with open(sys.argv[2], "w", encoding="utf-8") as target:
    yaml.safe_dump(config, target, sort_keys=False)
PY
    rm -f "$tmp"
    return 1
  fi
  chmod 600 "$tmp"
  mv "$tmp" "$REME_CONFIG"
}

generate_reme_global_config() {
  local status
  local tmp

  mkdir -p "$(dirname "$REME_GLOBAL_CONFIG")" "$REME_GLOBAL_WORKSPACE"
  chmod 700 "$REME_GLOBAL_WORKSPACE"
  if [[ -f "$REME_GLOBAL_CONFIG" ]]; then
    if reme_config_has_sensitive_value "$REME_GLOBAL_CONFIG"; then
      report_unsafe_config "$REME_GLOBAL_CONFIG" 1
      return 1
    else
      status=$?
      if [[ "$status" != "1" ]]; then
        report_unsafe_config "$REME_GLOBAL_CONFIG" 3
        return 1
      fi
    fi
  fi

  tmp="$(mktemp "${REME_GLOBAL_CONFIG}.tmp.XXXXXX")"
  if ! "$REME_VENV/bin/python" - generate-global "$tmp" \
    "$REME_GLOBAL_WORKSPACE" <<'PY'; then
import sys
from importlib.resources import files

import yaml

served_jobs = {
    "app_config",
    "auto_memory",
    "health_check",
    "search",
    "version",
}
runtime_jobs = served_jobs | {
    "daily_list",
    "daily_write",
    "digest_watch_loop",
    "dream_cron",
    "edit",
    "frontmatter_update",
    "index_update_loop",
    "move",
    "optimize_index_cron",
    "read",
    "write",
}

with files("reme.config").joinpath("default.yaml").open(encoding="utf-8") as source:
    config = yaml.safe_load(source)

missing_jobs = runtime_jobs - set(config["jobs"])
if missing_jobs:
    raise SystemExit(f"Pinned ReMe config is missing global jobs: {sorted(missing_jobs)}")

config["workspace_dir"] = sys.argv[3]
config["service"] = {
    "backend": "http",
    "host": "127.0.0.1",
    "port": 2333,
    "web_enabled": False,
    "jobs": sorted(served_jobs),
}
config["jobs"] = {name: config["jobs"][name] for name in sorted(runtime_jobs)}
for name, job in config["jobs"].items():
    job["enable_serve"] = name in served_jobs
config["enable_logo"] = False
config["log_to_console"] = False
config["log_to_file"] = False

with open(sys.argv[2], "w", encoding="utf-8") as target:
    yaml.safe_dump(config, target, sort_keys=False)
PY
    rm -f "$tmp"
    return 1
  fi
  chmod 600 "$tmp"
  mv "$tmp" "$REME_GLOBAL_CONFIG"
}

install_reme() {
  local installed=""
  local link="${REME_VENV}.link.$$"
  local package="reme-ai[core]==${REME_VERSION}"

  stop_reme_global_service
  installed="$(reme_installed_version || true)"
  if [[ "$installed" != "$REME_VERSION" ]] || ! reme_layout_ready ||
    ! reme_executable_ready; then
    reme_python_available || {
      log "ERROR ReMe requires Python 3.11 or newer: $REME_PYTHON" "$RED"
      return 1
    }
    if ! "$REME_PYTHON" -c \
      'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)'; then
      log "ERROR ReMe requires Python 3.11 or newer: $REME_PYTHON" "$RED"
      return 1
    fi

    mkdir -p "$REME_ROOT"
    rm -rf "$REME_VERSIONED_VENV"
    if ! "$REME_PYTHON" -m venv "$REME_VERSIONED_VENV" ||
      ! "$REME_VERSIONED_VENV/bin/python" -m pip install \
        --disable-pip-version-check --no-input "$package"; then
      rm -rf "$REME_VERSIONED_VENV"
      return 1
    fi
    if [[ "$("$REME_VERSIONED_VENV/bin/python" -c \
      'from importlib.metadata import version; print(version("reme-ai"))')" != "$REME_VERSION" ]]; then
      rm -rf "$REME_VERSIONED_VENV"
      log "ERROR ReMe installed version does not match $REME_VERSION" "$RED"
      return 1
    fi
    rm -f "$link"
    ln -s "$REME_VERSIONED_VENV" "$link"
    rm -rf "$REME_VENV"
    mv "$link" "$REME_VENV"
    log "安装 ReMe: $package" "$GREEN"
  else
    log "ReMe 已是固定版本: $REME_VERSION" "$GREEN"
  fi

  generate_reme_config
  log "安装 ReMe 候选记忆配置: $REME_CONFIG" "$GREEN"
  generate_reme_global_config
  log "安装 ReMe 全局记忆配置: $REME_GLOBAL_CONFIG" "$GREEN"
}

stop_reme_global_service() {
  reme_python_available || {
    log "ERROR cannot stop ReMe service without Python: $REME_PYTHON" "$RED"
    return 1
  }

  "$REME_PYTHON" - stop-global "$REME_GLOBAL_CONFIG" \
    "$REME_VENV/bin/reme" <<'PY'
import os
import signal
import shlex
import subprocess
import sys
import time

expected_config = f"config={sys.argv[2]}"
expected_reme = sys.argv[3]
matches = []

try:
    import psutil
except ImportError:
    psutil = None
process_errors = (OSError, subprocess.CalledProcessError, ValueError)
if psutil is not None:
    process_errors += (psutil.Error,)


def process_argv(pid):
    try:
        if psutil is not None:
            return psutil.Process(pid).cmdline()
        command = subprocess.check_output(
            ["ps", "-ww", "-p", str(pid), "-o", "command="],
            text=True,
        ).strip()
        return shlex.split(command)
    except process_errors:
        return []


def is_managed(pid):
    argv = process_argv(pid)
    return expected_reme in argv and "start" in argv and expected_config in argv


if psutil is not None:
    candidates = [proc.pid for proc in psutil.process_iter()]
else:
    output = subprocess.check_output(["ps", "-axo", "pid="], text=True)
    candidates = [int(value) for value in output.split() if value.isdigit()]

matches = [pid for pid in candidates if is_managed(pid)]

for pid in matches:
    if not is_managed(pid):
        continue
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass

deadline = time.monotonic() + 5
alive = matches
while alive and time.monotonic() < deadline:
    time.sleep(0.1)
    remaining = []
    for pid in alive:
        try:
            os.kill(pid, 0)
            remaining.append(pid)
        except ProcessLookupError:
            pass
    alive = remaining

for pid in alive:
    if not is_managed(pid):
        continue
    try:
        os.kill(pid, signal.SIGKILL)
    except ProcessLookupError:
        pass

if alive:
    time.sleep(0.1)
    for pid in alive:
        if is_managed(pid):
            raise SystemExit(f"Failed to stop managed ReMe process: {pid}")
PY
}

remove_reme() {
  local managed_link
  local source
  local target=""
  local managed_links=(
    "$HOME/.config/opencode/plugins/reme-memory.ts|$REPO_ROOT/config/opencode/plugins/reme-memory.ts"
    "$HOME/.config/agents/reme-memory-bridge.ts|$REPO_ROOT/config/agents/reme-memory-bridge.ts"
    "$HOME/.pi/agent/extensions/reme-memory.ts|$REPO_ROOT/config/pi/extensions/reme-memory.ts"
    "$REME_SERVICE_LAUNCHER|$REPO_ROOT/config/reme/start-global-service.sh"
    "$REME_PROJECT_RUNNER|$REPO_ROOT/config/reme/run-project-capture.py"
  )

  for managed_link in "${managed_links[@]}"; do
    source="${managed_link#*|}"
    managed_link="${managed_link%%|*}"
    if [[ -L "$managed_link" ]]; then
      target="$(readlink "$managed_link")"
      [[ "$target" == "$source" ]] && continue
    elif [[ ! -e "$managed_link" ]]; then
      continue
    fi
    log "ERROR managed-link-conflict $managed_link" "$RED"
    return 1
  done
  case "$REME_ROOT" in
  */mac-setup/reme) ;;
  *)
    log "ERROR unsafe ReMe install path: $REME_ROOT" "$RED"
    return 1
    ;;
  esac
  case "$REME_HOOK_STATE_ROOT" in
  */mac-setup/reme-hooks) ;;
  *)
    log "ERROR unsafe ReMe hook state path: $REME_HOOK_STATE_ROOT" "$RED"
    return 1
    ;;
  esac

  stop_reme_global_service
  for managed_link in "${managed_links[@]}"; do
    rm -f "${managed_link%%|*}"
  done
  rm -f "$REME_CONFIG" "$REME_GLOBAL_CONFIG"
  rm -rf "$REME_VENV" "$REME_VERSIONED_VENV"
  rm -rf "$REME_HOOK_STATE_ROOT"
  log "已移除托管的 ReMe 集成；项目和全局记忆数据未修改" "$GREEN"
}

apply_reme_runtime() {
  install_reme
  install_managed_link \
    "$REPO_ROOT/config/agents/reme-memory-bridge.ts" \
    "$HOME/.config/agents/reme-memory-bridge.ts"
  install_managed_link \
    "$REPO_ROOT/config/reme/start-global-service.sh" \
    "$REME_SERVICE_LAUNCHER"
  install_managed_link \
    "$REPO_ROOT/config/reme/run-project-capture.py" \
    "$REME_PROJECT_RUNNER"
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
  install_managed_link \
    "$REPO_ROOT/config/opencode/plugins/reme-memory.ts" \
    "$HOME/.config/opencode/plugins/reme-memory.ts"
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
  install_managed_link \
    "$REPO_ROOT/config/pi/extensions/reme-memory.ts" \
    "$HOME/.pi/agent/extensions/reme-memory.ts"
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

  [[ -e "$path" ]] || return 0
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

audit_reme() {
  local installed=""
  local status

  if ! reme_layout_ready || [[ ! -x "$REME_VENV/bin/python" ]] ||
    ! reme_executable_ready; then
    audit_fail reme-install "$REME_VENV"
    return
  fi
  installed="$(reme_installed_version || true)"
  if [[ "$installed" == "$REME_VERSION" ]]; then
    audit_ok reme-version "$REME_VERSION"
  else
    audit_fail reme-version "$REME_VENV"
  fi

  if [[ ! -f "$REME_CONFIG" ]]; then
    audit_fail reme-config "$REME_CONFIG"
    return
  fi
  if "$REME_VENV/bin/python" - audit "$REME_CONFIG" >/dev/null 2>&1 <<'PY'; then
import sys
from importlib.resources import files

import yaml

allowed_jobs = {
    "auto_memory",
    "daily_list",
    "daily_write",
    "edit",
    "frontmatter_update",
    "move",
    "read",
    "write",
}

allowed_components = {
    "agent_wrapper": {"default"},
    "as_llm": {"default"},
    "file_graph": {"default"},
    "file_store": {"default"},
    "keyword_index": {"default"},
    "tokenizer": {"default"},
}

with open(sys.argv[2], encoding="utf-8") as source:
    actual = yaml.safe_load(source)
with files("reme.config").joinpath("default.yaml").open(encoding="utf-8") as source:
    expected = yaml.safe_load(source)

missing_jobs = allowed_jobs - set(expected["jobs"])
if missing_jobs:
    raise SystemExit(1)

expected["service"] = {"backend": "cli", "web_enabled": False}
expected["jobs"] = {name: expected["jobs"][name] for name in sorted(allowed_jobs)}
expected["components"] = {
    group: {
        name: expected["components"][group][name]
        for name in sorted(names)
    }
    for group, names in allowed_components.items()
}
expected["enable_logo"] = False
expected["log_to_console"] = False
expected["log_to_file"] = False

raise SystemExit(0 if actual == expected else 1)
PY
    audit_ok reme-config-policy "$REME_CONFIG"
  else
    audit_fail reme-config-policy "$REME_CONFIG"
  fi
  audit_mode "$REME_CONFIG"
  if reme_config_has_sensitive_value "$REME_CONFIG"; then
    audit_fail sensitive-config "$REME_CONFIG"
  else
    status=$?
    case "$status" in
    1) audit_ok no-literal-secret "$REME_CONFIG" ;;
    *) audit_fail invalid-config "$REME_CONFIG" ;;
    esac
  fi

  if [[ ! -f "$REME_GLOBAL_CONFIG" ]]; then
    audit_fail reme-global-config "$REME_GLOBAL_CONFIG"
    return
  fi
  if "$REME_VENV/bin/python" - audit-global "$REME_GLOBAL_CONFIG" \
    "$REME_GLOBAL_WORKSPACE" >/dev/null 2>&1 <<'PY'; then
import sys
from importlib.resources import files

import yaml

served_jobs = {
    "app_config",
    "auto_memory",
    "health_check",
    "search",
    "version",
}
runtime_jobs = served_jobs | {
    "daily_list",
    "daily_write",
    "digest_watch_loop",
    "dream_cron",
    "edit",
    "frontmatter_update",
    "index_update_loop",
    "move",
    "optimize_index_cron",
    "read",
    "write",
}

with open(sys.argv[2], encoding="utf-8") as source:
    actual = yaml.safe_load(source)
with files("reme.config").joinpath("default.yaml").open(encoding="utf-8") as source:
    expected = yaml.safe_load(source)

missing_jobs = runtime_jobs - set(expected["jobs"])
if missing_jobs:
    raise SystemExit(1)

expected["workspace_dir"] = sys.argv[3]
expected["service"] = {
    "backend": "http",
    "host": "127.0.0.1",
    "port": 2333,
    "web_enabled": False,
    "jobs": sorted(served_jobs),
}
expected["jobs"] = {name: expected["jobs"][name] for name in sorted(runtime_jobs)}
for name, job in expected["jobs"].items():
    job["enable_serve"] = name in served_jobs
expected["enable_logo"] = False
expected["log_to_console"] = False
expected["log_to_file"] = False

raise SystemExit(0 if actual == expected else 1)
PY
    audit_ok reme-global-policy "$REME_GLOBAL_CONFIG"
  else
    audit_fail reme-global-policy "$REME_GLOBAL_CONFIG"
  fi
  audit_mode "$REME_GLOBAL_CONFIG"
  if reme_config_has_sensitive_value "$REME_GLOBAL_CONFIG"; then
    audit_fail sensitive-config "$REME_GLOBAL_CONFIG"
  else
    status=$?
    case "$status" in
    1) audit_ok no-literal-secret "$REME_GLOBAL_CONFIG" ;;
    *) audit_fail invalid-config "$REME_GLOBAL_CONFIG" ;;
    esac
  fi
  if [[ ! -d "$REME_GLOBAL_WORKSPACE" ]]; then
    audit_fail reme-global-workspace "$REME_GLOBAL_WORKSPACE"
  else
    audit_mode "$REME_GLOBAL_WORKSPACE"
  fi
  if [[ ! -f "$REME_HOOK_STATE_ROOT/status.json" ]]; then
    audit_ok reme-integration-health no-hook-activity
  elif python3 - "$REME_HOOK_STATE_ROOT/status.json" <<'PY' >/dev/null 2>&1; then
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    status = json.load(source)
valid = (
    isinstance(status, dict)
    and set(status) == {"stage", "success", "errorCode", "timestamp"}
    and status["stage"] in {"retrieve", "capture"}
    and isinstance(status["success"], bool)
    and status["errorCode"] in {None, "invalid-input", "state-error", "operation-error"}
    and isinstance(status["timestamp"], str)
    and len(json.dumps(status)) < 512
)
raise SystemExit(0 if valid else 1)
PY
    status="$(
      python3 - "$REME_HOOK_STATE_ROOT/status.json" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as source:
    value = json.load(source)
result = "ok" if value["success"] else value["errorCode"]
print(f'{value["stage"]}:{result}')
PY
    )"
    audit_ok reme-integration-health "$status"
    audit_mode "$REME_HOOK_STATE_ROOT"
    audit_mode "$REME_HOOK_STATE_ROOT/status.json"
  else
    audit_warn reme-integration-health invalid-status
  fi
}

audit_reme_runtime() {
  audit_reme
  audit_managed_link \
    "$REPO_ROOT/config/agents/reme-memory-bridge.ts" \
    "$HOME/.config/agents/reme-memory-bridge.ts"
  audit_managed_link \
    "$REPO_ROOT/config/reme/start-global-service.sh" \
    "$REME_SERVICE_LAUNCHER"
  audit_managed_link \
    "$REPO_ROOT/config/reme/run-project-capture.py" \
    "$REME_PROJECT_RUNNER"
  if [[ -x "$REME_SERVICE_LAUNCHER" ]]; then
    audit_ok executable "$REME_SERVICE_LAUNCHER"
  else
    audit_fail executable "$REME_SERVICE_LAUNCHER"
  fi
  return 0
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
  audit_managed_link \
    "$REPO_ROOT/config/opencode/plugins/reme-memory.ts" \
    "$HOME/.config/opencode/plugins/reme-memory.ts"
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
  audit_managed_link \
    "$REPO_ROOT/config/pi/extensions/reme-memory.ts" \
    "$HOME/.pi/agent/extensions/reme-memory.ts"
}

if [[ "$MODE" == "remove-reme" ]]; then
  remove_reme
  exit 0
fi

if [[ "$MODE" == "apply" ]]; then
  preflight_force
  selected shared && apply_shared
  if [[ "$TARGET" == "all" || "$TARGET" == "opencode" || "$TARGET" == "claude" ||
    "$TARGET" == "codex" || "$TARGET" == "pi" ]]; then
    apply_reme_runtime
  fi
  selected opencode && apply_opencode
  selected claude && apply_claude
  selected codex && apply_codex
  selected pi && apply_pi
  log "Agent 配置应用完成；运行 --audit 检查本机状态" "$GREEN"
  exit 0
fi

selected shared && audit_shared
if [[ "$TARGET" == "all" || "$TARGET" == "opencode" || "$TARGET" == "claude" ||
  "$TARGET" == "codex" || "$TARGET" == "pi" ]]; then
  audit_reme_runtime
fi
selected opencode && audit_opencode
selected claude && audit_claude
selected codex && audit_codex
selected pi && audit_pi

printf 'Agent audit: %d failure(s), %d warning(s).\n' \
  "$AUDIT_FAILURES" "$AUDIT_WARNINGS"
((AUDIT_FAILURES == 0))

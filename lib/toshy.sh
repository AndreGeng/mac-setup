#!/usr/bin/env bash
# Shared configuration hook; sourcing this file never installs Toshy.

configure_toshy() (
  local toshy_root
  toshy_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local runtime_helper="$HOME/.config/toshy/scripts/toshy-runtime-env.sh"
  local python=python3
  if [[ -f "$runtime_helper" ]]; then
    # Upstream resolves its venv or an externally managed runtime.
    source "$runtime_helper" || return 1
    python="$TOSHY_PYTHON"
  elif [[ -x "$HOME/.config/toshy/.venv/bin/python" ]]; then
    python="$HOME/.config/toshy/.venv/bin/python"
  fi
  log "同步 Toshy 自定义快捷键和 Fcitx 输入法绑定" "$GREEN"
  "$python" "$toshy_root/scripts/configure-toshy.py"
)

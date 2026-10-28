#!/usr/bin/env bash
set -euo pipefail

XFCE_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$XFCE_MODULE_DIR/../lib/utils.sh"

configure_xfce() {
  if [[ ":${XDG_CURRENT_DESKTOP:-}:" != *:XFCE:* || -z "${DISPLAY:-}" ]]; then
    log "跳过 XFCE 设置：未检测到 XFCE 桌面会话" "$YELLOW"
    return 0
  fi
  if ! command -v xfconf-query >/dev/null 2>&1; then
    log "跳过 XFCE 设置：未找到 xfconf-query" "$YELLOW"
    return 0
  fi
  xfconf-query -c keyboards -p /Default/KeyRepeat -n -t bool -s true
  xfconf-query -c keyboards -p /Default/KeyRepeat/Delay -n -t int -s 250
  xfconf-query -c keyboards -p /Default/KeyRepeat/Rate -n -t int -s 40
  log "XFCE 键盘重复已配置：延迟 250ms，每秒 40 次" "$GREEN"
}

configure_xfce

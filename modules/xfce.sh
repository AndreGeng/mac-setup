#!/usr/bin/env bash
set -euo pipefail

XFCE_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$XFCE_MODULE_DIR/../lib/utils.sh"

configure_xfce_battery() {
  if ! command -v xfce4-power-manager >/dev/null 2>&1 ||
    ! command -v xfce4-panel >/dev/null 2>&1; then
    log "跳过电量显示：需要已安装的 XFCE 电源管理器和面板" "$YELLOW"
    return 0
  fi

  local listing property value top_panel="" plugin_ids="" clock_id=""
  local battery_id="" max_id=0 id
  listing="$(xfconf-query -c xfce4-panel -lv)" || return 1
  while read -r property value; do
    if [[ "$property" =~ ^/plugins/plugin-([0-9]+)$ ]]; then
      id="${BASH_REMATCH[1]}"
      ((id <= max_id)) || max_id="$id"
      [[ "$value" != power-manager-plugin ]] || battery_id="$id"
      [[ "$value" != clock ]] || clock_id="$id"
    elif [[ "$property" =~ ^/panels/panel-([0-9]+)/position$ &&
      "$value" == 'p=6;'* && -z "$top_panel" ]]; then
      top_panel="${BASH_REMATCH[1]}"
    fi
  done <<<"$listing"

  if [[ -z "$battery_id" ]]; then
    # Preserve custom layouts when no standard top panel can be identified.
    while read -r property value; do
      if [[ -n "$top_panel" && "$property" == "/panels/panel-$top_panel/plugin-ids" ]]; then
        plugin_ids="$value"
      fi
    done <<<"$listing"
    if [[ ! "$plugin_ids" =~ ^\[[0-9]+(,[0-9]+)*\]$ ]]; then
      log "跳过电量显示：未找到可识别的 XFCE 顶部面板" "$YELLOW"
      return 0
    fi
    local -a ids args=()
    IFS=, read -r -a ids <<<"${plugin_ids:1:${#plugin_ids}-2}"
    battery_id="$((max_id + 1))"
    local inserted=0
    for id in "${ids[@]}"; do
      if [[ "$id" == "$clock_id" ]]; then
        args+=(-t int -s "$battery_id")
        inserted=1
      fi
      args+=(-t int -s "$id")
    done
    if [[ "$inserted" == 0 ]]; then
      args+=(-t int -s "$battery_id")
    fi
    xfconf-query -c xfce4-panel -p "/plugins/plugin-$battery_id" \
      -n -t string -s power-manager-plugin
    xfconf-query -c xfce4-panel -p "/panels/panel-$top_panel/plugin-ids" "${args[@]}"
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/show-panel-label \
      -n -t uint -s 1
    # New plugin IDs are loaded reliably after a panel restart.
    xfce4-panel --restart
  else
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/show-panel-label \
      -n -t uint -s 1
  fi
  log "XFCE 电池图标和电量百分比已配置" "$GREEN"
}

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
  configure_xfce_battery
}

configure_xfce

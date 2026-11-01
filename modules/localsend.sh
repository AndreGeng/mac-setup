#!/usr/bin/env bash
set -euo pipefail

LOCALSEND_MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! declare -F is_linux >/dev/null; then
  source "$LOCALSEND_MODULE_ROOT/lib/platform.sh"
fi
source "$LOCALSEND_MODULE_ROOT/lib/utils.sh"

localsend_has_terminal() { [[ -t 0 && -t 1 ]]; }

install_localsend() (
  is_linux || return 0
  if [[ "${MAC_SETUP_SKIP_LOCALSEND:-0}" == 1 || "${MAC_SETUP_NO_ROOT:-0}" == 1 ||
    "$(id -u)" == 0 || -n "${SUDO_USER:-}" || -n "${DOAS_USER:-}" ]]; then
    log "跳过 LocalSend：已禁用、--no-root 或非桌面普通用户" "$YELLOW"
    return 0
  fi
  if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    log "跳过 LocalSend：未检测到 Linux 桌面会话" "$YELLOW"
    return 0
  fi
  if command -v localsend >/dev/null 2>&1 || command -v localsend_app >/dev/null 2>&1; then
    log "LocalSend 已安装，保留现有设置" "$GREEN"
    return 0
  fi
  if [[ "$(detect_platform)" != arch ]]; then
    log "跳过 LocalSend：当前自动安装支持 Arch；其他 Linux 请先按官方说明安装" "$YELLOW"
    return 0
  fi
  if ! localsend_has_terminal; then
    log "跳过 LocalSend：需要交互终端；请运行 ./setup.sh --modules localsend" "$YELLOW"
    return 0
  fi
  log "安装 localsend-bin；请审阅 AUR 脚本、依赖和管理员授权提示" "$YELLOW"
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed localsend-bin || return 1
  elif command -v paru >/dev/null 2>&1; then
    paru -S --needed localsend-bin || return 1
  else
    log "请先安装 yay 或 paru，再重跑 LocalSend 模块" "$RED"
    return 1
  fi
  if ! command -v localsend >/dev/null 2>&1 && ! command -v localsend_app >/dev/null 2>&1; then
    log "LocalSend 安装后仍不可用，请检查 AUR 安装结果" "$RED"
    return 1
  fi
  log "LocalSend 已安装；可从应用菜单打开，与同一局域网设备互传文件和文字" "$GREEN"
)

install_localsend

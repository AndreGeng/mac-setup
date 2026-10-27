#!/usr/bin/env bash
set -euo pipefail

VICINAE_MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! declare -F is_linux >/dev/null; then
  source "$VICINAE_MODULE_ROOT/lib/platform.sh"
fi
source "$VICINAE_MODULE_ROOT/lib/utils.sh"
source "$VICINAE_MODULE_ROOT/lib/toshy.sh"

vicinae_has_terminal() { [[ -t 0 && -t 1 ]]; }

install_vicinae_appimage() (
  local manifest="$VICINAE_MODULE_ROOT/config/bootstrap/vicinae.tsv"
  local revision installer installer_sha version asset asset_sha arch dependency
  arch="$(uname -m)"
  case "$arch" in
  x86_64 | aarch64) ;;
  *)
    log "Vicinae AppImage 不支持此架构: $arch" "$RED"
    return 1
    ;;
  esac
  for dependency in curl jq node python3; do
    if ! command -v "$dependency" >/dev/null; then
      log "Vicinae 安装需要 $dependency；Node 可先用 nodejs 模块安装" "$RED"
      return 1
    fi
  done
  read -r revision installer installer_sha < <(awk '$1 == "installer" {print $2, $3, $4}' "$manifest")
  read -r version asset asset_sha < <(awk -v arch="$arch" '$1 == arch {print $2, $3, $4}' "$manifest")
  [[ "$revision" =~ ^[0-9a-f]{40}$ && "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ &&
    "$installer_sha" =~ ^[0-9a-f]{64}$ && "$asset_sha" =~ ^[0-9a-f]{64}$ &&
    "$installer" == scripts/install.sh && "$asset" == "Vicinae-$arch.AppImage" ]] || return 1
  local tmp_dir
  tmp_dir="$(mktemp -d)" || return 1
  trap 'rm -rf "$tmp_dir"' EXIT
  curl -fL "https://raw.githubusercontent.com/vicinaehq/vicinae/$revision/$installer" \
    -o "$tmp_dir/install.sh" || return 1
  verify_file_sha256 "$tmp_dir/install.sh" "$installer_sha" || return 1
  curl -fL "https://github.com/vicinaehq/vicinae/releases/download/$version/$asset" \
    -o "$tmp_dir/$asset" || return 1
  verify_file_sha256 "$tmp_dir/$asset" "$asset_sha" || return 1
  # A verified local AppImage prevents upstream from fetching a floating release.
  # A user-owned prefix avoids privilege escalation by the upstream installer.
  bash "$tmp_dir/install.sh" --appimage "$tmp_dir/$asset" --prefix "$HOME/.local"
)

install_vicinae() (
  is_linux || return 0
  if [[ "${MAC_SETUP_SKIP_VICINAE:-0}" == 1 || "${MAC_SETUP_NO_ROOT:-0}" == 1 ]]; then
    log "跳过 Vicinae：已禁用或启用了 --no-root" "$YELLOW"
    return 0
  fi
  if [[ "$(id -u)" == 0 || -n "${SUDO_USER:-}" || -n "${DOAS_USER:-}" ]]; then
    log "跳过 Vicinae：请以桌面普通用户运行" "$YELLOW"
    return 0
  fi
  if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]] || ! vicinae_has_terminal; then
    log "跳过 Vicinae：需要桌面交互终端；可重跑 ./setup.sh --modules vicinae" "$YELLOW"
    return 0
  fi
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v python3 >/dev/null || ! command -v systemctl >/dev/null; then
    log "Vicinae 模块需要 python3 和 systemd 用户服务" "$RED"
    return 1
  fi
  if ! command -v vicinae >/dev/null; then
    if [[ "$(detect_platform)" == arch && "$(uname -m)" == x86_64 ]]; then
      log "安装 vicinae-bin；请审阅 AUR 提示，XFCE 凭据服务可选择 gnome-keyring" "$YELLOW"
      if command -v yay >/dev/null; then
        yay -S --needed vicinae-bin || return 1
      elif command -v paru >/dev/null; then
        paru -S --needed vicinae-bin || return 1
      else
        log "请先安装 yay 或 paru，再重跑 Vicinae 模块" "$RED"
        return 1
      fi
    else
      install_vicinae_appimage || return 1
    fi
  fi
  command -v vicinae >/dev/null || {
    log "Vicinae 安装后仍不可用" "$RED"
    return 1
  }
  python3 "$VICINAE_MODULE_ROOT/scripts/configure-vicinae.py" || return 1
  if [[ -f "$HOME/.config/toshy/toshy_config.py" ]]; then
    configure_toshy || return 1
  fi
  # Includes ~/.local/bin so the upstream service can find the pinned Node runtime
  # and user-prefix Vicinae before any interactive shell has started.
  local name env_names=(PATH)
  for name in DISPLAY XAUTHORITY WAYLAND_DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP; do
    [[ -z "${!name:-}" ]] || env_names+=("$name")
  done
  systemctl --user import-environment "${env_names[@]}" || return 1
  systemctl --user daemon-reload || return 1
  systemctl --user enable vicinae.service || return 1
  systemctl --user restart vicinae.service || return 1
  local attempt
  for attempt in {1..20}; do
    if vicinae ping >/dev/null 2>&1; then
      systemctl --user is-active --quiet vicinae.service || return 1
      systemctl --user is-enabled --quiet vicinae.service || return 1
      log "Vicinae 已启动并设为登录自启动，快捷键 Ctrl+[" "$GREEN"
      if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        log "Wayland 全局快捷键取决于合成器支持；必要时绑定 vicinae toggle" "$YELLOW"
      fi
      return 0
    fi
    sleep 1
  done
  log "Vicinae 未就绪，请检查 journalctl --user -u vicinae.service" "$RED"
  return 1
)

install_vicinae

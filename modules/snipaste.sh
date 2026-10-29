#!/usr/bin/env bash
set -euo pipefail

SNIPASTE_MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! declare -F is_macos >/dev/null; then
  source "$SNIPASTE_MODULE_ROOT/lib/platform.sh"
fi
if ! declare -F verify_file_sha256 >/dev/null; then
  source "$SNIPASTE_MODULE_ROOT/lib/utils.sh"
fi

install_snipaste_linux() (
  local arch version url checksum tmp_dir destination
  arch="$(uname -m)"
  read -r arch version url checksum < <(
    awk -v arch="$arch" '$1 == arch {print $1, $2, $3, $4}' \
      "$SNIPASTE_MODULE_ROOT/config/bootstrap/snipaste.tsv"
  ) || return 1
  [[ "$arch" == x86_64 && "$version" == 2.11.3 &&
    "$url" == "https://download.snipaste.com/archives/Snipaste-$version-x86_64.AppImage" &&
    "$checksum" =~ ^[0-9a-f]{64}$ ]] || return 1
  destination="$HOME/.local/share/mac-setup/snipaste/$version"
  [[ ! -e "$destination" ]] || {
    [[ -x "$destination/usr/bin/Snipaste" ]]
    return $?
  }
  tmp_dir="$(mktemp -d)" || return 1
  trap 'rm -rf "$tmp_dir"' EXIT
  curl -fL --retry 3 --connect-timeout 20 "$url" -o "$tmp_dir/Snipaste.AppImage" || return 1
  verify_file_sha256 "$tmp_dir/Snipaste.AppImage" "$checksum" || return 1
  chmod +x "$tmp_dir/Snipaste.AppImage" || return 1
  cd "$tmp_dir" || return 1
  ./Snipaste.AppImage --appimage-extract >/dev/null || return 1
  [[ -x squashfs-root/usr/bin/Snipaste ]] || return 1
  mv Snipaste.AppImage squashfs-root/ || return 1
  mkdir -p "$(dirname "$destination")" || return 1
  mv squashfs-root "$destination"
)

install_snipaste() (
  if [[ "${MAC_SETUP_SKIP_SNIPASTE:-0}" == 1 || "${MAC_SETUP_NO_ROOT:-0}" == 1 ||
    "$(id -u)" == 0 || -n "${SUDO_USER:-}" || -n "${DOAS_USER:-}" ]]; then
    log "跳过 Snipaste：已禁用、--no-root 或非桌面普通用户" "$YELLOW"
    return 0
  fi
  if is_linux && [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    log "跳过 Snipaste：未检测到 Linux 桌面会话" "$YELLOW"
    return 0
  fi
  is_macos || is_linux || return 0
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mac-setup/snipaste"
  local launcher="$HOME/.local/bin/snipaste"
  if [[ -L "$config_dir/config.ini" || -L "$launcher" ]]; then
    log "Snipaste 配置或启动器存在冲突软链，请先检查" "$RED"
    return 1
  fi
  if [[ -e "$launcher" ]] && ! grep -q '^# mac-setup Snipaste launcher$' "$launcher"; then
    log "Snipaste 启动器路径已被占用，请先检查" "$RED"
    return 1
  fi
  if is_macos; then
    if [[ ! -x /Applications/Snipaste.app/Contents/MacOS/Snipaste &&
      ! -x "$HOME/Applications/Snipaste.app/Contents/MacOS/Snipaste" ]]; then
      brew install --cask snipaste || return 1
    fi
  elif ! command -v Snipaste >/dev/null 2>&1; then
    if [[ "$(uname -m)" != x86_64 ]]; then
      log "Snipaste 官方 Linux 包仅支持 x86_64" "$YELLOW"
      return 0
    fi
    install_snipaste_linux || return 1
  fi
  mkdir -p "$config_dir" "$HOME/.local/bin" || return 1
  if [[ ! -e "$config_dir/config.ini" ]]; then
    cp "$SNIPASTE_MODULE_ROOT/config/snipaste/config.ini" "$config_dir/config.ini" || return 1
  fi
  cp "$SNIPASTE_MODULE_ROOT/config/snipaste/launch.sh" "$launcher" || return 1
  chmod +x "$launcher" || return 1
  if is_linux; then
    local desktop_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications" escaped
    mkdir -p "$desktop_dir" || return 1
    escaped="${launcher//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"
    escaped="${escaped//\$/\\\$}"
    escaped="${escaped//\`/\\\`}"
    escaped="${escaped//%/%%}"
    printf '[Desktop Entry]\nType=Application\nName=Snipaste (mac-setup)\nExec="%s"\nIcon=Snipaste\nCategories=Graphics;\nTerminal=false\n' \
      "$escaped" >"$desktop_dir/mac-setup-snipaste.desktop" || return 1
  fi
  log "Snipaste 已安装；运行 ~/.local/bin/snipaste 使用仓库默认配置副本" "$GREEN"
  log "已有设置保留；请先退出旧实例再启动，不自动启用登录自启" "$YELLOW"
)

install_snipaste

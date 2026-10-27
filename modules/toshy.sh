#!/usr/bin/env bash
set -euo pipefail

TOSHY_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! declare -F is_linux >/dev/null; then
  source "$TOSHY_MODULE_DIR/../lib/platform.sh"
fi
source "$TOSHY_MODULE_DIR/../lib/utils.sh"

toshy_has_terminal() { [[ -t 0 && -t 1 ]]; }

source "$TOSHY_MODULE_DIR/../lib/toshy.sh"

# Keep upstream's interactive prompts and privilege handling. Run in a subshell
# so its working directory and our cleanup trap cannot affect other modules.
install_toshy() (
  is_linux || return 0
  if [[ "${MAC_SETUP_SKIP_TOSHY:-0}" == 1 || "${MAC_SETUP_NO_ROOT:-0}" == 1 ]]; then
    log "跳过 Toshy：已禁用或启用了 --no-root" "$YELLOW"
    return 0
  fi
  if [[ "$(id -u)" == 0 || -n "${SUDO_USER:-}" || -n "${DOAS_USER:-}" ]]; then
    log "跳过 Toshy：请以桌面普通用户运行 ./setup.sh --modules toshy" "$YELLOW"
    return 0
  fi
  if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    log "跳过 Toshy：未检测到 X11/Wayland 桌面会话" "$YELLOW"
    return 0
  fi
  if ! toshy_has_terminal; then
    log "跳过 Toshy：需要交互终端；请在桌面终端运行 ./setup.sh --modules toshy" "$YELLOW"
    return 0
  fi
  if [[ -f "$HOME/.config/toshy/toshy_config.py" &&
    -x "$HOME/.local/bin/toshy-config-start" ]]; then
    log "Toshy 已安装，跳过安装并同步快捷键" "$GREEN"
    configure_toshy
    return $?
  fi

  local dependency
  for dependency in curl tar python3; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      log "安装 Toshy 需要 $dependency，请先安装后重试" "$RED"
      return 1
    fi
  done

  # Reviewed upstream installer snapshot; update commit and checksum together.
  local revision=ac3dbfcdd6e7a11c95ea892c19fb5b1643f45a82
  local checksum=37e1c21fb7de8df5f7351b22080e90186d7009b6816b9cd4dd76fce08470989e
  local tmp_dir
  tmp_dir="$(mktemp -d)" || return 1
  trap 'rm -rf "$tmp_dir"' EXIT
  log "=== 安装 Toshy（Linux macOS 风格快捷键）===" "$GREEN"
  log "上游安装器将联网安装依赖，并交互请求系统权限；请阅读并回答其提示" "$YELLOW"
  if ! curl -fL "https://codeload.github.com/RedBearAK/toshy/tar.gz/$revision" \
    -o "$tmp_dir/toshy.tar.gz"; then
    log "Toshy 下载失败" "$RED"
    return 1
  fi
  if ! verify_file_sha256 "$tmp_dir/toshy.tar.gz" "$checksum"; then
    log "Toshy 校验失败，停止安装" "$RED"
    return 1
  fi
  mkdir "$tmp_dir/source" || return 1
  tar -xzf "$tmp_dir/toshy.tar.gz" -C "$tmp_dir/source" --strip-components=1 || return 1
  cd "$tmp_dir/source" || return 1
  # Do not pipe yes, run as sudo, or enable optional desktop tweaks.
  if ! python3 ./setup_toshy.py install; then
    log "Toshy 安装失败，请检查上游安装器输出后重试" "$RED"
    return 1
  fi
  configure_toshy || return 1
  log "Toshy 安装器已完成；请按提示注销或重启，并运行 toshy-services-status 检查服务" "$GREEN"
)

install_toshy

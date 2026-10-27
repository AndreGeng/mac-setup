#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

run_case() (
  local scenario="$1"
  export HOME="$TEMP_ROOT/$scenario.home" TMPDIR="$TEMP_ROOT/$scenario.tmp"
  local trace="$TEMP_ROOT/$scenario.trace"
  mkdir -p "$HOME" "$TMPDIR"
  : >"$trace"
  source "$ROOT_DIR/lib/platform.sh"
  source "$ROOT_DIR/lib/utils.sh"
  is_linux() { return 0; }
  detect_platform() { echo arch; }
  id() { echo 1000; }
  local vicinae_available=0
  command() {
    if [[ "${1:-}" == -v && ("${2:-}" == yay || "${2:-}" == paru) &&
      "$scenario" == no-helper ]]; then
      return 1
    elif [[ "${1:-}" == -v && "${2:-}" == yay && "$scenario" == paru ]]; then
      return 1
    elif [[ "${1:-}" == -v && "${2:-}" == vicinae ]]; then
      [[ "$vicinae_available" == 1 || -f "$HOME/.local/bin/vicinae" ]]
    else
      builtin command "$@"
    fi
  }
  vicinae() { printf 'vicinae %s\n' "$*" >>"$trace"; }
  jq() { :; }
  node() { :; }
  yay() {
    printf 'yay %s\n' "$*" >>"$trace"
    [[ "$scenario" != install-failure ]] || return 1
    vicinae_available=1
  }
  paru() {
    printf 'paru %s\n' "$*" >>"$trace"
    vicinae_available=1
  }
  python3() {
    printf 'config %s\n' "$*" >>"$trace"
    [[ "$scenario" != config-failure ]]
  }
  systemctl() {
    printf 'systemctl %s\n' "$*" >>"$trace"
    [[ "$scenario" != service-failure ]]
  }
  curl() {
    printf 'curl\n' >>"$trace"
    : >"${@: -1}"
  }

  bash() {
    printf 'installer %s\n' "$*" >>"$trace"
    mkdir -p "$HOME/.local/bin"
    : >"$HOME/.local/bin/vicinae"
  }
  export DISPLAY=:1
  unset WAYLAND_DISPLAY MAC_SETUP_NO_ROOT MAC_SETUP_SKIP_VICINAE SUDO_USER DOAS_USER
  source "$ROOT_DIR/modules/vicinae.sh"
  [[ ! -s "$trace" ]]
  verify_file_sha256() {
    printf 'checksum\n' >>"$trace"
    [[ "$scenario" != checksum-failure ]]
  }
  vicinae_has_terminal() { return 0; }
  case "$scenario" in
  macos) is_linux() { return 1; } ;;
  root) id() { echo 0; } ;;
  no-root) export MAC_SETUP_NO_ROOT=1 ;;
  opt-out) export MAC_SETUP_SKIP_VICINAE=1 ;;
  headless) unset DISPLAY ;;
  noninteractive) vicinae_has_terminal() { return 1; } ;;
  existing) vicinae_available=1 ;;
  with-toshy)
    vicinae_available=1
    mkdir -p "$HOME/.config/toshy"
    : >"$HOME/.config/toshy/toshy_config.py"
    ;;
  fallback | checksum-failure) detect_platform() { echo ubuntu; } ;;
  wayland)
    unset DISPLAY
    export WAYLAND_DISPLAY=wayland-0
    ;;
  esac
  case "$scenario" in
  install-failure | config-failure | service-failure | checksum-failure | no-helper)
    if install_vicinae; then return 1; fi
    if [[ "$scenario" == checksum-failure ]]; then
      ! grep -q '^installer ' "$trace"
    fi
    if [[ "$scenario" == install-failure || "$scenario" == config-failure ]]; then
      ! grep -q 'enable.*vicinae.service' "$trace"
    fi
    ;;
  macos | root | no-root | opt-out | headless | noninteractive)
    install_vicinae
    [[ ! -s "$trace" ]]
    ;;
  *)
    install_vicinae
    grep -q 'config .*configure-vicinae.py' "$trace"
    grep -q 'systemctl --user enable vicinae.service' "$trace"
    grep -q 'vicinae ping' "$trace"
    if [[ "$scenario" == fallback ]]; then
      [[ "$(grep -c '^checksum$' "$trace")" == 2 ]]
      grep -q 'installer .*--appimage .*--prefix' "$trace"
    elif [[ "$scenario" == paru ]]; then
      grep -q '^paru -S --needed vicinae-bin$' "$trace"
    elif [[ "$scenario" == with-toshy ]]; then
      grep -q 'config .*configure-toshy.py' "$trace"
      ! grep -q '^yay ' "$trace"
    elif [[ "$scenario" == existing ]]; then
      ! grep -q '^yay ' "$trace"
    else
      grep -q '^yay -S --needed vicinae-bin$' "$trace"
    fi
    ;;
  esac
  [[ -z "$(ls -A "$TMPDIR")" ]]
)

for scenario in macos root no-root opt-out headless noninteractive existing with-toshy desktop wayland \
  fallback paru no-helper checksum-failure install-failure config-failure service-failure; do
  run_case "$scenario"
  printf 'PASS vicinae %s\n' "$scenario"
done
output="$(OSTYPE=linux-gnu bash "$ROOT_DIR/setup.sh" --dry-run)"
[[ "$output" == *'/platforms/linux/vicinae.sh'* ]]
output="$(bash "$ROOT_DIR/setup.sh" --dry-run --modules vicinae)"
[[ "$output" == *'/modules/vicinae.sh'* && "$output" != *'/platforms/'* ]]
output="$(OSTYPE=linux-gnu bash "$ROOT_DIR/setup-lite.sh" --dry-run --with-platform)"
[[ "$output" == *'/platforms/linux/vicinae.sh'* ]]
printf 'PASS vicinae setup entry points\n'
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT_DIR/test/vicinae-config-test.py"

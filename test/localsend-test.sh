#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

run_case() (
  local scenario="$1" available=0
  export HOME="$TEMP_ROOT/$scenario.home"
  local trace="$TEMP_ROOT/$scenario.trace"
  mkdir -p "$HOME"
  : >"$trace"
  source "$ROOT_DIR/lib/platform.sh"
  source "$ROOT_DIR/lib/utils.sh"
  is_linux() { [[ "$scenario" != macos ]]; }
  detect_platform() {
    if [[ "$scenario" == other-linux ]]; then echo ubuntu; else echo arch; fi
  }
  id() { if [[ "$scenario" == root ]]; then echo 0; else echo 1000; fi; }
  localsend() { printf 'unexpected launch\n' >>"$trace"; }
  command() {
    if [[ "${1:-}" == -v ]]; then
      case "${2:-}" in
      localsend | localsend_app)
        [[ "$available" == 1 || "$scenario" == existing ]] &&
          [[ "${2:-}" == localsend ]] && return 0
        [[ "$scenario" == upstream-existing && "${2:-}" == localsend_app ]] && return 0
        return 1
        ;;
      yay)
        [[ "$scenario" != paru && "$scenario" != no-helper ]]
        return
        ;;
      paru)
        [[ "$scenario" != no-helper ]]
        return
        ;;
      esac
    fi
    builtin command "$@"
  }
  yay() {
    printf 'yay %s\n' "$*" >>"$trace"
    [[ "$scenario" != install-failure ]] || return 1
    [[ "$scenario" == missing-after-install ]] || available=1
  }
  paru() {
    printf 'paru %s\n' "$*" >>"$trace"
    available=1
  }
  export DISPLAY=:1
  unset WAYLAND_DISPLAY MAC_SETUP_NO_ROOT MAC_SETUP_SKIP_LOCALSEND SUDO_USER DOAS_USER
  # Loading in a noninteractive shell must not install anything.
  source "$ROOT_DIR/modules/localsend.sh"
  [[ ! -s "$trace" ]]
  localsend_has_terminal() { [[ "$scenario" != noninteractive ]]; }
  case "$scenario" in
  no-root) export MAC_SETUP_NO_ROOT=1 ;;
  opt-out) export MAC_SETUP_SKIP_LOCALSEND=1 ;;
  sudo-user) export SUDO_USER=operator ;;
  headless) unset DISPLAY ;;
  wayland)
    unset DISPLAY
    export WAYLAND_DISPLAY=wayland-0
    ;;
  esac
  case "$scenario" in
  no-helper | install-failure | missing-after-install)
    if install_localsend; then return 1; fi
    ;;
  *) install_localsend ;;
  esac
  case "$scenario" in
  desktop | wayland | missing-after-install | install-failure)
    grep -Fxq 'yay -S --needed localsend-bin' "$trace"
    ;;
  paru) grep -Fxq 'paru -S --needed localsend-bin' "$trace" ;;
  *) [[ ! -s "$trace" ]] ;;
  esac
  if [[ "$scenario" == desktop || "$scenario" == paru ]]; then
    : >"$trace"
    # Functions execute in a subshell, so emulate the package now being present.
    available=1
    install_localsend
    [[ ! -s "$trace" ]]
  fi
)

for scenario in macos root sudo-user no-root opt-out headless noninteractive existing \
  upstream-existing desktop wayland paru no-helper install-failure missing-after-install other-linux; do
  run_case "$scenario"
  printf 'PASS localsend %s\n' "$scenario"
done

output="$(OSTYPE=linux-gnu bash "$ROOT_DIR/setup.sh" --dry-run)"
[[ "$output" == *'/platforms/linux/localsend.sh'* ]]
output="$(bash "$ROOT_DIR/setup.sh" --dry-run --modules localsend)"
[[ "$output" == *'/modules/localsend.sh'* && "$output" != *'/platforms/'* ]]
output="$(OSTYPE=linux-gnu bash "$ROOT_DIR/setup-lite.sh" --dry-run --with-platform)"
[[ "$output" == *'/platforms/linux/localsend.sh'* ]]
output="$(OSTYPE=darwin bash "$ROOT_DIR/setup.sh" --dry-run)"
[[ "$output" != *'/platforms/linux/localsend.sh'* ]]
printf 'PASS localsend setup entry points\n'

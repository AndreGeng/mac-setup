#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

run_case() (
  local scenario="$1"
  export HOME="$TEMP_ROOT/$scenario home"
  unset XDG_CONFIG_HOME XDG_DATA_HOME
  mkdir -p "$HOME"
  source "$ROOT_DIR/lib/utils.sh"
  is_macos() { [[ "$scenario" == macos ]]; }
  is_linux() { ! is_macos; }
  id() { printf '1000\n'; }
  uname() { printf 'x86_64\n'; }
  brew() { printf '%s\n' "$*" >>"$HOME/brew.trace"; }
  curl() {
    printf 'download\n' >>"$HOME/download.trace"
    touch "${@: -1}"
  }
  verify_file_sha256() { [[ "$scenario" != bad-checksum ]]; }
  chmod() {
    command chmod "$@"
    if [[ "${*: -1}" == */Snipaste.AppImage ]]; then
      cat >"${@: -1}" <<'APPIMAGE'
#!/usr/bin/env bash
mkdir -p squashfs-root/usr/bin
printf '#!/bin/sh\nexit 0\n' >squashfs-root/usr/bin/Snipaste
chmod +x squashfs-root/usr/bin/Snipaste
APPIMAGE
    fi
  }
  if [[ "$scenario" == existing ]]; then
    Snipaste() { :; }
  fi
  command() {
    if [[ "${1:-}" == -v && "${2:-}" == Snipaste ]]; then
      [[ "$scenario" == existing ]] || return 1
    fi
    builtin command "$@"
  }
  export DISPLAY=:1
  unset WAYLAND_DISPLAY MAC_SETUP_SKIP_SNIPASTE MAC_SETUP_NO_ROOT SUDO_USER DOAS_USER
  if [[ "$scenario" == headless ]]; then unset DISPLAY; fi
  if [[ "$scenario" == no-root ]]; then export MAC_SETUP_NO_ROOT=1; fi
  if [[ "$scenario" == bad-checksum ]]; then
    if source "$ROOT_DIR/modules/snipaste.sh"; then return 1; fi
    [[ ! -e "$HOME/.local/bin/snipaste" ]]
    return
  fi
  source "$ROOT_DIR/modules/snipaste.sh"
  if [[ "$scenario" == headless || "$scenario" == no-root ]]; then
    [[ ! -e "$HOME/.local/bin/snipaste" ]]
    return
  fi
  [[ -x "$HOME/.local/bin/snipaste" ]]
  local config="$HOME/.config/mac-setup/snipaste/config.ini"
  [[ -f "$config" && ! -L "$config" ]]
  printf '\n[Personal]\nkeep=true\n' >>"$config"
  source "$ROOT_DIR/modules/snipaste.sh"
  rg -q 'keep=true' "$config"
  if is_macos; then
    rg -q 'install --cask snipaste' "$HOME/brew.trace"
  else
    [[ -f "$HOME/.local/share/applications/mac-setup-snipaste.desktop" ]]
  fi
  if [[ "$scenario" == existing ]]; then [[ ! -e "$HOME/download.trace" ]]; fi
)

for scenario in macos existing download bad-checksum headless no-root; do
  run_case "$scenario"
  printf 'PASS snipaste %s\n' "$scenario"
done

# Execute both launcher branches with fake binaries; paths deliberately contain spaces.
for platform in Linux Darwin; do
  trial_home="$TEMP_ROOT/launcher $platform"
  mkdir -p "$trial_home/fake-bin" "$trial_home/Applications/Snipaste.app/Contents/MacOS"
  printf '#!/bin/sh\nprintf "%%s\\n" %s\n' "$platform" >"$trial_home/fake-bin/uname"
  cat >"$trial_home/fake-bin/Snipaste" <<'BINARY'
#!/bin/sh
printf '%s\n' "$@" >"$HOME/args"
BINARY
  cp "$trial_home/fake-bin/Snipaste" "$trial_home/Applications/Snipaste.app/Contents/MacOS/Snipaste"
  chmod +x "$trial_home/fake-bin/"* "$trial_home/Applications/Snipaste.app/Contents/MacOS/Snipaste"
  HOME="$trial_home" XDG_CONFIG_HOME="$trial_home/custom config" \
    PATH="$trial_home/fake-bin:$PATH" bash "$ROOT_DIR/config/snipaste/launch.sh" snip -o clipboard
  expected="--config=$trial_home/custom config/mac-setup/snipaste/config.ini"
  [[ "$(head -n 1 "$trial_home/args")" == "$expected" ]]
  [[ "$(tail -n 3 "$trial_home/args")" == $'snip\n-o\nclipboard' ]]
  printf 'PASS snipaste launcher %s\n' "$platform"
done

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# Exercise the real sync module and link helper without touching the user's HOME.
for platform in linux macos; do
  HOME="$TEMP_ROOT/$platform" ROOT_DIR="$ROOT_DIR" PLATFORM="$platform" bash -c '
    set -euo pipefail
    source "$ROOT_DIR/lib/utils.sh"
    log() { :; }
    is_macos() { [[ "$PLATFORM" == macos ]]; }
    is_linux() { [[ "$PLATFORM" == linux ]]; }
    source "$ROOT_DIR/modules/sync.sh"
    autostart="$HOME/.config/autostart/devilspie2.desktop"
    target="$HOME/.config/devilspie2/workspaces.lua"
    if is_linux; then
      [[ -L "$target" ]]
      [[ "$(readlink "$target")" == "$ROOT_DIR/config/devilspie2/workspaces.lua" ]]
      [[ "$(readlink "$autostart")" == "$ROOT_DIR/config/devilspie2/devilspie2.desktop" ]]
      # Repeated sync must keep the same managed link.
      sync_configs
      [[ "$(readlink "$target")" == "$ROOT_DIR/config/devilspie2/workspaces.lua" ]]
    else
      [[ ! -e "$target" && ! -L "$target" ]]
      [[ ! -e "$autostart" && ! -L "$autostart" ]]
    fi
  '
done
printf 'PASS Linux Devilspie2 configuration sync and macOS isolation\n'

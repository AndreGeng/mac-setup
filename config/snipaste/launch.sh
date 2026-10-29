#!/usr/bin/env bash
# mac-setup Snipaste launcher
set -euo pipefail
config="${XDG_CONFIG_HOME:-$HOME/.config}/mac-setup/snipaste/config.ini"
if [[ "$(uname -s)" == Darwin ]]; then
  binary="/Applications/Snipaste.app/Contents/MacOS/Snipaste"
  if [[ ! -x "$binary" ]]; then
    binary="$HOME/Applications/Snipaste.app/Contents/MacOS/Snipaste"
  fi
elif command -v Snipaste >/dev/null 2>&1; then
  binary="$(command -v Snipaste)"
else
  binary="$HOME/.local/share/mac-setup/snipaste/2.11.3/usr/bin/Snipaste"
  export APPIMAGE="$HOME/.local/share/mac-setup/snipaste/2.11.3/Snipaste.AppImage"
fi
if [[ ! -x "$binary" ]]; then
  printf 'Snipaste is unavailable; run ./setup.sh --modules snipaste first.\n' >&2
  exit 1
fi
exec "$binary" "--config=$config" "$@"

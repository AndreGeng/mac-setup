#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
export HOME="$TEMP_ROOT/home"
mkdir -p "$HOME"
export XDG_CURRENT_DESKTOP=XFCE DISPLAY=:1
export TRACE="$TEMP_ROOT/trace"
xfconf-query() { printf '%s\n' "$*" >>"$TRACE"; }
export -f xfconf-query
bash "$ROOT_DIR/modules/xfce.sh"
grep -q '/Default/KeyRepeat/Delay -n -t int -s 250' "$TRACE"
grep -q '/Default/KeyRepeat/Rate -n -t int -s 40' "$TRACE"
[[ "$(wc -l <"$TRACE")" -eq 3 ]]
: >"$TRACE"
XDG_CURRENT_DESKTOP=GNOME bash "$ROOT_DIR/modules/xfce.sh"
[[ ! -s "$TRACE" ]]
printf 'PASS XFCE keyboard repeat settings and desktop guard\n'

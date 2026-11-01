#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
export HOME="$TEMP_ROOT/home"
mkdir -p "$HOME"
export XDG_CURRENT_DESKTOP=XFCE DISPLAY=:1
export TRACE="$TEMP_ROOT/trace"
xfconf-query() {
  [[ "$*" != '-c xfce4-panel -lv' ]] || return 0
  printf '%s\n' "$*" >>"$TRACE"
}
export -f xfconf-query
bash "$ROOT_DIR/modules/xfce.sh"
grep -q '/Default/KeyRepeat/Delay -n -t int -s 250' "$TRACE"
grep -q '/Default/KeyRepeat/Rate -n -t int -s 40' "$TRACE"
[[ "$(wc -l <"$TRACE")" -eq 3 ]]
: >"$TRACE"
XDG_CURRENT_DESKTOP=GNOME bash "$ROOT_DIR/modules/xfce.sh"
[[ ! -s "$TRACE" ]]
DISPLAY= bash "$ROOT_DIR/modules/xfce.sh"
[[ ! -s "$TRACE" ]]
printf 'PASS XFCE keyboard repeat settings and desktop guard\n'

# Load functions without touching the real session, then stub every desktop command.
XDG_CURRENT_DESKTOP=GNOME source "$ROOT_DIR/modules/xfce.sh"
xfce4-power-manager() { :; }
xfce4-panel() { printf 'restart\n' >>"$TRACE"; }
xfconf-query() {
  if [[ "$*" == '-c xfce4-panel -lv' ]]; then
    cat "$TEMP_ROOT/panel"
  else
    printf '%s\n' "$*" >>"$TRACE"
  fi
}
cat >"$TEMP_ROOT/panel" <<'EOF'
/panels/panel-1/position p=6;x=0;y=0
/panels/panel-1/plugin-ids [1,3,8,21,10]
/panels/panel-2/position p=10;x=0;y=0
/panels/panel-2/plugin-ids [11,12]
/plugins/plugin-1 applicationsmenu
/plugins/plugin-8 clock
/plugins/plugin-21 pulseaudio
EOF
: >"$TRACE"
configure_xfce_battery
grep -q '/plugins/plugin-22 -n -t string -s power-manager-plugin' "$TRACE"
grep -q '/show-panel-label -n -t uint -s 1' "$TRACE"
grep -q '/panels/panel-1/plugin-ids -t int -s 1 -t int -s 3 -t int -s 22 -t int -s 8 -t int -s 21 -t int -s 10' "$TRACE"
[[ "$(grep -c '^restart$' "$TRACE")" -eq 1 ]]
printf '/plugins/plugin-22 power-manager-plugin\n' >>"$TEMP_ROOT/panel"
: >"$TRACE"
configure_xfce_battery
[[ "$(wc -l <"$TRACE")" -eq 1 ]]
grep -q '/show-panel-label' "$TRACE"

# A top panel with another ID and no clock retains its order and gains one icon.
cat >"$TEMP_ROOT/panel" <<'EOF'
/panels/panel-4/position p=6;x=640;y=0
/panels/panel-4/plugin-ids [5,31]
/plugins/plugin-5 applicationsmenu
/plugins/plugin-31 actions
EOF
: >"$TRACE"
configure_xfce_battery
grep -q '/plugins/plugin-32 -n -t string -s power-manager-plugin' "$TRACE"
grep -q '/panels/panel-4/plugin-ids -t int -s 5 -t int -s 31 -t int -s 32' "$TRACE"

# An unfamiliar layout must not be rewritten or restarted.
sed -i '/power-manager-plugin/d; s/p=6;/p=10;/' "$TEMP_ROOT/panel"
: >"$TRACE"
configure_xfce_battery
[[ ! -s "$TRACE" ]]
printf 'PASS XFCE battery placement, existing plugin reuse and layout guard\n'

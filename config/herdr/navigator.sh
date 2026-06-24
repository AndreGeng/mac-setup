#!/usr/bin/env bash
set -euo pipefail

direction="${1:?direction required}"
key="${2:?key required}"

pane_json="$(herdr pane current)"
pane_id="$(printf '%s' "$pane_json" | sed -n 's/.*"pane_id":"\([^"]*\)".*/\1/p')"

if [[ -z "$pane_id" ]]; then
  exit 1
fi

process_json="$(herdr pane process-info --pane "$pane_id")"

if printf '%s' "$process_json" | grep -qiE '"name":"([^"]*/)?(g?view|l?n?vimx?|fzf)(diff)?"|"argv0":"([^"]*/)?(g?view|l?n?vimx?|fzf)(diff)?"'; then
  herdr pane send-keys "$pane_id" "$key"
else
  herdr pane focus --direction "$direction" --pane "$pane_id"
fi

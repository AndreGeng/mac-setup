#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# Exercise the startup block with and without zoxide, including Zinit's zi alias.
sed -n '/^# zoxide startup begin$/,/^# zoxide startup end$/p' \
  "$ROOT_DIR/config/.zshrc" >"$TEMP_ROOT/init.zsh"
[[ -s "$TEMP_ROOT/init.zsh" ]]
mkdir -p "$TEMP_ROOT/bin" "$TEMP_ROOT/home"
cat >"$TEMP_ROOT/bin/zoxide" <<'EOF'
#!/bin/sh
[ "$1 $2" = 'init zsh' ] || exit 1
printf '%s\n' 'z() { builtin cd -- "$1"; }' 'zi() { z "$1"; }'
EOF
chmod +x "$TEMP_ROOT/bin/zoxide"

HOME="$TEMP_ROOT/home" PATH="$TEMP_ROOT/bin" /usr/bin/zsh -f -c '
  alias zi=zinit
  source "$1"
  (( ${+functions[z]} && ${+functions[zi]} )) || exit 1
  zi "$HOME" && [[ "$PWD" == "$HOME" ]]
' -- "$TEMP_ROOT/init.zsh"

HOME="$TEMP_ROOT/home" PATH="$TEMP_ROOT/empty" /usr/bin/zsh -f -c '
  alias zi=zinit
  source "$1"
  [[ "$aliases[zi]" == zinit ]] && (( ! ${+functions[z]} ))
' -- "$TEMP_ROOT/init.zsh"
printf 'PASS zoxide startup and optional dependency\n'

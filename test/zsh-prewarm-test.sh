#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

source "$ROOT_DIR/lib/utils.sh"

if ! declare -F prewarm_zsh_environment >/dev/null; then
  printf '%s\n' 'FAIL prewarm_zsh_environment is missing' >&2
  exit 1
fi

home="$TEMP_ROOT/home"
fake_bin="$TEMP_ROOT/bin"
trace="$TEMP_ROOT/zsh.trace"
mkdir -p "$home" "$fake_bin"
: >"$home/.zshrc"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s|%s|%s\n" "${TERM:-}" "$PWD" "$*" >"$TRACE_FILE"' \
  >"$fake_bin/zsh"
chmod +x "$fake_bin/zsh"

HOME="$home" PATH="$fake_bin:/usr/bin:/bin" TERM=unknown TRACE_FILE="$trace" \
  prewarm_zsh_environment >/dev/null 2>&1 || {
  printf '%s\n' 'FAIL prewarm_zsh_environment returned non-zero' >&2
  exit 1
}

expected="xterm-256color|$home|-lic exit"
[[ "$(<"$trace")" == "$expected" ]] || {
  printf 'FAIL unexpected Zsh prewarm invocation: %s\n' "$(<"$trace")" >&2
  exit 1
}

printf '%s\n' 'PASS Zsh prewarm uses a stable terminal and login shell'

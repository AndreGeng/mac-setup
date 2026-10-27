#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

# Every case uses a private HOME, synthetic upstream payload, and no network/sudo.
run_case() (
  local scenario="$1"
  export HOME="$TEMP_ROOT/$scenario.home"
  export TMPDIR="$TEMP_ROOT/$scenario.tmp"
  local trace="$TEMP_ROOT/$scenario.trace"
  mkdir -p "$HOME" "$TMPDIR" "$TEMP_ROOT/payload/Toshy-fixture"
  : >"$trace"
  : >"$TEMP_ROOT/payload/Toshy-fixture/setup_toshy.py"
  tar -czf "$TEMP_ROOT/fixture.tar.gz" -C "$TEMP_ROOT/payload" Toshy-fixture

  source "$ROOT_DIR/lib/platform.sh"
  source "$ROOT_DIR/lib/utils.sh"
  is_linux() { return 0; }
  id() { printf '%s\n' 1000; }
  curl() {
    printf 'download %s\n' "$*" >>"$trace"
    [[ "$scenario" != download-failure ]] || return 1
    cp "$TEMP_ROOT/fixture.tar.gz" "${@: -1}"
  }
  python3() {
    if [[ "${1:-}" == */scripts/configure-toshy.py ]]; then
      printf 'configure shortcuts\n' >>"$trace"
      [[ "$scenario" != configure-failure ]]
      return
    fi
    printf 'python %s\n' "$*" >>"$trace"
    [[ "$scenario" != installer-failure ]] || return 7
    mkdir -p "$HOME/.config/toshy" "$HOME/.local/bin"
    : >"$HOME/.config/toshy/toshy_config.py"
    printf '#!/bin/sh\n' >"$HOME/.local/bin/toshy-config-start"
    chmod +x "$HOME/.local/bin/toshy-config-start"
  }
  export DISPLAY=:1
  unset WAYLAND_DISPLAY MAC_SETUP_NO_ROOT MAC_SETUP_SKIP_TOSHY
  # Loading is safe without a terminal; then emulate an interactive desktop.
  source "$ROOT_DIR/modules/toshy.sh" || return 1
  [[ ! -s "$trace" ]] || return 1
  toshy_has_terminal() { return 0; }
  if [[ "$scenario" != checksum-failure ]]; then
    verify_file_sha256() {
      [[ -f "$1" && "$2" == 37e1c21fb7de8df5f7351b22080e90186d7009b6816b9cd4dd76fce08470989e ]]
    }
  fi
  case "$scenario" in
  macos) is_linux() { return 1; } ;;
  root) id() { printf '%s\n' 0; } ;;
  no-root) export MAC_SETUP_NO_ROOT=1 ;;
  opt-out) export MAC_SETUP_SKIP_TOSHY=1 ;;
  headless) unset DISPLAY WAYLAND_DISPLAY ;;
  noninteractive) toshy_has_terminal() { return 1; } ;;
  wayland)
    unset DISPLAY
    export WAYLAND_DISPLAY=wayland-0
    ;;
  esac
  case "$scenario" in
  checksum-failure | download-failure | installer-failure | configure-failure)
    if install_toshy; then
      printf 'Unexpected success: %s\n' "$scenario" >&2
      return 1
    fi
    if [[ "$scenario" != installer-failure && "$scenario" != configure-failure ]]; then
      ! grep -q '^python ' "$trace" || return 1
    fi
    ;;
  macos | root | no-root | opt-out | headless | noninteractive)
    install_toshy || return 1
    [[ ! -s "$trace" ]] || return 1
    ;;
  desktop | wayland)
    install_toshy || return 1
    grep -q 'ac3dbfcdd6e7a11c95ea892c19fb5b1643f45a82' "$trace" || return 1
    grep -q '^python ./setup_toshy.py install$' "$trace" || return 1
    grep -q '^configure shortcuts$' "$trace" || return 1
    : >"$trace"
    install_toshy || return 1
    [[ "$(cat "$trace")" == 'configure shortcuts' ]] || return 1
    ;;
  esac
  [[ -z "$(ls -A "$TMPDIR")" ]]
)

for scenario in macos root no-root opt-out headless noninteractive desktop wayland \
  checksum-failure download-failure installer-failure configure-failure; do
  run_case "$scenario" >"$TEMP_ROOT/$scenario.out" 2>&1 || {
    cat "$TEMP_ROOT/$scenario.out" >&2
    printf 'FAIL toshy %s\n' "$scenario" >&2
    exit 1
  }
  printf 'PASS toshy %s\n' "$scenario"
done

# Platform enumeration must leave stdin available to upstream prompts.
fixture="$TEMP_ROOT/setup-fixture"
mkdir -p "$fixture/modules" "$fixture/platforms/linux" "$fixture/home"
cp "$ROOT_DIR/setup.sh" "$ROOT_DIR/setup-lite.sh" "$fixture/"
cp -R "$ROOT_DIR/lib" "$fixture/lib"
: >"$fixture/modules/sync.sh"
cat >"$fixture/platforms/linux/probe.sh" <<'EOF'
IFS= read -r answer
[[ "$answer" == toshy-prompt-input ]]
printf 'PROMPT_INPUT_PRESERVED\n'
EOF
for entry in setup.sh setup-lite.sh; do
  # Its sole module is empty and platform script only reads stdin.
  # setup-lite has no --no-root, so use a sudo stub.
  output="$(printf 'toshy-prompt-input\n' | OSTYPE=linux-gnu HOME="$fixture/home" \
    bash -c 'sudo() { return 0; }; source "$1" --modules sync --with-platform' \
    fixture "$fixture/$entry")"
  [[ "$output" == *PROMPT_INPUT_PRESERVED* ]]
done
printf 'PASS toshy platform prompts preserve stdin\n'

output="$(OSTYPE=linux-gnu bash "$ROOT_DIR/setup.sh" --dry-run)"
[[ "$output" == *'/platforms/linux/toshy.sh'* ]]
output="$(bash "$ROOT_DIR/setup.sh" --dry-run --modules toshy)"
[[ "$output" == *'/modules/toshy.sh'* && "$output" != *'/platforms/'* ]]
output="$(OSTYPE=linux-gnu bash "$ROOT_DIR/setup-lite.sh" --dry-run --with-platform)"
[[ "$output" == *'/platforms/linux/toshy.sh'* ]]
output="$(OSTYPE=darwin bash "$ROOT_DIR/setup.sh" --dry-run)"
[[ "$output" != *'/platforms/linux/toshy.sh'* ]]
printf 'PASS toshy setup entry points\n'

PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT_DIR/test/toshy-config-test.py"

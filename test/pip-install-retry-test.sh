#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

source "$ROOT_DIR/lib/utils.sh"

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

if ! declare -F pip_install_with_retry >/dev/null; then
  fail 'pip_install_with_retry is missing'
fi

fake_python="$TEMP_ROOT/python"
trace="$TEMP_ROOT/pip.trace"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >>"$PIP_TRACE"' \
  'attempt="$(wc -l <"$PIP_TRACE" | tr -d " ")"' \
  'if ((attempt <= FAIL_UNTIL)); then exit 1; fi' \
  >"$fake_python"
chmod +x "$fake_python"

PIP_TRACE="$trace" FAIL_UNTIL=2 \
  pip_install_with_retry "$fake_python" 'reme-ai[core]==0.4.1.7' 3 300 10 0 \
  >/dev/null 2>&1 || fail 'transient pip failures were not retried'

[[ "$(wc -l <"$trace" | tr -d ' ')" == "3" ]] ||
  fail 'successful install did not use exactly three attempts'
[[ "$(grep -Fc -- '--timeout 300 --retries 10' "$trace")" == "3" ]] ||
  fail 'pip timeout and retry options were not applied to every attempt'

: >"$trace"
if PIP_TRACE="$trace" FAIL_UNTIL=99 \
  pip_install_with_retry "$fake_python" 'reme-ai[core]==0.4.1.7' 2 300 10 0 \
  >/dev/null 2>&1; then
  fail 'permanent pip failure was silently accepted'
fi
[[ "$(wc -l <"$trace" | tr -d ' ')" == "2" ]] ||
  fail 'permanent failure did not stop at the configured attempt limit'

printf '%s\n' 'PASS pip install retries transient failures and preserves permanent failures'

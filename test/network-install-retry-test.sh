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

if ! declare -F run_with_retry >/dev/null; then
  fail 'run_with_retry is missing'
fi

fake_command="$TEMP_ROOT/mise"
trace="$TEMP_ROOT/mise.trace"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >>"$RETRY_TRACE"' \
  'attempt="$(wc -l <"$RETRY_TRACE" | tr -d " ")"' \
  'if ((attempt <= FAIL_UNTIL)); then exit 1; fi' \
  >"$fake_command"
chmod +x "$fake_command"

RETRY_TRACE="$trace" FAIL_UNTIL=2 \
  run_with_retry 'mise install python@3.11' 3 0 \
  "$fake_command" install python@3.11 >/dev/null 2>&1 ||
  fail 'transient command failures were not retried'
[[ "$(wc -l <"$trace" | tr -d ' ')" == "3" ]] ||
  fail 'successful command did not use exactly three attempts'

: >"$trace"
if RETRY_TRACE="$trace" FAIL_UNTIL=99 \
  run_with_retry 'mise install python@3.11' 2 0 \
  "$fake_command" install python@3.11 >/dev/null 2>&1; then
  fail 'permanent command failure was silently accepted'
fi
[[ "$(wc -l <"$trace" | tr -d ' ')" == "2" ]] ||
  fail 'permanent command failure did not stop at the configured limit'

grep -Fq 'run_with_retry "mise install $build_runtime"' "$ROOT_DIR/lib/utils.sh" ||
  fail 'tree-sitter build runtime does not retry mise install'
grep -Fq 'run_with_retry "mise install go@${go_version}"' "$ROOT_DIR/lib/utils.sh" ||
  fail 'Go runtime does not retry mise install'
grep -Fq 'run_with_retry "mise install python@${python3_version}"' "$ROOT_DIR/modules/vim.sh" ||
  fail 'Python runtime does not retry mise install'
grep -Fq 'run_with_retry "mise use ${runtime_name}@${runtime_version}"' \
  "$ROOT_DIR/modules/nodejs.sh" ||
  fail 'Node/Bun runtimes do not retry mise use'

printf '%s\n' 'PASS network installers retry transient command failures'

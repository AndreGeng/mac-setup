#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="$ROOT_DIR/bin/mac-setup"

fail() {
  printf 'FAIL ubuntu terminal E2E: %s\n' "$1" >&2
  exit 1
}

json_has() {
  local json="$1"
  local fragment="$2"
  printf '%s\n' "$json" | grep -Fq "$fragment"
}

printf '%s\n' 'E2E doctor'
doctor_json="$($CLI doctor --format json)"
printf '%s\n' "$doctor_json"
json_has "$doctor_json" '"status":"READY"' || fail 'doctor is not READY'
json_has "$doctor_json" '"platform":"ubuntu"' || fail 'platform is not ubuntu'

printf '%s\n' 'E2E initial plan'
plan_json="$($CLI plan terminal --format json)"
printf '%s\n' "$plan_json"
json_has "$plan_json" '"status":"CHANGES_REQUIRED"' || fail 'fresh plan has no changes'
json_has "$plan_json" '"type":"network"' || fail 'network approval is missing'
json_has "$plan_json" '"type":"sudo"' || fail 'sudo approval is missing'
plan_id="$(printf '%s\n' "$plan_json" | sed -n 's/.*"planId":"\([^"]*\)".*/\1/p')"
[[ -n "$plan_id" ]] || fail 'planId is missing'

printf 'E2E apply %s\n' "$plan_id"
if ! apply_json="$($CLI apply terminal --plan-id "$plan_id" \
  --allow network --allow sudo --non-interactive --format json)"; then
  printf '%s\n' "$apply_json"
  fail 'apply failed'
fi
printf '%s\n' "$apply_json"
json_has "$apply_json" '"status":"SUCCESS"' || fail 'apply did not report SUCCESS'

printf '%s\n' 'E2E verify'
verify_json="$($CLI verify terminal --format json)"
printf '%s\n' "$verify_json"
json_has "$verify_json" '"status":"COMPLIANT"' || fail 'verify is not COMPLIANT'
json_has "$verify_json" '"id":"fd-executable","status":"PASS"' ||
  fail 'fd executable did not pass verification'
json_has "$verify_json" '"id":"zinit-repository","status":"PASS"' ||
  fail 'Zinit repository did not pass verification'

zinit_dir="$HOME/.local/share/zinit/zinit.git"
[[ -d "$zinit_dir/.git" ]] || fail 'canonical Zinit Git repository is missing'
[[ -f "$zinit_dir/zinit.zsh" ]] || fail 'canonical Zinit entrypoint is missing'
[[ -L "$HOME/.local/bin/fd" ]] || fail 'fd compatibility link is missing'
[[ "$(readlink "$HOME/.local/bin/fd")" == "$(command -v fdfind)" ]] ||
  fail 'fd compatibility link does not target fdfind'

printf '%s\n' 'E2E idempotence plan'
replan_json="$($CLI plan terminal --format json)"
printf '%s\n' "$replan_json"
json_has "$replan_json" '"status":"COMPLIANT"' || fail 'second plan is not COMPLIANT'
json_has "$replan_json" '"changes":[]' || fail 'second plan still contains changes'
json_has "$replan_json" '"requiredApprovals":[]' ||
  fail 'second plan still requires approvals'

printf '%s\n' 'PASS ubuntu terminal E2E'

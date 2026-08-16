#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCANNER="$ROOT_DIR/scripts/privacy-scan.sh"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

pass_count=0

new_repo() {
  local name="$1"
  local repo="$TEMP_ROOT/$name"

  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email "security-test@example.invalid"
  git -C "$repo" config user.name "Security Test"
  printf '%s\n' "$repo"
}

expect_pass() {
  local name="$1"
  local repo="$2"

  if ! "$SCANNER" --repo "$repo" >"$TEMP_ROOT/$name.out" 2>&1; then
    printf 'FAIL %s: expected success\n' "$name" >&2
    sed 's/^/  /' "$TEMP_ROOT/$name.out" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_fail_without_value() {
  local name="$1"
  local repo="$2"
  local value="$3"
  shift 3

  if "$SCANNER" --repo "$repo" "$@" >"$TEMP_ROOT/$name.out" 2>&1; then
    printf 'FAIL %s: expected failure\n' "$name" >&2
    exit 1
  fi
  if grep -Fq "$value" "$TEMP_ROOT/$name.out"; then
    printf 'FAIL %s: scanner leaked the matched value\n' "$name" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_pass_args() {
  local name="$1"
  local repo="$2"
  shift 2

  if ! "$SCANNER" --repo "$repo" "$@" >"$TEMP_ROOT/$name.out" 2>&1; then
    printf 'FAIL %s: expected success\n' "$name" >&2
    sed 's/^/  /' "$TEMP_ROOT/$name.out" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

repo="$(new_repo safe)"
printf 'API_URL={env:API_URL}\n' >"$repo/config.txt"
git -C "$repo" add config.txt
expect_pass safe "$repo"

repo="$(new_repo mcp-token)"
value='mcp_''_testCredentialValue1234567890'
printf 'safe content before finding\n' >"$repo/00-safe.txt"
printf 'url=https://example.invalid/mcp/%s\n' "$value" >"$repo/config.txt"
git -C "$repo" add 00-safe.txt config.txt
expect_fail_without_value mcp-token "$repo" "$value"

repo="$(new_repo personal-path)"
value='/Users/''private-user/Documents/client-project'
printf 'root=%s\n' "$value" >"$repo/config.txt"
git -C "$repo" add config.txt
expect_fail_without_value personal-path "$repo" "$value"

repo="$(new_repo internal-domain)"
value='service.example.''srv'
printf 'endpoint=%s\n' "$value" >"$repo/config.txt"
git -C "$repo" add config.txt
expect_fail_without_value internal-domain "$repo" "$value"

repo="$(new_repo enterprise-email)"
value='developer@''xiaomi.com'
printf 'owner=%s\n' "$value" >"$repo/config.txt"
git -C "$repo" add config.txt
expect_fail_without_value enterprise-email "$repo" "$value"

repo="$(new_repo forbidden-file)"
mkdir -p "$repo/config"
printf '{}\n' >"$repo/config/auth.json"
git -C "$repo" add config/auth.json
expect_fail_without_value forbidden-file "$repo" 'unused-value'

repo="$(new_repo staged-snapshot)"
value='mcp_''_stagedCredentialValue1234567890'
printf 'url=%s\n' "$value" >"$repo/config.txt"
git -C "$repo" add config.txt
printf 'safe working tree\n' >"$repo/config.txt"
expect_fail_without_value staged-snapshot "$repo" "$value" --staged

repo="$(new_repo untracked)"
value='/Users/''untracked-user/private'
printf 'path=%s\n' "$value" >"$repo/untracked.txt"
expect_fail_without_value untracked "$repo" "$value" --untracked

repo="$(new_repo legacy-range)"
printf 'safe\n' >"$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -qm initial
mkdir -p "$repo/neovim3"
printf 'neovim3/\tlegacy baseline\n' >"$repo/.privacyignore"
value='/Users/''new-user/private'
printf 'path=%s\n' "$value" >"$repo/neovim3/new.txt"
git -C "$repo" add .privacyignore neovim3/new.txt
git -C "$repo" commit -qm sensitive-change
printf 'safe working tree\n' >"$repo/neovim3/new.txt"
expect_fail_without_value legacy-range "$repo" "$value" --range HEAD~1..HEAD

repo="$(new_repo range-additions-only)"
value='/Users/''legacy-user/private'
printf 'path=%s\n' "$value" >"$repo/config.txt"
git -C "$repo" add config.txt
git -C "$repo" commit -qm legacy
printf 'path=%s\nsafe=true\n' "$value" >"$repo/config.txt"
git -C "$repo" add config.txt
git -C "$repo" commit -qm safe-change
expect_pass_args range-additions-only "$repo" --range HEAD~1..HEAD

repo="$(new_repo plus-prefix-range)"
printf 'safe\n' >"$repo/config.txt"
git -C "$repo" add config.txt
git -C "$repo" commit -qm initial
value='mcp_''_plusPrefixCredentialValue1234567890'
printf '++ %s\n' "$value" >>"$repo/config.txt"
git -C "$repo" add config.txt
git -C "$repo" commit -qm plus-prefix
expect_fail_without_value plus-prefix-range "$repo" "$value" --range HEAD~1..HEAD

printf 'PASS security scanner tests (%d cases)\n' "$pass_count"

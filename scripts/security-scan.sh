#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v gitleaks >/dev/null 2>&1; then
  printf '%s\n' 'gitleaks is required. Install it with: brew install gitleaks' >&2
  exit 2
fi

printf '%s\n' 'Running Gitleaks history scan...'
gitleaks git \
  --config "$ROOT_DIR/.gitleaks.toml" \
  --gitleaks-ignore-path "$ROOT_DIR/.gitleaksignore" \
  --redact=100 \
  --no-banner \
  "$ROOT_DIR"

printf '%s\n' 'Running Gitleaks working tree scan...'
gitleaks dir \
  --config "$ROOT_DIR/.gitleaks.toml" \
  --redact=100 \
  --no-banner \
  "$ROOT_DIR"

printf '%s\n' 'Running repository privacy scan...'
"$ROOT_DIR/scripts/privacy-scan.sh" --repo "$ROOT_DIR"
"$ROOT_DIR/scripts/privacy-scan.sh" --repo "$ROOT_DIR" --staged
"$ROOT_DIR/scripts/privacy-scan.sh" --repo "$ROOT_DIR" --untracked

printf '%s\n' 'Security scan passed.'

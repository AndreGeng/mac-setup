#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="${MAC_SETUP_TERMINAL_E2E_IMAGE:-mac-setup-terminal-test}"

docker build -f "$ROOT_DIR/test/Dockerfile.ubuntu" -t "$IMAGE_NAME" "$ROOT_DIR"
docker run --rm --entrypoint bash "$IMAGE_NAME" \
  ./mac-setup/test/e2e/ubuntu-terminal.sh

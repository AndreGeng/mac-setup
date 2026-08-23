#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="mac-setup-arch-test"

# Mainline Arch Linux publishes its official container for amd64 only. On an
# Apple Silicon Docker host, exercise that real image through Docker's platform
# emulation instead of silently substituting a different distribution image.
docker build --platform linux/amd64 \
  -f "$ROOT_DIR/test/Dockerfile.arch" -t "$IMAGE_NAME" "$ROOT_DIR"
docker run --rm --platform linux/amd64 "$IMAGE_NAME"

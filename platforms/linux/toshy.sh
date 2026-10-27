#!/usr/bin/env bash
set -euo pipefail

# Shared by Ubuntu/Debian, Arch, Fedora, and the generic Linux platform phase.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/modules/toshy.sh"

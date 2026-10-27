#!/usr/bin/env bash
set -euo pipefail

# Runs after Toshy in the shared Linux desktop phase.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/modules/vicinae.sh"

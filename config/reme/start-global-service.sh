#!/usr/bin/env bash
set -euo pipefail

umask 077
exec "$@"

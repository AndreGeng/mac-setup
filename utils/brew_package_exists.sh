#!/usr/bin/env bash
#
# 若 Homebrew 公式未安装则 brew install；已安装则跳过（brewI = brew install if missing）。
# 注意: dirname "$0" 相对于「执行该脚本时的路径」，从非仓库根目录调用时可能需调整。
#
source $(dirname "$0")/utils/command_exists.sh

brewI() {
  if brew ls --versions "$1" >/dev/null; then
    # The package is installed
    log "$1 already exist!" $GREEN
  else
    # The package is not installed
    log "Installing $1 now!" $GREEN
    brew install "$@"
  fi
}

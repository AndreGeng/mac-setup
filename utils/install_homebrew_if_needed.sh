#!/usr/bin/env bash
#
# 未安装 Homebrew 时拉取国内镜像安装脚本；已安装则只打日志。
#

source $(dirname "$0")/utils/command_exists.sh
if exists brew; then
  log "homebrew already exists!" $GREEN
else
  log "Installing Homebrew Now"
  /bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
fi
export HOMEBREW_FORCE_BREWED_CURL=1

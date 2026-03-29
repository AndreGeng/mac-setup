#!/usr/bin/env bash
#
# 输出带颜色的日志；$1 文本，$2 为 1.constants 中的颜色变量名（如 $GREEN）。
#
log() {
  echo -e "${2}$1${COLOR_OFF}"
}

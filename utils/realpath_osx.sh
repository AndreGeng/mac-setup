#!/bin/bash
#
# macOS 上无 realpath 时的近似实现：返回脚本所在目录的规范绝对路径（依赖 $0）。
#
realpath_osx() {
  echo $(cd $(dirname "$0"); pwd -P)
}

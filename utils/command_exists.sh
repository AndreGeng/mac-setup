#!/usr/bin/env bash
#
# 判断命令是否在 PATH 中（command -v 比 which 更 POSIX、更可靠）。
#
exists() {
  command -v "$1" >/dev/null 2>&1
}

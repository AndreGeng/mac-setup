#!/usr/bin/env bash
#
# 延长 sudo 凭证有效期：先 sudo -v，再后台循环 sudo -n true，适合长时间安装脚本。
# kill -0 $$ 检测当前 shell 是否仍存活，进程结束则退出循环。
#
sudo -v
while true; do
  sudo -n true
  sleep 30
  kill -0 "$$" || exit
done 2>/dev/null &

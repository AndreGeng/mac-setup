#!/usr/bin/env bash
#
# 在 Docker 里构建并运行 Ubuntu 镜像，验证 setup 在 Linux 下的行为（见 test/Dockerfile.ubuntu）。
#

docker build -f test/Dockerfile.ubuntu -t mac-setup-test .
docker run --rm mac-setup-test

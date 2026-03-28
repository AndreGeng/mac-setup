#!/usr/bin/env bash

# Ubuntu Docker 测试脚本

docker build -f test/Dockerfile.ubuntu -t mac-setup-test .
docker run --rm mac-setup-test

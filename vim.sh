#!/usr/bin/env bash

for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

brewI neovim
brewI fd
brewI openssl
brewI xz
brewI the_silver_searcher
brewI ripgrep
brewI ack
brewI font-hack-nerd-font
brewI lua-language-server
brewI fzf
brewI zlib
brewI mise

# 确保mise已加载
eval "$(mise activate zsh)"

# 安装Python版本和创建虚拟环境
unset ALL_PROXY

VENV2_DIR="neovim2"
VENV3_DIR="neovim3"
PYTHON2_VERSION="2.7.18"
PYTHON3_VERSION="3.9.1"

# 检查并安装Python 2.7.18
if ! mise python list | grep -q "$PYTHON2_VERSION"; then
  log "Installing Python $PYTHON2_VERSION" $GREEN
  mise install python@$PYTHON2_VERSION
fi

# 检查并安装Python 3.9.1
if ! mise python list | grep -q "$PYTHON3_VERSION"; then
  log "Installing Python $PYTHON3_VERSION" $GREEN
  mise install python@$PYTHON3_VERSION
fi

mise exec python@$PYTHON2_VERSION -- pip install virtualenv >/dev/null 2>&1

# 创建Python 2.7虚拟环境
if [ ! -d "$VENV2_DIR" ]; then
  log "Creating virtual environment: $VENV2_DIR" $GREEN
  mise exec python@$PYTHON2_VERSION -- virtualenv $VENV2_DIR
fi

# 创建Python 3.9虚拟环境
if [ ! -d "$VENV3_DIR" ]; then
  log "Creating virtual environment: $VENV3_DIR" $GREEN
  mise exec python@$PYTHON3_VERSION -- python -m venv $VENV3_DIR
fi

# 在neovim2环境中安装pynvim
if ! $VENV2_DIR/bin/pip list | grep -q "pynvim"; then
  log "Installing pynvim in $VENV2_DIR virtual environment" $GREEN
  $VENV2_DIR/bin/pip install pynvim
fi

# 在neovim3环境中安装pynvim
if ! $VENV3_DIR/bin/pip list | grep -q "pynvim"; then
  log "Creating virtual environment: $VENV3_DIR" $GREEN
  $VENV3_DIR/bin/pip install pynvim
fi

# 在neovim3环境中安装neovim-remote
if ! $VENV3_DIR/bin/pip list | grep -q "neovim-remote"; then
  log "Installing neovim-remote in $VENV3_DIR virtual environment" $GREEN
  $VENV3_DIR/bin/pip install neovim-remote
fi

# 下载nvim配置
if [ ! -d "$HOME/.config/nvim" ]; then
  log "Copying nvim configuration" $GREEN
  cp -R $(dirname "$0")/mac-config/nvim ~/.config
else
  log "nvim configuration already exists, skipping copy" $YELLOW
fi

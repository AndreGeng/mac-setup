#!/usr/bin/env bash

install_cli_tools() {
  log "=== 安装 CLI 工具 ===" "$GREEN"

  # 通用工具列表
  local tools=(
    "lazygit"
    "the_silver_searcher"
    "git-delta"
    "ast-grep"
    "shfmt"
  )

  for tool in "${tools[@]}"; do
    local cmd_name="${tool%%-*}"
    if ! command -v "$cmd_name" &>/dev/null && ! command -v "$tool" &>/dev/null; then
      pkg_install "$tool" || log "跳过 $tool (可能需要 root)" "$YELLOW"
    else
      log "$tool 已安装，跳过" "$YELLOW"
    fi
  done

  # fzf 单独处理（因为依赖 go，在旧版 macOS 上可能失败）
  install_fzf_safe
}

install_fzf_safe() {
  local home_dir="${HOME:-/root}"

  # 检查多个可能的安装位置
  if command -v fzf &>/dev/null ||
    [[ -x /opt/homebrew/bin/fzf ]] ||
    [[ -x /usr/local/bin/fzf ]] ||
    [[ -x /usr/bin/fzf ]] ||
    [[ -x "$home_dir/.local/bin/fzf" ]]; then
    log "fzf 已安装，跳过" "$YELLOW"
    return 0
  fi

  log "安装 fzf..." "$GREEN"

  # 方法1: Homebrew（macOS）
  if command -v brew &>/dev/null && pkg_install fzf 2>/dev/null; then
    log "fzf 安装成功" "$GREEN"
    return 0
  fi

  log "Homebrew 安装 fzf 失败，尝试下载二进制..." "$YELLOW"

  # 方法2: 直接下载二进制
  local arch os version url ext retry count

  arch=$(uname -m)
  os=$(uname -s | tr '[:upper:]' '[:lower:]')

  # 从 API 获取最新版本
  version=$(curl -sL "https://api.github.com/repos/junegunn/fzf/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/' || echo "0.70.0")

  # 确定文件扩展名和后缀
  case "$os" in
  darwin)
    ext="tar.gz"
    case "$arch" in
    x86_64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    esac
    ;;
  linux)
    ext="tar.gz"
    case "$arch" in
    x86_64) arch="amd64" ;;
    aarch64 | arm64) arch="arm64" ;;
    esac
    ;;
  *)
    log "不支持的操作系统: $os" "$RED"
    return 1
    ;;
  esac

  url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${os}_${arch}.${ext}"

  mkdir -p "$home_dir/.local/bin"

  # 重试下载（网络问题可能临时失败）
  count=0
  while [[ $count -lt 3 ]]; do
    if curl --retry 3 --retry-delay 2 --tlsv1.2 -fLo "/tmp/fzf.${ext}" "$url" 2>/dev/null; then
      break
    fi
    count=$((count + 1))
    log "下载失败，重试 ($count/3)..." "$YELLOW"
    sleep 2
  done

  if [[ -f "/tmp/fzf.${ext}" ]]; then
    tar -xzf "/tmp/fzf.${ext}" -C /tmp
    mv /tmp/fzf "$home_dir/.local/bin/fzf"
    chmod +x "$home_dir/.local/bin/fzf"
    rm -f "/tmp/fzf.${ext}"
    export PATH="$home_dir/.local/bin:$PATH"
    log "fzf 安装成功" "$GREEN"
  else
    rm -f "/tmp/fzf.${ext}"
    log "fzf 下载失败（网络问题），跳过" "$YELLOW"
    return 0 # 不阻塞后续安装
  fi
}

install_cli_tools

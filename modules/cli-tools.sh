#!/usr/bin/env bash
#
# 模块：lazygit、ag、git-delta、ast-grep、shfmt 等 CLI；fzf 单独走 install_fzf_safe（多路回退）。
#

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
    # ${var%%-*} 去掉第一个 - 及其右侧，用于从 git-delta 得到 git 等可执行名探测
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

  # PATH 与常见绝对路径都查一遍，避免只装了二进制但未进当前 PATH
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

  # 方法2: 系统包管理器
  if command -v apt-get &>/dev/null; then
    if apt-get install -y fzf 2>/dev/null; then
      log "fzf 安装成功 (apt)" "$GREEN"
      return 0
    fi
  elif command -v dnf &>/dev/null; then
    if dnf install -y fzf 2>/dev/null; then
      log "fzf 安装成功 (dnf)" "$GREEN"
      return 0
    fi
  fi

  log "包管理器安装失败，尝试下载二进制..." "$YELLOW"

  # 方法3: 直接下载二进制
  local arch os version url ext count

  arch=$(uname -m)
  os=$(uname -s | tr '[:upper:]' '[:lower:]')

  version=$(curl -sL --connect-timeout 10 "https://api.github.com/repos/junegunn/fzf/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/' || echo "0.70.0")

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
    return 0
    ;;
  esac

  local base_url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${os}_${arch}.${ext}"
  local mirrors=(
    "$base_url"
    "https://ghproxy.com/$base_url"
    "https://mirror.ghproxy.com/$base_url"
  )

  mkdir -p "$home_dir/.local/bin"

  for url in "${mirrors[@]}"; do
    count=0
    while [[ $count -lt 2 ]]; do
      if curl -fL --connect-timeout 15 --retry 1 -o "/tmp/fzf.${ext}" "$url" 2>/dev/null; then
        break 2
      fi
      count=$((count + 1))
      sleep 1
    done
  done

  if [[ -s "/tmp/fzf.${ext}" ]]; then
    tar -xzf "/tmp/fzf.${ext}" -C /tmp
    if [[ -f /tmp/fzf ]]; then
      mv /tmp/fzf "$home_dir/.local/bin/fzf"
      chmod +x "$home_dir/.local/bin/fzf"
      rm -f "/tmp/fzf.${ext}"
      export PATH="$home_dir/.local/bin:$PATH"
      log "fzf 安装成功" "$GREEN"
    else
      log "fzf 下载文件无效，跳过" "$YELLOW"
      rm -f "/tmp/fzf.${ext}"
    fi
  else
    rm -f "/tmp/fzf.${ext}"
    log "fzf 下载失败（网络问题），跳过" "$YELLOW"
  fi
}

install_cli_tools

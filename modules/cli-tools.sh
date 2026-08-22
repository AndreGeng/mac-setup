#!/usr/bin/env bash
#
# 模块：lazygit、ag、git-delta、ast-grep、shfmt 等 CLI；fzf 单独走 install_fzf_safe（多路回退）。
#

install_cli_tools() {
  log "=== 安装 CLI 工具 ===" "$GREEN"

  # 通用工具列表
  local tools=(
    "lazygit"
    "yazi"
    "the_silver_searcher"
    "git-delta"
    "ast-grep"
    "shfmt"
    "ffmpeg"
    "jq"
    "poppler"
    "imagemagick"
    "sevenzip"
    "resvg"
    "zoxide"
  )

  for tool in "${tools[@]}"; do
    local cmd_name
    cmd_name="$(tool_command_name "$tool")"
    if ! command -v "$cmd_name" &>/dev/null; then
      pkg_install "$tool" || log "跳过 $tool (可能需要 root)" "$YELLOW"
    else
      log "$tool 已安装，跳过" "$YELLOW"
    fi
  done

  # fzf 单独处理（因为依赖 go，在旧版 macOS 上可能失败）
  install_fzf_safe

  install_yazi_safe
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
  local arch os version url ext count tmp_dir archive

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
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/fzf-install.XXXXXX")"
  archive="$tmp_dir/fzf.${ext}"
  mkdir -p "$home_dir/.local/bin"

  url="$base_url"
  count=0
  while [[ $count -lt 2 ]]; do
    if curl -fL --connect-timeout 15 --retry 1 -o "$archive" "$url" 2>/dev/null; then
      break
    fi
    count=$((count + 1))
    sleep 1
  done

  if [[ -s "$archive" ]]; then
    tar -xzf "$archive" -C "$tmp_dir"
    if [[ -f "$tmp_dir/fzf" ]]; then
      mv "$tmp_dir/fzf" "$home_dir/.local/bin/fzf"
      chmod +x "$home_dir/.local/bin/fzf"
      rm -rf "$tmp_dir"
      export PATH="$home_dir/.local/bin:$PATH"
      log "fzf 安装成功" "$GREEN"
    else
      log "fzf 下载文件无效，跳过" "$YELLOW"
      rm -rf "$tmp_dir"
    fi
  else
    rm -rf "$tmp_dir"
    log "fzf 下载失败（网络问题），跳过" "$YELLOW"
  fi
}

# Yazi 安装（Linux 端下载二进制，macOS/Arch 通过包管理器）
install_yazi_safe() {
  if command -v yazi &>/dev/null; then
    log "yazi 已安装，跳过" "$YELLOW"
    return 0
  fi

  local platform=$(detect_platform)
  local home_dir="${HOME:-/root}"

  # macOS 和 Arch 直接通过包管理器安装（在 tools 数组中已处理）
  if [[ "$platform" == "macos" ]] || [[ "$platform" == "arch" ]]; then
    return 0
  fi

  # Linux 端下载官方二进制
  if [[ "$platform" == "ubuntu" ]] || [[ "$platform" == "fedora" ]] || [[ "$platform" == "linux" ]]; then
    log "安装 yazi（Linux 二进制）..." "$GREEN"

    local arch os version url ext count tmp_dir archive extract_dir yazi_bin ya_bin
    arch=$(uname -m)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')

    version=$(curl -sL --connect-timeout 10 "https://api.github.com/repos/sxyazi/yazi/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/' || echo "25.5.31")

    case "$arch" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="aarch64" ;;
    *)
      log "不支持的架构: $arch" "$RED"
      return 1
      ;;
    esac

    ext="tar.gz"
    local base_url="https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-v${version}-${os}-${arch}.${ext}"
    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/yazi-install.XXXXXX")"
    archive="$tmp_dir/yazi.${ext}"
    extract_dir="$tmp_dir/extract"
    mkdir -p "$extract_dir"
    mkdir -p "$home_dir/.local/bin"

    url="$base_url"
    count=0
    while [[ $count -lt 2 ]]; do
      if curl -fL --connect-timeout 15 --retry 1 -o "$archive" "$url" 2>/dev/null; then
        break
      fi
      count=$((count + 1))
      sleep 1
    done

    if [[ -s "$archive" ]]; then
      tar -xzf "$archive" -C "$extract_dir"
      yazi_bin="$(find "$extract_dir" -type f -name yazi -perm -u+x -print -quit)"
      ya_bin="$(find "$extract_dir" -type f -name ya -perm -u+x -print -quit)"
      if [[ -n "$yazi_bin" && -n "$ya_bin" ]]; then
        mv "$yazi_bin" "$home_dir/.local/bin/yazi"
        mv "$ya_bin" "$home_dir/.local/bin/ya"
        chmod +x "$home_dir/.local/bin/yazi" "$home_dir/.local/bin/ya"
        rm -rf "$tmp_dir"
        export PATH="$home_dir/.local/bin:$PATH"
        log "yazi 安装成功" "$GREEN"
      else
        log "yazi 下载文件无效，跳过" "$YELLOW"
        rm -rf "$tmp_dir"
      fi
    else
      rm -rf "$tmp_dir"
      log "yazi 下载失败（网络问题），跳过" "$YELLOW"
    fi
  fi
}

install_cli_tools

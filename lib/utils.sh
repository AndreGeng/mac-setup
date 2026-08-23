#!/usr/bin/env bash
#
# 被 setup 与各模块 source 的通用工具：日志、软链、mise 安装与路径解析等。
#

UTILS_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$UTILS_REPO_ROOT/lib/bootstrap-manifest.sh"
source "$UTILS_REPO_ROOT/lib/runtime-manifest.sh"

# 终端 ANSI 颜色（NC = no color，用于 log 结尾重置样式）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# $1 消息 $2 可选颜色，默认绿色
log() {
  local msg="$1"
  local color="${2:-$GREEN}"
  echo -e "${color}${msg}${NC}"
}

# 获取脚本根目录
get_script_root() {
  local script_path="${BASH_SOURCE[0]}"
  local script_dir="$(cd "$(dirname "$script_path")" 2>/dev/null && pwd)"
  echo "$script_dir"
}

# 创建符号链接
symlink_config() {
  local src="$1"
  local dest="$2"
  local backup="${3:-true}"

  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]] && [[ "$backup" == "true" ]]; then
    mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  log "链接: $dest -> $src" "$GREEN"
}

# 跨平台 realpath
get_realpath() {
  local path="$1"
  if command -v realpath &>/dev/null; then
    realpath "$path"
  elif command -v grealpath &>/dev/null; then
    grealpath "$path"
  else
    # macOS fallback
    local dir="$(cd "$(dirname "$path")" 2>/dev/null && pwd)"
    echo "$dir/$(basename "$path")"
  fi
}

# 修复 zsh 相关目录权限
fix_zsh_permissions() {
  if [[ "${MAC_SETUP_NO_ROOT:-0}" == "1" ]]; then
    log "跳过 zsh 系统目录权限修复（--no-root）" "$YELLOW"
    return 0
  fi

  local zsh_dirs=(
    "/usr/local/share/zsh"
    "/usr/local/share/zsh/site-functions"
  )

  local sudo_cmd=()
  if [[ $EUID -ne 0 ]]; then
    sudo_cmd=(sudo)
  fi

  for dir in "${zsh_dirs[@]}"; do
    if [[ -d "$dir" ]] && [[ ! -w "$dir" ]]; then
      log "修复目录权限: $dir" "$YELLOW"
      "${sudo_cmd[@]}" chown -R "$(whoami)" "$dir" 2>/dev/null || true
      "${sudo_cmd[@]}" chmod -R u+w "$dir" 2>/dev/null || true
    fi
  done
}

# Zinit's canonical user-level installation, shared by install/plan/verify.
zinit_install_dir() {
  printf '%s\n' "${HOME:-/root}/.local/share/zinit/zinit.git"
}

zinit_install_is_valid() {
  local zinit_dir
  zinit_dir="$(zinit_install_dir)"
  [[ -d "$zinit_dir/.git" && -f "$zinit_dir/zinit.zsh" ]]
}

# 解析可用的 mise 可执行文件路径（必须是常规文件）。
# 注意：目录 ~/.local/bin/mise 在 Unix 上也可能带 +x，用 -x 会误判为「已安装」。
resolve_mise_executable() {
  local home_dir="${HOME:-/root}"
  export PATH="$home_dir/.local/bin:$home_dir/bin:/usr/local/bin:/usr/bin:$PATH"
  local c
  c="$(command -v mise 2>/dev/null || true)"
  if [[ -n "$c" && -f "$c" && -x "$c" ]]; then
    printf '%s\n' "$c"
    return 0
  fi
  local p
  for p in "$home_dir/.local/bin/mise" "$home_dir/bin/mise" /usr/local/bin/mise /usr/bin/mise; do
    if [[ -f "$p" && -x "$p" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

resolve_pinned_node_root() {
  local repo_root="${1:-$UTILS_REPO_ROOT}"
  local node_version mise_bin node_root
  node_version="$(node_manifest_version "$repo_root" runtime node)" || return 1
  mise_bin="$(resolve_mise_executable)" || return 1
  node_root="$("$mise_bin" where "node@${node_version}" 2>/dev/null)" || return 1
  [[ -d "$node_root/bin" ]] || return 1
  printf '%s\n' "$node_root"
}

activate_pinned_node_path() {
  local repo_root="${1:-$UTILS_REPO_ROOT}"
  local node_root
  node_root="$(resolve_pinned_node_root "$repo_root")" || return 1
  [[ -x "$node_root/bin/npm" ]] || return 1
  export PATH="$node_root/bin:$PATH"
}

mise_executable_version() {
  local executable="$1"
  local output
  [[ -f "$executable" && -x "$executable" ]] || return 1
  output="$("$executable" --version 2>/dev/null)" || return 1
  output="${output%% *}"
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  printf '%s\n' "$output"
}

mise_executable_matches() {
  local executable="$1"
  local expected_version="$2"
  local actual_version
  actual_version="$(mise_executable_version "$executable")" || return 1
  [[ "$actual_version" == "$expected_version" ]]
}

file_sha256() {
  local path="$1"
  local output
  if command -v sha256sum >/dev/null 2>&1; then
    output="$(sha256sum "$path")" || return 1
  elif command -v shasum >/dev/null 2>&1; then
    output="$(shasum -a 256 "$path")" || return 1
  else
    return 1
  fi
  output="${output%% *}"
  [[ "$output" =~ ^[0-9a-fA-F]{64}$ ]] || return 1
  printf '%s\n' "$output" | tr '[:upper:]' '[:lower:]'
}

verify_file_sha256() {
  local path="$1"
  local expected="$2"
  local actual
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || return 1
  actual="$(file_sha256 "$path")" || return 1
  [[ "$actual" == "$expected" ]]
}

resolve_neovim_executable() {
  local home_dir="${HOME:-/root}"
  local local_nvim="$home_dir/.local/bin/nvim"
  local resolved

  if [[ -f "$local_nvim" && -x "$local_nvim" ]]; then
    printf '%s\n' "$local_nvim"
    return 0
  fi
  resolved="$(command -v nvim 2>/dev/null || true)"
  [[ -n "$resolved" && -f "$resolved" && -x "$resolved" ]] || return 1
  printf '%s\n' "$resolved"
}

neovim_executable_version() {
  local executable="$1"
  local output
  [[ -f "$executable" && -x "$executable" ]] || return 1
  output="$("$executable" --version 2>/dev/null | head -n 1)" || return 1
  [[ "$output" =~ ^NVIM[[:space:]]v([0-9]+\.[0-9]+\.[0-9]+)$ ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

neovim_executable_matches() {
  local executable="$1"
  local expected_version="$2"
  local actual_version
  actual_version="$(neovim_executable_version "$executable")" || return 1
  [[ "$actual_version" == "$expected_version" ]]
}

neovim_runtime_matches() {
  local repo_root="${1:-$UTILS_REPO_ROOT}"
  local expected_version executable
  expected_version="$(neovim_bootstrap_version "$repo_root")" || return 1
  executable="$(resolve_neovim_executable)" || return 1
  neovim_executable_matches "$executable" "$expected_version"
}

install_neovim_runtime() {
  local home_dir="${HOME:-/root}"
  local local_bin="$home_dir/.local/bin"
  local repo_root="$UTILS_REPO_ROOT"
  local os arch
  export PATH="$local_bin:$PATH"

  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$os" in
  darwin) os=macos ;;
  linux) ;;
  *)
    log "不支持的 Neovim 操作系统: $os" "$RED"
    return 1
    ;;
  esac
  case "$arch" in
  x86_64) arch=x64 ;;
  arm64 | aarch64) arch=arm64 ;;
  *)
    log "不支持的 Neovim 架构: $arch" "$RED"
    return 1
    ;;
  esac

  local record version filename expected_sha256
  if ! record="$(neovim_bootstrap_record "$repo_root" "$os" "$arch")"; then
    log "Neovim bootstrap manifest 无效或不支持当前平台" "$RED"
    return 1
  fi
  IFS='|' read -r version filename expected_sha256 <<<"$record"

  local current_nvim=""
  current_nvim="$(resolve_neovim_executable 2>/dev/null)" || true
  if [[ -n "$current_nvim" ]] && neovim_executable_matches "$current_nvim" "$version"; then
    log "Neovim v${version} 已安装，跳过" "$YELLOW"
    return 0
  fi

  if [[ -n "$current_nvim" ]]; then
    log "Neovim 版本偏离，更新到 v${version}..." "$GREEN"
  else
    log "安装 Neovim v${version}..." "$GREEN"
  fi

  local url="https://github.com/neovim/neovim/releases/download/v${version}/${filename}"
  local tmp_dir archive extract_dir extracted_root runtime_parent runtime_dir stage_dir
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/neovim-install.XXXXXX")" || return 1
  archive="$tmp_dir/$filename"
  extract_dir="$tmp_dir/extract"
  extracted_root="$extract_dir/${filename%.tar.gz}"
  runtime_parent="$home_dir/.local/share/neovim/versions"
  runtime_dir="$runtime_parent/$version"

  log "下载 Neovim v${version}..." "$GREEN"
  if ! curl --proto '=https' --tlsv1.2 -fL -o "$archive" "$url"; then
    rm -rf "$tmp_dir"
    log "Neovim 下载失败；未修改现有安装" "$RED"
    return 1
  fi
  if ! verify_file_sha256 "$archive" "$expected_sha256"; then
    rm -rf "$tmp_dir"
    log "Neovim 下载文件 SHA-256 校验失败；未解压或修改现有安装" "$RED"
    return 1
  fi

  mkdir -p "$extract_dir" "$runtime_parent" "$local_bin"
  if ! tar -xzf "$archive" -C "$extract_dir" || [[ ! -x "$extracted_root/bin/nvim" ]]; then
    rm -rf "$tmp_dir"
    log "Neovim 归档解压失败；未修改现有安装" "$RED"
    return 1
  fi

  stage_dir="$(mktemp -d "$runtime_parent/.${version}.new.XXXXXX")" || {
    rm -rf "$tmp_dir"
    return 1
  }
  if ! cp -R "$extracted_root/." "$stage_dir/" ||
    ! neovim_executable_matches "$stage_dir/bin/nvim" "$version"; then
    rm -rf "$stage_dir" "$tmp_dir"
    log "Neovim 解压内容版本不匹配；未修改现有安装" "$RED"
    return 1
  fi

  rm -rf "$runtime_dir"
  if ! mv "$stage_dir" "$runtime_dir" ||
    ! symlink_config "$runtime_dir/bin/nvim" "$local_bin/nvim"; then
    rm -rf "$stage_dir" "$tmp_dir"
    log "Neovim 安装发布失败" "$RED"
    return 1
  fi

  rm -rf "$tmp_dir"
  export PATH="$local_bin:$PATH"
  log "Neovim v${version} 安装成功" "$GREEN"
}

resolve_tree_sitter_executable() {
  local home_dir="${HOME:-/root}"
  local local_tree_sitter="$home_dir/.local/bin/tree-sitter"
  local resolved

  if [[ -f "$local_tree_sitter" && -x "$local_tree_sitter" ]]; then
    printf '%s\n' "$local_tree_sitter"
    return 0
  fi
  resolved="$(command -v tree-sitter 2>/dev/null || true)"
  [[ -n "$resolved" && -f "$resolved" && -x "$resolved" ]] || return 1
  printf '%s\n' "$resolved"
}

tree_sitter_executable_version() {
  local executable="$1"
  local output
  [[ -f "$executable" && -x "$executable" ]] || return 1
  output="$("$executable" --version 2>/dev/null | head -n 1)" || return 1
  [[ "$output" =~ ^tree-sitter[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+) ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

tree_sitter_executable_matches() {
  local executable="$1"
  local expected_version="$2"
  local actual_version
  actual_version="$(tree_sitter_executable_version "$executable")" || return 1
  [[ "$actual_version" == "$expected_version" ]]
}

tree_sitter_runtime_matches() {
  local repo_root="${1:-$UTILS_REPO_ROOT}"
  local expected_version executable
  expected_version="$(tree_sitter_bootstrap_version "$repo_root")" || return 1
  executable="$(resolve_tree_sitter_executable)" || return 1
  tree_sitter_executable_matches "$executable" "$expected_version"
}

install_tree_sitter_cli() {
  local home_dir="${HOME:-/root}"
  local local_bin="$home_dir/.local/bin"
  local repo_root="$UTILS_REPO_ROOT"
  local os arch
  export PATH="$local_bin:$PATH"

  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$os" in
  darwin) os=macos ;;
  linux) ;;
  *)
    log "不支持的 tree-sitter 操作系统: $os" "$RED"
    return 1
    ;;
  esac
  case "$arch" in
  x86_64) arch=x64 ;;
  arm64 | aarch64) arch=arm64 ;;
  *)
    log "不支持的 tree-sitter 架构: $arch" "$RED"
    return 1
    ;;
  esac

  local record version method artifact expected_sha256 build_runtime
  if ! record="$(tree_sitter_bootstrap_record "$repo_root" "$os" "$arch")"; then
    log "tree-sitter bootstrap manifest 无效或不支持当前平台" "$RED"
    return 1
  fi
  IFS='|' read -r version method artifact expected_sha256 build_runtime <<<"$record"

  local current_tree_sitter=""
  current_tree_sitter="$(resolve_tree_sitter_executable 2>/dev/null)" || true
  if [[ -n "$current_tree_sitter" ]] &&
    tree_sitter_executable_matches "$current_tree_sitter" "$version"; then
    log "tree-sitter CLI v${version} 已安装，跳过" "$YELLOW"
    return 0
  fi

  local url tmp_dir archive extract_dir runtime_parent runtime_dir stage_dir=""
  local source_dir mise_cmd
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/tree-sitter-install.XXXXXX")" || return 1
  archive="$tmp_dir/$artifact"
  extract_dir="$tmp_dir/extract"
  runtime_parent="$home_dir/.local/share/tree-sitter/versions"
  runtime_dir="$runtime_parent/$version"

  case "$method" in
  github-release)
    url="https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/${artifact}"
    ;;
  crates-io)
    url="https://static.crates.io/crates/tree-sitter-cli/${artifact}"
    ;;
  *)
    rm -rf "$tmp_dir"
    log "不支持的 tree-sitter CLI 安装方式: $method" "$RED"
    return 1
    ;;
  esac

  log "下载 tree-sitter CLI v${version}（${method}）..." "$GREEN"
  if ! curl --proto '=https' --tlsv1.2 -fL -o "$archive" "$url"; then
    rm -rf "$tmp_dir"
    log "tree-sitter CLI 下载失败；未修改现有安装" "$RED"
    return 1
  fi
  if ! verify_file_sha256 "$archive" "$expected_sha256"; then
    rm -rf "$tmp_dir"
    log "tree-sitter CLI 下载文件 SHA-256 校验失败；未解压或修改现有安装" "$RED"
    return 1
  fi

  mkdir -p "$extract_dir" "$runtime_parent" "$local_bin"
  stage_dir="$(mktemp -d "$runtime_parent/.${version}.new.XXXXXX")" || {
    rm -rf "$tmp_dir"
    return 1
  }

  case "$method" in
  github-release)
    if ! unzip -q "$archive" -d "$extract_dir" ||
      [[ ! -f "$extract_dir/tree-sitter" ]] ||
      ! mkdir -p "$stage_dir/bin" ||
      ! cp "$extract_dir/tree-sitter" "$stage_dir/bin/tree-sitter" ||
      ! chmod 0755 "$stage_dir/bin/tree-sitter"; then
      rm -rf "$stage_dir" "$tmp_dir"
      log "tree-sitter CLI 归档解压失败；未修改现有安装" "$RED"
      return 1
    fi
    ;;
  crates-io)
    if ! tar -xzf "$archive" -C "$extract_dir"; then
      rm -rf "$stage_dir" "$tmp_dir"
      log "tree-sitter CLI 源码归档解压失败；未修改现有安装" "$RED"
      return 1
    fi
    source_dir="$extract_dir/tree-sitter-cli-${version}"
    if [[ ! -f "$source_dir/Cargo.toml" || ! -f "$source_dir/Cargo.lock" ]]; then
      rm -rf "$stage_dir" "$tmp_dir"
      log "tree-sitter CLI 源码缺少 Cargo.toml 或 Cargo.lock" "$RED"
      return 1
    fi
    if ! install_mise || ! mise_cmd="$(resolve_mise_executable)" ||
      ! "$mise_cmd" install "$build_runtime" ||
      # nvim-treesitter builds repositories that already contain generated parser.c files.
      # The default qjs-rt feature is only needed to generate parsers from grammar.js and
      # would add a libclang/QuickJS build dependency to the base editor environment.
      ! "$mise_cmd" exec "$build_runtime" -- cargo install --locked \
        --no-default-features --path "$source_dir" --root "$stage_dir"; then
      rm -rf "$stage_dir" "$tmp_dir"
      log "tree-sitter CLI 锁定源码构建失败；未修改现有安装" "$RED"
      return 1
    fi
    ;;
  esac

  if ! tree_sitter_executable_matches "$stage_dir/bin/tree-sitter" "$version"; then
    rm -rf "$stage_dir" "$tmp_dir"
    log "tree-sitter CLI 解压内容版本不匹配；未修改现有安装" "$RED"
    return 1
  fi

  rm -rf "$runtime_dir"
  if ! mv "$stage_dir" "$runtime_dir" ||
    ! symlink_config "$runtime_dir/bin/tree-sitter" "$local_bin/tree-sitter"; then
    rm -rf "$stage_dir" "$tmp_dir"
    log "tree-sitter CLI 安装发布失败" "$RED"
    return 1
  fi

  rm -rf "$tmp_dir"
  export PATH="$local_bin:$PATH"
  log "tree-sitter CLI v${version} 安装成功" "$GREEN"
}

# 若 ~/.local/bin/mise 误为目录，移除以便安装真实二进制
cleanup_mise_path_if_directory() {
  local home_dir="${HOME:-/root}"
  local p="${home_dir}/.local/bin/mise"
  if [[ -d "$p" ]]; then
    log "发现 $p 为目录（应为 mise 可执行文件），正在移除..." "$YELLOW"
    rm -rf "$p"
  fi
}

# 安装 mise（直接下载二进制）
install_mise() {
  local home_dir="${HOME:-/root}"
  local local_bin="$home_dir/.local/bin"
  local repo_root="$UTILS_REPO_ROOT"
  export PATH="$local_bin:$home_dir/bin:$PATH"

  # 检测系统和架构
  local arch
  local os
  arch=$(uname -m)
  os=$(uname -s | tr '[:upper:]' '[:lower:]')

  case "$os" in
  darwin) os="macos" ;;
  linux) ;;
  *)
    log "不支持的操作系统: $os" "$RED"
    return 1
    ;;
  esac

  case "$arch" in
  x86_64) arch="x64" ;;
  arm64 | aarch64) arch="arm64" ;;
  *)
    log "不支持的架构: $arch" "$RED"
    return 1
    ;;
  esac

  local record version filename expected_sha256
  if ! record="$(mise_bootstrap_record "$repo_root" "$os" "$arch")"; then
    log "mise bootstrap manifest 无效或不支持当前平台" "$RED"
    return 1
  fi
  IFS='|' read -r version filename expected_sha256 <<<"$record"

  local current_mise=""
  current_mise="$(resolve_mise_executable 2>/dev/null)" || true
  if [[ -n "$current_mise" ]] && mise_executable_matches "$current_mise" "$version"; then
    log "mise v${version} 已安装，跳过" "$YELLOW"
    return 0
  fi

  if [[ -n "$current_mise" ]]; then
    log "mise 版本偏离，更新到 v${version}..." "$GREEN"
  else
    log "安装 mise v${version}..." "$GREEN"
  fi
  cleanup_mise_path_if_directory

  local url="https://github.com/jdx/mise/releases/download/v${version}/${filename}"
  local tmp_dir archive extract_dir extracted_mise install_tmp
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/mise-install.XXXXXX")"
  archive="$tmp_dir/$filename"
  extract_dir="$tmp_dir/extract"
  extracted_mise="$extract_dir/mise/bin/mise"

  log "下载 mise v${version}..." "$GREEN"
  if ! curl --proto '=https' --tlsv1.2 -fL -o "$archive" "$url"; then
    rm -rf "$tmp_dir"
    log "mise 下载失败；未修改现有安装" "$RED"
    return 1
  fi
  if ! verify_file_sha256 "$archive" "$expected_sha256"; then
    rm -rf "$tmp_dir"
    log "mise 下载文件 SHA-256 校验失败；未解压或修改现有安装" "$RED"
    return 1
  fi

  mkdir -p "$extract_dir"
  if ! tar -xzf "$archive" -C "$extract_dir" || [[ ! -f "$extracted_mise" ]]; then
    rm -rf "$tmp_dir"
    log "mise 归档解压失败；未修改现有安装" "$RED"
    return 1
  fi

  mkdir -p "$local_bin"
  install_tmp="$(mktemp "$local_bin/.mise.new.XXXXXX")" || {
    rm -rf "$tmp_dir"
    return 1
  }
  if ! cp "$extracted_mise" "$install_tmp" || ! chmod 0755 "$install_tmp" ||
    ! mv -f "$install_tmp" "$local_bin/mise"; then
    rm -f "$install_tmp"
    rm -rf "$tmp_dir"
    log "mise 安装失败；现有安装未被完整替换" "$RED"
    return 1
  fi

  rm -rf "$tmp_dir"
  log "mise v${version} 安装成功" "$GREEN"
  return 0
}

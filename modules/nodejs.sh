#!/usr/bin/env bash
#
# 模块：mise 全局 Node/Bun + 一组由 manifest 固定版本的全局 npm 包。
#
NODEJS_MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$NODEJS_MODULE_ROOT/lib/runtime-manifest.sh"

if ! declare -F install_mise &>/dev/null; then
  # shellcheck source=../lib/utils.sh
  source "$NODEJS_MODULE_ROOT/lib/utils.sh"
fi

install_nodejs() {
  log "=== 安装 Node.js ===" "$GREEN"

  validate_node_manifest "$NODEJS_MODULE_ROOT" || return 1

  # 安装 mise（独立模块）
  install_mise

  # 确保 PATH 包含 mise
  export PATH="$HOME/.local/bin:$PATH"

  local _mise_bin
  if ! _mise_bin="$(resolve_mise_executable 2>/dev/null)"; then
    log "未找到 mise 可执行文件，无法安装 Node.js" "$RED"
    return 1
  fi

  local runtime_name runtime_version
  while IFS='|' read -r runtime_name runtime_version; do
    log "安装 ${runtime_name} ${runtime_version}..." "$GREEN"
    "$_mise_bin" use -g "${runtime_name}@${runtime_version}" || return 1
  done < <(node_manifest_records "$NODEJS_MODULE_ROOT" runtime)

  local node_version node_root npm_bin
  node_version="$(node_manifest_version "$NODEJS_MODULE_ROOT" runtime node)" || return 1
  if ! node_root="$("$_mise_bin" where "node@${node_version}" 2>/dev/null)"; then
    log "无法定位 node@${node_version}，不能安装全局 npm 包" "$RED"
    return 1
  fi
  npm_bin="$node_root/bin/npm"
  if [[ ! -f "$npm_bin" || ! -x "$npm_bin" ]]; then
    log "node@${node_version} 的 npm 可执行文件不可用" "$RED"
    return 1
  fi

  local package_name package_version package_spec
  while IFS='|' read -r package_name package_version; do
    package_spec="${package_name}@${package_version}"
    if ! PATH="$node_root/bin:$PATH" "$npm_bin" list -g --depth=0 \
      "$package_spec" &>/dev/null 2>&1; then
      log "安装 npm 包: $package_spec" "$GREEN"
      PATH="$node_root/bin:$PATH" "$npm_bin" install -g "$package_spec" || return 1
    else
      log "npm 包 $package_spec 已安装，跳过" "$YELLOW"
    fi
  done < <(node_manifest_records "$NODEJS_MODULE_ROOT" npm)
}

install_nodejs

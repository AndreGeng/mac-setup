#!/usr/bin/env bash
set -e

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载核心库
source "$SCRIPT_ROOT/lib/platform.sh"
source "$SCRIPT_ROOT/lib/package.sh"
source "$SCRIPT_ROOT/lib/utils.sh"

PLATFORM=$(detect_platform)
log "检测到平台: $PLATFORM" "$GREEN"
log "脚本根目录: $SCRIPT_ROOT" "$GREEN"

# Linux 上预先获取 sudo 权限
if is_linux; then
  if ! can_sudo; then
    echo ""
    echo "此脚本需要 sudo 权限来安装系统包。"
    echo "请输入密码以继续（密码不会显示）："
    sudo -v
    echo "sudo 权限获取成功"
  else
    log "sudo 权限已获取" "$GREEN"
  fi
fi

# 解析命令行参数
MODULES=()
DRY_RUN=false
NO_ROOT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --modules)
    IFS=',' read -ra MODULES <<<"$2"
    shift 2
    ;;
  --no-root)
    NO_ROOT=true
    shift
    ;;
  -h | --help)
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --dry-run           预览将执行的操作"
    echo "  --modules LIST      只安装指定模块 (逗号分隔)"
    echo "  --no-root           跳过需要 root 的步骤"
    echo "  -h, --help          显示帮助信息"
    echo ""
    echo "可用模块: zsh, vim, tmux, cli-tools, nodejs, sync"
    exit 0
    ;;
  *)
    shift
    ;;
  esac
done

# 默认所有模块
if [[ ${#MODULES[@]} -eq 0 ]]; then
  MODULES=(zsh vim tmux cli-tools nodejs sync)
fi

# 运行通用模块
log "=== 安装通用模块 ===" "$GREEN"
for module in "${MODULES[@]}"; do
  module_path="$SCRIPT_ROOT/modules/${module}.sh"
  if [[ -f "$module_path" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log "[DRY-RUN] 将执行: $module_path" "$YELLOW"
    else
      log "执行模块: $module" "$GREEN"
      source "$module_path"
    fi
  else
    log "模块不存在: $module" "$RED"
  fi
done

# 运行平台专属模块
platform_dir="$SCRIPT_ROOT/platforms/$PLATFORM"
if [[ -d "$platform_dir" ]]; then
  log "=== 安装 $PLATFORM 专属模块 ===" "$GREEN"
  for script in "$platform_dir"/*.sh; do
    if [[ -f "$script" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY-RUN] 将执行: $script" "$YELLOW"
      else
        log "执行: $(basename "$script")" "$GREEN"
        source "$script"
      fi
    fi
  done
fi

log "=== 环境搭建完成 ===" "$GREEN"

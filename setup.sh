#!/usr/bin/env bash
#
# 全量环境搭建入口：加载 lib → 按需 sudo / Homebrew 镜像 → 依次 source 各模块 → 再跑平台专属脚本。
# 用法: ./setup.sh [--dry-run] [--modules zsh,vim,...] [--no-root]；模块列表见 --help。
#
# set -e: 任一命令返回非 0 时立刻退出，避免错误被默默忽略。
set -e

# BASH_SOURCE[0] 在被 source 时仍指向本文件；dirname + cd + pwd 得到绝对路径，不依赖当前工作目录。
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 核心库顺序：platform（检测 OS）→ package（brew/apt 等）→ utils（log、symlink、mise 等）
source "$SCRIPT_ROOT/lib/platform.sh"
source "$SCRIPT_ROOT/lib/package.sh"
source "$SCRIPT_ROOT/lib/utils.sh"

PLATFORM=$(detect_platform)
log "检测到平台: $PLATFORM" "$GREEN"
log "脚本根目录: $SCRIPT_ROOT" "$GREEN"

# 预先获取 sudo 权限（避免多次输入）
if is_linux; then
  if [[ $EUID -eq 0 ]]; then
    log "以 root 用户运行，跳过 sudo 检查" "$GREEN"
  elif can_sudo; then
    log "sudo 权限已获取" "$GREEN"
  elif command -v sudo &>/dev/null; then
    echo ""
    echo "此脚本需要 sudo 权限来安装系统包。"
    echo "请输入密码以继续（密码不会显示）："
    sudo -v
    echo "sudo 权限获取成功"
  else
    log "未找到 sudo，可能需要 root 权限安装系统包" "$YELLOW"
  fi
elif is_macos; then
  # macOS 上预先获取 sudo 权限
  if ! sudo -n true 2>/dev/null; then
    echo ""
    echo "此脚本需要 sudo 权限来修复目录权限。"
    echo "请输入密码以继续："
    sudo -v
    echo "sudo 权限获取成功"
  else
    log "sudo 权限已获取" "$GREEN"
  fi

  # 修复 Homebrew 镜像源问题
  fix_brew_mirror

  # 如果设置了镜像 domain，应用到环境变量
  if [[ -n "$HOMEBREW_BOTTLE_DOMAIN" ]]; then
    export HOMEBREW_BOTTLE_DOMAIN
  fi
fi

# 命令行参数（$# 为剩余参数个数；shift 吃掉已处理项）
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
    # IFS=',' 仅作用于 read：把 "a,b,c" 读入数组 MODULES
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
    echo "可用模块: zsh, vim, tmux, cli-tools, nodejs, sync, opencode"
    exit 0
    ;;
  *)
    shift
    ;;
  esac
done

# 未指定 --modules 时使用默认全套模块（${#ARRAY[@]} 为数组长度）
if [[ ${#MODULES[@]} -eq 0 ]]; then
  MODULES=(zsh vim tmux cli-tools nodejs sync opencode)
fi

# 通用模块：每个文件在 subshell 外被 source，可调用已加载的 log、pkg_install 等函数
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

# 平台专属：例如 platforms/macos/*.sh、platforms/ubuntu/*.sh（按文件名排序依次 source）
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

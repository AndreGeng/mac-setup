#!/usr/bin/env bash
#
# 全量环境搭建入口：加载 lib → 按需 sudo / Homebrew 镜像 → 依次 source 各模块 → 再跑平台专属脚本。
# 用法: ./setup.sh [--dry-run] [--modules zsh,vim,...] [--with-platform] [--no-root]；
# 模块列表见 --help。
#
# 严格模式：错误、未定义变量和管道失败都会终止安装。
set -euo pipefail

# BASH_SOURCE[0] 在被 source 时仍指向本文件；dirname + cd + pwd 得到绝对路径，不依赖当前工作目录。
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 核心库顺序：platform（检测 OS）→ package（brew/apt 等）→ utils（log、symlink、mise 等）
source "$SCRIPT_ROOT/lib/platform.sh"
source "$SCRIPT_ROOT/lib/package.sh"
source "$SCRIPT_ROOT/lib/utils.sh"

# 命令行参数必须在 sudo、网络和 Homebrew 修改之前解析。
MODULES=()
DRY_RUN=false
NO_ROOT=false
RUN_PLATFORM=false
MODULES_SPECIFIED=false

usage() {
  cat <<'EOF'
用法: ./setup.sh [选项]

选项:
  --dry-run           预览将执行的操作，不获取 sudo 或修改 Homebrew
  --modules LIST      只安装指定模块（逗号分隔）；默认不执行平台模块
  --with-platform     与 --modules 一起显式执行平台专属模块
  --no-root           跳过需要 root 权限的步骤
  -h, --help          显示帮助信息

可用模块: zsh, vim, tmux, cli-tools, nodejs, herdr, sync, opencode, workmux, agents
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --modules)
    [[ $# -ge 2 && -n "$2" ]] || {
      printf '%s\n' '--modules 需要参数。' >&2
      exit 2
    }
    # IFS=',' 仅作用于 read：把 "a,b,c" 读入数组 MODULES
    IFS=',' read -ra MODULES <<<"$2"
    MODULES_SPECIFIED=true
    shift 2
    ;;
  --with-platform)
    RUN_PLATFORM=true
    shift
    ;;
  --no-root)
    NO_ROOT=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    printf '未知参数: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
  esac
done

# 未指定 --modules 时使用默认全套模块（${#ARRAY[@]} 为数组长度）
if [[ ${#MODULES[@]} -eq 0 ]]; then
  MODULES=(zsh vim tmux cli-tools nodejs herdr sync opencode workmux agents)
  if [[ "$MODULES_SPECIFIED" == "false" ]]; then
    RUN_PLATFORM=true
  fi
fi

for module in "${MODULES[@]}"; do
  case "$module" in
  zsh | vim | tmux | cli-tools | nodejs | herdr | sync | opencode | workmux | agents) ;;
  *)
    printf '未知模块: %s\n' "$module" >&2
    exit 2
    ;;
  esac
done

if [[ "$NO_ROOT" == "true" ]]; then
  export MAC_SETUP_NO_ROOT=1
else
  unset MAC_SETUP_NO_ROOT || true
fi

PLATFORM=$(detect_platform)
log "检测到平台: $PLATFORM" "$GREEN"
log "脚本根目录: $SCRIPT_ROOT" "$GREEN"

modules_need_root() {
  local module
  for module in "${MODULES[@]}"; do
    case "$module" in
    zsh | vim | tmux | cli-tools) return 0 ;;
    esac
  done
  return 1
}

if [[ "$DRY_RUN" != "true" ]]; then
  if [[ "$NO_ROOT" == "true" ]]; then
    log "已启用 --no-root：跳过 sudo 和需要 root 的安装步骤" "$YELLOW"
  elif is_linux && modules_need_root; then
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
      log "未找到 sudo，需要 root 的软件包将被跳过" "$YELLOW"
    fi
  fi

  if is_macos; then
    fix_brew_mirror
    [[ -n "${HOMEBREW_BOTTLE_DOMAIN:-}" ]] && export HOMEBREW_BOTTLE_DOMAIN
  fi
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

# 平台专属：Linux 先运行通用层，再运行发行版层；macOS 只运行 macos 层。
if [[ "$RUN_PLATFORM" == "true" ]]; then
  while IFS= read -r platform_dir; do
    [[ -d "$platform_dir" ]] || continue
    log "=== 安装 $(basename "$platform_dir") 平台模块 ===" "$GREEN"
    for script in "$platform_dir"/*.sh; do
      [[ -f "$script" ]] || continue
      if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY-RUN] 将执行: $script" "$YELLOW"
      else
        log "执行: $(basename "$script")" "$GREEN"
        source "$script"
      fi
    done
  done < <(platform_script_dirs "$SCRIPT_ROOT/platforms")
fi

log "=== 环境搭建完成 ===" "$GREEN"

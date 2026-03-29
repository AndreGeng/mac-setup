#!/usr/bin/env bash
# 简版环境搭建：核心开发工具，尽量快、依赖少。
# 默认跳过 zsh（zinit 首次较慢）、tmux、平台专属脚本（字体/GUI 等）。
# 用法见: ./setup-lite.sh --help

set -e

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_ROOT/lib/platform.sh"
source "$SCRIPT_ROOT/lib/package.sh"
source "$SCRIPT_ROOT/lib/utils.sh"

PLATFORM=$(detect_platform)

DRY_RUN=false
RUN_PLATFORM=false
WITH_ZSH=false
WITH_TMUX=false
WITH_NVIM_PYTHON=false
MODULES_OVERRIDE=()

usage() {
  cat <<'EOF'
用法: ./setup-lite.sh [选项]

简版默认安装模块（顺序）:
  vim nodejs cli-tools sync
  — Neovim、Node LTS、常用 CLI、fzf、配置软链
  — vim 模块默认跳过 setup_python_env（无 pynvim/nvr 虚拟环境，更快）

选项:
  --dry-run             只打印将执行的模块，不实际安装
  --with-nvim-python    vim 模块也执行 setup_python_env（pynvim + nvr，vim 内会装 mise+Python）
  --with-zsh            额外执行 zsh 模块（Oh My Zsh / Zinit，首次较慢）
  --with-tmux           额外执行 tmux 模块
  --with-platform       同时执行 platforms/<平台>/*.sh（字体、应用等）
  --modules A,B,C       完全自定义模块列表（逗号分隔），覆盖默认简版列表
  -h, --help            显示本帮助

完整安装请用: ./setup.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --with-platform)
    RUN_PLATFORM=true
    shift
    ;;
  --with-zsh)
    WITH_ZSH=true
    shift
    ;;
  --with-tmux)
    WITH_TMUX=true
    shift
    ;;
  --with-nvim-python)
    WITH_NVIM_PYTHON=true
    shift
    ;;
  --modules)
    IFS=',' read -ra MODULES_OVERRIDE <<<"$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    log "未知参数: $1（使用 --help）" "$RED"
    exit 1
    ;;
  esac
done

log "=== setup-lite（简版）===" "$GREEN"
log "平台: $PLATFORM  |  仓库: $SCRIPT_ROOT" "$GREEN"

# 与 setup.sh 相同的 sudo / Homebrew 前置（--help / --dry-run 不触发）
if [[ "$DRY_RUN" != "true" ]]; then
  if is_linux; then
    if [[ $EUID -eq 0 ]]; then
      log "以 root 运行，跳过 sudo" "$GREEN"
    elif command -v sudo &>/dev/null; then
      if ! sudo -n true 2>/dev/null; then
        echo ""
        echo "需要 sudo 以安装系统包，请输入密码："
        sudo -v
      fi
    fi
  elif is_macos; then
    if ! sudo -n true 2>/dev/null; then
      echo ""
      echo "需要 sudo（目录权限等），请输入密码："
      sudo -v
    fi
    fix_brew_mirror
    [[ -n "${HOMEBREW_BOTTLE_DOMAIN:-}" ]] && export HOMEBREW_BOTTLE_DOMAIN
  fi
fi

if [[ ${#MODULES_OVERRIDE[@]} -gt 0 ]]; then
  MODULES=("${MODULES_OVERRIDE[@]}")
else
  MODULES=(vim nodejs cli-tools sync)
  [[ "$WITH_ZSH" == "true" ]] && MODULES=(zsh "${MODULES[@]}")
  [[ "$WITH_TMUX" == "true" ]] && MODULES+=("tmux")
fi

# 简版默认跳过 Neovim Python/nvr；完整 setup.sh 不设此变量
if [[ "$WITH_NVIM_PYTHON" == "true" ]]; then
  unset MAC_SETUP_SKIP_NVIM_PYTHON
else
  export MAC_SETUP_SKIP_NVIM_PYTHON=1
fi

if [[ "${MAC_SETUP_SKIP_NVIM_PYTHON:-}" == "1" ]]; then
  log "vim 将跳过 setup_python_env（需要 pynvim/nvr 时用 --with-nvim-python）" "$YELLOW"
fi

log "将安装模块: ${MODULES[*]}" "$GREEN"

for module in "${MODULES[@]}"; do
  module_path="$SCRIPT_ROOT/modules/${module}.sh"
  if [[ ! -f "$module_path" ]]; then
    log "模块不存在: $module" "$RED"
    exit 1
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY-RUN] $module_path" "$YELLOW"
  else
    log "执行模块: $module" "$GREEN"
    # shellcheck source=/dev/null
    source "$module_path"
  fi
done

if [[ "$RUN_PLATFORM" == "true" ]]; then
  platform_dir="$SCRIPT_ROOT/platforms/$PLATFORM"
  if [[ -d "$platform_dir" ]]; then
    log "=== 平台专属脚本 ($PLATFORM) ===" "$GREEN"
    for script in "$platform_dir"/*.sh; do
      [[ -f "$script" ]] || continue
      if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY-RUN] $script" "$YELLOW"
      else
        log "执行: $(basename "$script")" "$GREEN"
        # shellcheck source=/dev/null
        source "$script"
      fi
    done
  else
    log "无平台目录: $platform_dir" "$YELLOW"
  fi
fi

log "=== setup-lite 完成 ===" "$GREEN"

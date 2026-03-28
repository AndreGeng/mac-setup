# Linux 环境支持实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 mac-setup 仓库改造为支持跨平台（macOS + Linux/Ubuntu）的开发环境快速搭建工具。

**Architecture:** 采用模块化设计，核心库抽象平台差异，通用模块处理跨平台逻辑，平台专属目录处理特定系统需求。统一入口检测平台后依次加载模块。

**Tech Stack:** Bash, mise, zinit, Homebrew (macOS), apt (Ubuntu)

---

## Phase 1: 核心库与基础设施

### Task 1.1: 创建核心库目录结构

**Files:**
- Create: `lib/platform.sh`
- Create: `lib/package.sh`
- Create: `lib/utils.sh`

**Step 1: 创建 lib 目录**

```bash
mkdir -p lib
```

**Step 2: 创建 lib/platform.sh**

```bash
#!/usr/bin/env bash

detect_platform() {
  case "$OSTYPE" in
    darwin*)  echo "macos" ;;
    linux*)   
      if command -v apt &>/dev/null; then
        echo "ubuntu"
      elif command -v dnf &>/dev/null; then
        echo "fedora"
      elif command -v pacman &>/dev/null; then
        echo "arch"
      else
        echo "linux"
      fi
      ;;
    *)        echo "unknown" ;;
  esac
}

is_macos() { [[ "$(detect_platform)" == "macos" ]]; }
is_linux() { [[ "$(detect_platform)" != "macos" ]]; }

has_root() {
  [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null
}

can_sudo() {
  sudo -n true 2>/dev/null || [[ $EUID -eq 0 ]]
}
```

**Step 3: 创建 lib/package.sh**

```bash
#!/usr/bin/env bash

# 包名映射表：通用名 -> 平台特定名
declare -A PKG_MAP=(
  ["openssl:ubuntu"]="libssl-dev"
  ["zlib:ubuntu"]="zlib1g-dev"
  ["xz:ubuntu"]="xz-utils"
  ["fd-find:ubuntu"]="fd-find"
  ["fd-find:macos"]="fd"
)

pkg_map_name() {
  local pkg="$1"
  local platform="${2:-$(detect_platform)}"
  echo "${PKG_MAP[$pkg:$platform]:-$pkg}"
}

pkg_install() {
  local pkg="$1"
  local platform=$(detect_platform)
  local mapped_pkg=$(pkg_map_name "$pkg" "$platform")
  
  if pkg_exists "$mapped_pkg"; then
    log "$mapped_pkg 已安装，跳过" $YELLOW
    return 0
  fi
  
  log "安装 $mapped_pkg..." $GREEN
  
  case "$platform" in
    macos)
      brew install "$mapped_pkg"
      ;;
    ubuntu|fedora|arch|linux)
      if ! can_sudo; then
        log "需要 sudo 权限安装 $mapped_pkg" $RED
        return 1
      fi
      _pkg_install_linux "$mapped_pkg"
      ;;
    *)
      log "不支持的平台: $platform" $RED
      return 1
      ;;
  esac
}

_pkg_install_linux() {
  local pkg="$1"
  if command -v apt &>/dev/null; then
    sudo apt install -y "$pkg"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$pkg"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$pkg"
  else
    log "未找到支持的包管理器" $RED
    return 1
  fi
}

pkg_exists() {
  local pkg="$1"
  local platform=$(detect_platform)
  
  case "$platform" in
    macos)
      brew list "$pkg" &>/dev/null
      ;;
    ubuntu)
      dpkg -l "$pkg" &>/dev/null 2>&1
      ;;
    fedora)
      rpm -q "$pkg" &>/dev/null 2>&1
      ;;
    arch)
      pacman -Qi "$pkg" &>/dev/null 2>&1
      ;;
    *)
      command -v "$pkg" &>/dev/null
      ;;
  esac
}

can_sudo() {
  sudo -n true 2>/dev/null || [[ $EUID -eq 0 ]]
}
```

**Step 4: 创建 lib/utils.sh**

```bash
#!/usr/bin/env bash

# 颜色常量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 日志函数
log() {
  local msg="$1"
  local color="${2:-$GREEN}"
  echo -e "${color}${msg}${NC}"
}

# 获取脚本根目录
get_script_root() {
  local script_path="${BASH_SOURCE[0]}"
  local script_dir="$(cd "$(dirname "$script_path")" && pwd)"
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
  log "链接: $dest -> $src" $GREEN
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
    local dir="$(cd "$(dirname "$path")" && pwd)"
    echo "$dir/$(basename "$path")"
  fi
}
```

**Step 5: 提交**

```bash
git add lib/
git commit -m "feat: 添加核心库 (platform, package, utils)"
```

---

### Task 1.2: 创建模块目录结构

**Files:**
- Create: `modules/.gitkeep`
- Create: `platforms/macos/.gitkeep`
- Create: `platforms/linux/.gitkeep`

**Step 1: 创建目录**

```bash
mkdir -p modules platforms/macos platforms/linux
touch modules/.gitkeep platforms/macos/.gitkeep platforms/linux/.gitkeep
```

**Step 2: 提交**

```bash
git add modules/ platforms/
git commit -m "feat: 创建模块目录结构"
```

---

## Phase 2: 通用模块迁移

### Task 2.1: 迁移 zsh.sh

**Files:**
- Create: `modules/zsh.sh`

**Step 1: 创建 modules/zsh.sh**

```bash
#!/usr/bin/env bash

install_zsh() {
  log "=== 安装 Zsh ===" $GREEN
  
  # 安装 zsh
  if ! command -v zsh &>/dev/null; then
    pkg_install zsh || return 1
  fi
  
  # 安装 zinit
  local zinit_dir="$HOME/.local/share/zinit"
  if [[ ! -d "$zinit_dir" ]]; then
    log "安装 zinit..." $GREEN
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)" -- -d "$zinit_dir"
  else
    log "zinit 已安装，跳过" $YELLOW
  fi
  
  # macOS 专属：zsh-completions
  if is_macos; then
    pkg_install zsh-completions || true
  fi
}

install_zsh
```

**Step 2: 提交**

```bash
git add modules/zsh.sh
git commit -m "feat: 添加跨平台 zsh 模块"
```

---

### Task 2.2: 迁移 vim.sh

**Files:**
- Create: `modules/vim.sh`

**Step 1: 创建 modules/vim.sh**

```bash
#!/usr/bin/env bash

install_neovim() {
  log "=== 安装 Neovim ===" $GREEN
  
  # 基础依赖
  local deps=("neovim" "ripgrep" "fzf")
  for dep in "${deps[@]}"; do
    pkg_install "$dep" || log "跳过 $dep" $YELLOW
  done
  
  # fd 在 Ubuntu 上包名不同
  if is_linux; then
    pkg_install "fd-find" || true
  else
    pkg_install "fd" || true
  fi
  
  # 安装 mise（如果不存在）
  if ! command -v mise &>/dev/null; then
    log "安装 mise..." $GREEN
    curl https://mise.run | sh
    # 添加到 PATH
    export PATH="$HOME/.local/bin:$PATH"
  fi
  
  # 加载 mise
  eval "$(mise activate bash 2>/dev/null || mise activate zsh 2>/dev/null || true)"
  
  # Python 环境
  setup_python_env
}

setup_python_env() {
  log "配置 Python 环境..." $GREEN
  
  unset ALL_PROXY
  
  local venv_dir="$HOME/.local/share/neovim"
  local python3_version="3.11"
  
  mkdir -p "$venv_dir"
  
  # 安装 Python
  if ! mise ls python 2>/dev/null | grep -q "$python3_version"; then
    log "安装 Python $python3_version..." $GREEN
    mise install python@$python3_version
  fi
  
  # 创建虚拟环境
  local venv_path="$venv_dir/neovim3"
  if [[ ! -d "$venv_path" ]]; then
    log "创建 Python 虚拟环境..." $GREEN
    mise exec python@$python3_version -- python -m venv "$venv_path"
  fi
  
  # 安装 pynvim
  if ! "$venv_path/bin/pip" show pynvim &>/dev/null; then
    log "安装 pynvim..." $GREEN
    "$venv_path/bin/pip" install pynvim
  fi
  
  # 安装 neovim-remote
  if ! "$venv_path/bin/pip" show neovim-remote &>/dev/null; then
    log "安装 neovim-remote..." $GREEN
    "$venv_path/bin/pip" install neovim-remote
  fi
}

install_neovim
```

**Step 2: 提交**

```bash
git add modules/vim.sh
git commit -m "feat: 添加跨平台 vim/neovim 模块"
```

---

### Task 2.3: 迁移 tmux.sh

**Files:**
- Create: `modules/tmux.sh`

**Step 1: 创建 modules/tmux.sh**

```bash
#!/usr/bin/env bash

install_tmux() {
  log "=== 安装 Tmux ===" $GREEN
  
  pkg_install tmux || return 1
  
  # macOS 专属：剪贴板支持
  if is_macos; then
    pkg_install reattach-to-user-namespace || true
  fi
  
  # TPM 插件管理器
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    log "安装 TPM..." $GREEN
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  else
    log "TPM 已安装，跳过" $YELLOW
  fi
}

install_tmux
```

**Step 2: 提交**

```bash
git add modules/tmux.sh
git commit -m "feat: 添加跨平台 tmux 模块"
```

---

### Task 2.4: 创建 cli-tools.sh

**Files:**
- Create: `modules/cli-tools.sh`

**Step 1: 创建 modules/cli-tools.sh**

```bash
#!/usr/bin/env bash

install_cli_tools() {
  log "=== 安装 CLI 工具 ===" $GREEN
  
  # 通用工具列表
  local tools=(
    "lazygit"
    "the_silver_searcher"
    "git-delta"
    "ast-grep"
    "shfmt"
  )
  
  for tool in "${tools[@]}"; do
    if ! command -v "${tool%%-*}" &>/dev/null && ! command -v "${tool}" &>/dev/null; then
      pkg_install "$tool" || log "跳过 $tool (可能需要 root)" $YELLOW
    else
      log "$tool 已安装，跳过" $YELLOW
    fi
  done
  
  # fzf 键绑定
  install_fzf_keybindings
}

install_fzf_keybindings() {
  local fzf_dir="$HOME/.fzf"
  
  if [[ ! -d "$fzf_dir" ]]; then
    log "安装 fzf 键绑定..." $GREEN
    git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"
    "$fzf_dir/install" --key-bindings --completion --no-update-rc
  else
    log "fzf 键绑定已安装，跳过" $YELLOW
  fi
}

install_cli_tools
```

**Step 2: 提交**

```bash
git add modules/cli-tools.sh
git commit -m "feat: 添加跨平台 CLI 工具模块"
```

---

### Task 2.5: 迁移 nodejs.sh

**Files:**
- Create: `modules/nodejs.sh`

**Step 1: 创建 modules/nodejs.sh**

```bash
#!/usr/bin/env bash

install_nodejs() {
  log "=== 安装 Node.js ===" $GREEN
  
  # 确保 mise 已安装
  if ! command -v mise &>/dev/null; then
    log "安装 mise..." $GREEN
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
  
  # 加载 mise
  eval "$(mise activate bash 2>/dev/null || mise activate zsh 2>/dev/null || true)"
  
  # 安装 Node.js LTS
  log "安装 Node.js LTS..." $GREEN
  mise use -g node@lts
  
  # 全局 npm 包
  local npm_packages=(
    "js-beautify"
    "prettier"
    "typescript"
    "bash-language-server"
    "typescript-language-server"
    "@olrtg/emmet-language-server"
    "eslint_d"
    "vscode-langservers-extracted"
  )
  
  for pkg in "${npm_packages[@]}"; do
    if ! npm list -g "$pkg" &>/dev/null; then
      log "安装 npm 包: $pkg" $GREEN
      npm install -g "$pkg"
    fi
  done
}

install_nodejs
```

**Step 2: 提交**

```bash
git add modules/nodejs.sh
git commit -m "feat: 添加跨平台 Node.js 模块"
```

---

### Task 2.6: 创建 sync.sh

**Files:**
- Create: `modules/sync.sh`

**Step 1: 创建 modules/sync.sh**

```bash
#!/usr/bin/env bash

sync_configs() {
  log "=== 同步配置文件 ===" $GREEN
  
  local script_root=$(get_realpath "$(dirname "${BASH_SOURCE[0]}")/..")
  local config_dir="$script_root/config"
  
  # 创建 ~/.config 目录
  mkdir -p "$HOME/.config"
  
  # 通用配置
  symlink_config "$config_dir/nvim" "$HOME/.config/nvim"
  symlink_config "$config_dir/ranger" "$HOME/.config/ranger"
  symlink_config "$config_dir/tmuxinator" "$HOME/.config/tmuxinator"
  symlink_config "$config_dir/.zsh-utils" "$HOME/.config/.zsh-utils"
  
  symlink_config "$config_dir/.zshrc" "$HOME/.zshrc"
  symlink_config "$config_dir/.p10k.zsh" "$HOME/.p10k.zsh"
  symlink_config "$config_dir/.tmux.conf" "$HOME/.tmux.conf"
  symlink_config "$config_dir/.agignore" "$HOME/.agignore"
  
  # fzf-git
  mkdir -p "$HOME/fzf-addons"
  symlink_config "$config_dir/fzf-git/fzf-git.sh" "$HOME/fzf-addons/fzf-git.sh"
  
  # 平台专属配置
  if is_macos; then
    sync_macos_configs "$config_dir"
  fi
}

sync_macos_configs() {
  local config_dir="$1"
  
  # lazygit
  local lazygit_dir="$HOME/Library/Application Support/jesseduffield/lazygit"
  mkdir -p "$lazygit_dir"
  symlink_config "$config_dir/lazygit/config.yml" "$lazygit_dir/config.yml"
  
  # macOS 专属工具配置
  symlink_config "$config_dir/karabiner" "$HOME/.config/karabiner"
  symlink_config "$config_dir/yabai" "$HOME/.config/yabai"
  symlink_config "$config_dir/.hammerspoon" "$HOME/.hammerspoon"
  symlink_config "$config_dir/ghostty" "$HOME/.config/ghostty"
}

sync_configs
```

**Step 2: 提交**

```bash
git add modules/sync.sh
git commit -m "feat: 添加跨平台配置同步模块"
```

---

## Phase 3: 平台专属模块

### Task 3.1: 创建 macOS 专属模块

**Files:**
- Create: `platforms/macos/apps.sh`
- Create: `platforms/macos/fonts.sh`

**Step 1: 创建 platforms/macos/apps.sh**

```bash
#!/usr/bin/env bash

install_macos_apps() {
  log "=== 安装 macOS GUI 应用 ===" $GREEN
  
  # 开发工具
  brew install --cask iterm2 || true
  brew install --cask visual-studio-code || true
  brew install --cask ghostty || true
  brew install --cask hammerspoon || true
  
  # 实用工具
  brew install --cask alfred || true
  brew install --cask snipaste || true
  brew install --cask caffeine || true
  brew install --cask appcleaner || true
  
  # 浏览器
  brew install --cask google-chrome || true
  
  # 其他
  brew install --cask notion || true
  brew install --cask drawio || true
  brew install --cask postman || true
}

install_macos_apps
```

**Step 2: 创建 platforms/macos/fonts.sh**

```bash
#!/usr/bin/env bash

install_macos_fonts() {
  log "=== 安装 macOS 字体 ===" $GREEN
  
  brew tap homebrew/cask-fonts || true
  brew install --cask font-hack-nerd-font || true
}

install_macos_fonts
```

**Step 3: 提交**

```bash
git add platforms/macos/
git commit -m "feat: 添加 macOS 专属模块 (apps, fonts)"
```

---

### Task 3.2: 创建 Linux 专属模块

**Files:**
- Create: `platforms/linux/fonts.sh`

**Step 1: 创建 platforms/linux/fonts.sh**

```bash
#!/usr/bin/env bash

install_linux_fonts() {
  log "=== 安装 Linux 字体 ===" $GREEN
  
  local font_dir="$HOME/.local/share/fonts"
  local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"
  local font_name="Hack Regular Nerd Font Complete.ttf"
  
  if [[ -f "$font_dir/$font_name" ]]; then
    log "字体已安装，跳过" $YELLOW
    return 0
  fi
  
  mkdir -p "$font_dir"
  
  local tmp_dir=$(mktemp -d)
  log "下载 Hack Nerd Font..." $GREEN
  
  if curl -fLo "$tmp_dir/Hack.zip" "$font_url"; then
    unzip -o "$tmp_dir/Hack.zip" -d "$tmp_dir" >/dev/null 2>&1
    cp "$tmp_dir/"*.ttf "$font_dir/" 2>/dev/null || true
    rm -rf "$tmp_dir"
    
    # 刷新字体缓存
    if command -v fc-cache &>/dev/null; then
      fc-cache -fv "$font_dir"
    fi
    
    log "字体安装完成" $GREEN
  else
    log "字体下载失败" $RED
    rm -rf "$tmp_dir"
    return 1
  fi
}

install_linux_fonts
```

**Step 2: 提交**

```bash
git add platforms/linux/
git commit -m "feat: 添加 Linux 专属字体模块"
```

---

## Phase 4: 入口脚本与配置迁移

### Task 4.1: 创建统一入口脚本

**Files:**
- Create: `setup.sh` (新版本)
- Backup: 原 `setup.sh` → `setup-macos.sh`

**Step 1: 备份原入口脚本**

```bash
mv setup.sh setup-macos.sh
```

**Step 2: 创建新的 setup.sh**

```bash
#!/usr/bin/env bash
set -e

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载核心库
source "$SCRIPT_ROOT/lib/platform.sh"
source "$SCRIPT_ROOT/lib/package.sh"
source "$SCRIPT_ROOT/lib/utils.sh"

PLATFORM=$(detect_platform)
log "检测到平台: $PLATFORM" $GREEN
log "脚本根目录: $SCRIPT_ROOT" $GREEN

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
      IFS=',' read -ra MODULES <<< "$2"
      shift 2
      ;;
    --no-root)
      NO_ROOT=true
      shift
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
log "=== 安装通用模块 ===" $GREEN
for module in "${MODULES[@]}"; do
  module_path="$SCRIPT_ROOT/modules/${module}.sh"
  if [[ -f "$module_path" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log "[DRY-RUN] 将执行: $module_path" $YELLOW
    else
      source "$module_path"
    fi
  else
    log "模块不存在: $module" $RED
  fi
done

# 运行平台专属模块
platform_dir="$SCRIPT_ROOT/platforms/$PLATFORM"
if [[ -d "$platform_dir" ]]; then
  log "=== 安装 $PLATFORM 专属模块 ===" $GREEN
  for script in "$platform_dir"/*.sh; do
    if [[ -f "$script" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY-RUN] 将执行: $script" $YELLOW
      else
        source "$script"
      fi
    fi
  done
fi

log "=== 环境搭建完成 ===" $GREEN
```

**Step 3: 提交**

```bash
git add setup.sh setup-macos.sh
git commit -m "feat: 创建统一入口脚本，备份 macOS 版本"
```

---

### Task 4.2: 重命名配置目录

**Files:**
- Move: `mac-config/` → `config/`

**Step 1: 重命名目录**

```bash
mv mac-config config
```

**Step 2: 更新 sync.sh 中的路径引用（已在 Task 2.6 完成）**

**Step 3: 提交**

```bash
git add -A
git commit -m "refactor: 重命名 mac-config 为 config"
```

---

## Phase 5: 文档与测试

### Task 5.1: 更新 README

**Files:**
- Modify: `README.md`

**Step 1: 更新 README.md**

添加 Linux 使用说明、平台支持矩阵、命令行参数说明。

**Step 2: 提交**

```bash
git add README.md
git commit -m "docs: 更新 README，添加 Linux 支持说明"
```

---

### Task 5.2: 添加 Ubuntu Docker 测试脚本

**Files:**
- Create: `test/ubuntu-test.sh`
- Create: `test/Dockerfile.ubuntu`

**Step 1: 创建 test/Dockerfile.ubuntu**

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 创建非 root 用户
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser

COPY . /home/testuser/mac-setup

CMD ["./mac-setup/setup.sh"]
```

**Step 2: 创建 test/ubuntu-test.sh**

```bash
#!/usr/bin/env bash

# Ubuntu Docker 测试脚本
docker build -f test/Dockerfile.ubuntu -t mac-setup-test .
docker run --rm mac-setup-test
```

**Step 3: 提交**

```bash
git add test/
git commit -m "test: 添加 Ubuntu Docker 测试脚本"
```

---

## 总结

| Phase | 任务数 | 说明 |
|-------|--------|------|
| Phase 1 | 2 | 核心库与目录结构 |
| Phase 2 | 6 | 通用模块迁移 |
| Phase 3 | 2 | 平台专属模块 |
| Phase 4 | 2 | 入口脚本与配置迁移 |
| Phase 5 | 2 | 文档与测试 |

**总任务数：14**

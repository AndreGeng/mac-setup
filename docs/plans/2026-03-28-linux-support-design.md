# Linux 环境支持设计文档

## 概述

将 mac-setup 仓库改造为支持跨平台（macOS + Linux/Ubuntu）的开发环境快速搭建工具。

## 目标

- 在 Linux 服务器上快速搭建开发环境：zsh + neovim + tmux + lazygit + CLI 工具
- 保持现有 macOS 功能不变
- 模块化设计，便于维护和扩展

## 约束

- 目标平台：macOS + Ubuntu/Debian
- 支持 root 和非 root 用户场景
- 核心工具：mise、zinit、fzf 等跨平台工具

## 架构

### 目录结构

```
mac-setup/
├── setup.sh                    # 统一入口
├── lib/                        # 核心库
│   ├── platform.sh             # 平台检测
│   ├── package.sh              # 包管理器抽象
│   └── utils.sh                # 通用工具函数
├── modules/                    # 通用模块（跨平台）
│   ├── zsh.sh                  # Zsh + zinit
│   ├── vim.sh                  # Neovim + Python 环境
│   ├── tmux.sh                 # Tmux + TPM
│   ├── cli-tools.sh            # lazygit, fzf, ripgrep, fd 等
│   ├── nodejs.sh               # Node.js (mise)
│   └── sync.sh                 # 配置文件符号链接
├── platforms/                  # 平台专属模块
│   ├── macos/
│   │   ├── apps.sh             # GUI 应用（brew cask）
│   │   ├── karabiner.sh        # 键盘映射
│   │   └── fonts.sh            # Homebrew 字体
│   └── linux/
│       ├── fonts.sh            # 手动安装 Nerd Fonts
│       └── system.sh           # 系统级配置（可选）
├── config/                     # 配置文件（原 mac-config 重命名）
│   ├── nvim/
│   ├── .zshrc
│   ├── .tmux.conf
│   └── ...
└── utils/                      # 旧工具函数（保留兼容）
```

### 执行流程

```
setup.sh
    │
    ├─→ lib/platform.sh      # 检测平台
    ├─→ lib/package.sh       # 加载包管理器
    │
    ├─→ modules/*.sh         # 通用模块（按顺序）
    │   ├── zsh.sh
    │   ├── vim.sh
    │   ├── tmux.sh
    │   ├── cli-tools.sh
    │   ├── nodejs.sh
    │   └── sync.sh
    │
    └─→ platforms/{platform}/*.sh  # 平台专属模块
        └── macos/apps.sh
        └── linux/fonts.sh
```

## 核心模块

### 1. lib/platform.sh

```bash
detect_platform()   # 返回: macos | ubuntu | fedora | arch | unknown
is_macos()          # 布尔判断
is_linux()          # 布尔判断
has_root()          # 检测是否有 root 权限
```

### 2. lib/package.sh

```bash
pkg_install(pkg)    # 跨平台包安装
pkg_exists(pkg)     # 检查包是否已安装
PKG_MAP             # 包名映射表（macOS → Linux）
```

### 3. lib/utils.sh

```bash
log(msg, color)           # 日志输出
get_script_root()         # 获取脚本根目录
symlink_config(src, dest) # 创建符号链接
```

## 模块职责

### 通用模块 (modules/)

| 模块 | 功能 | 跨平台方式 |
|------|------|-----------|
| zsh.sh | 安装 zsh + zinit | 包管理器 + curl |
| vim.sh | 安装 neovim + Python 环境 | 包管理器 + mise |
| tmux.sh | 安装 tmux + TPM | 包管理器 + git |
| cli-tools.sh | lazygit, fzf, ripgrep 等 | 包管理器 |
| nodejs.sh | Node.js 环境 | mise |
| sync.sh | 配置文件链接 | 符号链接 |

### 平台专属模块 (platforms/)

| 平台 | 模块 | 功能 |
|------|------|------|
| macos | apps.sh | iTerm2, VSCode, Ghostty 等 GUI 应用 |
| macos | karabiner.sh | 键盘映射工具 |
| macos | fonts.sh | Homebrew cask 字体 |
| linux | fonts.sh | 手动下载安装 Nerd Fonts |
| linux | system.sh | 系统级配置（可选，需 root） |

## 包名映射

| 通用名 | macOS | Ubuntu |
|--------|-------|--------|
| neovim | neovim | neovim |
| tmux | tmux | tmux |
| zsh | zsh | zsh |
| openssl | openssl | libssl-dev |
| zlib | zlib | zlib1g-dev |
| ripgrep | ripgrep | ripgrep |
| fd-find | fd | fd-find |
| lazygit | lazygit | lazygit |

## 配置文件处理

### sync.sh 逻辑

```bash
# 通用配置（所有平台）
~/.config/nvim
~/.config/ranger
~/.config/tmuxinator
~/.zshrc
~/.tmux.conf
~/.agignore

# macOS 专属
~/Library/Application Support/jesseduffield/lazygit/
~/.config/karabiner
~/.config/yabai
~/.hammerspoon

# 跳过 Linux 不存在的路径
```

## 向后兼容

- 保留 `utils/` 目录现有函数
- `mac-config/` 重命名为 `config/`，但保留符号链接兼容
- 现有 `setup.sh` 重命名为 `setup-macos.sh`（可选）

## 命令行参数（可选增强）

```bash
./setup.sh                    # 全部安装
./setup.sh --dry-run          # 预览操作
./setup.sh --modules zsh,vim  # 只安装指定模块
./setup.sh --no-root          # 跳过需要 root 的步骤
```

## 测试策略

1. macOS 上运行 `./setup.sh`，验证现有功能不受影响
2. Ubuntu Docker 容器中测试 Linux 安装流程
3. 非 root 用户场景测试

## 风险与缓解

| 风险 | 缓解措施 |
|------|----------|
| 现有 macOS 流程回归 | 保留旧脚本，增量改造 |
| 包名差异导致安装失败 | 完善包名映射表 |
| 非 root 用户无法安装系统包 | 使用 mise/conda 等用户态工具替代 |

## 实现优先级

1. **P0 - 核心**：lib/, modules/zsh.sh, modules/vim.sh, modules/tmux.sh
2. **P1 - CLI 增强**：modules/cli-tools.sh, modules/sync.sh
3. **P2 - 平台专属**：platforms/macos/, platforms/linux/
4. **P3 - 增强**：命令行参数、dry-run 模式

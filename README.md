# mac-setup

跨平台开发环境快速搭建脚本，支持 macOS 和 Linux (Ubuntu/Debian)。

## 快速开始

### macOS

```bash
git clone https://github.com/yourname/mac-setup.git
cd mac-setup
./setup.sh
```

### Linux (Ubuntu/Debian)

```bash
git clone https://github.com/yourname/mac-setup.git
cd mac-setup
./setup.sh
```

## 命令行参数

```bash
./setup.sh                    # 全部安装
./setup.sh --dry-run          # 预览将执行的操作
./setup.sh --modules zsh,vim  # 只安装指定模块
./setup.sh --no-root          # 跳过需要 root 的步骤
./setup.sh --help             # 显示帮助
```

## 可用模块

| 模块 | 说明 | 平台 |
|------|------|------|
| zsh | Zsh + zinit | macOS, Linux |
| vim | Neovim + Python 环境 | macOS, Linux |
| tmux | Tmux + TPM | macOS, Linux |
| cli-tools | lazygit, fzf, ripgrep, delta 等 | macOS, Linux |
| nodejs | Node.js LTS + 全局 npm 包 | macOS, Linux |
| sync | 配置文件符号链接 | macOS, Linux |

## 平台支持

### macOS 专属

- GUI 应用：iTerm2, VSCode, Ghostty, Hammerspoon, Alfred 等
- 字体：通过 Homebrew cask 安装 Nerd Font
- 工具：Karabiner-Elements, Yabai 等

### Linux 专属

- 字体：手动下载安装 Nerd Font

## 目录结构

```
.
├── setup.sh           # 统一入口脚本
├── setup-macos.sh     # macOS 原入口 (备份)
├── lib/               # 核心库
│   ├── platform.sh    # 平台检测
│   ├── package.sh     # 包管理器抽象
│   └── utils.sh       # 通用工具
├── modules/           # 跨平台模块
│   ├── zsh.sh
│   ├── vim.sh
│   ├── tmux.sh
│   ├── cli-tools.sh
│   ├── nodejs.sh
│   └── sync.sh
├── platforms/         # 平台专属模块
│   ├── macos/
│   │   ├── apps.sh
│   │   └── fonts.sh
│   └── linux/
│       └── fonts.sh
└── config/            # 配置文件
    ├── nvim/
    ├── .zshrc
    ├── .tmux.conf
    └── ...
```

## 手动配置

### macOS

1. Shadowsocks 代理配置
2. iTerm2 字体设置为 "Hack Nerd Font"
   - Preference -> Profiles -> Text -> Font
3. 触控板开启 'tap to click'
   - System Preference -> TrackPad
4. Tab 控制对话框按钮
   - System Preference -> Keyboard -> Shortcuts -> Full Keyboard Access
5. 输入法切换快捷键
   - System Preference -> Keyboard -> Shortcuts -> Input Sources

### Linux

字体安装后可能需要重新登录终端或运行 `fc-cache -fv` 刷新字体缓存。

## 依赖

- curl, git (预装或手动安装)
- macOS: Homebrew
- Linux: apt (Ubuntu/Debian)

## 许可证

MIT

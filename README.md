# mac-setup

跨平台开发环境快速搭建脚本，支持 macOS 和 Linux (Ubuntu/Debian)。

## 快速开始

### macOS

```bash
git clone https://github.com/AndreGeng/mac-setup.git
cd mac-setup
./setup.sh
```

### Linux (Ubuntu/Debian)

```bash
git clone https://github.com/AndreGeng/mac-setup.git
cd mac-setup
./setup.sh
```

## 命令行参数

```bash
./setup.sh                    # 全部安装
./setup.sh --dry-run          # 预览将执行的操作
./setup.sh --modules zsh,vim  # 只安装指定模块
./setup.sh --modules sync --with-platform  # 指定模块，并显式执行平台模块
./setup.sh --no-root          # 跳过需要 root 的步骤
./setup.sh --help             # 显示帮助
```

指定 `--modules` 时默认只执行列出的通用模块，不执行 `platforms/`；需要平台应用、字体等
额外配置时再加 `--with-platform`。`--dry-run` 不请求 sudo、不修改 Homebrew，也不执行安装。

这是面向新电脑的个人环境模板。`sync` 模块会用仓库配置接管 Neovim、Zsh、Tmux 等路径；
如果目标电脑已经有同名配置，请先自行备份。Agent 工具的可变配置是例外，默认保留已有文件，
只有显式使用 `modules/agents.sh --force` 才会备份并刷新。

## 可用模块

| 模块 | 说明 | 平台 |
|------|------|------|
| zsh | Zsh + zinit | macOS, Linux |
| vim | Neovim + Python 环境 | macOS, Linux |
| tmux | Tmux + TPM | macOS, Linux |
| cli-tools | lazygit, fzf, ripgrep, delta 等 | macOS, Linux |
| nodejs | Node.js LTS、Bun 1.3.7 + 全局 npm 包 | macOS, Linux |
| herdr | Herdr agent multiplexer + 配置 | macOS, Linux |
| sync | 配置文件符号链接 | macOS, Linux |
| opencode | OpenCode CLI 与常用 LSP | macOS, Linux |
| workmux | Workmux 并行开发工作区工具 | macOS, Linux |
| agents | OpenCode、Claude Code、Codex、Pi 配置与自定义 skills | macOS, Linux |

## 让 Codex / OpenCode 配置电脑

`bin/mac-setup` 是面向人和 Agent 的稳定操作接口。Agent 应当先生成只读计划，说明网络、
sudo 和配置接管需求，获得授权后执行同一个 plan，最后独立验证结果：

```bash
./bin/mac-setup list --format json
./bin/mac-setup plan vim --format json
./bin/mac-setup apply vim --plan-id <plan-id> --allow network --allow sudo \
  --allow replace-config --non-interactive --format json
./bin/mac-setup verify vim --format json

# 一次配置 Zsh + Neovim 终端环境
./bin/mac-setup plan terminal --format json
./bin/mac-setup apply terminal --plan-id <plan-id> --allow network --allow sudo \
  --allow replace-config --non-interactive --format json
./bin/mac-setup verify terminal --format json
```

当前提供 `editor.nvim`（别名 `vim`、`nvim`、`neovim`）和 `shell.zsh`（别名 `zsh`、
`shell`）两个完整 capability，以及按固定顺序组合二者的 `profile.terminal`（别名
`terminal`）。Profile 会生成一份合并计划，对重复的 network、sudo、replace-config 审批
去重，并在 change 和 verify check 中标明所属 member。Neovim Python provider 可在单独
capability 或 terminal profile 的 plan、apply、verify 中一致地增加
`--with python-provider`。`plan` 不访问网络、不请求 sudo、不写用户目录；JSON 模式只在
stdout 输出协议数据，进度日志写入 stderr。

仓库自带的 `mac-setup` shared skill 会发布到 `~/.agents/skills/mac-setup`，供 Codex、
OpenCode、Claude Code 和 Pi 复用。可以直接对 Agent 说：“用 mac-setup 帮我配置好终端
开发环境，先给我看计划，确认后执行并验证。”

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
├── setup-lite.sh      # 精简开发环境入口
├── lib/               # 核心库
│   ├── platform.sh    # 平台检测
│   ├── package.sh     # 包管理器抽象
│   └── utils.sh       # 通用工具
├── modules/           # 跨平台模块
│   ├── zsh.sh
│   ├── vim.sh
│   ├── tmux.sh
│   ├── cli-tools.sh
│   ├── herdr.sh
│   ├── nodejs.sh
│   ├── opencode.sh
│   ├── workmux.sh
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

`nodejs` 模块通过 mise 安装并固定 Bun 1.3.7；Agent ReMe 记忆桥接依赖这个运行时。

## 测试

修改安装器后优先运行不触碰真实用户目录的回归测试：

```bash
bash test/setup-test.sh
bash test/agents-test.sh
bun test ./test/reme-memory-test.ts ./test/reme-bridge-test.ts
bash test/security-scan-test.sh
bash scripts/privacy-scan.sh
```

## 安全检查

本仓库是公开仓库。提交前安装 Gitleaks 并运行敏感信息检查：

```bash
brew install gitleaks
./scripts/security-scan.sh
```

GitHub Actions 会在每个 Pull Request 和 `master` 推送上执行相同检查。规则、误报处理和
凭据泄露响应流程见 [docs/security.md](docs/security.md)。

## Agent 配置迁移

完整安装会自动部署脱敏后的 Agent 配置，也可以单独执行：

```bash
bash modules/agents.sh --audit
bash modules/agents.sh --apply
bash modules/agents.sh --apply --only opencode --repair-links
```

现有应用配置默认保留。需要用仓库模板刷新单个工具时：

```bash
bash modules/agents.sh --apply --only opencode --force
```

`--force` 检测到明文凭据时会在创建备份前停止。第三方 skills 不复制进仓库，其来源、
审计和安全更新流程见
[docs/agent-migration.md](docs/agent-migration.md)。

## 许可证

MIT

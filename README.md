# mac-setup

跨平台开发环境快速搭建脚本，支持 macOS、Ubuntu/Debian 和 Arch Linux。

## 快速开始

### macOS

```bash
git clone https://github.com/AndreGeng/mac-setup.git
cd mac-setup
./setup.sh
```

### Linux (Ubuntu/Debian/Arch)

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
| zsh | Zsh + zinit，并设置为默认登录 shell | macOS, Linux |
| vim | Neovim、tree-sitter、Go/gopls + 可选 Python 环境 | macOS, Linux |
| tmux | Tmux + TPM | macOS, Linux |
| cli-tools | lazygit, fzf, ripgrep, delta 等 | macOS, Linux |
| nodejs | Node.js、Bun、OpenCode/Codex CLI + 全局 npm 包 | macOS, Linux |
| herdr | Herdr agent multiplexer + 配置 | macOS, Linux |
| sync | 配置文件符号链接 | macOS, Linux |
| opencode | OpenCode CLI 与常用 LSP | macOS, Linux |
| workmux | Workmux 并行开发工作区工具 | macOS, Linux |
| agents | OpenCode、Claude Code、Codex、Pi 配置与自定义 skills | macOS, Linux |
| toshy | Toshy：在桌面交互终端安装 macOS 风格快捷键 | Linux |
| vicinae | Vicinae 启动器、Ctrl+[ 快捷键和登录自启动 | Linux |
| xfce | XFCE 键盘重复：延迟 250ms、每秒 40 次 | Linux/XFCE |
| snipaste | [Snipaste 安装、配置副本与启动器](docs/snipaste.md) | macOS, Linux x86_64 |

XFCE 键盘重复设置可用 `./setup.sh --modules xfce` 单独应用；Linux 平台阶段也会
自动执行。仅在 XFCE 桌面会话中生效，不安装依赖，设置由 xfconf 保存。

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

当前提供 `editor.nvim`（别名 `vim`、`nvim`、`neovim`）、`shell.zsh`（别名 `zsh`、
`shell`）、`terminal.tmux`（别名 `tmux`）和 `runtime.node`（别名 `node`、`nodejs`）
四个完整 capability，以及按固定顺序组合 Zsh 与 Neovim 的 `profile.terminal`（别名
`terminal`）。Profile 会生成一份合并计划，对重复的 network、sudo、replace-config 审批
去重，并在 change 和 verify check 中标明所属 member。Neovim Python provider 可在单独
capability 或 terminal profile 的 plan、apply、verify 中一致地增加
`--with python-provider`。`plan` 不访问网络、不请求 sudo、不写用户目录；JSON 模式只在
stdout 输出协议数据，进度日志写入 stderr。

`editor.nvim` 从 `config/bootstrap/neovim.tsv`、`config/bootstrap/tree-sitter.tsv` 和
`config/runtime/editor.tsv` 读取 Neovim、tree-sitter、Go 与 gopls 的精确版本。安装、
plan 和 verify 共享这些 desired state；Neovim 启动时优先使用发布到 `~/.local/bin` 的
受管工具，因此不依赖启动它的旧终端是否已经重新加载 PATH。gopls 不再由 Mason 在编辑器
启动时隐式安装，Mason 只管理仓库未接管的插件工具。

Go 文件保存时会先通过已连接的 gopls 同步整理 import，再由 Conform 调用 LSP 格式化
（遵循 gopls 的 `gofumpt` 设置）；尚未连接 gopls 时仅回退到 `gofmt` 排版。
`:FormatDisable!` 关闭当前文件的保存格式化，`:FormatDisable` 全局关闭，
`:FormatEnable` 恢复。若 Go 补全或跳转不可用，先执行 `bin/mac-setup verify vim --format json`
检查受管 `~/.local/bin/gopls`，通过 plan/apply 修复，不要改用 Mason 的另一个版本。

`runtime.node` 从 `config/runtime/node.tsv` 读取 Node、Bun 和全局 npm 工具的唯一 desired
state，并从 `config/bootstrap/mise.tsv` 读取 mise 引导版本及 macOS/Linux、arm64/x64
资产的 SHA-256。安装、plan 和 verify 共享这两份 manifest；下载内容必须通过摘要校验后
才会解压，并通过同目录原子重命名发布。OpenCode 和 Codex CLI 也由 manifest 固定版本，
并把 Node、Bun、OpenCode 和 Codex 发布到 `~/.local/bin`，不依赖当前 Bash 是否已经
执行 `mise activate`。可以使用：

```bash
./bin/mac-setup plan node --format json
./bin/mac-setup apply node --plan-id <plan-id> --allow network \
  --non-interactive --format json
./bin/mac-setup verify node --format json
```

完整 `setup.sh` 和 `setup-lite.sh --with-zsh --with-agents` 都会同时安装 Agent CLI 与配置。
Linux 上安装器会把 Zsh 设置为账户的默认登录 shell；安装器无法修改它的父进程，因此当前
Bash 终端需要运行 `exec zsh -l`，或者关闭后重新打开终端。

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
- 键盘：[Toshy](https://github.com/RedBearAK/toshy)，使用 macOS 风格快捷键
- 启动器：[Vicinae](https://docs.vicinae.com/)，默认通过 `Ctrl+[` 唤起
- 触控板：[gestures 三指拖拽](docs/gestures.md)，Linux `sync` 发布配置：2.5 倍速度、
  150ms 释放延迟；程序安装与登录自启按文档手动启用，已在 XFCE/X11 试用。

完整 `./setup.sh` 在 Linux 平台阶段自动尝试安装 Toshy；精简安装通过
`./setup-lite.sh --with-platform` 包含此步骤，也可以单独执行：

```bash
./setup.sh --dry-run --modules toshy  # 预览
./setup.sh --modules toshy            # 在 Linux 桌面终端中交互安装
MAC_SETUP_SKIP_TOSHY=1 ./setup.sh     # 完整安装时跳过 Toshy
```

Toshy 需要普通用户的 X11/Wayland 桌面会话和交互终端。root/sudo 运行、无桌面、
非交互环境（如 CI/容器）和 `--no-root` 均会明确跳过，之后可在桌面终端单独重跑。
模块需要已有的 `curl`、`tar`、`python3`，下载固定提交的源码归档并验证 SHA-256，
再运行官方 `python3 ./setup_toshy.py install`。版本与校验值一起记录在
`modules/toshy.sh`；此固定范围为 Toshy 源码，上游安装器仍自行管理其系统/Python 依赖。

安装器保留官方交互提示，自行请求 sudo、安装依赖、配置 udev/input 权限和用户服务。
请按提示操作；GNOME Wayland 可能还需安装并启用兼容扩展，权限变更后可能需要注销或重启。
完成后运行 `toshy-services-status` 检查服务，并在实际应用中确认快捷键。
安装后以及检测到已有 Toshy 时，模块会同步 `config/toshy/` 中的默认快捷键：

- 按住 `d` + `h/j/k/l` → 左/下/上/右；单击 `d` 仍输入字母。
  Ghostty 的 Linux 配置会忽略导航使用的 F24，避免控制序列进入 shell；
  `d` 与空格重叠时依次输出 `d` 和空格。
  与其他普通字母、数字或常用标点重叠时补回 `d`；一旦识别为普通输入，
  本次按住 D 期间的后续字母继续按文本输出，避免 `mkdir` 丢失 `d`。
- Caps Lock 单击为 Esc，按住为 Ctrl。
- Cmd+Space 直接调用 `fcitx5-remote -t` 切换输入法。
- 移除 Fcitx 的 Ctrl+Space 切换绑定，为 Herdr 前缀保留该组合键。
- 为 Vicinae 将 GUI 应用中的实体 Ctrl+[ 恢复为字面的 Ctrl+[。

快捷键写入 Toshy 的 `user_custom_modmaps` / `user_apps` 用户区域内的受管块，
其他配置保留；重复运行不会重复插入。会迁移本仓库此前手动添加的相同快捷键；
若同名快捷键已被自行修改则停止，请先解决冲突。上游重装会保留这些用户区域。
Fcitx 只修改 TriggerKeys 中的 Ctrl+Space，其余快捷键和设置保留；没有配置文件时
创建空的 TriggerKeys 列表，禁用其默认 Ctrl+Space。此步骤不安装 Fcitx，
Cmd+Space 需要另行安装并启动 Fcitx5；`d` 组合键在快速打字时可能误触。

同步会使用 Toshy 的 Python runtime 校验完整配置，失败时恢复原配置文件，
不会创建含用户配置的备份。更改后重载运行中的 Fcitx 并重启运行中的 Toshy 用户服务；
未启动的服务仍需按上游提示启动、注销或重启。可在桌面终端重新运行
`./setup.sh --modules toshy` 同步后续配置更新。

Toshy 的更新、修复和卸载仍使用
[上游安装器](https://github.com/RedBearAK/toshy#how-to-install)及其 `install` / `uninstall`
命令，不由配置同步模块覆盖。

### Vicinae 默认安装

完整 `./setup.sh` 的 Linux 平台阶段会在 Toshy 之后安装并配置 Vicinae；
精简安装通过 `./setup-lite.sh --with-platform` 包含此步骤。也可单独运行：

```bash
./setup.sh --dry-run --modules vicinae
./setup.sh --modules vicinae
MAC_SETUP_SKIP_VICINAE=1 ./setup.sh  # 跳过安装、配置和服务操作
```

模块要求普通用户的 Linux 桌面交互终端、Python 3 和 systemd 用户服务。
root/sudo 运行、无桌面、非交互环境及 `--no-root` 会明确跳过。已有 Vicinae 时
不重新安装，但仍合并配置并重启用户服务；启动后检查服务状态、自启动状态和 `vicinae ping`。

- Arch x86_64 使用已有的 `yay` 或 `paru` 交互安装 `vicinae-bin`，包及依赖由 AUR/系统管理。
  不自动安装 AUR helper；没有 helper 时停止并提示。XFCE 的 Secret Service 提供者
  可选择 `gnome-keyring`。AUR 安装钩子会配置输入辅助程序权限，安装时请审阅提示。
- 其他 Linux（包括 Arch aarch64）使用 `config/bootstrap/vicinae.tsv` 固定的官方安装脚本和 AppImage，
  分别校验 SHA-256 后调用上游安装器，安装到 `~/.local`。支持 x86_64/aarch64；
  需已有 `curl`、`jq` 和 Node.js（可先运行 `./setup.sh --modules nodejs`）。
  不执行上游的浮动版本下载，也不自动授予输入设备权限；文本片段和粘贴功能可能
  需要按上游文档另行设置权限。升级时需一起更新版本/提交和校验值。

`config/vicinae/settings.json` 只管理 `global_shortcuts.toggle = control+[`。
合并器支持上游生成的 JSONC，保留其他设置值；需更新快捷键时会重新排版配置并去掉注释，
无需更新时不重写。配置文件保持可写，不链接整个用户配置目录，也不复制凭据数据库。
若 Toshy 已安装，会复用其配置同步器添加 Ctrl+[ 兼容映射并重载；不自动安装 Toshy。

模块导入桌面环境和包含 `~/.local/bin` 的 PATH，启用并重启 `vicinae.service`。
X11 支持原生全局快捷键；Wayland 取决于合成器支持，必要时在合成器中绑定
`vicinae toggle`。重跑 `./setup.sh --modules vicinae` 可同步配置。

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
│       ├── fonts.sh
│       ├── toshy.sh
│       └── vicinae.sh
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
- Linux: apt (Ubuntu/Debian) 或 pacman (Arch)

`nodejs` 模块通过固定版本的 mise 安装 Node.js 和 Bun；Agent ReMe 记忆桥接依赖这个
运行时。升级 mise 时，需要同时更新 `config/bootstrap/mise.tsv` 中四个平台的文件名和
官方 SHA-256，不能改回 `latest` 查询或未经校验的远程安装脚本。

## 测试

修改安装器后优先运行不触碰真实用户目录的回归测试：

```bash
bash test/setup-test.sh
bash test/toshy-test.sh
# 可选：使用已安装的 Toshy runtime 离线回放按键，不访问真实输入设备。
~/.config/toshy/.venv/bin/python test/toshy-events-test.py
bash test/vicinae-test.sh
bash test/nvim-go-test.sh
# 使用本机已有 Neovim、gopls 和 Conform，离线验证真实 import/格式化保存流程
bash test/nvim-go-test.sh --integration
bash test/agents-test.sh
bun test ./test/reme-memory-test.ts ./test/reme-bridge-test.ts
bash test/security-scan-test.sh
bash scripts/privacy-scan.sh

# Docker 中真实执行 Agent terminal 的 plan/apply/verify/replan 闭环
bash test/ubuntu-terminal-test.sh

# Docker 中执行 Ubuntu/Arch 全量安装：使用全新登录 Zsh 验收命令发现，
# 实际启动 Neovim/Lazy/tree-sitter/gopls 与 OpenCode/Codex 配置加载器，
# 然后再次完整安装并重复运行态验收，检查幂等性
bash test/ubuntu-test.sh
bash test/arch-test.sh
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

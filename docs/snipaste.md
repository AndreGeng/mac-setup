# Snipaste

macOS 和 Linux 桌面均包含 Snipaste，可单独执行：

```bash
./setup.sh --dry-run --modules snipaste
./setup.sh --modules snipaste
~/.local/bin/snipaste
```

完整安装的平台阶段会执行此模块；精简安装可使用 `--with-platform`。
`MAC_SETUP_SKIP_SNIPASTE=1` 可跳过安装。root/sudo、`--no-root` 和无 Linux 桌面会话
均跳过；本模块不自动启动软件或启用登录自启。

macOS 使用 Homebrew cask（Universal），已有应用则复用。首次运行按系统提示授予
屏幕录制权限。Linux 优先复用 `Snipaste` 命令，例如通过 AUR 安装的版本；
没有时根据 `config/bootstrap/snipaste.tsv` 下载固定版本的官方 x86_64 AppImage，
校验 SHA-256 后解压到 `~/.local/share/mac-setup/snipaste/2.11.3`，无需 FUSE 或 sudo。
Linux ARM 尚无此官方包，会明确跳过。

## 配置及启动

`config/snipaste/config.ini` 是最小默认模板，目前保留英文界面和软件自带快捷键。
模块首次复制到 `${XDG_CONFIG_HOME:-~/.config}/mac-setup/snipaste/config.ini`，
已有副本不覆盖；本地设置由软件自行保存。模板变化后如需更新，请退出 Snipaste，
手动将需要的设置合并进副本。

`~/.local/bin/snipaste` 使用官方 `--config=路径` 参数指定该副本。
Linux 应用菜单中的 **Snipaste (mac-setup)** 也使用此启动器。
macOS 请通过该命令启动以使用仓库配置；从原始应用图标启动可能使用原有配置。
如果已经有后台实例，请先从托盘退出，再使用启动器，否则配置参数可能不会生效。
不改写现有的 `~/.snipaste/config.ini` 或其他原生配置，也不修改原有开机启动项。

常用操作：F1 截图，框选后 Enter 复制，F3 贴图。
程序已经在后台运行时也可调用：

```bash
~/.local/bin/snipaste snip -o clipboard
```

截图历史、贴图、日志、保存目录、授权信息和机器相关状态不收录到仓库。
四指按住截图保持关闭。

## 更新及移除

Homebrew/AUR 安装由原包管理器更新和卸载。Linux 本地包由 mac-setup 管理，
升级时需同时审核和更新 manifest 与启动器内的固定版本。
移除前退出软件，再删除本模块发布的 `~/.local/bin/snipaste`、Linux 菜单文件
`~/.local/share/applications/mac-setup-snipaste.desktop` 和对应的版本目录。
配置副本和历史由用户决定是否保留；若设置了 XDG_DATA_HOME，菜单文件位于其 applications 下。

参考：[官方下载](https://www.snipaste.com/download.html)、
[官方命令行说明](https://github.com/Snipaste/feedback/wiki/Command-Line-Options)。

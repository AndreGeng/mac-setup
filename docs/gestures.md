# Linux 三指拖拽

仓库管理 `config/gestures/gestures.kdl`，由 Linux 的 `sync` 模块链接到
`~/.config/gestures/gestures.kdl`。参数是在 Apple bcm5974 触控板、XFCE/X11 上
试用的值：三指拖拽速度 2.5 倍，抬手后 150 毫秒释放左键。

四指左滑切到下一个工作区，右滑切到上一个工作区，抬手时触发。
此绑定通过 `xdotool set_desktop --relative` 控制 X11 工作区，不依赖键盘快捷键；
需要 `xdotool` 命令在服务的 PATH 中，并已配置至少两个工作区。
四指绑定仅适用于 X11，Wayland 需替换为对应桌面的命令。

四指按住不绑定操作，避免与四指滑动切工作区混淆。

同步只发布配置，不安装程序、不修改设备权限、不启动或重载服务。macOS 不同步此配置。

## 安装与试用

上游是 [ferstar/gestures](https://github.com/ferstar/gestures)，配置格式参见
[上游说明](https://github.com/ferstar/gestures/blob/v0.8.3/config.md)。
需要 Rust/Cargo、C 编译工具、pkg-config，以及 libinput、libudev、libxdo 开发库。
Arch 的 libxdo 由 xdotool 提供；Ubuntu/Debian 对应 libinput-dev、libudev-dev、
libxdo-dev。请先按发行版安装依赖。

推荐从固定源码构建，以匹配本机 libxdo 的 ABI；v0.8.3 官方预编译包依赖
`libxdo.so.3`，而新版 Arch xdotool 已提供 `libxdo.so.4`，不能通过改库名软链替代。

```bash
cargo install --git https://github.com/ferstar/gestures.git \
  --rev 9dcbb2192503c5fd46285345c244269386bbfc71 --locked
./setup.sh --dry-run --modules sync
./setup.sh --modules sync
gestures --x11 --conf "$HOME/.config/gestures/gestures.kdl" start
```

以上在桌面普通用户的终端执行，并确保 `~/.cargo/bin` 在 PATH 中。
`sync` 也会同步仓库的其他通用配置，已有普通文件按现有同步规则备份。
先停止此前运行的 gestures 实例，避免多个实例同时响应。前台试用时用 Ctrl+C 退出。
`/tmp` 下的试用程序不能作为持久安装或自启入口。

指针放在标题栏，三指移动拖动窗口；也支持拖文件和选择文字。
检查双指滚动、轻触点击、拖拽释放及防误触表现。程序需要访问触控板的
`/dev/input/event*`；先检查当前桌面会话的设备 ACL，不要默认以 root 运行或授予
所有输入设备权限。Wayland 需要额外的 ydotool/ydotoold，尚未在本仓库验证。

## 可选登录自启

试用满意、确认输入权限和依赖正常后，在桌面会话中运行上游命令：

```bash
gestures install-service --print
gestures install-service
systemctl --user enable --now gestures.service
journalctl --user -u gestures.service -n 25 --no-pager
```

上游生成的服务使用默认配置搜索路径；如果存在 `~/.config/gestures.kdl`，
它会优先于仓库的 `~/.config/gestures/gestures.kdl`。启用前确认没有旧配置覆盖。
上游管理二进制和生成的 systemd 用户服务，仓库仅管理 KDL 配置。

## 本机用户目录安装与 XFCE 自启记录

当前机器采用用户目录安装，不依赖 `/tmp` 中的文件：

| 项目 | 位置 / 版本 |
| --- | --- |
| gestures | `~/.local/bin/gestures`，v0.8.3，源码提交 `9dcbb2192503c5fd46285345c244269386bbfc71` |
| xdotool | `~/.local/bin/xdotool`，上游标签 `v3.20211022.1`，提交 `eb489de1b4fb3fd0cd935d68ae16ecd4c653ac7d` |
| libxdo | `~/.local/lib/libxdo.so.3`，与上述 xdotool 一起从源码构建 |
| 手势配置 | 服务显式读取 `/home/mac/mac-setup/config/gestures/gestures.kdl` |
| 用户服务 | 上游 `gestures install-service` 生成 `~/.config/systemd/user/gestures.service` |
| 服务补充配置 | `~/.config/systemd/user/gestures.service.d/desktop.conf` |
| XFCE 登录自启 | `~/.config/autostart/mac-setup-gestures.desktop` |

以下为本机安装的复现步骤，需事先准备好上一节所列构建依赖。下载源码和依赖需要
联网；在空的构建目录中执行，不覆盖现有源码。已有 Rust 工具链需加入 PATH。
本机使用 `~/.rustup/toolchains/1.88.0-x86_64-unknown-linux-gnu/bin`。

```bash
git clone --depth 1 --branch v3.20211022.1 https://github.com/jordansissel/xdotool.git
make -C xdotool -j2 PREFIX="$HOME/.local" \
  libxdo.so libxdo.so.3 xdotool installlib installprog

git clone https://github.com/ferstar/gestures.git
git -C gestures checkout 9dcbb2192503c5fd46285345c244269386bbfc71
LIBRARY_PATH="$HOME/.local/lib" \
  RUSTFLAGS="-L native=$HOME/.local/lib -C link-arg=-Wl,-rpath,$HOME/.local/lib" \
  cargo build --release --locked --manifest-path gestures/Cargo.toml
install -Dm755 gestures/target/release/gestures "$HOME/.local/bin/gestures"
"$HOME/.local/bin/gestures" install-service
```

上游管理生成的主服务；以下补充配置由本机维护，不直接修改上游输出。
`~/.config/systemd/user/gestures.service.d/desktop.conf` 内容：

```ini
[Service]
Environment=PATH=/home/mac/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=
ExecStart=/home/mac/.local/bin/gestures --x11 --conf /home/mac/mac-setup/config/gestures/gestures.kdl start
Restart=on-failure
RestartSec=5
```

`~/.config/autostart/mac-setup-gestures.desktop` 内容：

```ini
[Desktop Entry]
Type=Application
Name=Touchpad Gestures
Comment=Start touchpad gestures after desktop login
Exec=sh -c "systemctl --user import-environment DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP; systemctl --user restart gestures.service"
Terminal=false
StartupNotify=false
```

复现时先创建上述两个文件的父目录，再保存内容。路径针对当前用户和仓库位置；
迁移用户或移动仓库时必须相应调整。仓库仅记录这些本机配置，`sync` 不会发布它们。
XFCE 自启项在登录桌面后导入 X11 环境并重启服务；systemd 同时启用用户服务，
异常退出后每 5 秒重试。这里的“开机自启”指登录图形桌面后可用。

在桌面终端启用并验证：

```bash
systemctl --user import-environment DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
systemctl --user daemon-reload
systemctl --user enable --now gestures.service
systemctl --user is-enabled gestures.service
systemctl --user is-active gestures.service
journalctl --user -u gestures.service -n 25 --no-pager
"$HOME/.local/bin/xdotool" get_num_desktops
```

本次验证结果为 `enabled`、`active`，进程成功打开 bcm5974 触控板的
`/dev/input/event7`；设备编号可能随启动变化。未扩大输入设备权限，未使用 root
运行 gestures。实际手势还需在触控板上检查。

## 重载与停止

修改仓库配置后，已运行的实例需执行 `~/.local/bin/gestures reload`。停止和取消自启：

```bash
systemctl --user disable --now gestures.service
~/.local/bin/xdotool mouseup 1
```

停止前先抬起手指；`mouseup` 用于释放可能残留的模拟左键状态。

本机还配置了 XFCE 自启项；要永久取消登录自启，需同时在 XFCE 的“会话和启动”中
禁用 Touchpad Gestures，否则下次登录仍会启动该服务。

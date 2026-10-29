# Linux 三指拖拽

仓库管理 `config/gestures/gestures.kdl`，由 Linux 的 `sync` 模块链接到
`~/.config/gestures/gestures.kdl`。参数是在 Apple bcm5974 触控板、XFCE/X11 上
试用的值：三指拖拽速度 2.5 倍，抬手后 150 毫秒释放左键。

四指左滑切到下一个工作区，右滑切到上一个工作区，抬手时触发。
此绑定通过 `xdotool set_desktop --relative` 控制 X11 工作区，不依赖键盘快捷键；
需要 `xdotool` 命令在服务的 PATH 中，并已配置至少两个工作区。
四指绑定仅适用于 X11，Wayland 需替换为对应桌面的命令。

四指轻放并停住，随后抬起，会直接框选截图并复制到剪贴板
（`xfce4-screenshooter --region --clipboard`），不再选择后续操作。
需安装 `xfce4-screenshooter`；它与四指滑动共用手指数，试用时检查是否误触。
gestures v0.8.3 在 hold 结束时执行命令，而不是手指仍停在触控板上时执行。

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
先停止此前运行的 gestures 实例，避免多个实例同时响应；本次临时试用可用
`/tmp/mac-setup-gestures-trial/stop.sh` 停止。前台试用时用 Ctrl+C 退出。

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

修改仓库配置后，已运行的实例需执行 `gestures reload`。停止和取消自启：

```bash
systemctl --user disable --now gestures.service
xdotool mouseup 1
```

停止前先抬起手指；`mouseup` 用于释放可能残留的模拟左键状态。

# LocalSend

LocalSend 用于 Linux 电脑与 iPhone、Android、macOS、Windows 等设备在局域网内
互传文件和文字，无需云端账户。两端需打开 LocalSend，手机允许本地网络访问。

```bash
./setup.sh --dry-run --modules localsend
./setup.sh --modules localsend
```

完整安装的 Linux 平台阶段会自动执行该模块；精简安装使用
`./setup-lite.sh --with-platform`，也可以单独选择 `--modules localsend`。

Arch 使用已有的 `yay` 或 `paru` 安装 `localsend-bin`，保留 AUR 审阅和 sudo 提示，
不自动安装 AUR helper，也不以 root 运行它。该包使用上游预编译文件，校验由
审阅后的 PKGBUILD 管理。更新和卸载沿用 AUR helper / pacman。
其他 Linux 会复用已有的 `localsend` / `localsend_app` 命令；未安装时提示手动安装，
不会添加软件源或绕过系统包管理器。

已安装时直接复用，不覆盖偏好设置，不启动软件、不添加自启动、不修改防火墙。
root/sudo、`--no-root`、无桌面会话或 `MAC_SETUP_SKIP_LOCALSEND=1` 时跳过；
需要安装但没有交互终端时也会跳过。

从应用菜单打开 LocalSend，在「设置 → 接收」选择保存目录。
未配置 XDG 下载目录时，文件可能存到主目录；可手动选择 `~/Downloads`。
个人偏好、传输历史和收到的文件均不收录到仓库。

验证：`bash test/localsend-test.sh`。测试使用临时 HOME 和模拟安装器，不联网、不安装软件。

参考：[上游项目及安装渠道](https://github.com/localsend/localsend)、
[AUR localsend-bin](https://aur.archlinux.org/packages/localsend-bin)。
